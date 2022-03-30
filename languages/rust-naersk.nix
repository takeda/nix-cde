{ config, lib, pkgs, ... }:

{
  options = with lib; {
    rust = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "rust";
        };
      };
    };

    out_rust = mkOption {
      type = types.package;
      readOnly = true;
    };
    out_rust_toolchain = mkOption {
      type = types.package;
      readOnly = true;
    };
  };

  config = let
    cfg = config.rust;
  in lib.mkIf cfg.enable {
    out_rust_toolchain = pkgs.buildEnv {
      name = config.name + "-env";
      paths = with pkgs; [
        rustc
        cargo
      ];
    };

    out_rust = pkgs.naersk.buildPackage {
      pname = config.name;
      root = config.src;
    };

    dev_apps = with pkgs; [
      rustc
      cargo
    ] ++ lib.optionals pkgs.stdenv.isDarwin [
      libiconv
      darwin.apple_sdk.frameworks.CoreFoundation
    ];
  };
}
