{ modulesPath, pkgs, ... }:

{
  require = [
    "${modulesPath}/languages/python-poetry.nix"
  ];

  name = "assume";
  src = ./.;

  python = {
    enable = true;
    package = pkgs.python39;
  };

  dev_commands = with pkgs; [
    awscli2
  ];
}
