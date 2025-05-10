let
  lockfile = builtins.fromJSON (builtins.readFile ./flake.nix);
  rev = lockfile.nodes.nixpkgs.locked;

  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/${rev.owner}/${rev.repo}/archive/${rev.rev}";
    narHash = rev.sha256;
  };

  pkgs = import nixpkgs {
    config = {};
    overlays = [];
  };
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      # used for ./hack/generateSystems.js
      nodejs_latest
    ];
  }
