{ stdenv, buildPythonPackage,fetchurl, glibcLocales, fetchFromGitHub }:

buildPythonPackage rec {
  pname = "pyarabic";
  version = "0.6.4";

  # no tests in PyPI tarball
  src = fetchurl  {
    #owner = "linuxscout";
    #repo = pname;
    #rev = "${version}";
    url = "https://files.pythonhosted.org/packages/47/89/32f86a49c4a69adf41a71c5a79ccf4b3443efaf60b4fae9100b20dc1c9e4/PyArabic-0.6.4.tar.gz";
    sha256 = "ddf24211220d7964b348b7ab4faa823612cdfe73bbcb41e52b3ce379620ef14d";
  };

  nativeBuildInputs = [ glibcLocales ]; 
  LC_ALL = "en_US.utf-8";


  # No tests in the tarball
  doCheck = false;

  meta = with stdenv.lib; {
    description = "A specific Arabic language library for Python, provides basic functions to manipulate Arabic letters and text";
    homepage = https://pyarabic.sourceforge.io/;
    license = licenses.gpl;
    maintainers = with maintainers; [ psyanticy ];
  };
}
