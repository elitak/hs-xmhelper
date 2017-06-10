{
  stdenv, mkDerivation,
  aeson, base, bytestring, foldl, regex-applicative, text, turtle
}:
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
}
