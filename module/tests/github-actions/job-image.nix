{ test-lib, ... }:

let
  checkoutStep = {
    uses = "actions/checkout@v7";
  };
in
{
  test-github-actions-job-with-image = {
    expr = test-lib.eval-github-actions {
      jobs.job.image = "ubuntu:24.04";
    };
    expected = {
      jobs.job = {
        container.image = "ubuntu:24.04";
        steps = [ checkoutStep ];
      };
    };
  };

  test-github-actions-job-with-image-from-registry = {
    expr = test-lib.eval-github-actions {
      imageRegistry.nix = "europe-docker.pkg.dev/org/repo/nix:latest";
      jobs.job.image = "nix";
    };
    expected = {
      jobs.job = {
        container.image = "europe-docker.pkg.dev/org/repo/nix:latest";
        steps = [ checkoutStep ];
      };
    };
  };

  test-github-actions-job-image-opt-out = {
    expr =
      let
        result = test-lib.eval-github-actions {
          github-actions.enableImage = false;
          jobs.job.image = "nix";
        };
      in
      result.jobs.job ? container;
    expected = false;
  };
}
