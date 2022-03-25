{
  description = "nix-cde";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    npmlock2nix.url = "github:nix-community/npmlock2nix";
    npmlock2nix.flake = false;

    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";

    terraform-providers.url = "github:numtide/nixpkgs-terraform-providers-bin";
    terraform-providers.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, npmlock2nix, poetry2nix, terraform-providers } @ sources: {
    lib.mkCDE = import ./nix-cde.nix { inherit sources; };
  };
}
