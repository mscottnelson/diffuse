{ pkgs ? import <nixpkgs> {} }: with pkgs; let

  isM1Mac = stdenv.system == "aarch64-darwin";

  # Rust
  # ----

  rust = rust-bin.stable.latest.default;
  rustPlatform = makeRustPlatform {
    cargo = rust;
    rustc = rust;
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
      stack
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
