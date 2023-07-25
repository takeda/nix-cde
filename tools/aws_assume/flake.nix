{
  description = "aws-assume";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nix-cde.url = "path:../..";

  outputs = { self, flake-utils, nix-cde }: flake-utils.lib.eachDefaultSystem (build_system:
    let
      cde = is_shell: nix-cde.lib.mkCDE ./project.nix { inherit build_system is_shell self; };
    in {
      packages.default = (cde false).outputs.out_python;
      devShells.default = (cde true).outputs.out_shell;
    }
  );
}
