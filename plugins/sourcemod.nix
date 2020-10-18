{ multiStdenv, fetchgit, ambuild, hl2sdk-csgo, metamod-source, git }:

multiStdenv.mkDerivation rec {
  name = "sourcemod-${version}";
  version = "1.10";

  src = fetchgit {
    url = "https://github.com/alliedmodders/sourcemod.git";
    rev = "39c2dc60e0c0d963cfbe39bee3a7cf953cc8055c";
    sha256 = "sha256-hKbYuM/mR5Kw4F4FiCEHfMHEfFAod9gK3xLO/FoyNGE";
    leaveDotGit = true;
  };

  buildInputs = [
    ambuild
    git
  ];

  hardeningDisable = [ "all" ];

  buildPhase = ''
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
