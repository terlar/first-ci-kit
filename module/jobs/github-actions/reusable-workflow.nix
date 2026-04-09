# Build the YAML attrset for a single reusable workflow.
#
# Arguments:
#   lib            — nixpkgs lib
#
# Returns a function taking:
#   jobs           — attrs of rendered GHA job attrsets (name -> job attrset)
#   changes        — list of "jobname:paths\\|..." strings for the diff step (may be [])
#   checkoutAction — string, e.g. "actions/checkout@v6"
#   defaultRunsOn  — string or null
#
# Returns an attrset representing the reusable workflow YAML structure.
{ lib }:

{
  jobs,
  changes,
  checkoutAction,
  defaultRunsOn,
}:

let
  changesJob = lib.optionalAttrs (changes != [ ]) {
    changes = {
      outputs.changes = "\${{ steps.diff.outputs.changes }}";
      runs-on = defaultRunsOn;
      steps = [
        { uses = checkoutAction; }
        {
          id = "diff";
          shell = "bash";
          env = {
            DIFF_PATHS = builtins.concatStringsSep "\n" changes;
            GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
            GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
          };
          run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
        }
      ];
    };
  };
in
{
  on.workflow_call = { };
  jobs = changesJob // jobs;
}
