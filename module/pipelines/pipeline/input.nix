{ lib, ... }:

{
  options = {
    type = lib.mkOption {
      type = lib.types.enum [
        "string"
        "boolean"
        "number"
        "environment"
        "choice"
      ];
      default = "string";
      description = "Input type.";
    };

    required = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this input is required.";
    };

    default = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Default value. Must be a string (GitHub Actions requirement).";
    };

    description = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Human-readable description of this input.";
    };

    options = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Valid choices. Only meaningful when type = 'choice'.";
    };
  };
}
