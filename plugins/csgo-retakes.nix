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
    mkdir -p $out/share/addons/sourcemod/plugins
    mkdir -p $out/share/cfg/sourcemod
    cp addons/sourcemod/plugins/retakes.smx $out/share/addons/sourcemod/plugins
    cp -r addons/sourcemod/translations $out/share/addons/sourcemod
    cp -r cfg/sourcemod/retakes $out/share/cfg/sourcemod
  '';
}
