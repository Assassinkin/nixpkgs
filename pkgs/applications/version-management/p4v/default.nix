{ stdenv, fetchurl, lib, qt59, qtbase, qtmultimedia, qtscript, qtsensors, qtwebkit, openssl, xkeyboard_config, makeWrapper }:

stdenv.mkDerivation rec {
  name = "p4v-${version}";
  version = "2018.2.1661700";

  src = fetchurl {
    url = "http://www.perforce.com/downloads/perforce/r18.2/bin.linux26x86_64/p4v.tgz";
    sha256 = "18jxk9yf3480c0lgkpm53rkbblmjcv9qd21xilmp0jb9g2plmhfl";
  };

  dontBuild = true;
  nativeBuildInputs = [makeWrapper];

  ldLibraryPath = lib.makeLibraryPath [
      stdenv.cc.cc.lib
      qtbase
      qtmultimedia
      qtscript
      qtsensors
      qtwebkit
      openssl
  ];

  installPhase = ''
    mkdir $out
    cp -r bin $out
    mkdir -p $out/lib/p4v
    cp -r lib/P4VResources $out/lib/p4v
    cp -r lib/plugins $out/lib/p4v
    for f in $out/bin/*.bin ; do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $f

      wrapProgram $f \
        --suffix LD_LIBRARY_PATH : ${ldLibraryPath} \
        --suffix QT_XKB_CONFIG_ROOT : ${xkeyboard_config}/share/X11/xkb \
        --suffix QT_PLUGIN_PATH : ${qt59.qtbase.bin}/${qt59.qtbase.qtPluginPrefix}
    done
  '';

  meta = {
    description = "Perforce Visual Client";
    homepage = https://www.perforce.com;
    license = stdenv.lib.licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
    maintainers = [ stdenv.lib.maintainers.nioncode ];
  };
}
