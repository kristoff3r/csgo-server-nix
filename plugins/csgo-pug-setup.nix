{ stdenv, fetchurl, unzip }:

stdenv.mkDerivation {
  name = "csgo-pug-setup";
  src = fetchurl {
    url = "https://github.com/splewis/csgo-pug-setup/releases/download/2.0.5/pugsetup_2.0.5.zip";
    sha256 = "sha256-w3A7nhCdzoWIeMBFzt+2BgZ5lleFmPccZupa4IEoRps=";
  };

  nativeBuildInputs = [
    unzip
  ];

  phases = [ "installPhase" ];

  installPhase = ''
    unzip $src
    mkdir -p $out/share
    cp -r . $out/share
  '';
}
