{ stdenv, buildPythonPackage, fetchPypi, isPy3k, python_magic, pypdf2, passlib, beautifulsoup4, icalendar, lxml, bcrypt, pdfkit, html5lib, requests, dns, dkimpy }:

buildPythonPackage rec {
  pname = "gpgmailencrypt";
  version = "3.4.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0vn62hv4fw5ahrd3kjhhrp90kgkbvrifnz8ky1vd1fjpval8jgvd";
  };

  disabled = !isPy3k;

  propagatedBuildInputs = [ python_magic pypdf2 passlib beautifulsoup4 icalendar lxml bcrypt pdfkit  html5lib requests ];

  checkInputs = [ dns dkimpy ];
  # Fails when trying to import a local module!!
  #doCheck = false;

  meta = with stdenv.lib; {
    description = "an e-mail encryption, virus- and spam- checking module, gateway and daemon";
    homepage = https://github.com/gpgmailencrypt/gpgmailencrypt;
    license = licenses.gpl3;
    maintainers = with maintainers; [ psyanticy ];
  };

}

