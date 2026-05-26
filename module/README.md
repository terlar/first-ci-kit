## autoEnvInputs

When true and inputs are declared, automatically inject each input as an
uppercased environment variable available to all jobs\.

GitHub Actions: adds ` env: ` at workflow level mapping e\.g\. SERVICE to
` ${{ inputs.service }} `\.

GitLab CI: adds ` variables: ` at pipeline level mapping e\.g\. SERVICE to
` $[[ inputs.service ]] `\.

Set to false to opt out and manage env/variables manually\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [interface\.nix](interface.nix)



## defaultJobFactory



Default factory name used for stacks that do not set ` jobFactory `\.
When both are null, an error is thrown at evaluation time\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "tofu-component" `

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## formatJobName



Function from a list of name parts to a job name string\. Used by the
stacks module when constructing job and jobSet names, and passed to
factory functions as ` formatJobName ` so factories can use the same
convention\.

Defaults to joining parts with underscores, e\.g\.
` ["app" "api" "dev"] ` → ` "app_api_dev" `\.



*Type:*
function that evaluates to a(n) string



*Default:*
` lib.concatStringsSep "_" `

*Declared by:*
 - [interface\.nix](interface.nix)



## github-actions\.changes\.enable



Whether to enable auto-injection of ` changes ` and ` changes_key ` string inputs into this
pipeline’s ` on.workflow_call.inputs `\. Enable this on pipelines that are
called via ` pipelineCall ` from a parent job that has change detection
(` branches.*.changes.paths `) configured, so that GitHub Actions accepts
the inputs the parent passes automatically\.
\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.changesFetchDepth



` fetch-depth ` passed to the checkout action in the auto-generated
` changes ` job\. Defaults to ` 0 ` (full history) because the change
detection script compares arbitrary commits and requires the full
git history to be available\.



*Type:*
signed integer



*Default:*
` 0 `



*Example:*
` 50 `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.checkoutAction



The default checkout action to use for jobs



*Type:*
string



*Default:*
` "actions/checkout@v6" `



*Example:*
` "actions/checkout@v5" `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.defaultBranch



The name of the default branch\. Used to resolve the special ` "default" `
branch key in ` job.branches ` when auto-populating
` on.push.branches ` and ` on.pull_request.branches `\.



*Type:*
string



*Default:*
` "main" `



*Example:*
` "master" `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.defaultRunsOn



The default runs-on to use for jobs



*Type:*
null or string or list of string



*Default:*
` null `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.downloadArtifactAction



The download-artifact action to use for artifact download steps



*Type:*
string



*Default:*
` "actions/download-artifact@v8" `



*Example:*
` "actions/download-artifact@v3" `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.forceRunAll\.enable



Whether to enable auto-injection of a ` force_run_all ` boolean input and a ` workflow_dispatch `
trigger into the generated workflow\. When the input is set to ` true ` at
runtime, change detection is skipped and all jobs are treated as affected\.
Enabled by default whenever the auto-generated ` changes ` job is present\.
\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.forceRunAll\.inputName



Name of the generated ` workflow_dispatch ` / ` workflow_call ` input\.



*Type:*
string



*Default:*
` "force_run_all" `



*Example:*
` "run_all" `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.settings



Configuration written for job to ` workflow.yml `\.



*Type:*
YAML value



*Default:*
` { } `



*Example:*

```
{
  name = "CI";
  on = [ "push" ];
  env.DAY_OF_WEEK = "Monday";
}

```

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.summaryJob\.enable



Whether to enable workflow summary job that runs last and links to all non-skipped jobs\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.summaryJob\.name



Key name for the generated summary job\.



*Type:*
string



*Default:*
` "summary" `



*Example:*
` "workflow-summary" `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.summaryJob\.runsOn



` runs-on ` for the summary job\. Falls back to
` github-actions.defaultRunsOn ` when ` null `\.



*Type:*
null or string or list of string



*Default:*
` null `



*Example:*
` "ubuntu-latest" `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.transformJobName



A function to transform job names



*Type:*
function that evaluates to a(n) string



*Default:*
` <function> `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## github-actions\.uploadArtifactAction



The upload-artifact action to use for artifact upload steps



*Type:*
string



*Default:*
` "actions/upload-artifact@v7" `



*Example:*
` "actions/upload-artifact@v3" `

*Declared by:*
 - [github-actions\.nix](github-actions.nix)



## gitlab-ci\.defaultStage



The default stage to use for jobs



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [gitlab-ci\.nix](gitlab-ci.nix)



## gitlab-ci\.inputs



Define inputs for the CI/CD configuration\.
This will be added as a separate YAML document at the top of the ` pipeline.yml `\.



*Type:*
YAML value



*Default:*
` { } `



*Example:*

```
{
  website = {};
  user.default = "test-user";
  flags.default = "";
}

