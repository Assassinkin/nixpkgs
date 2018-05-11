{ stdenv, pkgs, buildPythonPackage, fetchPypi, ipaddress, six, simplejson }:

buildPythonPackage rec {
 pname = "mail-parser";
 version = "3.3.1";

   src = fetchPypi {
     inherit pname version;
     sha256 = "0w8hwcld67j6hqzjycbbqk6pvsjpg0a5si6fzzdhzdh7h55y6gd9";
   };

   propagatedBuildInputs = [ ipaddress six simplejson ];

   doCheck = false;

   meta = with stdenv.lib; {
     description = "A mail parser for python 2 and 3";
     homepage = https://github.com/SpamScope/mail-parser;
     license = licenses.asl20;
     maintainers = with maintainers; [ Assassinkin ];
   };
}
