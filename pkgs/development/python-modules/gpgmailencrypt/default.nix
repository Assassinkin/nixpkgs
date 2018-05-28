{ stdenv, buildPythonPackage, fetchPypi, isPy3k, python, coreutils, gnupg, openssl, pdftk, p7zip, wkhtmltopdf
, pypdf2, beautifulsoup4, icalendar, python_magic, lxml, requests, passlib, bcrypt, html5lib }:

buildPythonPackage rec {
  pname = "gpgmailencrypt";
  version = "3.4.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0vn62hv4fw5ahrd3kjhhrp90kgkbvrifnz8ky1vd1fjpval8jgvd";
  };

  disabled = !isPy3k;

  makeWrapperArgs = ["--prefix" "PATH" ":" "${stdenv.lib.makeBinPath [ coreutils openssl gnupg pdftk p7zip wkhtmltopdf ]}" ];
  # html5lib  dns dkimpy html5lib
  propagatedBuildInputs = [ pypdf2 beautifulsoup4 icalendar python_magic lxml requests passlib bcrypt html5lib ];
  #checkinputs = [ coreutils ];
  # Fails when trying to import a local module!!
  checkPhase = ''
    ${python.interpreter} tests/gmeunittests.py -vbc
  '';
  doCheck = false;

  meta = with stdenv.lib; {
    description = "an e-mail encryption, virus- and spam- checking module, gateway and daemon";
    homepage = https://github.com/gpgmailencrypt/gpgmailencrypt;
    license = licenses.gpl3;
    maintainers = with maintainers; [ psyanticy ];
  };

}
