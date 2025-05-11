# crossbuild.nix is a builder that builds the `vscode-insiders` package
# in CI. Since we're not actually doing cross-compilation, it is easy to
# see where we might've messed up.
#
# Example:
#    # Build the `x86_64-linux` version of the derivation
#    $ nix build --file crossbuild.nix --argstr system x86_64-unknown-linux-gnu
{system ? ""}: let
  lockfile = builtins.fromJSON (builtins.readFile ./flake.nix);
  rev = lockfile.nodes.nixpkgs.locked;
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/${rev.owner}/${rev.repo}/archive/${rev.rev}";
    narHash = rev.sha256;
  };

  pkgs = import nixpkgs {
    crossSystem.config = system;
  };

  vscode-insiders = import ./overlay.nix {} pkgs;
in
  vscode-insiders
