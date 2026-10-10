{
  description = "Nova Rio | Isolated Yazelix terminal fork";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [flake-parts.flakeModules.easyOverlay];

      systems = import inputs.systems;

      perSystem = {
        self',
        inputs',
        pkgs,
        system,
        lib,
        ...
      }: let
        # Defines a devshell using the `rust-toolchain`, allowing for
        # different versions of rust to be used.
        mkDevShell = rust-toolchain: let
          runtimeDeps = self'.packages.nrio.runtimeDependencies;
          tools =
            self'.packages.nrio.nativeBuildInputs ++ self'.packages.nrio.buildInputs ++ [rust-toolchain];
        in
          pkgs.mkShell {
            packages = [self'.formatter] ++ tools;
            LD_LIBRARY_PATH = "${lib.makeLibraryPath runtimeDeps}";
          };
        toolchains = rec {
          msrv = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
          stable = pkgs.rust-bin.stable.latest.minimal;
          nightly = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.minimal);
          nrio = msrv;
          default = nrio;
        };
      in {
        formatter = pkgs.alejandra;
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [(import inputs.rust-overlay)];
        };

        # Keep upstream pkgs.rio independent.
        overlayAttrs = {inherit (self'.packages) nrio;};
        packages =
          lib.mapAttrs' (
            k: v: {
              name =
                if builtins.elem k ["nrio" "default"]
                then k
                else "nrio-${k}";
              value = pkgs.callPackage ./pkgRio.nix {rust-toolchain = v;};
            }
          )
          toolchains;
        checks.coexistence =
          pkgs.runCommand "nova-rio-coexistence" {
            nativeBuildInputs = [pkgs.bash pkgs.coreutils pkgs.gnugrep];
          } ''
            bash ${./misc/scripts/check-coexistence.sh} ${self'.packages.nrio} ${pkgs.rio} ${pkgs.buildEnv {
              name = "rio-and-nova-rio";
              paths = [pkgs.rio self'.packages.nrio];
            }}
            touch "$out"
          '';
        # Different devshells for different rust versions
        devShells = lib.mapAttrs (_: v: mkDevShell v) toolchains;
      };
    };
}
