{ modulesPath, pkgs, ... }:

{
  require = [
    "${modulesPath}/languages/python-poetry.nix"
  ];

  name = "example-app";
  src = ./.;

  python = {
    enable = true;
    package = pkgs.python311;
    inject_app_env = true;
    prefer_wheels = false;
  };

  dev_commands = with pkgs; [
    awscli2
  ];
}
