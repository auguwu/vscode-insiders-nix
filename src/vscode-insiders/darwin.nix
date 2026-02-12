{
  pname,
  version,
  src,
  vscode,
  longName,
  undmg,
}:
vscode.overrideAttrs (old: {
  inherit pname version src;

  nativeBuildInputs =
    old.nativeBuildInputs
    ++ [
      undmg
    ];

  installPhase = ''
    mkdir -p "$out/Applications/${longName}.app" "$out/bin"
    cp -r ./* "$out/Applications/${longName}.app"
    ln -s "$out/Applications/${longName}.app/Contents/Resources/app/bin/code" "$out/bin/code-insiders"

    # home-manager expects `code` to be available for some reason
    ln -s "$out/Applications/${longName}.app/Contents/Resources/app/bin/code" "$out/bin/code"
  '';
})
