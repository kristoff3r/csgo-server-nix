{ multiStdenv, fetchgit, hl2sdk-csgo, ambuild, git }:

multiStdenv.mkDerivation rec {
  name = "metamod-source-${version}";
  version = "1.10";

  src = fetchgit {
    url = "https://github.com/alliedmodders/metamod-source.git";
    # Current master
    rev = "b8d1fd401d685fe711ad27e4e169742bd8a51978";
    sha256 = "sha256-8rQJ99f+XxD+rSP7OpyU5Ml+Wwp/SqJ9+B9EEWmcqDY=";
    # dev-1.10 (doesn't work, seems abandoned)
    # rev = "6c8495f05825c71a9ba53d03a88047e3c4088f5d";
    # sha256 = "sha256-FMZmoBS4xA/QbUaeSu3oreAwhwH8uNHzN9z0pQdB1hA=";
  };

  buildInputs = [
    ambuild
    git
  ];

  hardeningDisable = [ "all" ];

  CFLAGS="-Wno-error=class-memaccess";

  buildPhase = ''
    git init
    git config user.email "you@example.com"
    git config user.name "Your Name"
    git add .
    git commit -m "dummy commit"
    ln -s ${hl2sdk-csgo} hl2sdk-csgo
    mkdir build
    cd build
    python ../configure.py --sdks present
    ambuild
  '';

  installPhase = ''
    mkdir $out
    mv package $out/share
    cp -r $src $out/include
  '';
}
