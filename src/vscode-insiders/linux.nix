{
  pname,
  version,
  src,
  vscode,
  webkitgtk_4_1,
  libsoup_3,
  openssl,
  curl,
  makeDesktopItem,
  longName,
  libglvnd,
  bash,
  stdenv,
  lib,
  ripgrep,
  libxtst,
  pipewire,
  libjpeg8,
  libei,
}:
vscode.overrideAttrs (old: {
  inherit pname version src;

  desktopItems = [
    (makeDesktopItem {
      name = "code-insiders";
      desktopName = longName;
      comment = "Code Editing. Redefined.";
      genericName = "Text Editor";
      exec = "code-insiders %F";
      icon = "vscode-insiders";
      startupNotify = true;
      startupWMClass = "Code - Insiders";
      categories = [
        "Utility"
        "TextEditor"
        "Development"
        "IDE"
      ];

      keywords = ["vscode"];
      actions.new-empty-window = {
        name = "New Empty Window";
        exec = "code-insiders --new-window %F";
        icon = "vscode-insiders";
      };
    })

    (makeDesktopItem {
      name = "code-insiders-url-handler";
      desktopName = longName + " - URL Handler";
      comment = "Code Editing. Redefined.";
      genericName = "Text Editor";
      exec = "code-insiders --open-url %U";
      icon = "vscode-insiders";
      startupNotify = true;
      startupWMClass = "Code - Insiders";
      categories = [
        "Utility"
        "TextEditor"
        "Development"
        "IDE"
      ];

      mimeTypes = ["x-scheme-handler/vscode-insiders"];
      keywords = ["vscode"];
      noDisplay = true;
    })
  ];

  # i want microsoft to jump off a cliff for making me do this
  autoPatchelfIgnoreMissingDeps = [
    "libcublas.so.12"
    "libcublasLt.so.12"
    "libcudart.so.12"
    "libcurand.so.10"
    "libcufft.so.11"
    "libcudnn.so.9"
    "libnvinfer.so.10"
    "libnvonnxparser.so.10"
  ];

  nativeBuildInputs =
    old.nativeBuildInputs
    ++ [
      # i fucking hate you microsoft
      libxtst
      pipewire
      libjpeg8
      libei

      # These are required by `libmsalruntime.so` because god forbid Microsoft
      # does this shit correctly, which only is avaliable on Linux for some
      # god fucking reason
      webkitgtk_4_1
      libsoup_3
      openssl
      curl
    ];

  installPhase = ''
    runHook preInstall

    # `$out` is not previously created, so we need to create it first before
    # doing anything.
    mkdir -p "$out"
    mkdir -p "$out/lib/vscode" "$out/bin"
    cp -r ./* "$out/lib/vscode"
    ln -s "$out/lib/vscode/bin/code-insiders" "$out/bin/code-insiders"

    # These are named vscode.png, vscode-insiders.png, etc to match the name in upstream *.deb packages.
    mkdir -p "$out/share/pixmaps"
    cp "$out/lib/vscode/resources/app/resources/linux/code.png" "$out/share/pixmaps/vscode-insiders.png"

    # Override the previously determined VSCODE_PATH with the one we know to be correct
    sed -i "/ELECTRON=/iVSCODE_PATH='$out/lib/vscode'" "$out/bin/code-insiders"

    # Remove native encryption code, as it derives the key from the executable path which does not work for us.
    # The credentials should be stored in a secure keychain already, so the benefit of this is questionable
    # in the first place.
    rm -rf "$out/lib/vscode/resources/app/node_modules/vscode-encrypt"

    runHook postInstall
  '';

  # Modified version of `vscode`'s `postPatch`.
  # more: https://github.com/NixOS/nixpkgs/issues/49643#issuecomment-873853897
  # from: https://github.com/NixOS/nixpkgs/blob/08a2d5fff737305a13c39a47a49cf8590567220d/pkgs/applications/editors/vscode/generic.nix#L382-L454
  postPatch =
    # disable update checks
    ''
      tmpProductJson="$(mktemp)"
      jq 'del(.updateUrl, .backupUpdateUrl)' resources/app/product.json > "$tmpProductJson"
      mv "$tmpProductJson" resources/app/product.json
    ''
    +
    # this is a fix for "save as root" functionality
    ''
      packed="resources/app/node_modules.asar"
      unpacked="resources/app/node_modules"
      asar extract "$packed" "$unpacked"
      substituteInPlace $unpacked/@vscode/sudo-prompt/index.js \
        --replace-fail "/usr/bin/pkexec" "/run/wrappers/bin/pkexec" \
        --replace-fail "/bin/bash" "${bash}/bin/bash"

      rm -rf "$packed"
    ''
    +
    # without this symlink loading JsChardet, the library that is used for auto encoding detection when files.autoGuessEncoding is true,
    # fails to load with: electron/js2c/renderer_init: Error: Cannot find module 'jschardet'
    # and the window immediately closes which renders VSCode unusable
    # see https://github.com/NixOS/nixpkgs/issues/152939 for full log
    ''
      ln -rs "$unpacked" "$packed"
    ''
    + (
      let
        nodeModulesPath = "resources/app/node_modules";

        # see https://www.npmjs.com/package/@vscode/ripgrep-universal?activeTab=code
        ripgrepSystem =
          {
            x86_64-darwin = "darwin-x64";
            aarch64-darwin = "darwin-arm64";
            armv7l-linux = "linux-arm";
            aarch64-linux = "linux-arm64";
            i686-linux = "linux-ia32";
            powerpc64-linux = "linux-ppc64";
            riscv64-linux = "linux-riscv64";
            s390x-linux = "linux-s390x";
            x86_64-linux = "linux-x64";
          }
          .${
            stdenv.hostPlatform.system
          }
            or (throw "Unknown system for ripgrep-universal: ${stdenv.hostPlatform.system}");

        ripgrepPath =
          if lib.versionAtLeast version "1.122.0"
          then "@vscode/ripgrep-universal/bin/${ripgrepSystem}/rg"
          else "@vscode/ripgrep/bin/rg";

        vscodeRipgrep = "${nodeModulesPath}/${ripgrepPath}";
      in ''
        rm ${vscodeRipgrep}
        ln -s ${ripgrep}/bin/rg ${vscodeRipgrep}
      ''
    );

  # postFixup are a modified version of nixpkgs' version of the `vscode` derivation
  # https://github.com/NixOS/nixpkgs/blob/00c1e4a18675a620cc582dc81c744766e3badb6e/pkgs/applications/editors/vscode/generic.nix#L327-L333
  postFixup = ''
    patchelf \
      --add-needed ${libglvnd}/lib/libGLESv2.so.2 \
      --add-needed ${libglvnd}/lib/libGL.so.1 \
      --add-needed ${libglvnd}/lib/libEGL.so.1 \
      $out/lib/vscode/code-insiders
  '';
})
