{ pkgs ? import <nixpkgs> {}, compiler ? "ghc7102" }:
with pkgs.lib;
let
  aliases = [
    "xmo"
    "xmcheck"
    "xmf"
    "xmclean"
    "xmtest"
  ];
in overrideDerivation (pkgs.haskell.packages.${compiler}.callPackage ./xmhelper.nix { }) (oldAttrs: {
  # TODO move out into default, replace this file with nontracked package.nix. ALSO add upperlevel abstraction to notify when that nixfile is missing! (add to src/nix-template or whatev)
  inherit (pkgs) rsync transmission;
  postPatch = ''
    substituteAllInPlace src/CommandPaths.hs
  '';
  postInstall = ''
    for alias in ${concatStringsSep " " aliases}; do
      ln -s xm $out/bin/$alias
    done
  '';
})
