{ lib, ... }:

{
  options = {
    value = lib.mkOption {
      type = lib.types.str;
      description = ''
        Expression referencing the job output.
        Example: "''${{ jobs.plan.outputs.plan }}"
      '';
    };

    description = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Human-readable description of this output.";
    };
  };
}
