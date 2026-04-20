{
  lib,
  ci-lib,
  config,
  ...
}:

let
  # Build caller job for one child pipeline (GHA)
  mkGhaDispatch =
    childName: child:
    let
      callerNeeds = map (n: config.github-actions.transformJobName n.job) (
        ci-lib.expandPipelineNeeds config.jobSets child.needs
      );

      callerJob = {
        uses = "./.github/workflows/${childName}.yml";
        secrets = "inherit";
      }
      // lib.optionalAttrs (child.github-actions.dispatch.callerIf != null) {
        "if" = child.github-actions.dispatch.callerIf;
      }
      // lib.optionalAttrs (callerNeeds != [ ]) {
        needs = callerNeeds;
      };
    in
    {
      ${childName} = callerJob;
    };
in
{
  config.github-actions.settings.jobs = lib.mkMerge (
    lib.mapAttrsToList mkGhaDispatch config.pipelines
  );
}
