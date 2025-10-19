{
  description = "A Typst project that uses Typst packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    # Example of downloading icons from a non-flake source
    # font-awesome = {
    #   url = "github:FortAwesome/Font-Awesome";
    #   flake = false;
    # };
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
      date = builtins.substring 0 10 (builtins.readFile "${pkgs.runCommand "date" {} "date -I > $out"}");
      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./main.typ
          ./data
        ];
      };

      # src = typixLib.cleanTypstSource ./.;

      commonArgs = {
        typstSource = "main.typ";

        fontPaths = [
          # Add paths to fonts here
          # "${pkgs.roboto}/share/fonts/truetype"
        ];

        virtualPaths = [
          # Add paths that must be locally accessible to typst here
          # {
          #   dest = "icons";
          #   src = "${inputs.font-awesome}/svgs/regular";
          # }
        ];
      };

      unstable_typstPackages = [
        {
          name = "kiresume";
          version = "0.1.17";
          hash = "sha256-waedSOjHgbw/ci+5ScAfeX/PnpklGExO9A3vQkTx0HU=";
        }
      ];

      # Compile a Typst project, *without* copying the result
      # to the current directory
      # build-drv = typixLib.buildTypstProject (commonArgs
      #   // {
      #     inherit src unstable_typstPackages;
      #   });

      # Compile a Typst project, and then copy the result
      # to the current directory
      # build-script = typixLib.buildTypstProjectLocal (commonArgs
      #   // {
      #     inherit src unstable_typstPackages;
      #   });

      # Watch a project and recompile on changes
      # watch-script = typixLib.watchTypstProject commonArgs;

      # Function to build for a specific language with custom name
      buildForLanguage = lang: let
        rawBuild = typixLib.buildTypstProject (commonArgs
          // {
            src = src;
            inherit unstable_typstPackages;
            typstOpts = {
              input = {inherit lang;};
            };
          });

        # Rename the output
        fileName = "MathieuDeRaedt_${date}_${lang}.pdf";
      in
        pkgs.runCommand "resume-${lang}" {} ''
          mkdir -p $out
          cp ${rawBuild}/main.pdf $out/${fileName}
        '';
      # Individual language builds
      builds = {
        en = buildForLanguage "en";
        de = buildForLanguage "de";
        nl = buildForLanguage "nl";
      };

      # Build all languages into one derivation
      build-all = pkgs.runCommand "resume-all-languages" {} ''
        mkdir -p $out
        cp ${builds.en}/*.pdf $out/
        cp ${builds.de}/*.pdf $out/
        cp ${builds.nl}/*.pdf $out/
      '';

      # Local build scripts for each language
      buildScriptFor = lang: let
        build = builds.${lang};
      in
        pkgs.writeShellApplication {
          name = "build-resume-${lang}";
          runtimeInputs = [pkgs.coreutils];
          text = ''
            cp ${build}/*.pdf .
            echo "Built resume for ${lang}: $(ls MathieuDeRaedt_*_${lang}.pdf)"
          '';
        };

      watch-script = typixLib.watchTypstProject (commonArgs
        // {
          typstOpts = {
            input = {lang = "en";};
          };
        });
    in {
      packages = {
        default = build-all;
        en = builds.en;
        de = builds.de;
        nl = builds.nl;
      };
      # checks = {
      #     inherit build-en build-nl build-de build-all watch-script
      #     };

      apps = rec {
        default = watch;

        # Build commands for each language
        build-en = flake-utils.lib.mkApp {
          drv = buildScriptFor "en";
        };
        build-de = flake-utils.lib.mkApp {
          drv = buildScriptFor "de";
        };
        build-nl = flake-utils.lib.mkApp {
          drv = buildScriptFor "nl";
        };

        # Build all languages
        build-all = flake-utils.lib.mkApp {
          drv = pkgs.writeShellApplication {
            name = "build-all-resumes";
            runtimeInputs = [pkgs.coreutils];
            text = ''
              cp ${build-all}/*.pdf .
              echo "Built all resumes:"
              ls -1 MathieuDeRaedt_*.pdf
            '';
          };
        };

        watch = flake-utils.lib.mkApp {
          drv = watch-script;
        };
      };
      # checks = {
      #   inherit build-en build-de build-nl watch-script;
      # };

      # packages.default = build-drv;

      # apps = rec {
      #   default = watch;
      #   build = flake-utils.lib.mkApp {
      #     drv = build-script;
      #   };
      #   watch = flake-utils.lib.mkApp {
      #     drv = watch-script;
      #   };
      # };

      devShells.default = typixLib.devShell {
        inherit (commonArgs) fontPaths virtualPaths;
        packages = [
          # WARNING: Don't run `typst-build` directly, instead use `nix run .#build`
          # See https://github.com/loqusion/typix/issues/2
          # build-script
          watch-script
          # More packages can be added here, like typstfmt
          pkgs.typstfmt
          pkgs.just
        ];
      };
    });
}
