# crossbuild.nix is a builder that builds the `vscode-insiders` package
# in CI. Since we're not actually doing cross-compilation, it is easy to
# see where we might've messed up.
#
# Example:
#    # Build the `x86_64-linux` version of the derivation
#    $ nix build --file crossbuild.nix --argstr system x86_64-unknown-linux-gnu
{system ? ""}: let
  lockfile = builtins.fromJSON (builtins.readFile ./flake.lock);
  rev = lockfile.nodes.nixpkgs.locked;
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/${rev.owner}/${rev.repo}/archive/${rev.rev}.tar.gz";
    sha256 = rev.narHash;
  };

  pkgs = import nixpkgs {
    crossSystem.config = system;
    config.allowUnfree = true;
  };

  vscode-insiders = import ./overlay.nix {} pkgs;
in
  vscode-insiders
