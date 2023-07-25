{ modulesPath, pkgs, ... }:

{
  require = [
    "${modulesPath}/languages/python-poetry.nix"
  ];

  name = "assume";
  src = ./.;
  src_ignore = [''
    *
    !/assume.py
    !/pyproject.toml
    !/poetry.lock
  ''];

  python = {
    enable = true;
    package = pkgs.python3;
    inject_app_env = true;
    prefer_wheels = false;
  };

  dev_commands = with pkgs; [
    awscli2
  ];
}
