{
  pname,
  version,
  src,
  vscode,
  longName,
  undmg,
  stdenv,
  lib,
}:
vscode.overrideAttrs (old: {
  inherit pname version src;

  nativeBuildInputs =
    old.nativeBuildInputs
    ++ [
      undmg
    ];

  sourceRoot = "${longName}.app";
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications/${longName}.app" "$out/bin"
    cp -r ./* "$out/Applications/${longName}.app"
    ln -s "$out/Applications/${longName}.app/Contents/Resources/app/bin/code" "$out/bin/code-insiders"

    # home-manager expects `code` to be available for some reason
    ln -s "$out/Applications/${longName}.app/Contents/Resources/app/bin/code" "$out/bin/code"

    runHook postInstall
  '';

  # Modified version of `vscode`'s `postPatch`.
  # more: https://github.com/NixOS/nixpkgs/issues/49643#issuecomment-873853897
  # from: https://github.com/NixOS/nixpkgs/blob/08a2d5fff737305a13c39a47a49cf8590567220d/pkgs/applications/editors/vscode/generic.nix#L382-L454
  postPatch = (
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
      chmod +x ${vscodeRipgrep}
    ''
  );
})
