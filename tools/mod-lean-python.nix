{ config, is_shell, lib, pkgs, ... }:

{
  options = with lib; {
    lean_python = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "lean python";
          package = mkOption {
            type = types.package;
            description = "python package";
            example = "python311";
          };
          bzip2 = mkOption { type = types.bool; default = false; };
          # you might need it on darwin for _scproxy module
          configd = mkOption { type = types.bool; default = false; };
          expat = mkOption { type = types.bool; default = true; };
          libffi = mkOption { type = types.bool; default = false; };
          gdbm = mkOption { type = types.bool; default = false; };
          xz = mkOption { type = types.bool; default = false; };
          ncurses = mkOption { type = types.bool; default = false; };
          openssl = mkOption { type = types.bool; default = false; };
          readline = mkOption { type = types.bool; default = false; };
          sqlite = mkOption { type = types.bool; default = false; };
          zlib = mkOption { type = types.bool; default = true; };
          tzdata = mkOption { type = types.bool; default = false; };
          mimetypes_support = mkOption { type = types.bool; default = false; };
          x11_support = mkOption { type = types.bool; default = false; };
          strip_config = mkOption { type = types.bool; default = true; };
          strip_idlelib = mkOption { type = types.bool; default = true; };
          strip_tests = mkOption { type = types.bool; default = true; };
          strip_tkinter = mkOption { type = types.bool; default = true; };
          # for CLI app rebuild_bytecode set to true can decrease startup time
          # at the cost of space
          rebuild_bytecode = mkOption { type = types.bool; default = false; };
          strip_bytecode = mkOption { type = types.bool; default = true; };
          include_site_customize = mkOption { type = types.bool; default = false; };
          lto = mkOption { type = types.bool; default = true; };
          enable_optimizations = mkOption { type = types.bool; default = false; };
          strip_debug_symbols = mkOption { type = types.bool; default = true; };
        };
      };
      description = "whether to use slimmed down version of python";
      default = {};
    };

    out_lean_python = mkOption {
      type = types.package;
      readOnly = true;
    };
  };

  config = let
    lean_python = config.lean_python;
    out_lean_python = with lib; if (!config.lean_python.enable || is_shell)
      then lean_python.package
      else (lean_python.package.override ({
        self = out_lean_python;
        mimetypesSupport = lean_python.mimetypes_support;
        x11Support = lean_python.x11_support;
        stripConfig = lean_python.strip_config;
        stripIdlelib = lean_python.strip_idlelib;
        stripTests = lean_python.strip_tests;
        stripTkinter = lean_python.strip_tkinter;
        enableLTO = lean_python.lto && (pkgs.stdenv.is64bit && pkgs.stdenv.isLinux);
        rebuildBytecode = lean_python.rebuild_bytecode;
        stripBytecode = lean_python.strip_bytecode;
        includeSiteCustomize = lean_python.include_site_customize;
        enableOptimizations = lean_python.enable_optimizations && !pkgs.stdenv.cc.isClang;
        packageOverrides = self: super: {
          # unit tests require some components that we might want to keep
          # disabled
          babel = super.babel.overridePythonAttrs (_: {
            doCheck = false;
          });
          freezegun = super.freezegun.overridePythonAttrs (_: {
            doCheck = false;
          });
          pytest-xdist = super.pytest-xdist.overridePythonAttrs (_: {
            doCheck = false;
          });
          six = super.six.overridePythonAttrs (_: {
            doCheck = false;
          });
        };
      }
      // optionalAttrs (!lean_python.bzip2) { bzip2 = null; }
      // optionalAttrs (!lean_python.configd) { configd = null; }
      // optionalAttrs (!lean_python.expat) { expat = null; }
      // optionalAttrs (!lean_python.libffi) { libffi = pkgs.libffiBoot; }
      // optionalAttrs (!lean_python.gdbm) { gdbm = null; }
      // optionalAttrs (!lean_python.xz) { xz = null; }
      // optionalAttrs (!lean_python.ncurses) { ncurses = null; }
      // optionalAttrs (!lean_python.openssl) { openssl = null; openssl_legacy = null; }
      // optionalAttrs (!lean_python.readline) { readline = null; }
      // optionalAttrs (!lean_python.sqlite) { sqlite = null; }
      // optionalAttrs (!lean_python.zlib) { zlib = null; }
      // optionalAttrs (!lean_python.tzdata) { tzdata = null; }
      ));
#      .overrideAttrs (old: {
#        strictDeps = true;
#        pname = "lean-python3";
#        preConfigure = (old.preConfigure or "") + lib.optionalString (lean_python.strip_debug_symbols && !pkgs.stdenv.buildPlatform.isDarwin) ''
#          export NIX_LDFLAGS+=" --strip-all"
#        '';
#      });
  in {
    inherit out_lean_python;
  };
}
