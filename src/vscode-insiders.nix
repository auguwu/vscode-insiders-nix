{
  vscode,
  fetchzip,
  stdenv,
  lib,
  libglvnd,
  makeDesktopItem,
}: let
  systems = import ../systems.nix {inherit fetchzip;};
  system = stdenv.hostPlatform.system;

  longName = "Visual Studio Code - Insiders";

  # phases are a modified version of nixpkgs' version of the `vscode` derivation
  # https://github.com/NixOS/nixpkgs/blob/00c1e4a18675a620cc582dc81c744766e3badb6e/pkgs/applications/editors/vscode/generic.nix#L236-L270
  darwinInstallPhase = ''
    mkdir -p "$out/Applications/${longName}.app" "$out/bin"
    cp -r ./* "$out/Applications/${longName}.app"
    ln -s "$out/Applications/${longName}.app/Contents/Resources/app/bin/code" "$out/bin/code-insiders"
  '';

  linuxInstallPhase = ''
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
  '';
in
  vscode.overrideAttrs (old: {
    # version comes from `package.json` of the `microsoft/vscode` repository
    version = "1.104.0";
    pname = "vscode-insiders";
    src = systems.${system} or (throw "unsupported system: ${system}");

    # modified from the `vscode` derivation to make desktop items exist.
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

    # a modified version of nixpkgs' version of the `vscode` derivation
    # https://github.com/NixOS/nixpkgs/blob/00c1e4a18675a620cc582dc81c744766e3badb6e/pkgs/applications/editors/vscode/generic.nix#L236-L270
    installPhase = ''
      runHook preInstall

      ${
        if stdenv.hostPlatform.isDarwin
        then darwinInstallPhase
        else linuxInstallPhase
      }

      runHook postInstall
    '';

    # postFixup are a modified version of nixpkgs' version of the `vscode` derivation
    # https://github.com/NixOS/nixpkgs/blob/00c1e4a18675a620cc582dc81c744766e3badb6e/pkgs/applications/editors/vscode/generic.nix#L327-L333
    postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
      patchelf \
        --add-needed ${libglvnd}/lib/libGLESv2.so.2 \
        --add-needed ${libglvnd}/lib/libGL.so.1 \
        --add-needed ${libglvnd}/lib/libEGL.so.1 \
        $out/lib/vscode/code-insiders
    '';
  })
