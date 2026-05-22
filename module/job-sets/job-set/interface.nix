{ lib, ... }:

let
  inherit (lib) types;

  needsType = types.submoduleWith {
    description = "Job set needs configuration";
    modules = [
      {
        options = {
          jobSet = lib.mkOption {
            type = types.str;
            description = "Name of the job set that must complete before this job set runs.";
            example = "networking_vpc_prod";
          };
        };
      }
    ];
  };
in
{
  options = {
    jobDefaults = lib.mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
      description = ''
        Configuration merged into every job listed in `jobs`. Use this to
        apply shared settings (image, tags, environment variables, etc.)
        without repeating them on each job definition.
      '';
      example = lib.literalExpression ''
        {
          image = "registry.example.com/tofu:1.9";
          tags = [ "linux" ];
        }
      '';
    };

    needs = lib.mkOption {
      type = types.listOf needsType;
      default = [ ];
      description = ''
        Job sets that must complete successfully before any job in this job
        set is allowed to run. Translated to `needs:` (GitHub Actions) or
        `needs:` rules (GitLab CI) on each job in the set.
      '';
      example = lib.literalExpression ''
        [
          { jobSet = "networking_vpc_prod"; }
          { jobSet = "security_iam_prod"; }
        ]
      '';
    };

    jobs = lib.mkOption {
      type = types.listOf types.str;
      apply = lib.unique;
      default = [ ];
      description = ''
        Names of jobs that belong to this job set. Duplicates are removed
        automatically. Jobs listed here receive the `jobDefaults` of this
        set merged into their config.
      '';
      example = lib.literalExpression ''
        [ "cluster_control-plane_prod" "cluster_node-pools_prod" ]
      '';
    };

    tags = lib.mkOption {
      type = types.listOf types.str;
      apply = lib.unique;
      default = [ ];
      description = ''
        Arbitrary string labels associated with this job set. Duplicates are
        removed automatically. Tags are used by backends to select or filter
        job sets (e.g. GitLab runner tag matching).
      '';
      example = lib.literalExpression ''[ "prod" "infra" ]'';
    };
  };
}
