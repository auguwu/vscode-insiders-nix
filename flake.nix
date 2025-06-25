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

    nixpkgsFor = system:
      import nixpkgs {
        inherit system;

        # Allow building `vscode-insiders` as the derivation uses
        # Microsoft's official packaging.
        config.allowUnfree = true;
      };
  in {
    formatter = eachSystem (system: (nixpkgsFor system).alejandra);
    packages = eachSystem (system: let
      pkgs = nixpkgsFor system;
      vscode-insiders = (import ./overlay.nix {} pkgs).vscode-insiders;
    in {
      inherit vscode-insiders;
      default = vscode-insiders;
    });

    overlays.default = import ./overlay.nix;
  };
}
