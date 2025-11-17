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

      variations = ["en" "de" "nl"];
      VERSION = "2025_11";

      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./main.typ
          ./template
          ./data
        ];
      };

      commonArgs = {
        typstSource = "main.typ";
        fontPaths = [
          "${pkgs.noto-fonts}/share/fonts/truetype"
        ];
        virtualPaths = [];
      };

      unstable_typstPackages = [
      ];

      # Function to create local build script for a language
      buildScriptFor = lang:
        typixLib.buildTypstProjectLocal (commonArgs
          // {
            inherit src unstable_typstPackages;
            typstOpts = {
              input = ["lang=${lang}" "version=${VERSION}"];
            };
            typstOutput = "MathieuDeRaedt_${VERSION}_${lib.toUpper lang}.pdf";
          });

      buildScripts = lib.genAttrs variations buildScriptFor;
    in {
      apps =
        (lib.mapAttrs (lang: script:
          flake-utils.lib.mkApp {
            drv = script;
          })
        buildScripts)
        // {
          default = flake-utils.lib.mkApp {
            drv = buildScripts.en;
          };
        };

      devShells.default = typixLib.devShell {
        inherit (commonArgs) fontPaths virtualPaths;
        packages = [
          pkgs.typstfmt
          pkgs.just
          pkgs.entr
        ];
      };
    });
}
