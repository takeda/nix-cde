{
  description = "An example application";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix-cde.url = "github:takeda/nix-cde";
  };

  outputs = { self, flake-utils, nix-cde, ... }: flake-utils.lib.eachDefaultSystem (build_system:
  let
    cde = is_shell: nix-cde.lib.mkCDE ./project.nix { inherit build_system is_shell self; };
    cde-docker = nix-cde.lib.mkCDE ./project.nix {
      inherit build_system self;
      host_system = "x86_64-linux";
    };
  in {
    packages.default = (cde false).outputs.out_python;
    packages.docker = cde-docker.outputs.out_docker;
    devShells.default = (cde true).outputs.out_shell;
  });
}
