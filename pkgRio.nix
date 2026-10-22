{
  # rust-overlay deps
  rust-toolchain,
  makeRustPlatform,
  # Normal deps
  lib,
  stdenv,
  darwin,
  autoPatchelfHook,
  makeWrapper,
  mesa,
  cmake,
  ncurses,
  pkg-config,
  gcc-unwrapped,
  fontconfig,
  libGL,
  vulkan-loader,
  libxkbcommon,
  withX11 ? !stdenv.isDarwin,
  libX11,
  libXcursor,
  libXi,
  libXrandr,
  libxcb,
  withWayland ? !stdenv.isDarwin,
  wayland,
  shaderc,
  ...
}: let
  readTOML = f: builtins.fromTOML (builtins.readFile f);
  cargoToml = readTOML ./Cargo.toml;
  rioToml = readTOML ./frontends/rioterm/Cargo.toml;
  rustPlatform = makeRustPlatform {
    cargo = rust-toolchain;
    rustc = rust-toolchain;
  };
  rlinkLibs =
    lib.optionals stdenv.isLinux [
      (lib.getLib gcc-unwrapped)
      fontconfig
      libGL
      libxkbcommon
      vulkan-loader
    ]
    ++ lib.optionals withX11 [
      libX11
      libXcursor
      libXi
      libXrandr
      libxcb
    ]
    ++ lib.optionals withWayland [
      wayland
    ];

  inherit (lib.fileset) unions toSource;
in
  rustPlatform.buildRustPackage {
    inherit (cargoToml.workspace.package) version;
    name = "nova-rio";
    src = toSource {
      root = ./.;
      fileset = unions ([
          ./Cargo.lock
          ./Cargo.toml
          ./misc # Extra desktop/terminfo files
        ]
        ++ (map (x: ./. + "/${x}") cargoToml.workspace.members));
    };
    cargoLock.lockFile = ./Cargo.lock;

    cargoBuildFlags = "-p rioterm";

    buildInputs = rlinkLibs ++ (lib.optionals stdenv.isDarwin [darwin.libutil]);
    runtimeDependencies = rlinkLibs;

    nativeBuildInputs =
      [
        rustPlatform.bindgenHook
        ncurses
        shaderc
      ]
      ++ lib.optionals stdenv.isLinux [
        cmake
        pkg-config
        autoPatchelfHook
        makeWrapper
      ];

    outputs = [
      "out"
      "terminfo"
    ];

    postInstall =
      ''
        install -D -m 644 misc/com.yazelix.nova-rio.desktop -t \
                          $out/share/applications
        install -D -m 644 misc/logo.svg \
                          $out/share/icons/hicolor/scalable/apps/nrio.svg

        # Install terminfo files
        install -dm 755 "$terminfo/share/terminfo/r/"
        tic -xe xterm-rio,rio,rio-direct -o "$terminfo/share/terminfo" misc/rio.terminfo
        mkdir -p $out/nix-support
        echo "$terminfo" >> $out/nix-support/propagated-user-env-packages
      ''
      # Outside NixOS the Nix Vulkan loader finds no usable driver; add packaged
      # Mesa to standard discovery, keeping host drivers and user overrides.
      + lib.optionalString stdenv.hostPlatform.isLinux ''
        wrapProgram $out/bin/nrio \
          --set-default VK_ADD_DRIVER_FILES ${mesa}/share/vulkan/icd.d
      ''
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        mkdir $out/Applications/
        cp -R "misc/osx/NovaRio.app" "$out/Applications/"
        mkdir "$out/Applications/NovaRio.app/Contents/MacOS/"
        ln -s $out/bin/nrio "$out/Applications/NovaRio.app/Contents/MacOS/nrio"
      '';

    buildNoDefaultFeatures = true;
    buildFeatures = (lib.optionals withX11 ["x11"]) ++ (lib.optionals withWayland ["wayland"]);
    checkType = "debug";
    meta = {
      description = rioToml.package.description;
      longDescription = rioToml.package.extended-description;
      homepage = cargoToml.workspace.package.homepage;
      license = lib.licenses.mit;
      platforms = lib.platforms.unix;
      changelog = "https://github.com/raphamorim/rio/blob/master/CHANGELOG.md";
      mainProgram = "nrio";
    };
  }
