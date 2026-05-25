{ lib, test-lib, ... }:

let
  capturingFactory =
    args:
    let
      jobName = "${args.stack}_${args.component}_${args.deployment}";
      envTag = "env:${if args.settings.environment != null then args.settings.environment else "null"}";
      imageTag = "image:${args.settings.image or "none"}";
      extraPathTags = map (p: "path:${p}") args.settings.extraPaths;
    in
    {
      jobs.${jobName} = {
        tags = [
          envTag
          imageTag
        ]
        ++ extraPathTags;
      };
      jobSets.${jobName} = { };
    };

  baseConfig = {
    defaultJobFactory = "capture";
    jobFactories.capture.fn = capturingFactory;
  };
in
{
  # settings.environment is passed to factory
  test-stacks-settings-environment = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev.environment = "dev";
              components.api = { };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobs"
            "app_api_dev"
            "tags"
          ])
          (lib.filter (lib.hasPrefix "env:"))
        ];
    expected = [ "env:dev" ];
  };

  # settings carries freeform deployment fields through to the factory
  test-stacks-settings-freeform = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = {
                environment = "dev";
                image = "my-runner:1.0";
              };
              components.api = { };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobs"
            "app_api_dev"
            "tags"
          ])
          (lib.filter (lib.hasPrefix "image:"))
        ];
    expected = [ "image:my-runner:1.0" ];
  };

  # settings.environment defaults to the deployment name when not set
  test-stacks-settings-environment-default = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = { };
              components.api = { };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobs"
            "app_api_dev"
            "tags"
          ])
          (lib.filter (lib.hasPrefix "env:"))
        ];
    expected = [ "env:dev" ];
  };

  # settings.environment can be set to null to indicate no environment
  test-stacks-settings-environment-null = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev.environment = null;
              components.api = { };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobs"
            "app_api_dev"
            "tags"
          ])
          (lib.filter (lib.hasPrefix "env:"))
        ];
    expected = [ "env:null" ];
  };

  # deployment config takes precedence over component config on key conflict
  test-stacks-settings-deployment-wins = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev.extraPaths = [ "deployment-override/**" ];
              components.api.extraPaths = [ "component-default/**" ];
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobs"
            "app_api_dev"
            "tags"
          ])
          (lib.filter (lib.hasPrefix "path:"))
        ];
    expected = [ "path:deployment-override/**" ];
  };

  # settings.extraPaths from component is passed to the factory
  test-stacks-settings-extrapaths = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = { };
              components.api.extraPaths = [ "shared/modules/**" ];
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobs"
            "app_api_dev"
            "tags"
          ])
          (lib.filter (lib.hasPrefix "path:"))
        ];
    expected = [ "path:shared/modules/**" ];
  };

  # settings.extraPaths with multiple entries
  test-stacks-settings-extrapaths-multiple = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = { };
              components.api.extraPaths = [
                "shared/modules/**"
                "config/common.yaml"
              ];
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobs"
            "app_api_dev"
            "tags"
          ])
          (lib.filter (lib.hasPrefix "path:"))
        ];
    expected = [
      "path:shared/modules/**"
      "path:config/common.yaml"
    ];
  };

  # settings.extraPaths defaults to empty list
  test-stacks-settings-extrapaths-default = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = { };
              components.api = { };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobs"
            "app_api_dev"
            "tags"
          ])
          (lib.filter (lib.hasPrefix "path:"))
        ];
    expected = [ ];
  };
}
