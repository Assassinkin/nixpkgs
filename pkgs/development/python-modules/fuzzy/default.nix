{ stdenv, buildPythonPackage, fetchPypi, cython, pytest, python, glibcLocales, isPy3k, setuptools_scm }:

buildPythonPackage rec {
  pname = "Fuzzy";
  version = "1.2.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "6b240e630235f183730b27fcb70fdd0d409bee2c3a4e7a964eeae093a28c4f38";
  };


  buildInputs = [ cython setuptools_scm ];
  checkInputs = [ pytest glibcLocales ];

  checkPhase = ''
    export LC_ALL=${if isPy3k then "UTF-8" else "en_US.UTF-8"}
    ${python.interpreter} -m pytest 
  '';

  meta = with stdenv.lib; {
    description = "A python library implementing common phonetic algorithms quickly";
    homepage = "https://github.com/yougov/Fuzzy";
    license = licenses.lgpl2;
    maintainers = with maintainers; [ psyanticy ];
  };
}
