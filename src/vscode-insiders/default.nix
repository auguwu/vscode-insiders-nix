{
  fetchzip,
  fetchurl,
  stdenv,
  callPackage,
}: let
  # version comes from `package.json` of the `microsoft/vscode` repository
  version = "1.110.0";
  longName = "Visual Studio Code - Insiders";
  systems = import ../../systems.nix {inherit fetchzip fetchurl;};
  pname = "vscode-insiders";
  src = systems.${stdenv.hostPlatform.system} or (throw "unsupported system: ${stdenv.hostPlatform.system}");

  package =
    if stdenv.hostPlatform.isLinux
    then ./linux.nix
    else ./darwin.nix;
in
  callPackage package {inherit pname version src longName;}