```

*Declared by:*
 - [gitlab-ci\.nix](gitlab-ci.nix)



## gitlab-ci\.settings



Configuration written for job to ` pipeline.yml `\.



*Type:*
YAML value



*Default:*
` { } `



*Example:*

```
{
  image = "ubuntu";
  stages = [ "validate" "test" "build" "deploy" ];
  default.tags = [ "gke-runner" ];
}

```

*Declared by:*
 - [gitlab-ci\.nix](gitlab-ci.nix)



## gitlab-ci\.templatePath



Local path to the GitLab CI component template for this pipeline (e\.g\.
“gitlab-templates/profile-tofu/template\.yml”)\. When set, jobs that call
this pipeline via ` pipelineCall ` will emit an ` include: ` entry pointing
to this path\. Defaults to ` "${gitlab-ci.templatesPath}/${name}/template.yml" `
when the pipeline name is known (i\.e\. set via ` flake-module.nix `)\.



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [gitlab-ci\.nix](gitlab-ci.nix)



## gitlab-ci\.templatesPath



Base directory under which GitLab CI component templates are stored\.
Used as the prefix when deriving the default ` templatePath ` for each
pipeline: ` "${templatesPath}/${name}/template.yml" `\.



*Type:*
string



*Default:*
` "gitlab-templates" `

*Declared by:*
 - [gitlab-ci\.nix](gitlab-ci.nix)



## gitlab-ci\.transformJobName



A function to transform job names



*Type:*
function that evaluates to a(n) string



*Default:*
` <function> `

*Declared by:*
 - [gitlab-ci\.nix](gitlab-ci.nix)



## imageRegistry



Named map of container image references\. Jobs can reference entries
here (e\.g\. ` config.imageRegistry.tofu `) instead of hard-coding image
strings, making registry or version changes a single-point edit\.



*Type:*
lazy attribute set of string



*Default:*
` { } `



*Example:*

```
{
  tofu   = "registry.example.com/tofu:1.9";
  python = "registry.example.com/python:3.12";
}

```

*Declared by:*
 - [interface\.nix](interface.nix)



## inputs



Declared inputs for this pipeline\. Becomes ` on.workflow_call.inputs `
on GitHub Actions and ` spec.inputs ` on GitLab CI\.

When ` autoEnvInputs = true ` (the default), each input is also
injected as an uppercased environment variable available to all jobs\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `



*Example:*

```
{
  service   = { type = "string"; required = true; description = "Service name to deploy."; };
  dry-run   = { type = "boolean"; default = "false"; description = "Skip destructive steps."; };
  environment = {
    type = "choice";
    options = [ "dev" "stg" "prod" ];
    default = "dev";
  };
}

```

*Declared by:*
 - [interface\.nix](interface.nix)



## inputs\.\<name>\.default



Default value\. Must be a string (GitHub Actions requirement)\.



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [interface\.nix](interface.nix)



## inputs\.\<name>\.description



Human-readable description of this input\.



*Type:*
string



*Default:*
` "" `

*Declared by:*
 - [interface\.nix](interface.nix)



## inputs\.\<name>\.options



Valid choices\. Only meaningful when type = ‘choice’\.



*Type:*
list of string



*Default:*
` [ ] `

*Declared by:*
 - [interface\.nix](interface.nix)



## inputs\.\<name>\.required



Whether this input is required\.



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [interface\.nix](interface.nix)



## inputs\.\<name>\.type



Input type\.



*Type:*
one of “string”, “boolean”, “number”, “environment”, “choice”



*Default:*
` "string" `

*Declared by:*
 - [interface\.nix](interface.nix)



## jobFactories



Named job factories\. Each factory has a ` fn ` that produces pipeline
config from an argument attrset, and an ` applications ` list of argument
attrsets to apply\.

Factories are referenced by name from ` config.stacks.*.jobFactory ` or
` config.defaultJobFactory `\.



*Type:*
lazy attribute set of (submodule)



*Default:*
` { } `



*Example:*

```
{
  tofu-component.fn = { stack, component, deployment, formatJobName, needs, ... }:
    let jobName = formatJobName [ stack.name component.name deployment ]; in
    {
      jobs.${jobName} = {
        image = "registry.example.com/tofu:1.9";
        script = [ "tofu apply" ];
      };
      jobSets.${jobName}.jobs = [ jobName ];
    };
}

```

*Declared by:*
 - [job-factories/interface\.nix](job-factories/interface.nix)



## jobFactories\.\<name>\.applications



List of argument attrsets to apply to ` fn `\. Each entry calls
` fn <args> ` and merges the result into the pipeline config\.

Typically populated automatically by the stacks engine; set
manually only when using a factory without the stacks module\.



*Type:*
list of (attribute set)



