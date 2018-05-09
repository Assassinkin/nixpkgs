{ stdenv, fetchurl, which }:

stdenv.mkDerivation {
  name = "ossec-client-2.7";

  src = fetchurl {
    url = https://github.com/ossec/ossec-hids/releases/download/v2.7/ossec-hids-2.7.tar.gz;

    sha256 = "0jbjfjfzwyga5d167d16s1zshs1sz9mr0g2fy6j8r2h6fiylmb7q";
  };

  buildInputs = [ which ];

  phases = [ "unpackPhase" "patchPhase" "buildPhase" ];

  patches = [ ./no-root.patch ];

  buildPhase = ''
    echo "en

agent
$out
127.0.0.1
yes
yes
yes


"   | ./install.sh
  '';

  meta = {
    description = "Open soruce host-based instrusion detection system";
    homepage = http://www.ossec.net;
    license = stdenv.lib.licenses.gpl2;
    platforms = stdenv.lib.platforms.linux;
  };
}
