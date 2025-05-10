### 🐻‍❄️💵 Visual Studio Code - Insiders
#### *Nix flake that tracks all [Visual Studio Code - Insiders] releases*

This project is a successor of [`cideM/visual-studio-code-insiders-nix`], this will track all releases of Visual Studio Code - Insiders on a scheduled cron job via GitHub Actions and will publish artifacts on [`noel.cachix.org`], in the future, it'll use `nix.noel.pink` as the binary cache.

## Usage
### Nix Flake
You can use this repository as a flake input and pull the `vscode-insiders` derivation from the overlay:

```nix
{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        vscode-insiders = {
            url = "github:auguwu/vscode-insiders-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { nixpkgs, vscode-insiders, ... }: let
        overlays = [(import vscode-insiders)];

        myNixPkgs = import nixpkgs { system = "x86_64-linux"; };
    in {
        /* when you use `myNixPkgs`, there will be a `vscode-insiders` derivation avaliable */
    };
}
```

## License
This project is released under the **Unlicense**. You can use the Nix flake as you like and modify it to your liking.

[`cideM/visual-studio-code-insiders-nix`]: https://github.com/cideM/visual-studio-code-insiders-nix
[Visual Studio Code - Insiders]: https://code.visualstudio.com/insiders
[`noel.cachix.org`]: https://noel.cachix.org
