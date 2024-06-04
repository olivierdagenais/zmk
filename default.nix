{ pkgs ? (import ./nix/pinned-nixpkgs.nix {}) }:
let
  inherit (pkgs) newScope;
  inherit (pkgs.lib) makeScope;
in

makeScope newScope (self: with self; {
  west = pkgs.python3Packages.west.overrideAttrs(attrs: {
    patches = (attrs.patches or []) ++ [./nix/west-manifest.patch];
  });

  # To update the pinned Zephyr dependecies using west and update-manifest:
  #  nix shell -f . west -c west init -l app
  #  nix shell -f . west -c west update
  #  nix shell -f . update-manifest -c update-manifest > nix/manifest.json
  # Note that any `group-filter` groups in west.yml need to be temporarily
  # removed, as `west update-manifest` requires all dependencies to be fetched.
  update-manifest = callPackage ./nix/update-manifest { inherit west; };

  combine_uf2 = a: b: pkgs.runCommandNoCC "combined_${a.name}_${b.name}" {}
  ''
    mkdir -p $out
    cat ${a}/zmk.uf2 ${b}/zmk.uf2 > $out/glove81.uf2
  '';

  zephyr = callPackage ./nix/zephyr.nix { };

  zmk = callPackage ./nix/zmk.nix { };

  zmk_settings_reset = zmk.override {
    shield = "settings_reset";
  };

  glove81_left = zmk.override {
    board = "glove81_lh";
  };

  glove81_right = zmk.override {
    board = "glove81_rh";
  };

  glove81_combined = combine_uf2 glove81_left glove81_right;

  glove81_v0_left = zmk.override {
    board = "glove81_v0_lh";
  };

  glove81_v0_right = zmk.override {
    board = "glove81_v0_rh";
  };
})
