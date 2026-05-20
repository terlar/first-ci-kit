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



## gitlab-ci\.transformJobName



A function to transform job names



*Type:*
function that evaluates to a(n) string



*Default:*
` <function> `

*Declared by:*
 - [gitlab-ci\.nix](gitlab-ci.nix)



## imageRegistry



Image registry with image names



*Type:*
lazy attribute set of string



*Default:*
` { } `

*Declared by:*
 - [interface\.nix](interface.nix)



## inputs



Declared inputs for this pipeline\.
Becomes on\.workflow_call\.inputs on GitHub Actions and spec\.inputs on GitLab CI\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `

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



Job factories that produce pipeline-level config\. Each factory has a
` fn ` that takes arguments and an ` applications ` list of argument
attrsets to apply\.



*Type:*
lazy attribute set of (submodule)



*Default:*
` { } `

*Declared by:*
 - [job-factories/interface\.nix](job-factories/interface.nix)



## jobFactories\.\<name>\.applications



List of argument attrsets to apply to ` fn `\. Each entry calls
` fn <args> ` and merges the result into the pipeline config\.



*Type:*
list of (attribute set)



*Default:*
` [ ] `

*Declared by:*
 - [job-factories/interface\.nix](job-factories/interface.nix)



## jobFactories\.\<name>\.fn



Factory function that takes arguments and returns an attrset of
config options (e\.g\. ` { jobs = {...}; jobSets = {...}; } `)\.



*Type:*
function that evaluates to a(n) (attribute set)

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



Configuration added to all the jobs within the job set\.



*Type:*
lazy attribute set of raw value



*Default:*
` { } `

*Declared by:*
 - [job-sets/job-set/interface\.nix](job-sets/job-set/interface.nix)



## jobSets\.\<name>\.jobs



List of job names associated with the job set



*Type:*
list of string



*Default:*
` [ ] `

*Declared by:*
 - [job-sets/job-set/interface\.nix](job-sets/job-set/interface.nix)



## jobSets\.\<name>\.needs



Job Sets needed by the Job Set\.



*Type:*
list of (Job set needs configuration)



*Default:*
` [ ] `

*Declared by:*
 - [job-sets/job-set/interface\.nix](job-sets/job-set/interface.nix)



## jobSets\.\<name>\.needs\.\*\.jobSet



Name of the needed job set\.



*Type:*
string

*Declared by:*
 - [job-sets/job-set/interface\.nix](job-sets/job-set/interface.nix)



## jobSets\.\<name>\.tags



List of tags associated with the job set



*Type:*
list of string



*Default:*
` [ ] `

*Declared by:*
 - [job-sets/job-set/interface\.nix](job-sets/job-set/interface.nix)



## jobs



Jobs to run in pipeline\.



*Type:*
lazy attribute set of (Job configuration)



*Default:*
` { } `

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



Job configuration targeting GitHub Actions\.



*Type:*
YAML value



*Default:*
` { } `

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



Job configuration targeting GitLab CI\.



*Type:*
YAML value



*Default:*
` { } `

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



Call a child pipeline (reusable workflow / template include) instead of running commands directly\.



*Type:*
null or (submodule)



*Default:*
` null `

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
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.pipelineCall\.github-actions\.passSecrets



Whether to pass ` secrets: inherit ` to the called reusable workflow\.
Set to ` false ` to opt out, e\.g\. when calling a public or cross-org
workflow that does not accept inherited secrets\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



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
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



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
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



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
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



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
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



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
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



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
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



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
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



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
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.pipelineCall\.pipeline



Name of a pipeline declared in ` config.pipelines ` to call\. On GitHub
Actions the job is rendered as a ` uses: ` reusable-workflow caller; on
GitLab CI the job is suppressed and an ` include: ` entry pointing to
the pipeline’s ` gitlab-ci.templatePath ` is emitted instead\.



*Type:*
string

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.pipelineCallProfile



Name of a profile declared in ` config.pipelineCallProfiles `\. When set,
populates ` pipelineCall ` from the named profile using ` lib.mkDefault `, so
any explicitly set ` pipelineCall ` options take precedence over the profile\.



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.process-compose



Job configuration targeting process-compose\.



*Type:*
module



*Default:*
` { } `

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



Declared outputs for this pipeline\.
Becomes on\.workflow_call\.outputs on GitHub Actions\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `

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


