# Module Structure Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce unnecessary directory nesting in `module/` while preserving the interface/backend file naming pattern.

**Architecture:** Five targeted structural changes: fold two tiny type files into `interface.nix`, flatten two single-file directories, and remove three pure-aggregator `default.nix` files by importing their contents directly from `module/default.nix`.

**Tech Stack:** Nix, flake-parts, NixOS module system

---

## File map: before → after

| Before | After | Change |
|---|---|---|
| `module/input.nix` | (deleted) | folded into `module/interface.nix` |
| `module/output.nix` | (deleted) | folded into `module/interface.nix` |
| `module/interface.nix` | `module/interface.nix` | updated (inline input/output submodule options) |
| `module/job-interfaces/default.nix` | (deleted) | was pure aggregator |
| `module/job-interfaces/interface.nix` | `module/job-interfaces.nix` | flattened |
| `module/jobs/github-actions/default.nix` | `module/jobs/github-actions.nix` | flattened; fix readFile path |
| `module/jobs/default.nix` | `module/jobs/default.nix` | update import path |
| `module/job-sets/default.nix` | (deleted) | options merged into `interface.nix` |
| `module/job-sets/interface.nix` | `module/job-sets/interface.nix` | absorbs `options.jobs` from deleted `default.nix` |
| `module/pipelines/default.nix` | (deleted) | was pure aggregator |
| `module/default.nix` | `module/default.nix` | imports updated throughout |

---

## Task 1: Fold `input.nix` and `output.nix` into `interface.nix`

**Files:**
- Modify: `module/interface.nix`
- Delete: `module/input.nix`
- Delete: `module/output.nix`

- [ ] **Step 1: Replace `interface.nix` with inlined submodule options**

Replace the entire content of `module/interface.nix` with:

```nix
{ lib, ... }:

let
  inherit (lib) types;

  inputModule = {
    options = {
      type = lib.mkOption {
        type = lib.types.enum [
          "string"
          "boolean"
          "number"
          "environment"
          "choice"
        ];
        default = "string";
        description = "Input type.";
      };

      required = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether this input is required.";
      };

      default = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Default value. Must be a string (GitHub Actions requirement).";
      };

      description = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Human-readable description of this input.";
      };

      options = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Valid choices. Only meaningful when type = 'choice'.";
      };
    };
  };

  outputModule = {
    options = {
      value = lib.mkOption {
        type = lib.types.str;
        description = ''
          Expression referencing the job output.
          Example: "''${{ jobs.plan.outputs.plan }}"
        '';
      };

      description = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Human-readable description of this output.";
      };
    };
  };
in
{
  options = {
    imageRegistry = lib.mkOption {
      type = types.lazyAttrsOf types.str;
      default = { };
      description = "Image registry with image names";
    };

    types = lib.mkOption {
      internal = true;
      type = types.lazyAttrsOf types.optionType;
      default = {
        yamlType =
          let
            valueType =
              types.nullOr (
                types.oneOf [
                  types.bool
                  types.int
                  types.float
                  types.str
                  types.path
                  (types.attrsOf valueType)
                  (types.listOf valueType)
                ]
              )
              // {
                description = "YAML value";
              };
          in
          valueType;
      };
    };

    inputs = lib.mkOption {
      type = types.attrsOf (
        types.submoduleWith {
          modules = [ inputModule ];
          shorthandOnlyDefinesConfig = true;
        }
      );
      default = { };
      description = ''
        Declared inputs for this pipeline.
        Becomes on.workflow_call.inputs on GitHub Actions and spec.inputs on GitLab CI.
      '';
    };

    outputs = lib.mkOption {
      type = types.attrsOf (
        types.submoduleWith {
          modules = [ outputModule ];
          shorthandOnlyDefinesConfig = true;
        }
      );
      default = { };
      description = ''
        Declared outputs for this pipeline.
        Becomes on.workflow_call.outputs on GitHub Actions.
      '';
    };
  };
}
```

- [ ] **Step 2: Delete `input.nix` and `output.nix`**

```bash
git rm module/input.nix module/output.nix
```

- [ ] **Step 3: Verify tests still pass**

```bash
git add -A
nix eval .#tests.first-ci-kit
```

Expected: attribute set of test results (no errors).

