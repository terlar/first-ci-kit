<p align="center">
  <img src="https://github.com/user-attachments/assets/e994e52a-bcea-4eb3-9ca8-ab25e73e7a59" />
</p>
<h1 align="center">first-ci-kit</h1>
<p align="center">CI pipeline abstraction built on the Nix module system</p>

---

Define your CI pipeline once in Nix and generate configuration for multiple CI systems from that single source of truth. Instead of maintaining a GitLab CI YAML, a GitHub Actions workflow, and a local runner config separately, you write one Nix module and let first-ci-kit produce all of them.

## Generation targets

| Backend | Status |
|---------|--------|
| GitLab CI | Stable |
| GitHub Actions | Stable |
| process-compose (local) | Work in progress |

## Quick start

Bootstrap a new project from the template:

```bash
nix flake init -t github:terlar/first-ci-kit
```

This creates a `dev/ci.nix` with a minimal working pipeline you can expand:

```nix
{
  first-ci-kit.pipelines.default = {
    pipeline = {
      gitlab-ci = {
        defaultStage = "main";
        settings = {
          stages = [ "main" ];
          workflow.rules = [
            { "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_PROTECTED"; }
            { "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"; }
          ];
        };
      };

      github-actions.settings = {
        name = "CI";
        on.push.branches = [ "main" ];
        on.pull_request.branches = [ "main" ];
      };
    };

    jobs.test = {
      github-actions.runs-on = "ubuntu-latest";
      commands = [ ''echo "hello from first-ci-kit"'' ];
    };
  };
}
```

## Adding to an existing flake

first-ci-kit has **no nixpkgs dependency** — it only requires `flake-parts`:

```nix
# flake.nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    first-ci-kit.url = "github:terlar/first-ci-kit";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [ inputs.first-ci-kit.flakeModule ];
    # your first-ci-kit.pipelines config here
  };
}
```

## Concepts

- **Job** — a single unit of work with commands, steps, image, tags, and optional features (checkout, nix, nix cache, artifacts).
- **JobSet** — a named group of jobs that share common defaults (image, tags, needs).
- **Stack** — a high-level abstraction that combines components and deployments and generates jobs automatically via a job factory.
- **Pipeline** — a collection of jobs with backend-specific settings (stages, triggers, runners).
- **Job factory** — a parameterised function that generates jobs from a common template.

## Module documentation

Full option reference is in [`module/README.md`](./module/README.md). Reusable patterns and recipes are in [`docs/patterns.md`](./docs/patterns.md). It is generated from the Nix module sources and covers every option with types, defaults, and examples.

## Building pipelines manually

```bash
nix build .#ci-pipelines-github-actions   # GitHub Actions workflow files
nix build .#ci-pipelines-gitlab-ci        # GitLab CI pipeline files
```

Both commands build a single bundle derivation (via `pkgs.linkFarm`) containing all pipeline files, which you can then copy into your repo.

## Contributing

```bash
nix develop      # or: direnv allow
nix eval .#tests.first-ci-kit   # run tests (pure Nix eval, fast)
nix flake check                 # run all checks
```

Pre-commit hooks run automatically on `git commit` and `git push`.
