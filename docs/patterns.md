# Patterns

Reusable patterns for working with first-ci-kit. Each pattern answers a specific design question and shows the idiomatic Nix module solution.

---

## 1. Shared pipeline call config with jobSet defaults

**Problem:** Many jobs call the same child pipeline with the same base configuration. You want to define that configuration once and share it across jobs without a dedicated "profiles" abstraction.

Use `jobSet.jobDefaults.pipelineCall`. Any job that carries the matching tag inherits the shared `pipelineCall` config, and can still override individual fields.

```nix
{
  jobSets.terraform = {
    tags = [ "terraform" ];
    jobDefaults.pipelineCall = {
      pipeline = "terraform";
      gitlab-ci.rulesInput = "rules";
    };
  };

  pipelines.default.jobs = {
    vpc-dev = {
      tags = [ "terraform" ];
      pipelineCall.inputs.environment = "dev";   # override one field
      branches.default.triggers.onMergeRequest = true;
      branches.default.triggers.onPush = true;
    };
    vpc-prod = {
      tags = [ "terraform" ];
      pipelineCall.inputs.environment = "prod";
      branches.production.triggers.onPush = true;
    };
  };
}
```

`jobDefaults` is applied with `lib.mkDefault`, so any explicit `pipelineCall` setting on the job takes precedence over the shared defaults.

---

## 2. Tag-based job grouping

**Problem:** You want a `jobSet` to apply defaults to a category of jobs without maintaining an explicit membership list.

Set `tags` on the `jobSet` instead of listing jobs by name. A job is automatically a member of the set if it carries all of the set's tags.

```nix
{
  jobSets.nix = {
    tags = [ "nix" ];
    jobDefaults = {
      image = "nixos/nix";
      env.NIX_CONFIG = "experimental-features = nix-command flakes";
    };
  };

  pipelines.default.jobs = {
    build.tags = [ "nix" ];    # member — gets image and NIX_CONFIG
    test.tags  = [ "nix" ];    # member
    lint.tags  = [ "shell" ];  # not a member
  };
}
```

A job may carry multiple tags and therefore belong to multiple jobSets, accumulating defaults from each.

---

## 3. Staged pipelines with jobSet needs

**Problem:** You want all jobs in one phase to complete before any job in the next phase starts, without wiring each dependency manually.

Declare `needs = [{ jobSet = "…"; }]` on the downstream jobSet. It expands automatically to every concrete job in the upstream set.

```nix
{
  jobSets = {
    build = { tags = [ "build" ]; };
    test  = { tags = [ "test" ]; needs = [{ jobSet = "build"; }]; };
    deploy = { tags = [ "deploy" ]; needs = [{ jobSet = "test"; }]; };
  };
}
```

This pattern scales to environment promotion gates. A single line enforces that every staging job waits for the entire dev phase:

```nix
jobSets.stg.needs = [{ jobSet = "dev"; }];
```

Because the factory (or manual job definitions) already tags staging jobs with `stg`, this one declaration propagates to all of them.

---

## 4. Parameterised job generation with factories

**Problem:** Many jobs share the same structure but differ in a few parameters (stack name, environment, service). Writing each job by hand does not scale.

Define a `jobFactory`: a function `fn` that accepts an attrset of parameters and returns `{ jobs = …; jobSets = …; }`, plus an `applications` list of parameter sets to call it with.

```nix
let
  serviceFactory = { name, env, ... }: {
    jobs = {
      "${name}_${env}_lint"   = { commands = [ "lint ${name}" ]; };
      "${name}_${env}_test"   = { commands = [ "test ${name}" ]; needs = [{ job = "${name}_${env}_lint"; }]; };
      "${name}_${env}_deploy" = { commands = [ "deploy ${name} ${env}" ]; needs = [{ job = "${name}_${env}_test"; }]; };
    };
    jobSets."${name}_${env}" = {
      jobs = [ "${name}_${env}_lint" "${name}_${env}_test" "${name}_${env}_deploy" ];
    };
  };
in
{
  jobFactories.service = {
    fn = serviceFactory;
    applications = [
      { name = "api";    env = "dev"; }
      { name = "api";    env = "prod"; }
      { name = "worker"; env = "dev"; }
    ];
  };
}
```

All results are merged into the top-level `jobs` and `jobSets`.

