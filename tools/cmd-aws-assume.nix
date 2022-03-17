{ nix-cde, ... }:

{
  config = let
    project = nix-cde ./aws_assume/project.nix {};
    assume = project.outputs.out_python;
  in {
    dev_commands = [
      assume
    ];
  };
}
