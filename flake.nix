{
  description = "Nix-CDE (Nix-based Common Development Envrionemnt) provides a reproducible development environment that abstracts away Nix rough edges through the use of NixOS modules.";

  inputs = {
    #nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/4de4818c1ffa76d57787af936e8a23648bda6be4";

    npmlock2nix.url = "github:nix-community/npmlock2nix";
    npmlock2nix.flake = false;

    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";

    terraform-providers.url = "github:numtide/nixpkgs-terraform-providers-bin";
    terraform-providers.inputs.nixpkgs.follows = "nixpkgs";

    gomod2nix.url = "github:nix-community/gomod2nix";
    gomod2nix.inputs.nixpkgs.follows = "nixpkgs";

    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";

    nix-bundle.url = "github:takeda/nix-bundle/nix-cde";
    nix-bundle.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... } @ sources: let
    nix-cde = nixpkgs.lib.fix (import ./nix-cde.nix);
  in {
    templates.default = {
      path = ./template;
      description = "An example of a nix-cde project";
    };

    overlays.default = final: prev: {
      mkCDE = nix-cde { inherit sources; };
    };

    lib.mkCDE = nix-cde { inherit sources; };
  };
}
