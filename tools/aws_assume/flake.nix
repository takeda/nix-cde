{
  description = "aws-assume";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nix-cde.url = "path:../..";

  outputs = { self, flake-utils, nix-cde, nixpkgs }: flake-utils.lib.eachDefaultSystem (system: 
    let
      cde = is_shell: nix-cde.lib.mkCDE ./project.nix {
        inherit is_shell;
        build_system = system;
      };
    in {
      packages.default = (cde false).outputs.out_python;
      devShells.default = (cde true).outputs.out_shell;
    });
}
