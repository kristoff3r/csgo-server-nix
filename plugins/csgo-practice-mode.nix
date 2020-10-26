{ stdenv, fetchurl, unzip }:

stdenv.mkDerivation {
  name = "csgo-practice-mode";
  src = fetchurl {
    url = "https://github.com/splewis/csgo-practice-mode/releases/download/1.3.3/practicemode_1.3.3.zip";
    sha256 = "sha256-xuAGl9xjHwm93gy59NyE915iW4Lr7jd+//91WMqrs0U=";
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