*Default:*
` [ ] `



*Example:*

```
[
  { stack = "networking"; component = "vpc"; deployment = "prod"; needs = []; }
  { stack = "networking"; component = "dns"; deployment = "prod"; needs = []; }
]

```

*Declared by:*
 - [job-factories/interface\.nix](job-factories/interface.nix)



## jobFactories\.\<name>\.fn



Factory function that receives a context attrset and returns
pipeline-level config (typically ` { jobs = { … }; jobSets = { … }; } `)\.

When used via ` config.stacks `, the context contains:
` { stack, component, deployment, needs, formatJobName, factoryName } `\.
When used via ` applications `, the context is whatever attrset was
passed in that list entry\.



*Type:*
function that evaluates to a(n) (attribute set)



*Example:*

```
{ stack, component, deployment, needs, formatJobName, ... }:
let
  jobName = formatJobName [ stack.name component.name deployment ];
in
{
  jobs.${jobName} = {
    image = "registry.example.com/tofu:latest";
    needs = map (n: n.jobSet) needs;
    script = [ "tofu -chdir=stacks/${stack.name}/${component.name} apply" ];
  };
  jobSets.${jobName}.jobs = [ jobName ];
}

```

*Declared by:*
 - [job-factories/interface\.nix](job-factories/interface.nix)



## jobSets



Job Sets to group jobs\.



*Type:*
lazy attribute set of (Job Set configuration)



*Default:*
` { } `

*Declared by:*
 - [job-sets/interface\.nix](job-sets/interface.nix)



## jobSets\.\<name>\.jobDefaults



Configuration merged into every job listed in ` jobs `\. Use this to
apply shared settings (image, tags, environment variables, etc\.)
without repeating them on each job definition\.



*Type:*
lazy attribute set of raw value



*Default:*
` { } `



*Example:*

```
{
  image = "registry.example.com/tofu:1.9";
  tags = [ "linux" ];
}

```

*Declared by:*
 - [job-sets/job-set/interface\.nix](job-sets/job-set/interface.nix)



## jobSets\.\<name>\.jobs



Names of jobs that belong to this job set\. Duplicates are removed
automatically\. Jobs listed here receive the ` jobDefaults ` of this
set merged into their config\.



*Type:*
list of string



*Default:*
` [ ] `



*Example:*

```
[ "cluster_control-plane_prod" "cluster_node-pools_prod" ]

```

*Declared by:*
 - [job-sets/job-set/interface\.nix](job-sets/job-set/interface.nix)



## jobSets\.\<name>\.needs



Job sets that must complete successfully before any job in this job
set is allowed to run\. Translated to ` needs: ` (GitHub Actions) or
` needs: ` rules (GitLab CI) on each job in the set\.



*Type:*
list of (Job set needs configuration)



*Default:*
` [ ] `



*Example:*

```
[
  { jobSet = "networking_vpc_prod"; }
  { jobSet = "security_iam_prod"; }
]

```

*Declared by:*
 - [job-sets/job-set/interface\.nix](job-sets/job-set/interface.nix)



## jobSets\.\<name>\.needs\.\*\.jobSet



Name of the job set that must complete before this job set runs\.



*Type:*
string



*Example:*
` "networking_vpc_prod" `

*Declared by:*
 - [job-sets/job-set/interface\.nix](job-sets/job-set/interface.nix)



## jobSets\.\<name>\.tags



Arbitrary string labels associated with this job set\. Duplicates are
removed automatically\. Tags are used by backends to select or filter
job sets (e\.g\. GitLab runner tag matching)\.



*Type:*
list of string



*Default:*
` [ ] `



*Example:*
` [ "prod" "infra" ] `

*Declared by:*
 - [job-sets/job-set/interface\.nix](job-sets/job-set/interface.nix)



## jobs



Jobs to run in this pipeline\. Each attribute name becomes the job
identifier used in backend output (` jobs: ` in GitHub Actions,
job keys in GitLab CI)\.



*Type:*
lazy attribute set of (Job configuration)



*Default:*
` { } `



*Example:*

```
{
  build = {
    image = "nixos/nix:latest";
    script = [ "nix build" ];
    tags = [ "linux" ];
  };
  test = {
    image = "nixos/nix:latest";
    needs = [ "build" ];
    script = [ "nix flake check" ];
  };
}

```

*Declared by:*
 - [jobs/interface\.nix](jobs/interface.nix)
 - [job-sets](job-sets)



## jobs\.\<name>\.enable



Whether to enable Job\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.artifacts



Artifact configuration for this job\.



*Type:*
submodule



*Default:*
` { } `



*Example:*

```
{
  upload = { name = "build-output"; paths = [ "dist/" ]; };
  download = { name = "build-output"; };
}

```

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.artifacts\.download



