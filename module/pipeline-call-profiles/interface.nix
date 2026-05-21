{ lib, ci-lib, ... }:

{
  options.pipelineCallProfiles = lib.mkOption {
    type = lib.types.lazyAttrsOf ci-lib.types.pipelineCallType;
    default = { };
    description = ''
      Named pipeline call profiles. Each profile is a reusable `pipelineCall`
      configuration that can be referenced by name via `job.pipelineCallProfile`.
    '';
  };
}
