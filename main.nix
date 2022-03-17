{ config, lib, pkgs, ...}:

{
  options = with lib; {
    name = mkOption {
      type = types.str;
      description = "name of the project";
    };
    src = mkOption {
      type = types.path;
      description = "path to the source code";
      example = "./.";
    };
    #cross_compile = mkOption {
    #  type = types.bool;
    #  description = "try to cross compile";
    #  default = false;
    #  example = "true";
    #};
    dev_commands = mkOption {
      type = types.listOf types.package;
      description = "list of packages to include in dev environment (exposes only /bin and /share)";
      default = [];
    };
    dev_apps = mkOption {
      type = types.listOf types.package;
      description = "list of packages to include in dev environment";
      default = [];
    };
    shell_vars = mkOption {
      type = types.lines;
      description = "additional variables for the shell";
      default = "";
    };

    out_shell = mkOption {
      type = types.package;
      readOnly = true;
    };
  };

  config = let
    dev_tools_env = pkgs.buildEnv {
      name = config.name + "-dev-tools";
      paths = config.dev_commands;
      pathsToLink = [
        "/bin"
        "/share"
      ];
    };
  in {
    out_shell = pkgs.mkShell {
      buildInputs = config.dev_apps ++ [ dev_tools_env ];
      shellHook = config.shell_vars;
    };
  };
}
