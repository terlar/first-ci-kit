{ lib, ... }:

let
  inherit (lib) types;

  stepType = types.submodule {
    options = {
      run = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Shell command to run.";
      };

      block = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Name of a stepBlocks entry to use.";
      };

      inputs = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Inputs passed to the block. Only valid together with `block`.";
      };

      name = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional display name for the step.";
      };

      env = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment variables for this step.";
      };

      github-actions = lib.mkOption {
        type = types.nullOr (types.attrsOf types.anything);
        default = null;
        description = "Raw GitHub Actions step attrs, merged over the rendered step for `run`/`block` (native mode); a GitHub-only step on its own.";
      };

      gitlab-ci = lib.mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "GitLab script lines for a GitLab-only step; ignored when `run` or `block` is set.";
      };
    };
  };

  stepBlockType = types.submodule {
    options = {
      description = lib.mkOption {
        type = types.str;
        default = "";
        description = "Used for the composite action description.";
      };

      inputs = lib.mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              description = lib.mkOption {
                type = types.str;
                default = "";
                description = "Input description.";
              };

              default = lib.mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Default value. `null` means the input is required.";
              };
            };
          }
        );
        default = { };
        description = "Declared inputs for this block.";
      };

      steps = lib.mkOption {
        type = types.functionTo (types.listOf stepType);
        description = "Function from `{ inputs }` to a list of steps.";
      };
    };
  };

  expandPipelineNeed =
    jobSets: need:
    if need.jobSet != null then
      map (job: {
        inherit job;
        inherit (need) optional artifacts;
      }) jobSets.${need.jobSet}.jobs
    else
      [
        {
          inherit (need) job optional artifacts;
        }
      ];
in
{
  # Resolve a job image reference against the shared imageRegistry. Only
  # entries found in the registry get the repository prefix (relative entries,
  # i.e. without "/"); any other image reference is used literally.
  resolveImage =
    repository: registry: image:
    if registry ? ${image} then
      let
        entry = registry.${image};
      in
      if repository != null && !lib.hasInfix "/" entry then "${repository}/${entry}" else entry
    else
      image;

  # Component names as found by stackDiscovery. With `stackName` set, the
  # names under `path`; otherwise "<stack>/<component>" across stacks.
  # Defaults mirror the stackDiscovery option defaults.
  discoverComponentNames =
    {
      path,
      stackName ? null,
      excludeDirs ? [ "modules" ],
      deployments ? { },
      ...
    }:
    let
      deps = {
        subdirectory = "deployments";
        detection = "directories";
        extension = ".tfvars";
      }
      // deployments;

      subdirs =
        dir:
        lib.pipe dir [
          builtins.readDir
          (lib.filterAttrs (_: type: type == "directory"))
          builtins.attrNames
        ];

      isComponent =
        dir:
        let
          entries = builtins.readDir dir;
        in
        if deps.subdirectory != null then
          (entries.${deps.subdirectory} or "") == "directory"
        else if deps.detection == "files" then
          builtins.any (lib.hasSuffix deps.extension) (builtins.attrNames entries)
        else
          builtins.any (t: t == "directory") (builtins.attrValues entries);

      componentsIn = dir: lib.filter (name: isComponent "${dir}/${name}") (subdirs dir);
    in
    if stackName != null then
      componentsIn path
    else
      lib.concatMap (stack: map (c: "${stack}/${c}") (componentsIn "${path}/${stack}")) (
        lib.filter (s: !builtins.elem s excludeDirs) (subdirs path)
      );

  documentsToYAML = lib.concatMapStringsSep "---\n" (x: (builtins.toJSON x) + "\n");

  types = {
    needsType = types.submoduleWith {
      description = "Needs configuration";
      modules = [
        {
          options = {
            job = lib.mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Name of the needed job.";
            };

            jobSet = lib.mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Name of the needed job set.";
            };

            optional = lib.mkOption {
              type = types.bool;
              default = false;
              description = "Whether need is optional.";
            };

            artifacts = lib.mkOption {
              type = types.bool;
              default = true;
              description = "Whether artifacts from dependency are used.";
            };
          };
        }
      ];
    };

    inherit stepType stepBlockType;
  };

  jobToNeed = job: {
    inherit job;
    artifacts = false;
    optional = true;
  };

  # Expand a single pipeline need given a jobSets attrset.
  # Returns a list of { job, optional, artifacts }.
  inherit expandPipelineNeed;

  # Expand a list of pipeline needs into a flat list of { job, optional, artifacts }.
  expandPipelineNeeds = jobSets: needs: lib.flatten (map (expandPipelineNeed jobSets) needs);

  replaceVariables =
    variables:
    let
      from = lib.pipe variables [
        builtins.attrNames
        (map (x: "{${x}}"))
      ];
      to = builtins.attrValues variables;
    in
    map (builtins.replaceStrings from to);

  gitlab-ci = import ./gitlab-ci.nix { inherit lib; };
  process-compose = import ./process-compose.nix { inherit lib; };
  stepBlocks = import ./step-blocks.nix { inherit lib; };
}
