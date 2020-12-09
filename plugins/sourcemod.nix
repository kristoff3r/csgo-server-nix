{ multiStdenv, fetchgit, ambuild, hl2sdk-csgo, metamod-source, git }:

multiStdenv.mkDerivation rec {
  name = "sourcemod-${version}";
  version = "1.10";

  src = fetchgit {
    url = "https://github.com/alliedmodders/sourcemod.git";
    rev = "39c2dc60e0c0d963cfbe39bee3a7cf953cc8055c";
    sha256 = "sha256-SwrBuOAebmLq5bgjw5i8CFuEDTtvDqLYY/dk4holrzw=";
  };

  buildInputs = [
    ambuild
    git
  ];

  hardeningDisable = [ "all" ];

  buildPhase = ''
    # Requires a valid git HEAD to build
    git init
    git config user.email "you@example.com"
    git config user.name "Your Name"
    git add .
    git commit -m "dummy commit"

    # Build
    ln -s ${hl2sdk-csgo} hl2sdk-csgo
    ln -s ${metamod-source}/include metamod-source
    mkdir build
    cd build
    python ../configure.py --sdks present --no-mysql
    ambuild
  '';

  installPhase = ''
    mkdir $out
    mv package $out/share
  '';
}