- [ ] **Step 4: Commit**

```bash
git add module/interface.nix
git commit -m "refactor: inline input and output submodule types into interface"
```

---

## Task 2: Flatten `job-interfaces/` → `job-interfaces.nix`

**Files:**
- Create: `module/job-interfaces.nix`
- Delete: `module/job-interfaces/` (both files)
- Modify: `module/default.nix`

- [ ] **Step 1: Create `module/job-interfaces.nix`**

```nix
{ lib, ... }:

let
  inherit (lib) types;
in
{
  options.jobInterfaces = lib.mkOption {
    type = types.lazyAttrsOf (types.functionTo (types.lazyAttrsOf types.deferredModule));
    default = { };
    description = "Job Interfaces to define jobs.";
  };
}
```

- [ ] **Step 2: Delete the `job-interfaces/` directory**

```bash
git rm module/job-interfaces/default.nix module/job-interfaces/interface.nix
```

- [ ] **Step 3: Update `module/default.nix` — change `./job-interfaces` to `./job-interfaces.nix`**

In `module/default.nix`, change:
```nix
    ./job-interfaces
```
to:
```nix
    ./job-interfaces.nix
```

- [ ] **Step 4: Verify tests still pass**

```bash
git add -A
nix eval .#tests.first-ci-kit
```

- [ ] **Step 5: Commit**

```bash
git add module/job-interfaces.nix module/default.nix
git commit -m "refactor: flatten job-interfaces directory into single file"
```

---

## Task 3: Flatten `jobs/github-actions/default.nix` → `jobs/github-actions.nix`

**Files:**
- Create: `module/jobs/github-actions.nix`
- Delete: `module/jobs/github-actions/` directory
- Modify: `module/jobs/default.nix`

- [ ] **Step 1: Create `module/jobs/github-actions.nix`**

The content is the same as `module/jobs/github-actions/default.nix` but the `readFile` path changes from `../../../packages/` to `../../packages/` (one fewer directory level).

```nix
{ lib, config, ... }:

let
  inherit (config.github-actions) checkoutAction;
  enabledJobs = lib.filterAttrs (_: job: job.enable && job.github-actions.enable) config.jobs;

  changes = lib.pipe enabledJobs [
    (builtins.mapAttrs (_: job: job.branches.default.changes.paths or [ ]))
    (lib.filterAttrs (_: paths: paths != [ ]))
    (builtins.mapAttrs (_: builtins.concatStringsSep "\\|"))
    (lib.mapAttrsToList (name: paths: "${name}:${paths}"))
  ];
in
{
  github-actions.settings.jobs = lib.mkMerge [
    (lib.mkIf (changes != [ ]) {
      changes = {
        outputs.changes = "\${{ steps.diff.outputs.changes }}";
        runs-on = config.github-actions.defaultRunsOn;
        steps = [
          { uses = checkoutAction; }
          {
            id = "diff";
            shell = "bash";
            env = {
              DIFF_PATHS = builtins.concatStringsSep "\n" changes;
              GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
              GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
            };
            run = builtins.readFile ../../packages/gha-path-changes/main.bash;
          }
        ];
      };
    })

    (lib.mapAttrs' (name: job: {
      name = config.github-actions.transformJobName name;
      value = builtins.removeAttrs job.github-actions [ "enable" ];
    }) enabledJobs)
  ];
}
```

- [ ] **Step 2: Delete the `jobs/github-actions/` directory**

```bash
git rm module/jobs/github-actions/default.nix
```

- [ ] **Step 3: Update `module/jobs/default.nix` — change `./github-actions` to `./github-actions.nix`**

In `module/jobs/default.nix`, change:
```nix
    ./github-actions
```
to:
```nix
    ./github-actions.nix
```

- [ ] **Step 4: Verify tests still pass**

```bash
git add -A
nix eval .#tests.first-ci-kit
```

- [ ] **Step 5: Commit**

```bash
git add module/jobs/github-actions.nix module/jobs/default.nix
git commit -m "refactor: flatten jobs/github-actions directory into single file"
```

---

## Task 4: Remove `job-sets/default.nix` aggregator

