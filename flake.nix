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

    gomod2nix.url = "github:tweag/gomod2nix";
    gomod2nix.inputs.nixpkgs.follows = "nixpkgs";

    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";

    nix-bundle.url = "github:takeda/nix-bundle/nix-cde";
  };

  outputs = { ... } @ sources: {
    defaultTemplate = {
      path = ./template;
      description = "An example of a nix-cde project";
    };

    overlay = final: prev: {
      mkCDE = import ./nix-cde.nix { inherit sources; };
    };

    lib.mkCDE = import ./nix-cde.nix { inherit sources; };
  };
}