Artifact to download before this job runs\.



*Type:*
null or (submodule)



*Default:*
` null `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.artifacts\.download\.name



Name of the artifact to download\.



*Type:*
string



*Example:*
` "build-output" `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.artifacts\.download\.path



Destination path for the downloaded artifact\. Defaults to the workspace root when null\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` ".ci/terraform" `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.artifacts\.upload



Artifact to upload after this job completes\.



*Type:*
null or (submodule)



*Default:*
` null `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.artifacts\.upload\.gitlab-ci



GitLab CI-specific artifact upload options\.



*Type:*
submodule



*Default:*
` { } `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.artifacts\.upload\.gitlab-ci\.expire_in



GitLab CI artifact expiry string\. Overrides retentionDays for GitLab CI when set\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "1 week" `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.artifacts\.upload\.gitlab-ci\.reports



GitLab CI report artifacts\.



*Type:*
null or (attribute set of string)



*Default:*
` null `



*Example:*
` { terraform = ".ci/terraform/plan-summary.json"; } `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.artifacts\.upload\.name



Artifact name\.



*Type:*
string



*Example:*
` "build-output" `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.artifacts\.upload\.paths



Paths to include in the artifact\.



*Type:*
list of string



*Default:*
` [ ] `



*Example:*
` [ "dist/" "result.log" ] `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.artifacts\.upload\.retentionDays



Artifact retention in days\. Used by both GitHub Actions and GitLab CI (as expire_in), unless overridden by gitlab-ci\.expire_in\.



*Type:*
null or signed integer



*Default:*
` null `



*Example:*
` 7 `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.branches



Branch configuration for job\.



*Type:*
attribute set of (Job branch configuration)



*Default:*
` { } `



*Example:*

```
{
  main.triggers.onPush = true;
  main.changes.paths = [ "src/" ];
}

```

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.branches\.\<name>\.changes\.paths



Paths affecting the job\.



*Type:*
list of string



*Default:*
` [ ] `



*Example:*
` [ "src/" "go.sum" ] `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.branches\.\<name>\.triggers\.onMergeRequest



Whether to enable trigger on merge request to branch\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.branches\.\<name>\.triggers\.onPush



Whether to enable trigger on push to branch\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.checkout



Whether to enable whether a git checkout should be made\.



*Type:*
boolean



*Default:*
` true `



*Example:*
` true `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.commands



Commands to be executed by the job\.



*Type:*
list of string



*Default:*
` [ ] `



*Example:*
` [ "make build" "make test" ] `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.env



Environment variables set for all backends\. Merged into GitHub Actions
job-level ` env: ` and GitLab CI ` variables: `\. Backend-specific settings
(` github-actions.env ` and ` gitlab-ci.variables `) take precedence\.



*Type:*
attribute set of string



*Default:*
` { } `



*Example:*

```
{
  LOG_LEVEL = "debug";
  CONFIG_FILE = "config.json";
}

```

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.fetchDepth



Number of commits to fetch during clone/checkout\. ` null ` omits the
setting, relying on the backend default (GitHub Actions: 1,
GitLab CI: project-level Git shallow clone setting, typically 20)\.
Set to ` 0 ` for a full clone with complete history\.



*Type:*
null or signed integer



*Default:*
` null `



*Example:*
` 0 `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.github-actions



GitHub Actions-specific job configuration\. Accepts any YAML-typed
field supported by GitHub Actions job syntax (e\.g\. ` runs-on `,
` environment `, ` concurrency `)\. Merged with the shared job settings;
backend-specific values take precedence over the shared equivalents\.

Set ` enable = false ` to exclude this job from GitHub Actions output
while keeping it active for other backends\.



*Type:*
YAML value



*Default:*
` { } `



*Example:*

```
{
  runs-on = "ubuntu-latest";
  environment = "production";
  concurrency = { group = "deploy-prod"; cancel-in-progress = false; };
}

```

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.github-actions\.enable



Whether the job is enabled for GitHub Actions\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.gitlab-ci



GitLab CI-specific job configuration\. Accepts any YAML-typed field
supported by GitLab CI job syntax (e\.g\. ` variables `, ` cache `,
` interruptible `, ` resource_group `)\. Merged with the shared job
settings; backend-specific values take precedence\.

Set ` enable = false ` to exclude this job from GitLab CI output while
keeping it active for other backends\.



*Type:*
YAML value



*Default:*
` { } `



*Example:*

```
{
  resource_group = "deploy-prod";
  interruptible = false;
  variables.TF_VAR_env = "prod";
}

```

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.gitlab-ci\.enable



Whether the job is enabled for GitLab CI\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.image



Image to use for job\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "ubuntu:24.04" `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.needs



Jobs needed by the job\.



*Type:*
list of (Needs configuration)



