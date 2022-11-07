{ config, lib, pkgs, ... }:

{
  options = with lib; {
    python = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "python";

          package = mkOption {
            type = types.package;
            description = "python package";
            example = "python38";
          };

          modules = mkOption {
            type = with types; attrsOf path;
            description = "mapping of python module => path, used primarily for shell environment to install package in an editable mode (note that root of the source dir is already added under src name)";
            example = "{ python_microservice = ./python_microservice; }";
            default = {};
          };

          inject_app_env = mkOption {
            type = types.bool;
            description = "include the app in the dev env";
            default = true;
          };

          overrides = mkOption {
            type = types.unspecified;
            description = "override list for poetry packages";
            example = ''
              self: super:
              {
                psutil = super.psutil.overridePythonAttrs (
                  old: {
                    buildInputs = (old.buildInputs or []) ++
                      lib.optional stdenv.isDarwin pkgs.darwin.apple_sdk.frameworks.IOKit;
                  }
                );
              }
            '';
            default = self: super: {};
          };

          check_command = mkOption {
            type = types.str;
            description = "command to run to execute unit tests";
            example = "pytest --no-cov";
            default = "";
          };
        };
      };
    };

    out_pypackages = mkOption {
      type = types.anything;
      readOnly = true;
    };

    out_python = mkOption {
      type = types.package;
      readOnly = true;
    };
  };

  config = let
    cfg = config.python;
    poetry = python: let
      poetry2nix = pkgs.poetry2nix.overrideScope' (p2nself: p2nsuper: {
        defaultPoetryOverrides = p2nsuper.defaultPoetryOverrides.extend cfg.overrides;
      });
    in {
      app = poetry2nix.mkPoetryApplication {
        inherit python;
        projectDir = config.src;
        doCheck = false;
      };
      env = poetry2nix.mkPoetryEnv {
        inherit python;
        projectDir = config.src;
        editablePackageSources = {
          src = config.src;
        } // cfg.modules;
      };
      packages = poetry2nix.mkPoetryPackages {
        inherit python;
        projectDir = config.src;
      };
    };

    # python environment used for dev shell
    python_env = if (cfg.inject_app_env && builtins.pathExists (config.src + "/poetry.lock"))
    then (poetry cfg.package).env
    else cfg.package; # if there's no poetry project, just expose python itself

  in lib.mkIf cfg.enable {
    dev_commands = [
      pkgs.poetry
    ];
    dev_apps = [
      python_env
    ];

    out_pypackages = (poetry cfg.package).packages;
    out_python = (poetry cfg.package).app;
  };
}
