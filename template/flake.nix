{
  description = "An example application";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix-cde.url = "github:takeda/nix-cde";
  };

  outputs = { self, flake-utils, nix-cde, nixpkgs }: flake-utils.lib.eachDefaultSystem (build_system:
  let
    cde = is_shell: nix-cde.lib.mkCDE ./project.nix { inherit build_system is_shell; };
    cde-docker = nix-cde.lib.mkCDE ./project.nix {
      inherit build_system;
      host_system = "x86_64-linux";
    };
  in {
    packages.docker = cde-docker.outputs.out_docker;
    defaultPackage = (cde false).outputs.out_python;
    devShell = (cde true).outputs.out_shell;
  });
}