*Default:*
` [ ] `



*Example:*

```
[
  { job = "build"; }
  { jobSet = "integration"; optional = true; }
]

```

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.needs\.\*\.artifacts



Whether artifacts from dependency are used\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.needs\.\*\.job



Name of the needed job\.



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.needs\.\*\.jobSet



Name of the needed job set\.



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.needs\.\*\.optional



Whether need is optional\.



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.pipelineCall



Call a child pipeline instead of running commands directly\.
Generates a reusable workflow call (GitHub Actions) or a
` trigger:include: ` job (GitLab CI)\.

When set, ` commands ` and ` script ` on the job are ignored\.
The child pipeline must be declared separately (e\.g\. a pipeline
whose outputs are included via ` gitlab-templates/<name>/template.yml `)\.



*Type:*
null or (submodule)



*Default:*
` null `



*Example:*

```
{
  pipeline = "infra";
  inputs = { service = "api"; environment = "prod"; };
}

```

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.pipelineCall\.github-actions\.extraInputs



Additional GitHub Actions ` with: ` inputs that are NOT forwarded to
the GitLab CI include\. Use this for GHA-only inputs such as
` profile ` (Nix dev-shell selector) or a dynamic ` run_deploy `
expression\.



*Type:*
attribute set of string



*Default:*
` { } `

*Declared by:*
 - [jobs/job/pipeline-call\.nix](jobs/job/pipeline-call.nix)



## jobs\.\<name>\.pipelineCall\.github-actions\.passSecrets



Whether to pass ` secrets: inherit ` to the called reusable workflow\.
Set to ` false ` to opt out, e\.g\. when calling a public or cross-org
workflow that does not accept inherited secrets\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [jobs/job/pipeline-call\.nix](jobs/job/pipeline-call.nix)



## jobs\.\<name>\.pipelineCall\.gitlab-ci\.allRulesInput



When set to an input name, automatically computes all GitLab CI
rules (MR + push) from the job’s ` branches ` config and passes them
as that input to the child pipeline\. Unlike ` rulesInput `, this can
be set alongside ` rulesInput ` to populate a second input with the
same rule set\. The computed value is merged after ` extraInputs `\.



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [jobs/job/pipeline-call\.nix](jobs/job/pipeline-call.nix)



## jobs\.\<name>\.pipelineCall\.gitlab-ci\.extraInputs



Additional GitLab CI ` inputs: ` values that are NOT forwarded to
GitHub Actions\. Use this for GitLab CI-only inputs such as
` plan_needs ` (an array of job names or needs-entry objects with
` job `, ` artifacts `, and ` optional ` keys)\.



*Type:*
attribute set of (string or list of (string or (GitLab CI needs entry)))



*Default:*
` { } `

*Declared by:*
 - [jobs/job/pipeline-call\.nix](jobs/job/pipeline-call.nix)



## jobs\.\<name>\.pipelineCall\.gitlab-ci\.needsInputs



Maps GitLab CI input names to child job name suffixes\. For each
entry, automatically computes the child job names for all dependency
pipelineCall jobs and passes them as that input to the child
pipeline\. The computed values are merged after ` extraInputs `\.
Example: ` { "plan_needs" = "deploy"; } `



*Type:*
attribute set of string



*Default:*
` { } `

*Declared by:*
 - [jobs/job/pipeline-call\.nix](jobs/job/pipeline-call.nix)



## jobs\.\<name>\.pipelineCall\.gitlab-ci\.pushRulesInput



When set to an input name (e\.g\. ` "deploy_rules" `), automatically
computes push-only GitLab CI rules from the job’s ` branches ` config
and passes them as that input to the child pipeline\. The computed
value is merged after ` extraInputs `\.



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [jobs/job/pipeline-call\.nix](jobs/job/pipeline-call.nix)



## jobs\.\<name>\.pipelineCall\.gitlab-ci\.rulesInput



When set to an input name (e\.g\. ` "rules" `), automatically computes
all GitLab CI rules (MR + push) from the job’s ` branches ` config and
passes them as that input to the child pipeline\. The computed value
is merged after ` extraInputs `\.



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [jobs/job/pipeline-call\.nix](jobs/job/pipeline-call.nix)



## jobs\.\<name>\.pipelineCall\.gitlab-ci\.templatePath



Local path to the GitLab CI component template for the called
pipeline (e\.g\. “ci/gitlab-templates/profile-terraform/template\.yml”)\.
When set, takes precedence over looking up the path via
` config.pipelines.<pipeline>.gitlab-ci.templatePath `\.



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [jobs/job/pipeline-call\.nix](jobs/job/pipeline-call.nix)



## jobs\.\<name>\.pipelineCall\.gitlab-ci\.toChildJobName



