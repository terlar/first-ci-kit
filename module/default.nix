{ lib, ... }:

{
  config._module.args.ci-lib = import ./lib { inherit lib; };

  imports = [
    ./interface.nix
    ./jobs
    ./job-interfaces
    ./job-sets
  ];
}
