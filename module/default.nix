{ lib, ... }:

{
  imports = [
    {
      config._module.args = {
        ci-lib = import ./lib { inherit lib; };
      };
    }

    ./interface.nix
    ./jobs
    ./job-sets
  ];
}
