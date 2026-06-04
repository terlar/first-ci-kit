{ lib, ... }:

{
  options.process-compose = {
    cli = lib.mkOption {
      type = lib.types.raw;
      default = { };
      description = "CLI configuration of process-compose to be passed to process-compose-flake cli.";
    };

    settings = lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
      description = ''
        Configuration of process-compose to be passed to process-compose-flake settings.
      '';
    };
  };
}
