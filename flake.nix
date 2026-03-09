{
    description = "StarPU derivation for NixOS.";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
        # There is a bug involving glibc and NVCC. 
        # using this specific commti hash, that references glibc 2.40-36
        # makes it work
        cudaNixpkgs.url = "github:nixos/nixpkgs/1da52dd49a127ad74486b135898da2cef8c62665";
    };

    outputs = { self, nixpkgs, cudaNixpkgs }: 
    let 
        system = "x86_64-linux";

        cudapkgs = import cudaNixpkgs { 
            inherit system; 
            config = { 
                allowUnfree = true;
                cudaSupport = true;
                cudaVersion = "13";
            };
        };
        pkgs = import nixpkgs {
            inherit system;
            config = { 
                allowUnfree = true;
                cudaSupport = true;
                cudaVersion = "13";
            };
        };

        fxt = pkgs.callPackage ./fxt.nix { static = true; };
        StarPU = pkgs.callPackage ./starpu.nix { 
            # enableCUDA = true; 
            # use the proper cuda pkgs for no compilation error 
            cudaPackages  = cudapkgs.cudaPackages;
            linuxPackages = cudapkgs.linuxPackages;

            # pass fxt to be able to implement trace 
            inherit fxt;

            #maxBuffers = 56;
            #enableTrace = true;
        };
    in
    {
        packages.${system} = {
            default = StarPU;
            inherit fxt StarPU;
        };
    };
}
