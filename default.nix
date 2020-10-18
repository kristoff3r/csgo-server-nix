{ pkgs ? import <nixpkgs> { } }:

rec {
  nixos = import ./nixos;
  plugins = import ./plugins { inherit pkgs ambuild; };
  ambuild = pkgs.callPackage ./deps/ambuild.nix { inherit (pkgs.python3Packages) buildPythonPackage; };
}
