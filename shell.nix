let
  lockfile = builtins.fromJSON (builtins.readFile ./flake.lock);
  rev = lockfile.nodes.nixpkgs.locked;

  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/${rev.owner}/${rev.repo}/archive/${rev.rev}";
    sha256 = rev.narHash;
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
