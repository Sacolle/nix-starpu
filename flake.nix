{
    description = "StarPU derivation for NixOS.";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    };

    outputs = { self, nixpkgs }: 
    let 
        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };

        fxt = pkgs.callPackage ./fxt.nix { static = true; };
        StarPU = pkgs.callPackage ./starpu.nix { 
            inherit fxt; 
            stdenv = pkgs.gcc13Stdenv;
        };
    in
    {
        packages.${system} = {
            default = StarPU;
            inherit fxt StarPU;
        };
    };
}
