{ config, lib, pkgs, sources, ... }:

{
  options = with lib; {
    terraform = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "terraform binary providers";

          package = mkOption {
            type = types.package;
            description = "terraform package to use";
            example = "pkgs.terraform_1";
            default = pkgs.teraform;
          };

          providers = mkOption {
            type = with types; functionTo (listOf package);
            description = "list of providers to include";
            example = "p: [ p.hashicorp.nomad ]";
          };
        };
      };
    };

    out_terraform = mkOption {
      type = types.package;
      readOnly = true;
    };
  };

  config = let
    cfg = config.terraform;
    terraform = sources.terraform-providers.legacyPackages.${pkgs.system}.wrapTerraform cfg.package cfg.providers;
  in lib.mkIf cfg.enable {
    out_terraform = terraform;

    dev_commands = [
      terraform
    ];
  };
}
