# This expression takes a file like `hackage-packages.nix` and constructs
# a full package set out of that.

# required dependencies:
{ pkgs, stdenv, all-cabal-hashes }:

# arguments:
#  * ghc package to use
#  * package-set: a function that takes { pkgs, stdenv, callPackage } as first arg and `self` as second
{ ghc, package-set }:

# return value: a function from self to the package set
self: let

  inherit (stdenv.lib) fix' extends makeOverridable;
  inherit (import ./lib.nix { inherit pkgs; }) overrideCabal;

  mkDerivationImpl = pkgs.callPackage ./generic-builder.nix {
    inherit stdenv;
    inherit (pkgs) fetchurl pkgconfig glibcLocales coreutils gnugrep gnused;
    nodejs = pkgs.nodejs-slim;
    jailbreak-cabal = if (self.ghc.cross or null) != null
      then self.ghc.bootPkgs.jailbreak-cabal
      else self.jailbreak-cabal;
    inherit (self) ghc;
    hscolour = overrideCabal self.hscolour (drv: {
      isLibrary = false;
      doHaddock = false;
      hyperlinkSource = false;      # Avoid depending on hscolour for this build.
      postFixup = "rm -rf $out/lib $out/share $out/nix-support";
    });
    cpphs = overrideCabal (self.cpphs.overrideScope (self: super: {
      mkDerivation = drv: super.mkDerivation (drv // {
        enableSharedExecutables = false;
        enableSharedLibraries = false;
        doHaddock = false;
        useCpphs = false;
      });
    })) (drv: {
        isLibrary = false;
        postFixup = "rm -rf $out/lib $out/share $out/nix-support";
    });
  };

  mkDerivation = makeOverridable mkDerivationImpl;

  callPackageWithScope = scope: drv: args: (stdenv.lib.callPackageWith scope drv args) // {
    overrideScope = f: callPackageWithScope (mkScope (fix' (extends f scope.__unfix__))) drv args;
  };

  mkScope = scope: pkgs // pkgs.xorg // pkgs.gnome2 // scope;
  defaultScope = mkScope self;
  callPackage = drv: args: callPackageWithScope defaultScope drv args;

  withPackages = packages: callPackage ./with-packages-wrapper.nix {
    inherit (self) llvmPackages;
    haskellPackages = self;
    inherit packages;
  };

  haskellSrc2nix = { name, src, sha256 ? null }:
    let
      sha256Arg = if isNull sha256 then "--sha256=" else ''--sha256="${sha256}"'';
    in pkgs.stdenv.mkDerivation {
      name = "cabal2nix-${name}";
      buildInputs = [ pkgs.cabal2nix ];
      phases = ["installPhase"];
      LANG = "en_US.UTF-8";
      LOCALE_ARCHIVE = pkgs.lib.optionalString pkgs.stdenv.isLinux "${pkgs.glibcLocales}/lib/locale/locale-archive";
      installPhase = ''
        export HOME="$TMP"
        mkdir -p "$out"
        cabal2nix --compiler=${self.ghc.name} --system=${stdenv.system} ${sha256Arg} "${src}" > "$out/default.nix"
      '';
  };

  hackage2nix = name: version: haskellSrc2nix {
    name   = "${name}-${version}";
    sha256 = ''$(sed -e 's/.*"SHA256":"//' -e 's/".*$//' "${all-cabal-hashes}/${name}/${version}/${name}.json")'';
    src    = "${all-cabal-hashes}/${name}/${version}/${name}.cabal";
  };

in package-set { inherit pkgs stdenv callPackage; } self // {

    inherit mkDerivation callPackage haskellSrc2nix hackage2nix;

    callHackage = name: version: self.callPackage (self.hackage2nix name version);

    # Creates a Haskell package from a source package by calling cabal2nix on the source.
    callCabal2nix = name: src: self.callPackage (self.haskellSrc2nix { inherit src name; });

    ghcWithPackages = selectFrom: withPackages (selectFrom self);

    ghcWithHoogle = selectFrom:
      let
        packages = selectFrom self;
        hoogle = callPackage ./hoogle.nix {
          inherit packages;
        };
      in withPackages (packages ++ [ hoogle ]);

    ghc = ghc // {
      withPackages = self.ghcWithPackages;
      withHoogle = self.ghcWithHoogle;
    };

  }
