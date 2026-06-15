{
    description = "StarPU derivation for NixOS.";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
        # There is a bug involving glibc and NVCC. 
        # using this specific commti hash, that references glibc 2.40-36
        # makes it work
        #cudaNixpkgs.url = "github:nixos/nixpkgs/1da52dd49a127ad74486b135898da2cef8c62665";
    };

    outputs = { self, nixpkgs }: 
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
        pkgs = import nixpkgs pkgsconfig;

        fxt = pkgs.callPackage ./fxt.nix { static = true; };
        StarPU = pkgs.callPackage ./starpu.nix { inherit fxt; };
        StarPUCuda = pkgs.callPackage ./starpu.nix { inherit fxt; enableCUDA = true; };
    in
    {
        packages.${system} = {
            default = StarPU;
            inherit fxt StarPU StarPUCuda;
        };
        devShells.${system} = {
            test = pkgs.mkShell {
                buildInputs = [ pkgs.pkg-config pkgs.hwloc pkgs.cudaPackages.cuda_cuobjdump StarPUCuda ];
            };
        };
    };
}
