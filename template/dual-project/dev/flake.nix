{
  description = "Dependencies for development purposes";

  inputs = {
    dev-flake.url = "github:terlar/dev-flake";
    first-ci-kit = {
      url = "github:terlar/first-ci-kit";
      inputs.flake-parts.follows = "dev-flake/flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    process-compose.url = "github:platonic-systems/process-compose-flake";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
  };

  outputs = _: { };
}
