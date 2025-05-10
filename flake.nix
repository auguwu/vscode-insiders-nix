{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = {nixpkgs, ...}: let
    eachSystem = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "armv7l-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    nixpkgsFor = system: import nixpkgs {inherit system;};
  in {
    formatter = eachSystem (system: (nixpkgsFor system).alejandra);
    packages = eachSystem (system: let
      pkgs = nixpkgsFor system;
      vscode = (import ./overlay.nix {} pkgs).vscode;
    in {
      inherit vscode;
      default = vscode;
    });

    overlays.default = import ./overlay.nix;
  };
}
