{ modulesPath, pkgs, ... }:

{
  require = [
    "${modulesPath}/languages/python-poetry.nix"
  ];

  name = "example-app";
  src = ./.;

  python = {
    enable = true;
    package = pkgs.python310;
  };

  dev_commands = with pkgs; [
    awscli2
  ];
}
