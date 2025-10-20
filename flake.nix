{
  description = "A Typst project that uses Typst packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {
    nixpkgs,
    typix,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;

      typixLib = typix.lib.${system};

      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./MathieuDeRaedt.typ
          ./template
          ./data
        ];
      };

      commonArgs = {
        typstSource = "MathieuDeRaedt.typ";
        fontPaths = [
          "${pkgs.noto-fonts}/share/fonts/truetype"
          "${pkgs.roboto}/share/fonts/truetype"
        ];
        virtualPaths = [];
      };

      unstable_typstPackages = [
      ];

      # Get dynamic date for filename
      date = builtins.substring 0 10 (
        builtins.readFile (
          pkgs.runCommand "get-date" {} "date -I > $out"
        )
      );

      # Function to build for a specific language (for nix build)
      buildForLanguage = lang:
        typixLib.buildTypstProject (commonArgs
          // {
            inherit src unstable_typstPackages;
            typstOpts = {
              input = ["lang=${lang}"];
            };
          });

      # Function to create local build script for a language
      buildScriptFor = lang:
        typixLib.buildTypstProjectLocal (commonArgs
          // {
            inherit src unstable_typstPackages;
            typstOpts = {
              input = ["lang=${lang}"];
            };
            typstOutput = "MathieuDeRaedt_${date}_${lib.toUpper lang}.pdf";
          });

      # Individual language builds (for nix build .#en)
      builds = {
        en = buildForLanguage "en";
        de = buildForLanguage "de";
        nl = buildForLanguage "nl";
      };

      # Build scripts for local use (for nix run .#build-en)
      buildScripts = {
        en = buildScriptFor "en";
        de = buildScriptFor "de";
        nl = buildScriptFor "nl";
      };

      watch-script = typixLib.watchTypstProject (commonArgs
        // {
          typstOpts = {
            input = ["lang=en"];
          };
        });
    in {
      packages = {
        default = builds.en;
        en = builds.en;
        de = builds.de;
        nl = builds.nl;
      };

      checks = {
        build-en = builds.en;
        build-de = builds.de;
        build-nl = builds.nl;
      };

      apps = rec {
        default = watch;

        # Build commands for each language
        build-en = flake-utils.lib.mkApp {
          drv = buildScripts.en;
        };
        build-de = flake-utils.lib.mkApp {
          drv = buildScripts.de;
        };
        build-nl = flake-utils.lib.mkApp {
          drv = buildScripts.nl;
        };

        watch = flake-utils.lib.mkApp {
          drv = watch-script;
        };
      };

      devShells.default = typixLib.devShell {
        inherit (commonArgs) fontPaths virtualPaths;
        packages = [
          watch-script
          pkgs.typstfmt
          pkgs.just
        ];
      };
    });
}