`applications` defaults to `[]` and does not need to be set explicitly. When `stacks` is used, the stack engine populates `applications` automatically — see [pattern 5](#5-stacks--components--deployments).

---

## 5. Stacks — components × deployments

**Problem:** Your infrastructure is a matrix of components (e.g. `vpc`, `cluster`) and deployments (e.g. `dev`, `prod`). You need a job per combination, with cross-component dependency ordering within each deployment.

The `stacks` module handles this directly. Declare components and deployments; the stack engine generates one factory application per triple and resolves `needs` within the same deployment.

```nix
{
  defaultJobFactory = "tofu";

  stacks.networking = {
    deployments = { dev = {}; prod = {}; };
    components = {
      vpc = {};
      dns = { needs = [{ component = "vpc"; }]; };
    };
  };
}
# Generates jobs: networking_vpc_dev, networking_vpc_prod,
#                 networking_dns_dev, networking_dns_prod
# networking_dns_dev automatically needs networking_vpc_dev (same deployment).
```

The factory function receives `stack`, `component`, `deployment`, `needs` (pre-resolved), and `formatJobName`. Use `formatJobName` rather than manual string concatenation — it applies the pipeline's configured separator consistently:

```nix
jobFactories.tofu.fn =
  { stack, component, deployment, needs, formatJobName, ... }:
  let
    jobName         = formatJobName [ stack component deployment ];
    stackDeployment = formatJobName [ stack deployment ];
  in
  {
    jobs.${jobName} = {
      tags = [ stackDeployment jobName ];
      branches.default = {
        changes.paths = [ "terraform/${stack}/${component}/**" ];
        triggers.onPush = true;
        triggers.onMergeRequest = true;
      };
      pipelineCall = {
        pipeline = "deploy";
        inputs   = { inherit stack component deployment; };
        gitlab-ci = {
          rulesInput     = "rules";
          pushRulesInput = "deploy_rules";
        };
      };
    };
    jobSets = {
      ${deployment}.tags       = [ deployment ];
      ${stackDeployment}.tags  = [ stackDeployment ];
      ${jobName} = { tags = [ jobName ]; inherit needs; };
    };
  };
```

`pipelineCall.gitlab-ci.templatePath` is auto-derived from the pipeline name (`gitlab-templates/<name>/template.yml`) and does not need to be set explicitly unless you use a non-standard path.

Cross-stack dependencies are expressed with `{ stack = "networking"; }` (all components of that stack, same deployment) or `{ stack = "networking"; component = "vpc"; }` (specific component):

```nix
stacks.cluster = {
  deployments = { dev = {}; prod = {}; };
  components = {
    control-plane.needs = [{ stack = "networking"; }];
    node-pools.needs    = [{ component = "control-plane"; }];
  };
};
```

### Separating topology from pipeline logic

For larger projects, put the topology data in a separate Nix file that is purely data — no pipeline options — so it can be consumed by other tools (diagram generators, documentation scripts) as well as the CI module:

```nix
# dev/flake-module.nix
{
  first-ci-kit.pipelines.default.stacks = import ./stacks.nix;
}
```

---

## 6. Splitting pipeline config across files

**Problem:** A pipeline has fixed top-level settings (workflow triggers, default image), a factory, and a child pipeline definition. Keeping everything in one file becomes unreadable.

Split the pipeline config across multiple flake-module files. The NixOS module system merges all imports, so each file can set any subset of `first-ci-kit.pipelines.<name>` options without coordination.

```
dev/
  flake-module.nix      ← imports the others
  ci/
    settings.nix        ← gitlab-ci/github-actions settings, jobSets ordering
    factory.nix         ← stacks, defaultJobFactory, jobFactories
    profile-tofu.nix    ← pipelines.profile-tofu definition
```

```nix
# dev/flake-module.nix
{
  imports = [
    ./ci/settings.nix
    ./ci/factory.nix
    ./ci/profile-tofu.nix
  ];
}

# dev/ci/settings.nix
{
  first-ci-kit.pipelines.default = {
    gitlab-ci.settings = {
      stages = [ "main" ];
      workflow.rules = [ … ];
    };
    github-actions = {
      defaultRunsOn = "ubuntu-latest";
      summaryJob.enable = true;
    };
    jobSets.stg.needs = [{ jobSet = "dev"; }];   # promotion gate
  };
}

# dev/ci/factory.nix
{
  first-ci-kit.pipelines.default = {
    stacks = import ../stacks.nix;
    defaultJobFactory = "tofu-component";
    jobFactories.tofu-component.fn = { stack, component, deployment, needs, formatJobName, ... }: { … };
  };
}

# dev/ci/profile-tofu.nix
{
  first-ci-kit.pipelines.profile-tofu = {
    inputs = { … };
    jobs = { … };
  };
}
```

Each file is a valid flake-parts module that sets only the options it owns. No `lib.mkMerge` or manual merging needed.

`lib.mkMerge` is still useful within a single file when you want to keep hand-written settings visually separate from a generated block, or when you need to merge conditional (`lib.mkIf`) config fragments.

---

## 7. Branch filtering and change detection

**Problem:** Jobs should only run when relevant files change, and only on the appropriate triggers (push, MR, or both).

Declare `branches.<name>` with `triggers` and `changes.paths`. Use `default` as the branch name to target the default branch; use any other string to target a named branch.

```nix
{
  jobs.deploy = {
    branches = {
      default = {
        changes.paths           = [ "src/**" "config/**" ];
        triggers.onMergeRequest = true;
        triggers.onPush         = true;
      };
      production = {
        changes.paths      = [ "src/**" ];
        triggers.onPush    = true;
      };
    };
  };
}
```

**GitLab CI** renders each branch entry as one or two `rules:` entries with `changes:` and `if:` conditions.

**GitHub Actions** auto-generates a `changes` job that runs the `gha-path-changes` script and emits a JSON output map. Every job with `changes.paths` gets a `needs: [changes]` and an `if:` condition gating on that map.

`workflow_dispatch` with `force_run_all: true` is a built-in capability of the changes system — no extra config required. When triggered manually with that input, the changes job marks every job as changed so the full pipeline runs.

---

## 8. Artifacts across jobs

**Problem:** One job produces a file (a plan, a build output) that a later job needs to consume.

Declare `artifacts.upload` on the producing job and `artifacts.download` on the consuming job. first-ci-kit renders the appropriate backend primitives on each platform.

```nix
{
  jobs = {
    plan = {
      commands = [ "tofu plan -out tfplan" ];
      artifacts.upload = {
        name          = "vpc-dev-plan";
        paths         = [ "tfplan" ];
        retentionDays = 7;
      };
    };

    apply = {
      needs = [{ job = "plan"; }];
      commands = [ "tofu apply tfplan" ];
      artifacts.download = {
        name = "vpc-dev-plan";
        path = ".";
      };
    };
  };
}
```

- **GitLab CI:** `upload` → `artifacts: { paths:, expire_in: }`; `download` is implicit via `needs` with `artifacts: true`.
- **GitHub Actions:** `upload` → `actions/upload-artifact` step; `download` → `actions/download-artifact` step inserted before the job's commands.

When the artifact name must include runtime values (e.g. an input variable), use `\${{ inputs.name }}` to emit a GHA expression literal — the backslash prevents Nix from interpreting the `${{}}` during evaluation:

```nix
artifacts.upload.name = "\${{ inputs.stack }}-\${{ inputs.deployment }}-plan";
```

---

## 9. Per-backend enable/disable

**Problem:** A job is only meaningful on one CI backend, or you need to temporarily disable a job on one platform without removing it.

Use `gitlab-ci.enable` or `github-actions.enable`. Disabled jobs are also pruned from `needs` lists and `triggers` references throughout the pipeline so no dangling dependencies remain.

```nix
{
  jobs = {
    # Only runs on GitLab CI — skipped entirely on GitHub Actions
    security-scan = {
      github-actions.enable = false;
      commands = [ "gitlab-security-scan" ];
    };

    # Only runs on GitHub Actions
    codeql = {
      gitlab-ci.enable = false;
      github-actions.runs-on = "ubuntu-latest";
      commands = [ "codeql analyze" ];
    };
  };
}
```

Setting `enable = false` at the top level disables the job on all backends and takes precedence over per-backend flags.

---

## 10. Reusable pipelines with inputs

**Problem:** A pipeline is called from multiple places (or multiple stacks) with different parameter values. You want a typed, documented interface for those parameters.

Declare `inputs` (and optionally `outputs`) on the pipeline. `autoEnvInputs = true` (the default) automatically makes each input available as an environment variable in every job.

```nix
{
  pipelines.deploy = {
    inputs = {
      environment = {
        type        = "choice";
        required    = true;
        description = "Target environment";
        options     = [ "dev" "stg" "prod" ];
      };
      dry_run = {
        type    = "boolean";
        default = "false";
      };
    };

    jobs.apply = {
      commands = [ "deploy --env $ENVIRONMENT" ];
      # $ENVIRONMENT is injected automatically via autoEnvInputs
    };
  };
}
```

- **GitHub Actions:** adds a workflow-level `env:` block mapping each input to `${{ inputs.<name> }}`.
- **GitLab CI:** emits a leading `spec.inputs:` YAML document and adds `variables: { NAME: "$[[ inputs.name ]]" }` to every job.

Set `autoEnvInputs = false` to manage environment variables manually.

### Backend-specific inputs

Some inputs only make sense on one backend. Use `gitlab-ci.inputs` for GitLab-only typed inputs (e.g. array-typed rule sets):

```nix
{
  pipelines.deploy = {
    inputs.environment = {};  # shared across backends

    gitlab-ci.inputs = {
      rules        = { type = "array"; default = []; description = "MR + push rules"; };
      deploy_rules = { type = "array"; default = []; description = "Push-only rules"; };
    };
  };
}
```

### transformJobName for reusable component templates

When a GitLab CI pipeline is used as a component template (called from many places), job names must be unique across all instantiations. Use `gitlab-ci.transformJobName` to prefix job names with runtime input values:

```nix
{
  pipelines.deploy = {
    inputs.stack      = {};
    inputs.deployment = {};

    gitlab-ci.transformJobName =
      name: "$[[ inputs.stack ]]_$[[ inputs.deployment ]]_${name}";
    # ${name} is Nix interpolation (resolved at generation time)
    # $[[ … ]] is a GitLab CI expression (emitted literally, resolved at runtime)
  };
}
```

---

## 11. Summary job as a required status check

**Problem:** GitHub branch protection requires listing every job as a required status check. Adding or removing a job means updating the branch protection rules.

Enable `summaryJob` on the pipeline. It generates a single fan-in job that always runs, needs every other job, and reports their statuses. Use this one job as the branch protection check instead of all individual jobs.

```nix
{
  pipelines.default.github-actions.summaryJob.enable = true;
}
```

The generated `summary` job:
- runs `if: always()` so it executes even when upstream jobs fail
- fans in on every other job via `needs:`
- requires `permissions: { actions: read }` to call the GitHub Actions API
- renders a Markdown status table to `$GITHUB_STEP_SUMMARY`

---

## 12. Shared setup steps with `lib.mkOrder`

**Problem:** Every job in a jobSet needs the same setup steps (install a tool, activate a dev shell) before its own commands, but you do not want to repeat them on each job.

Set `jobDefaults.github-actions.steps` with `lib.mkOrder` to position the shared steps relative to the automatically inserted checkout step and the job's own commands.

```nix
{
  jobSets.nix-jobs = {
    tags = [ "nix" ];
    jobDefaults.github-actions.steps = lib.mkOrder 550 [
      {
        name = "Install Nix";
        uses = "cachix/install-nix-action@v31";
      }
      {
        name = "Enter dev shell";
        run  = ''
          nix print-dev-env .#ci > env.sh
          echo "BASH_ENV=$PWD/env.sh" >> "$GITHUB_ENV"
        '';
      }
    ];
  };
}
```

Steps are merged in numeric order. The checkout step is inserted at a lower order value, so `lib.mkOrder 550` places Install Nix and Enter dev shell after checkout but before the job's own `run:` steps.

The `BASH_ENV` trick activates the Nix dev shell for all subsequent `run:` steps without wrapping each command in `source env.sh`. Bash reads `$BASH_ENV` automatically at the start of every non-interactive shell.

For GitLab CI, use `jobDefaults.gitlab-ci.before_script` instead:

```nix
{
  jobSets.nix-jobs = {
    tags = [ "nix" ];
    jobDefaults.gitlab-ci.before_script = [
      "nix print-dev-env .#ci > env.sh"
      ". ./env.sh"
    ];
  };
}
```
