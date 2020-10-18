{ pkgs, ambuild }:

let
  hl2sdk-csgo = pkgs.fetchFromGitHub {
    owner = "alliedmodders";
    repo = "hl2sdk";
    rev = "1d2902bce6e556c6b5ec21732c53b7a066e21741";
    sha256 = "sha256-EoU5iCq37QfPFzrdWWk3tAlxFx399B+xgXQAXq2Bv1c=";
  };
  metamod-source = pkgs.fetchFromGitHub {
    owner = "alliedmodders";
    repo = "metamod-source";
    rev = "6c8495f05825c71a9ba53d03a88047e3c4088f5d";
    sha256 = "sha256-FMZmoBS4xA/QbUaeSu3oreAwhwH8uNHzN9z0pQdB1hA=";
  };
in
{
  sourcemod = pkgs.callPackage ./sourcemod.nix { inherit hl2sdk-csgo ambuild metamod-source; };
  csgo-retakes = pkgs.callPackage ./csgo-retakes.nix { };
}
