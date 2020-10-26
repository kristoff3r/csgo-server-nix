{ pkgs, ambuild }:

let
  hl2sdk-csgo = pkgs.fetchFromGitHub {
    owner = "alliedmodders";
    repo = "hl2sdk";
    rev = "1d2902bce6e556c6b5ec21732c53b7a066e21741";
    sha256 = "sha256-EoU5iCq37QfPFzrdWWk3tAlxFx399B+xgXQAXq2Bv1c=";
  };
in
rec {
  metamod-source = pkgs.callPackage ./metamod-source.nix { inherit hl2sdk-csgo ambuild; };
  sourcemod = pkgs.callPackage ./sourcemod.nix { inherit hl2sdk-csgo ambuild metamod-source; };
  csgo-retakes = pkgs.callPackage ./csgo-retakes.nix { };
  csgo-practice-mode = pkgs.callPackage ./csgo-practice-mode.nix { };
  csgo-pug-setup = pkgs.callPackage ./csgo-pug-setup.nix { };
}
