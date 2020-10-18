{ lib, buildPythonPackage, fetchFromGitHub }:

buildPythonPackage rec {
  pname = "ambuild";
  version = "2.2";
  name = "${pname}-${version}";

  src = fetchFromGitHub {
    owner = "alliedmodders";
    repo = pname;
    rev = version;
    sha256 = "sha256-XJiQ+aGNuloMGdo51xT7OXjR6AvQvIrYe0BE8tx6M08";
  };

  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/alliedmodders/ambuild";
    description = "AMBuild is a lightweight build system designed for performance and accuracy";
    license = licenses.bsd3;
    maintainers = with maintainers; [ kristoff3r ];
  };
}
