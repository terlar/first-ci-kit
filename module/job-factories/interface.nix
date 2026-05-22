{ lib, ... }:

let
  inherit (lib) types;
in
{
  options = {
    jobFactories = lib.mkOption {
      type = types.lazyAttrsOf (
        types.submodule {
          options = {
            fn = lib.mkOption {
              type = types.functionTo types.attrs;
              description = ''
                Factory function that receives a context attrset and returns
                pipeline-level config (typically `{ jobs = { … }; jobSets = { … }; }`).

                When used via `config.stacks`, the context contains:
                `{ stack, component, deployment, needs, formatJobName, factoryName }`.
                When used via `applications`, the context is whatever attrset was
                passed in that list entry.
              '';
              example = lib.literalExpression ''
                { stack, component, deployment, needs, formatJobName, ... }:
                let
                  jobName = formatJobName [ stack.name component.name deployment ];
                in
                {
                  jobs.''${jobName} = {
                    image = "registry.example.com/tofu:latest";
                    needs = map (n: n.jobSet) needs;
                    script = [ "tofu -chdir=stacks/''${stack.name}/''${component.name} apply" ];
                  };
                  jobSets.''${jobName}.jobs = [ jobName ];
                }
              '';
            };

            applications = lib.mkOption {
              type = types.listOf types.attrs;
              default = [ ];
              description = ''
                List of argument attrsets to apply to `fn`. Each entry calls
                `fn <args>` and merges the result into the pipeline config.

                Typically populated automatically by the stacks engine; set
                manually only when using a factory without the stacks module.
              '';
              example = lib.literalExpression ''
                [
                  { stack = "networking"; component = "vpc"; deployment = "prod"; needs = []; }
                  { stack = "networking"; component = "dns"; deployment = "prod"; needs = []; }
                ]
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        Named job factories. Each factory has a `fn` that produces pipeline
        config from an argument attrset, and an `applications` list of argument
        attrsets to apply.

        Factories are referenced by name from `config.stacks.*.jobFactory` or
        `config.defaultJobFactory`.
      '';
      example = lib.literalExpression ''
        {
          tofu-component.fn = { stack, component, deployment, formatJobName, needs, ... }:
            let jobName = formatJobName [ stack.name component.name deployment ]; in
            {
              jobs.''${jobName} = {
                image = "registry.example.com/tofu:1.9";
                script = [ "tofu apply" ];
              };
              jobSets.''${jobName}.jobs = [ jobName ];
            };
        }
      '';
    };
  };
}