Function from a child job name suffix (e\.g\. ` "deploy" `) to the full
child job name as it appears in the parent GitLab CI pipeline (e\.g\.
` "networking_vpc_dev_deploy" `)\. Used by dependent jobs’
` needsInputs ` to compute the actual job names to pass as inputs\.

The default (` lib.id `) is a neutral identity function\. Jobs
override this via ` lib.mkDefault ` to prefix the parent job key with
an underscore separator, e\.g\.
` childJobSuffix: "${name}_${childJobSuffix}" `\. Override
explicitly when a different separator is used, e\.g\.
` childJobSuffix: "${name}:${childJobSuffix}" ` when
` transformJobName ` uses colons\.



*Type:*
function that evaluates to a(n) string



*Default:*
` lib.id `

*Declared by:*
 - [jobs/job/pipeline-call\.nix](jobs/job/pipeline-call.nix)



## jobs\.\<name>\.pipelineCall\.inputs



Input values forwarded to the called pipeline on both GitHub Actions
(` with: `) and GitLab CI (` inputs: `)\. Changes-detection inputs
(` changes `, ` changes_key `) are injected automatically on GitHub
Actions when the job has ` branches.default.changes.paths ` configured\.



*Type:*
attribute set of string



*Default:*
` { } `

*Declared by:*
 - [jobs/job/pipeline-call\.nix](jobs/job/pipeline-call.nix)



## jobs\.\<name>\.pipelineCall\.pipeline



Name of a pipeline declared in ` config.pipelines ` to call\. On GitHub
Actions the job is rendered as a ` uses: ` reusable-workflow caller; on
GitLab CI the job is suppressed and an ` include: ` entry pointing to
the pipeline’s ` gitlab-ci.templatePath ` is emitted instead\.



*Type:*
string

*Declared by:*
 - [jobs/job/pipeline-call\.nix](jobs/job/pipeline-call.nix)



## jobs\.\<name>\.process-compose



process-compose-specific job configuration\. Accepts a deferred module
that is merged into the process-compose process definition for this job\.

Set ` enable = false ` to exclude this job from process-compose output
while keeping it active for other backends\.



*Type:*
module



*Default:*
` { } `



*Example:*

```
{
  availability.restart = "on_failure";
  environment = [ "DEBUG=1" ];
}

```

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.process-compose\.enable



Whether the job is enabled for process-compose\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.runAlways



Whether the job should run regardless of dependency failure\.
Equivalent to GitLab CI’s ` when: always `\.
On GitHub Actions, adds ` always() ` to the ` if ` condition and guards
required needs with ` (result == 'success' || result == 'failure') ` to
avoid running when dependencies were skipped or canceled (e\.g\. on pull requests)\.



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.tags



Tags associated with the job\.



*Type:*
list of string



*Default:*
` [ ] `



*Example:*
` [ "gke-runner" ] `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.triggers



Jobs triggering the job\.



*Type:*
list of string



*Default:*
` [ ] `



*Example:*
` [ "deploy" ] `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## outputs



Declared outputs for this pipeline\. Becomes ` on.workflow_call.outputs `
on GitHub Actions\. GitLab CI does not currently support pipeline-level
outputs\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `



*Example:*

```
{
  plan-summary.value = "${{ jobs.plan.outputs.summary }}";
}

