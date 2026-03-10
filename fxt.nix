{ 
      # derivation dependencies
    lib,
    fetchurl,
    stdenv,
    autoreconfHook,


    perl,
    help2man,

    static ? false
}:
stdenv.mkDerivation (finalAttrs: {
    pname = "fxt";
    system = "x86_64-linux";
    version = "0.3.14";

    inherit static;

    src = fetchurl {
        url = "https://download.savannah.gnu.org/releases/fkt/fxt-${finalAttrs.version}.tar.gz";
        hash = "sha256-MX2Nkxdc2fJ+xDuDkLbSncZhFPBqp08jKYR9Sbqq6/I=";
    };

    nativeBuildInputs = [
        perl
        help2man
    ];

    buildInputs = [
        perl
        help2man
    ];

    configureFlags = (lib.optional finalAttrs.static ["CFLAGS=-fPIC" "--enable-static=yes" "--enable-shared=no"]); 
  /**
      postConfigure = ''
        # Patch shebangs recursively because a lot of scripts are used
        shopt -s globstar
        patchShebangs --build ***.sh
      '';

      postPatch = ''
        # Patch shebangs recursively because a lot of scripts are used
        shopt -s globstar
        patchShebangs --build **.sh
      '';
      */

      doCheck = true;
})



