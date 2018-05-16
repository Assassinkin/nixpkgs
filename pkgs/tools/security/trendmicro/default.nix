{ stdenv, zlib, acl, fetchurl, unzip, makeWrapper, cpio, rpm }:
stdenv.mkDerivation rec {
  name = "ds-agent-${version}";
  version = "10.0.0-2797";

  src = fetchurl {
    url = "https://files.trendmicro.com/products/deepsecurity/en/10.0/Agent-RedHat_EL7-10.0.0-2797.x86_64.zip";
    #url = "http://files.trendmicro.com/products/deepsecurity/en/9.6/Agent-RedHat_EL7-${version}.x86_64.zip";
    sha256 = "0fg8w4c2p2n75ji7bk0cc0b9dc89jdxk5brljrrwj6pjsnhb157w";
  };

  buildInputs = [ unzip makeWrapper cpio rpm ];

  deps = [ stdenv.cc.cc zlib acl rpm ];

  buildCommand = ''
    mkdir -p $out $out/bin
    unzip $src
    rpm2cpio *.rpm | cpio -idmv
    mv opt $out/

    for f in dsa ds_agent; do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
          --set-rpath '$ORIGIN/lib:${stdenv.lib.makeLibraryPath deps}' \
          $out/opt/ds_agent/$f
      wrapProgram $out/opt/ds_agent/$f --prefix LD_LIBRARY_PATH : ${stdenv.lib.makeLibraryPath deps}
      ln -s $out/opt/ds_agent/$f $out/bin/$f
    done
  '';
  meta = with stdenv.lib; {
    description = "An alerting dashboard for Graphite";
    homepage = https://github.com/scobal/seyren;
    license = licenses.asl20;
    maintainers = [ maintainers.rob ];
    platforms = platforms.all;
  };
}
