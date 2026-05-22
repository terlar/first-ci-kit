{
  pkgs,
  lib,
  config,
}:

let
  inherit (config.pre-commit.settings) hooks;
  gh = hooks.first-ci-kit-gen-github-actions;
  gl = hooks.first-ci-kit-gen-gitlab-ci;

  tests = {
    "github-actions: default pipelines" = gh.settings.pipelines.default == ".github/workflows/ci.yml";
    "gitlab-ci: default pipelines" = gl.settings.pipelines.default == ".gitlab-ci.yml";
    "github-actions: hook name" = gh.name == "generate-github-actions";
    "gitlab-ci: hook name" = gl.name == "generate-gitlab-ci";
    "github-actions: pass_filenames is false" = !gh.pass_filenames;
    "gitlab-ci: pass_filenames is false" = !gl.pass_filenames;
  };
in
pkgs.runCommand "test-git-hooks" { } (
  ''
    set -e
  ''
  + lib.concatStrings (
    lib.mapAttrsToList (
      name: check:
      if check then
        ""
      else
        ''
          echo "FAILED: ${name}"
          exit 1
        ''
    ) tests
  )
  + ''
    echo "All git-hooks tests passed" > $out
  ''
)
