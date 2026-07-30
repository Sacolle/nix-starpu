{
    description = "StarPU derivation for NixOS.";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { self, flake-utils, nixpkgs }: 
    flake-utils.lib.eachDefaultSystem (system:
    let 
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };

        fxt = pkgs.callPackage ./fxt.nix { static = true; };
        StarPU = pkgs.callPackage ./starpu.nix { inherit fxt; };
        StarPUCuda = pkgs.callPackage ./starpu.nix { inherit fxt; enableCUDA = true; };
    in
    {
        packages = {
            default = StarPU;
            inherit fxt StarPU StarPUCuda;
        };
        devShells = {
            test = pkgs.mkShell {
                buildInputs = [ pkgs.pkg-config pkgs.hwloc pkgs.cudaPackages.cuda_cuobjdump StarPUCuda ];
            };
        };
    });
}
