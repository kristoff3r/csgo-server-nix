{ stdenv, fetchurl, unzip }:

stdenv.mkDerivation {
  name = "csgo-retakes";
  src = fetchurl {
    url = "https://github.com/splewis/csgo-retakes/releases/download/v0.3.4/retakes_0.3.4.zip";
    sha256 = "sha256-r7iJ/vFkqZvknOKOJ9xaGWva7B62vANVVydhlmChg04";
  };

  nativeBuildInputs = [
    unzip
  ];

  phases = [ "installPhase" ];

  installPhase = ''
    unzip $src
    mkdir -p $out/addons/sourcemod/plugins
    mkdir -p $out/cfg/sourcemod
    cp addons/sourcemod/plugins/retakes.smx $out/addons/sourcemod/plugins
    cp -r addons/sourcemod/translations $out/addons/sourcemod
    cp -r cfg/sourcemod/retakes $out/cfg/sourcemod
  '';
}
