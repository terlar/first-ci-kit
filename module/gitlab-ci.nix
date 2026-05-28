{
  lib,
  config,
  ci-lib,
  ...
}:

let
  inherit (lib) types;

  renderGitlabInput =
    _name: input:
    lib.mergeAttrsList [
      (lib.optionalAttrs (input.default != null) { inherit (input) default; })
      (lib.optionalAttrs (input.description != "") { inherit (input) description; })
      (lib.optionalAttrs (input.type == "boolean") { type = "boolean"; })
      (lib.optionalAttrs (input.type == "choice" && input.options != [ ]) { inherit (input) options; })
    ];
in
{
  options.gitlab-ci = {
    templatesPath = lib.mkOption {
      type = types.str;
      default = "gitlab-templates";
      description = ''
        Base directory under which GitLab CI component templates are stored.
        Used as the prefix when deriving the default `templatePath` for each
        pipeline: `"''${templatesPath}/''${name}/template.yml"`.
      '';
    };

    generate = lib.mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to generate a GitLab CI pipeline file for this pipeline.
        Set to `false` to opt out of file generation (e.g. for pipelines that
        only target another backend such as GitHub Actions).
      '';
    };

    templatePath = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Local path to the GitLab CI component template for this pipeline (e.g.
        "gitlab-templates/profile-tofu/template.yml"). When set, jobs that call
        this pipeline via `pipelineCall` will emit an `include:` entry pointing
        to this path. Defaults to `"''${gitlab-ci.templatesPath}/''${name}/template.yml"`
        when the pipeline name is known (i.e. set via `flake-module.nix`).
      '';
    };

    inputs = lib.mkOption {
      type = config.types.yamlType;
      default = { };
      description = ''
        Define inputs for the CI/CD configuration.
        This will be added as a separate YAML document at the top of the {file}`pipeline.yml`.
      '';
      example = lib.literalExpression ''
        {
          website = {};
          user.default = "test-user";
          flags.default = "";
        }
      '';
    };

    settings = lib.mkOption {
      type = config.types.yamlType;
      default = { };
      description = "Configuration written for job to {file}`pipeline.yml`.";
      example = lib.literalExpression ''
        {
          image = "ubuntu";
          stages = [ "validate" "test" "build" "deploy" ];
          default.tags = [ "gke-runner" ];
        }
      '';
    };

    defaultStage = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The default stage to use for jobs";
    };

    transformJobName = lib.mkOption {
      type = types.functionTo types.str;
      default = lib.id;
      description = "A function to transform job names";
    };

    fileDocuments = lib.mkOption {
      internal = true;
      type = types.listOf config.types.yamlType;
      default = [ ];
      description = "Documents to write to the pipeline.yml";
    };

    file = lib.mkOption {
      internal = true;
      type = types.package;
      default = lib.pipe config.gitlab-ci.fileDocuments [
        ci-lib.documentsToYAML
        (builtins.toFile "pipeline.yml")
      ];
      description = "Package of the pipeline.yml";
    };
  };

  config = lib.mkIf (config.inputs != { }) {
    gitlab-ci.inputs = lib.mapAttrs renderGitlabInput config.inputs;
  };
}
