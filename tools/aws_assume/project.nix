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
    inject_app_env = true;
    prefer_wheels = false;
    overrides = self: super: {
      tan = super.tan.overridePythonAttrs (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [
          self.setuptools
        ];
      });
    };
  };

  dev_commands = with pkgs; [
    awscli2
  ];
}
