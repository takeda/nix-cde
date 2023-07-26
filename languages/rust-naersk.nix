{ config, lib, pkgs, sources, src, ... }:

{
  options = with lib; {
    rust = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "rust";

          toolchain = mkOption {
            type = with types; listOf package;
            description = "Rust toolchain";
            example = ''
              with fenix_packages; [
                minimal.rustc
                minimal.cargo
                targets.x86_64-unknown-linux-musl.latest.rust-std
              ]
            '';
            default = with sources.fenix.packages.${pkgs.system}; [
                minimal.rustc
                minimal.cargo
            ];
          };

          build_options = mkOption {
            type = types.attrs;
            description = "Additional options to pass to naersk.buildPackage";
            example = ''
              {
                doCheck = true;
                nativeBuildInputs = with pkgs; [ pkgsStatic.stdenv.cc ];
                CARGO_BUILD_TARGET = "x86_64-unknown-linux-musl";
                CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
              }
            '';
            default = {};
          };
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
    fenix_packages = sources.fenix.packages.${pkgs.system};
    toolchain = with fenix_packages;
      combine cfg.toolchain;
    naersk = sources.naersk.lib.${pkgs.system}.override {
      cargo = toolchain;
      rustc = toolchain;
    };
  in lib.mkIf config.rust.enable {
    _module.args = {
      inherit fenix_packages;
    };

    out_rust_toolchain = toolchain;

    out_rust = naersk.buildPackage ({
      inherit src;
    } // cfg.build_options);

    dev_apps = [
      toolchain
    ];
  };
}