`job-sets/default.nix` imports `./interface.nix` and declares `options.jobs`. Neither is a `config` block — it's pure options. Moving `options.jobs` into `job-sets/interface.nix` lets us delete the aggregator and import only `./job-sets/interface.nix` from `module/default.nix`.

**Files:**
- Modify: `module/job-sets/interface.nix`
- Delete: `module/job-sets/default.nix`
- Modify: `module/default.nix`

- [ ] **Step 1: Update `module/job-sets/interface.nix` to absorb `options.jobs`**

Replace the entire content with:

```nix
{ config, lib, ci-lib, ... }:

let
  inherit (lib) types;

  needsType = types.submoduleWith {
    description = "Job set needs configuration";
    modules = [
      {
        options = {
          jobSet = lib.mkOption {
            type = types.str;
            description = "Name of the needed job set.";
          };
        };
      }
    ];
  };
in
{
  options = {
    jobSets = lib.mkOption {
      type = types.lazyAttrsOf (
        types.submoduleWith {
          description = "Job Set configuration";
          modules = [ ./job-set ];
          specialArgs.rootConfig = config;
        }
      );
      default = { };
      description = "Job Sets to group jobs.";
    };

    jobs = lib.mkOption {
      type = types.lazyAttrsOf (
        types.submoduleWith {
          modules = [ ./job-integration.nix ];
          specialArgs = {
            inherit ci-lib;
          };
        }
      );
    };
  };
}
```

- [ ] **Step 2: Delete `module/job-sets/default.nix`**

```bash
git rm module/job-sets/default.nix
```

- [ ] **Step 3: Update `module/default.nix` — change `./job-sets` to `./job-sets/interface.nix`**

In `module/default.nix`, change:
```nix
    ./job-sets
```
to:
```nix
    ./job-sets/interface.nix
```

Also add `ci-lib` to the `specialArgs` of the module, since `job-sets/interface.nix` now requires `ci-lib`. Check how `ci-lib` is currently available — it's set as `_module.args.ci-lib` in `module/default.nix`'s `config` block, which is available to all modules as a module argument. So no additional change is needed.

- [ ] **Step 4: Verify tests still pass**

```bash
git add -A
nix eval .#tests.first-ci-kit
```

- [ ] **Step 5: Commit**

```bash
git add module/job-sets/interface.nix module/default.nix
git commit -m "refactor: remove job-sets default.nix aggregator, merge options into interface"
```

---

## Task 5: Remove `pipelines/default.nix` aggregator

`pipelines/default.nix` is a pure import aggregator with no options or config of its own.

**Files:**
- Delete: `module/pipelines/default.nix`
- Modify: `module/default.nix`

- [ ] **Step 1: Delete `module/pipelines/default.nix`**

```bash
git rm module/pipelines/default.nix
```

- [ ] **Step 2: Update `module/default.nix` — replace `./pipelines` with explicit imports**

In `module/default.nix`, change:
```nix
    ./pipelines
```
to:
```nix
    ./pipelines/interface.nix
    ./pipelines/github-actions.nix
    ./pipelines/gitlab-ci.nix
```

- [ ] **Step 3: Verify tests still pass**

```bash
git add -A
nix eval .#tests.first-ci-kit
```

- [ ] **Step 4: Commit**

```bash
git add module/default.nix
git commit -m "refactor: remove pipelines default.nix aggregator, import files explicitly"
```

---

## Final check

After all tasks:

- [ ] Run full test suite: `nix eval .#tests.first-ci-kit`
- [ ] Run pre-commit hooks: `pre-commit run --all-files`
- [ ] Confirm file tree matches expected structure:

```
module/
  default.nix
  interface.nix          ← includes inlined input/output submodule types
  github-actions.nix
  gitlab-ci.nix
  process-compose.nix
  job-interfaces.nix     ← was job-interfaces/
  jobs/
    default.nix
    interface.nix
    github-actions.nix   ← was jobs/github-actions/default.nix
    job/
      default.nix
      interface.nix
      github-actions.nix
      gitlab-ci.nix
      process-compose.nix
  job-sets/
    interface.nix        ← merged from interface.nix + default.nix
    job-integration.nix
    job-set/
      default.nix
      interface.nix
  pipelines/
    interface.nix
    github-actions.nix
    gitlab-ci.nix
    pipeline/
      interface.nix
  lib/
  tests/
```
