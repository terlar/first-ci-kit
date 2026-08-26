{
  lib,
  pkgs,
  nixosOptionsDoc,
  # Args
  moduleRoot,
  specialArgs ? { },
  extraModules ? [ ],
}:
let
  # Rewrite declarations under moduleRoot to relative paths.
  mapDeclarations =
    opt:
    opt
    // {
      declarations = map (
        decl:
        if lib.hasPrefix (toString moduleRoot) (toString decl) then
          let
            subpath = lib.removePrefix "/" (lib.removePrefix (toString moduleRoot) (toString decl));
          in
          {
            url = subpath;
            name = subpath;
          }
        else
          decl
      ) opt.declarations;
    };

  eval = lib.evalModules {
    inherit specialArgs;
    modules = [
      { options._module.args = lib.mkOption { internal = true; }; }
      moduleRoot
    ]
    ++ extraModules;
  };

  doc = nixosOptionsDoc {
    inherit (eval) options;
    transformOptions = mapDeclarations;
  };

  # Child pipelines embed the full root module for their own evaluation, which
  # makes the option tree self-referential and unusable for docs generation.
  # Instead, document only the child-pipeline-specific options by evaluating
  # the pipeline interface on its own.
  pipelineEval = lib.evalModules {
    modules = [
      (moduleRoot + "/pipelines/pipeline/interface.nix")
      # Satisfy the config references to backend options without documenting
      # them here (they are documented at the top level).
      {
        options.gitlab-ci.defaultStage = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          internal = true;
          visible = false;
          default = null;
        };
      }
      { _module.check = false; }
    ];
    specialArgs = {
      ci-lib = import (moduleRoot + "/lib") { inherit lib; };
    };
  };

  pipelineDoc = nixosOptionsDoc {
    inherit (pipelineEval) options;
    transformOptions =
      opt:
      mapDeclarations (
        opt
        // {
          name = "pipelines.<name>.${opt.name}";
          # Drop module-system internals (e.g. _module.args)
          visible = !lib.hasPrefix "_module" opt.name;
        }
      );
  };
in
# Append the child-pipeline-specific section to the main documentation.
pkgs.runCommand "options.md" { } ''
  cat ${doc.optionsCommonMark} >> $out
  cat <<'EOF' >> $out

  ## Child pipelines

  Each entry in `pipelines.<name>` is evaluated as an independent pipeline
  instance and accepts the same options as a top-level pipeline (jobs,
  jobSets, backend settings, and so on). The options below are specific to
  being dispatched as a child of another pipeline.

  EOF
  cat ${pipelineDoc.optionsCommonMark} >> $out
''
