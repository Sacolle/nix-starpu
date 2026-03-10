# from https://github.com/PhoqueEberlue/nixpkgs/blob/add-starpu/pkgs/by-name/st/starpu/package.nix
{ 
  # derivation dependencies
  lib,
  fetchurl,
  gcc13Stdenv,
  writableTmpDirAsHomeHook,
  autoreconfHook,
  # starpu dependencies
  hwloc,
  libuuid,
  libX11,
  fftw,
  fftwFloat, # Same than previous but with float precision
  pkg-config,
  libtool,
  simgrid,
  mpi,

  python313,
  fxt,

  # These two packages may fail to build with current nixpkgs
  # If that is the case, the current build works for these two packages comming from
  # nixpkgs.url = "github:nixos/nixpkgs/1da52dd49a127ad74486b135898da2cef8c62665";
  cudaPackages,
  linuxPackages,

  # Options
  maxBuffers ? 8,
  compileAsRelease ? false,
  enableStarpupy ? false,
  enableSimgrid ? false,
  enableMPI ? false,
  enableCUDA ? false,
  enableTrace ? false,
  extraOptions ? []
}:
let 
    cudaPkgs = with cudaPackages; [
        linuxPackages.nvidiaPackages.stable
        cudatoolkit
    ];
in
gcc13Stdenv.mkDerivation (finalAttrs: {
    pname = "StarPU";
    system = "x86_64-linux";
    version = "1.4.7";

    inherit maxBuffers compileAsRelease enableStarpupy enableSimgrid enableMPI enableCUDA enableTrace extraOptions;

    src = fetchurl {
        url = "http://files.inria.fr/starpu/starpu-${finalAttrs.version}/starpu-${finalAttrs.version}.tar.gz";
        hash = "sha256-HrPfVRCJFT/m4LFyrZURhDS0qB6p6qWiw4cl0NtTsT4=";
    };
    nativeBuildInputs = [
        pkg-config
        hwloc
        libtool
        writableTmpDirAsHomeHook
        autoreconfHook
        python313

    ] 
        ++ lib.optional finalAttrs.enableSimgrid simgrid
        ++ lib.optional finalAttrs.enableMPI mpi
        ++ lib.optional finalAttrs.enableCUDA cudaPkgs
        ++ lib.optional finalAttrs.enableTrace fxt
        ;

    buildInputs = [
        libuuid
        libX11
        fftw
        fftwFloat
        hwloc
    ]
        ++ lib.optional finalAttrs.enableSimgrid simgrid
        ++ lib.optional finalAttrs.enableMPI mpi
        ++ lib.optional finalAttrs.enableCUDA cudaPkgs
        ++ lib.optional finalAttrs.enableTrace fxt
        ;

    

    configureFlags = [
        (lib.enableFeature true "quick-check")
        (lib.enableFeature false "build-examples")
        (lib.enableFeature false "build-doc ")

        (lib.enableFeature finalAttrs.enableStarpupy "starpupy")
        (lib.enableFeature finalAttrs.enableSimgrid "simgrid")

         # Static linking is mandatory for smpi
        (lib.enableFeature finalAttrs.enableMPI "mpi")
        (lib.enableFeature finalAttrs.enableMPI "mpi-check")
        (lib.enableFeature (!finalAttrs.enableMPI) "shared") 

        (lib.optional finalAttrs.enableTrace "--with-fxt=${fxt}")
    ] 
    ++ (
        if finalAttrs.compileAsRelease then [ "--enable-fast" ]
        else [ "--enable-debug" "--enable-verbose" "--enable-spinlock-check" ]
    ) 
    ++ (lib.optional (finalAttrs.maxBuffers != 8) "--enable-maxbuffers=${toString finalAttrs.maxBuffers}")
    ++ finalAttrs.extraOptions
    ;


      # No need to add flags for CUDA, it should be detected by ./configure

      patchPhase = ''
        # Patch shebangs recursively because a lot of scripts are used
        shopt -s globstar
        patchShebangs --build **/*.in
      '';

      postConfigure = ''
        # Patch shebangs recursively because a lot of scripts are used
        shopt -s globstar
        patchShebangs --build **/*.sh
      '';

      enableParallelBuilding = true;
      doCheck = true;
})



