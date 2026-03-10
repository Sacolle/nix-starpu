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
        pkgsconfig = { 
            inherit system; 
            config = { 
                allowUnfree = true;
                cudaSupport = true;
                cudaVersion = "13";
            };
        };
        cudapkgs = import cudaNixpkgs pkgsconfig;
        pkgs = import nixpkgs pkgsconfig;

        fxt = pkgs.callPackage ./fxt.nix { static = true; };
        StarPU = pkgs.callPackage ./starpu.nix { 
            # use the proper cuda pkgs for proper compilation
            cudaPackages  = cudapkgs.cudaPackages;
            linuxPackages = cudapkgs.linuxPackages;

            # pass fxt to be able to implement trace 
            inherit fxt;
        };
            
    in
    {
        packages.${system} = {
            default = StarPU;
            inherit fxt StarPU;
        };
    };
}
