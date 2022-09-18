{ pkgs ? import <nixpkgs> {} }: with pkgs; let

  isM1Mac = stdenv.system == "aarch64-darwin";

  # Rust
  # ----

  rust = rust-bin.stable.latest.default;
  rustPlatform = makeRustPlatform {
    cargo = rust;
    rustc = rust;
  };

  # Wraps
  # -----
  # Inspired by https://www.tweag.io/blog/2022-06-02-haskell-stack-nix-shell/

  # https://github.com/NixOS/nixpkgs/issues/140774#issuecomment-976899227
  m1HaskellPackages =
    pkgs.haskellPackages.override {
      overrides = self: super:
        let
          workaround140774 = hpkg: with pkgs.haskell.lib;
            overrideCabal hpkg (drv: {
              enableSeparateBinOutput = false;
            });
        in
        {
          ghcid = workaround140774 super.ghcid;
          stack = workaround140774 super.stack;
        };
    };

  stack-wrapped = symlinkJoin {
    name = "stack";
    paths =
      [ (if isM1Mac
          then m1HaskellPackages.stack
          else haskellPackages.stack
        )
      ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/stack \
        --add-flags "\
          --nix \
          --no-nix-pure \
          --nix-shell-file=nix/stack-integration.nix \
        "
    '';
  };

  # Dependencies
  # ------------

  deps = {

    tools = [
      curl
      just
      simple-http-server
      (if isM1Mac then pkgs-x86.watchexec else watchexec)
    ];

    languages = [
      elmPackages.elm
      elmPackages.elm-format
      nodejs-18_x
      nodePackages.pnpm
      rust
      stack-wrapped
    ];

    tauri = {
      # Needed to build Tauri on Mac OS
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/darwin/apple-sdk/frameworks.nix
      macOS = [
        darwin.apple_sdk.frameworks.AppKit
        darwin.apple_sdk.frameworks.WebKit
        libiconv
      ];
    };

  };

in

mkShell {

  buildInputs = builtins.concatLists [
    deps.tools
    deps.languages

    # Mac OS dependencies
    (lib.optionals stdenv.isDarwin deps.tauri.macOS)
  ];

  NIX_PATH = "nixpkgs=" + path;

}