```

*Declared by:*
 - [interface\.nix](interface.nix)



## outputs\.\<name>\.description



Human-readable description of this output\.



*Type:*
string



*Default:*
` "" `

*Declared by:*
 - [interface\.nix](interface.nix)



## outputs\.\<name>\.value



Expression referencing the job output\.
Example: “${{ jobs\.plan\.outputs\.plan }}”



*Type:*
string

*Declared by:*
 - [interface\.nix](interface.nix)



## process-compose\.cli



CLI configuration of process-compose to be passed to process-compose-flake cli\.



*Type:*
raw value



*Default:*
` { } `

*Declared by:*
 - [process-compose\.nix](process-compose.nix)



## process-compose\.settings



Configuration of process-compose to be passed to process-compose-flake settings\.



*Type:*
module



*Default:*
` { } `

*Declared by:*
 - [process-compose\.nix](process-compose.nix)



## stackDiscovery\.enable



Whether to enable filesystem-based stack discovery\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [stacks/discover\.nix](stacks/discover.nix)



## stackDiscovery\.component\.configFile



Filename within each component directory imported as a plain Nix
attrset of component options\. May set any component option: ` needs `,
` extraPaths `, ` jobFactory `, ` deployments `, etc\. Values from this file
are applied at normal priority — they win over filesystem-derived
defaults but lose to explicit hand-written config\.

When the file does not exist the component is discovered with
filesystem-derived defaults only\.



*Type:*
string



*Default:*
` "component.nix" `



*Example:*
` "component.nix" `

*Declared by:*
 - [stacks/discover\.nix](stacks/discover.nix)



## stackDiscovery\.deployments\.detection



How deployments are identified inside the scanned directory
(` deployments.subdirectory `, or the component directory when
` deployments.subdirectory ` is ` null `)\.

 - ` "directories" `: each subdirectory is a deployment; the directory
   name becomes the key\.
 - ` "files" `: each file whose name ends with ` deployments.extension `
   is a deployment; the extension is stripped to form the key\.



*Type:*
one of “files”, “directories”



*Default:*
` "directories" `



*Example:*
` "files" `

*Declared by:*
 - [stacks/discover\.nix](stacks/discover.nix)



## stackDiscovery\.deployments\.environmentFromName



Function mapping a discovered deployment directory/file name to the
logical ` environment ` value stored on that deployment\. Applied to
every deployment discovered by the filesystem scan\.

The default is the identity function (deployment key = environment)\.
Override this when your deployment naming convention encodes the
environment as a prefix or substring, e\.g\.:

```nix
environmentFromName = dep: lib.head (lib.splitString "_" dep);
```

This sets ` environment = "dev" ` for a deployment named ` dev_tooling `,
keeping the env-extraction convention in the consuming repository
rather than in the upstream library\.



*Type:*
function that evaluates to a(n) string



*Default:*
` <function> `



*Example:*
` dep: lib.head (lib.splitString "_" dep) `

*Declared by:*
 - [stacks/discover\.nix](stacks/discover.nix)



## stackDiscovery\.deployments\.extension



File extension used to identify deployment files when
` deployments.detection ` is ` "files" `\. The basename with this
extension stripped becomes the deployment key\.



*Type:*
string



*Default:*
` ".tfvars" `



*Example:*
` ".tfvars" `

*Declared by:*
 - [stacks/discover\.nix](stacks/discover.nix)



## stackDiscovery\.deployments\.subdirectory



Subdirectory inside each component that holds deployment entries\.
A component is recognised when this subdirectory exists\.

Set to ` null ` to scan the component directory itself\. In that case
a directory qualifies as a component when it contains at least one
entry matching ` deployments.detection ` (a file with
` deployments.extension `, or a subdirectory)\.



*Type:*
null or string



*Default:*
` "deployments" `



*Example:*
` null `

*Declared by:*
 - [stacks/discover\.nix](stacks/discover.nix)



## stackDiscovery\.excludeDirs



Subdirectory names to skip during stack-level scanning\. Only applies
when ` stackName ` is null\.



*Type:*
list of string



*Default:*

```
[
  "modules"
]
```



*Example:*
` [ "modules" "shared" ] `

*Declared by:*
 - [stacks/discover\.nix](stacks/discover.nix)



## stackDiscovery\.path



Root directory to scan\. When ` stackName ` is null (the default),
first-level subdirectories become stack names and second-level
subdirectories that qualify as components become component names\.
When ` stackName ` is set, ` path ` is treated as the stack directory
itself and first-level subdirectories become component names directly\.



*Type:*
absolute path



*Example:*
` ./terraform `

*Declared by:*
 - [stacks/discover\.nix](stacks/discover.nix)



## stackDiscovery\.stackName

When set, ` path ` is treated as a single stack with this name\.
First-level subdirectories of ` path ` become component names directly,
with no intermediate stack-level directory\.

When null (the default), first-level subdirectories of ` path ` are
treated as stack names\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "infra" `

*Declared by:*
 - [stacks/discover\.nix](stacks/discover.nix)



## stacks



Infrastructure stacks topology\. Each stack declares its deployment
environments and components\. The stack engine generates one factory
application per component × deployment combination and resolves
cross-component ` needs ` within each deployment\.



*Type:*
lazy attribute set of (submodule)



*Default:*
` { } `



*Example:*

```
{
  networking = {
    deployments = { dev = { }; prod = { }; };
    components = {
      vpc = { };
      dns.needs = [ { component = "vpc"; } ];
    };
  };
  cluster = {
    deployments = { dev = { }; prod = { }; };
    components = {
      control-plane.needs = [ { stack = "networking"; } ];
      node-pools.needs    = [ { component = "control-plane"; } ];
    };
  };
}

```

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.components



Components within this stack\. Each component generates one job per
deployment via the stack’s factory\.



*Type:*
lazy attribute set of (submodule)



*Default:*
` { } `



*Example:*

```
{
  vpc = { };
  dns.needs = [ { component = "vpc"; } ];
  cluster.needs = [ { component = "vpc"; } { component = "dns"; } ];
}

```

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.components\.\<name>\.deployments



Deployment environments for this component\. When set, overrides the
stack-level ` deployments ` for this component only\. When null
(the default), the component inherits the stack-level ` deployments `\.



