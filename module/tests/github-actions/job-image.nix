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
          github-actions.images.enable = false;
          jobs.job.image = "nix";
        };
      in
      result.jobs.job ? container;
    expected = false;
  };

  test-github-actions-job-with-image-from-repository = {
    expr = test-lib.eval-github-actions {
      github-actions.images.repository = "ghcr.io/org";
      imageRegistry.nix = "nix:latest";
      jobs.job.image = "nix";
    };
    expected = {
      jobs.job = {
        container.image = "ghcr.io/org/nix:latest";
        steps = [ checkoutStep ];
      };
    };
  };

  # Direct job image references are never prefixed, even when a repository is set
  test-github-actions-job-with-direct-image-ignores-repository = {
    expr = test-lib.eval-github-actions {
      github-actions.images.repository = "ghcr.io/org";
      jobs.job.image = "ubuntu:24.04";
    };
    expected = {
      jobs.job = {
        container.image = "ubuntu:24.04";
        steps = [ checkoutStep ];
      };
    };
  };

  test-github-actions-job-with-external-image-from-repository = {
    expr = test-lib.eval-github-actions {
      github-actions.images.repository = "ghcr.io/org";
      imageRegistry.ubuntu = "docker.io/library/ubuntu:24.04";
      jobs.job.image = "ubuntu";
    };
    expected = {
      jobs.job = {
        container.image = "docker.io/library/ubuntu:24.04";
        steps = [ checkoutStep ];
      };
    };
  };
}
