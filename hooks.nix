{ lib, hookModule, ... }:

let
  inherit (lib) types;
in
{
  options.hooks = {
    first-ci-kit-gen-github-actions = lib.mkOption {
      description = "generate GitHub Actions workflow";
      type = types.submodule {
	imports = [ hookModule ];
	options.settings = {
	  pipeline = lib.mkOption {
	    type = types.str;
	    description = "The pipeline to generate.";
	    default = "default";
	    example = "pr";
	  };

          outputPath = lib.mkOption {
	    type = types.str;
	    description = "The path of the output file generated.";
	    default = ".github/workflows/ci.yaml";
	    example = ".github/workflows/example.yaml";
	  };
	};
      };
    };

    first-ci-kit-gen-gitlab-ci = lib.mkOption {
      description = "generate GitLab CI pipeline";
      type = types.submodule {
	imports = [ hookModule ];
	options.settings = {
	  pipeline = lib.mkOption {
	    type = types.str;
	    description = "The pipeline to generate.";
	    default = "default";
	    example = "pr";
	  };

          outputPath = lib.mkOption {
	    type = types.str;
	    description = "The path of the output file generated.";
	    default = ".gitlab-ci.yml";
	    example = ".gitlab/ci.yml";
	  };
	};
      };
    };
  };
}