*Type:*
null or (lazy attribute set of (attribute set))



*Default:*
` null `



*Example:*

```
{
  dev = { };
  stg = { };
  prod = { };
}

```

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.components\.\<name>\.deployments\.\<name>\.environment



Logical environment this deployment targets (e\.g\. “dev”, “prod”)\.
Passed to the factory as part of ` settings `\. Defaults to the
deployment name\. Set to null to indicate no environment association\.



*Type:*
null or string



*Default:*
` "‹name›" `



*Example:*
` "prod" `

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.components\.\<name>\.extraPaths



Additional glob paths to include in change detection for this
component, beyond what the job factory derives from
stack/component/deployment\. Passed to the factory as ` extraPaths `\.



*Type:*
list of string



*Default:*
` [ ] `



*Example:*
` [ "shared/modules/**" "config/common.yaml" ] `

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.components\.\<name>\.jobFactory



Name of a factory in ` config.jobFactories ` used for this component\.
When null, falls back to the stack’s ` jobFactory `, then to
` config.defaultJobFactory `\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "tofu-component" `

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.components\.\<name>\.needs



Dependencies on other components or stacks\. By default needs are
resolved within the same deployment as the declaring component\.

Use ` { component = "name"; } ` for a sibling component in the same stack,
` { stack = "name"; } ` for all components of another stack, or
` { stack = "name"; component = "name"; } ` for a specific component in
another stack\. Set ` deployment = "name" ` to pin to a specific deployment,
or ` matchDeployment = { environment = null; } ` to match all deployments
whose ` environment ` value equals the current deployment’s ` environment `\.



*Type:*
list of (submodule)



*Default:*
` [ ] `



*Example:*

```
[
  { component = "vpc"; }
  { stack = "security"; component = "iam"; }
  { component = "network"; matchDeployment.environment = null; }
]

```

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.components\.\<name>\.needs\.\*\.component



Component name of the dependency\. When null, depends on the
stack-level jobSet (all components of the target stack at
the same deployment)\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "vpc" `

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.components\.\<name>\.needs\.\*\.deployment



Explicit deployment name of the dependency\. When null and
` matchDeployment ` is also null, the target deployment is the
same name as the current deployment\. Ignored when
` matchDeployment ` is set\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "dev_tooling" `

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.components\.\<name>\.needs\.\*\.matchDeployment



When non-null, resolve to all deployments of the target
stack/component whose deployment settings match every
attribute in this set\. A ` null ` attribute value means
“match targets whose value for that attribute equals the
current deployment’s value”\. Produces zero jobSets when no
deployment matches\. When null (the default), the target
deployment is resolved by the ` deployment ` field (or the
current deployment name when ` deployment ` is also null)\.



*Type:*
null or (submodule)



*Default:*
` null `



*Example:*

```
{ environment = null; }   # same environment as current deployment

```

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.components\.\<name>\.needs\.\*\.matchDeployment\.environment



Match target deployments by ` environment ` value\.

 - ` null ` (default): match targets whose ` environment ` equals the
   current deployment’s ` environment `\.
 - A string: match targets whose ` environment ` equals this value\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "prod" `

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.components\.\<name>\.needs\.\*\.optional



When true and ` matchDeployment ` is null, silently skip this
dependency if the resolved target deployment does not exist in
the target component\. Useful when a component has a dep that
only exists for a subset of deployments\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.components\.\<name>\.needs\.\*\.stack



Stack name of the dependency\. When null, uses the current stack\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "networking" `

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.deployments



Deployment environments\. Attribute names are the deployment keys used
in job naming\. Values may set ` environment ` (logical target environment)
and any additional fields, which are passed to the job factory as
` deploymentConfig ` after module evaluation\.



*Type:*
lazy attribute set of (attribute set)



*Default:*
` { } `



*Example:*

```
{
  dev = { };
  stg = { };
  prod = { };
}

```

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.deployments\.\<name>\.environment



Logical environment this deployment targets (e\.g\. “dev”, “prod”)\.
Passed to the factory as part of ` settings `\. Defaults to the
deployment name\. Set to null to indicate no environment association\.



*Type:*
null or string



*Default:*
` "‹name›" `



*Example:*
` "prod" `

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)



## stacks\.\<name>\.jobFactory



Name of a factory in ` config.jobFactories ` used to generate jobs and
jobSets for each component × deployment combination in this stack\.
When null, falls back to ` config.defaultJobFactory `\.

The factory ` fn ` receives
` { stack, component, deployment, settings, needs, formatJobName, factoryName } `
and must return ` { jobs, jobSets } `\. ` settings ` contains all deployment
fields (including ` environment `) plus ` extraPaths ` from the component\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "tofu-component" `

*Declared by:*
 - [stacks/interface\.nix](stacks/interface.nix)


