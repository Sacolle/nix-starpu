# from https://github.com/PhoqueEberlue/nixpkgs/blob/add-starpu/pkgs/by-name/st/starpu/package.nix
{ 
  # derivation dependencies
  lib,
  fetchurl,
  stdenv,
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

  cudaPackages,

  # Options
  maxBuffers ? 8,
  compileAsRelease ? false,
  enableStarpupy ? false,

  # have not tested this options yet
  #enableSimgrid ? false,
  #enableMPI ? false,
  enableCUDA ? false,
  enableTrace ? false,
  extraOptions ? []
}:
let 
    cudaHwloc = hwloc.override { 
        inherit cudaPackages; 
        enableCuda = true;
    };

    cudaNativePkgs = with cudaPackages; [
        cuda_nvcc
    ];
    cudaBuildPkgs = with cudaPackages; [
        cuda_cudart
        cuda_cccl 
        cuda_nvml_dev 
        libcublas 
        libcusparse
        libcusolver
        libcufft
    ];

    my-hwloc = if enableCUDA then cudaHwloc else hwloc;
in
stdenv.mkDerivation (f: {
    pname = "StarPU";
    system = "x86_64-linux";
    version = "1.4.7";

    src = fetchurl {
        url = "http://files.inria.fr/starpu/starpu-${f.version}/starpu-${f.version}.tar.gz";
        hash = "sha256-HrPfVRCJFT/m4LFyrZURhDS0qB6p6qWiw4cl0NtTsT4=";
    };
    nativeBuildInputs = [
        pkg-config
        my-hwloc
        libtool
        writableTmpDirAsHomeHook
        autoreconfHook
        python313

    ] 
  #     ++ lib.optional enableSimgrid simgrid
  #      ++ lib.optional enableMPI mpi
        ++ lib.optionals enableCUDA cudaNativePkgs
        ++ lib.optional enableTrace fxt
        ;

    buildInputs = [
        libuuid
        libX11
        fftw
        fftwFloat
        my-hwloc
    ]
 #       ++ lib.optional enableSimgrid simgrid
 #       ++ lib.optional enableMPI mpi
        ++ lib.optionals enableCUDA cudaBuildPkgs
        ++ lib.optional enableTrace fxt
        ;

    
    NVCCFLAGS = lib.optionalString enableCUDA "-std=c++14";

    configureFlags = [
        (lib.enableFeature true "quick-check")
        (lib.enableFeature false "build-examples")
        (lib.enableFeature false "build-doc ")

        (lib.enableFeature enableStarpupy "starpupy")
        #(lib.enableFeature enableSimgrid "simgrid")

         # Static linking is mandatory for smpi
        #(lib.enableFeature enableMPI "mpi")
        #(lib.enableFeature enableMPI "mpi-check")
        #(lib.enableFeature (!enableMPI) "shared") 

        (lib.optional enableTrace "--with-fxt=${fxt}")
    ] 
    ++ (
        if compileAsRelease then [ "--enable-fast" ]
        else [ "--enable-debug" "--enable-verbose" "--enable-spinlock-check" ]
    ) 
    ++ (lib.optional (maxBuffers != 8) "--enable-maxbuffers=${toString maxBuffers}")
    ++ extraOptions
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



