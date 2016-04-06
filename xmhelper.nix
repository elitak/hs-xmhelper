{
  stdenv, mkDerivation,
  aeson, base, bytestring, foldl, regex-applicative, text, turtle,
  transmission
}:
with stdenv.lib;
let
  aliases = [
    "xmo"
    "xmcheck"
    "xmf"
    "xmclean"
    "xmtest"
  ];
in
mkDerivation {
  pname = "xmhelper";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    aeson
    base
    bytestring
    foldl
    regex-applicative
    text
    turtle
  ];
  license = stdenv.lib.licenses.unfree;
  postPatch = ''
    substituteInPlace src/Main.hs --replace \"transmission-remote \"${transmission}/bin/transmission-remote
  '';
  postInstall = ''
    for alias in ${concatStringsSep " " aliases}; do
      ln -s xm $out/bin/$alias
    done
  '';
}
