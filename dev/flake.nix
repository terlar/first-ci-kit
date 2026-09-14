{
  description = "Dependencies for development purposes";

  inputs = {
    dev-flake = {
      url = "github:terlar/dev-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    process-compose.url = "github:platonic-systems/process-compose-flake";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
  };

  outputs = _: { };
}
