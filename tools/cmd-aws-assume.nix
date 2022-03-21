{ pkgs, ... }:

{
  config = let
    project = pkgs.nix-cde.mkCDE ./aws_assume/project.nix {};
    assume = project.outputs.out_python;
  in {
    dev_commands = [
      assume
    ];
  };
}
