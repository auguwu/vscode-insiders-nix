{
  vscode,
  fetchzip,
  stdenv,
}: let
  systems = import ../systems.nix {inherit fetchzip;};
  system = stdenv.hostPlatform.system;
in
  vscode.overrideAttrs (old: {
    isInsiders = true;
    version = "1.101.0-insider";
    pname = "vscode-insiders";
    src = systems.${system} or throw "unsupported system: ${system}";

    preInstall =
      if system == "x86_64-darwin" || system == "aarch64-darwin"
      then ''
        cp ./Contents/Resources/app/bin/code ./Contents/Resources/app/bin/code-insiders
      ''
      else "";
  })
