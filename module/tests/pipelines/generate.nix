{ lib, test-lib, ... }:

{
  # gitlab-ci.generate defaults to true
  test-gitlab-ci-generate-default = {
    expr = lib.pipe { } [
      test-lib.evalConfig
      (cfg: cfg.gitlab-ci.generate)
    ];
    expected = true;
  };

  # gitlab-ci.generate can be set to false
  test-gitlab-ci-generate-false = {
    expr = lib.pipe { gitlab-ci.generate = false; } [
      test-lib.evalConfig
      (cfg: cfg.gitlab-ci.generate)
    ];
    expected = false;
  };

  # github-actions.generate defaults to true
  test-github-actions-generate-default = {
    expr = lib.pipe { } [
      test-lib.evalConfig
      (cfg: cfg.github-actions.generate)
    ];
    expected = true;
  };

  # github-actions.generate can be set to false
  test-github-actions-generate-false = {
    expr = lib.pipe { github-actions.generate = false; } [
      test-lib.evalConfig
      (cfg: cfg.github-actions.generate)
    ];
    expected = false;
  };
}
