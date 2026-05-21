{
  lib,
  config,
  rootConfig,
  ...
}:

{
  config = lib.mkIf (config.pipelineCallProfile != null) (
    let
      profileName = config.pipelineCallProfile;
      profile =
        rootConfig.pipelineCallProfiles.${profileName}
          or (throw "pipelineCallProfile: profile '${profileName}' not found in pipelineCallProfiles");
    in
    {
      pipelineCall = {
        pipeline = lib.mkDefault profile.pipeline;
        inputs = lib.mkDefault profile.inputs;
        github-actions = lib.mapAttrs (_: lib.mkDefault) profile.github-actions;
        gitlab-ci = lib.mapAttrs (_: lib.mkDefault) profile.gitlab-ci;
      };
    }
  );
}
