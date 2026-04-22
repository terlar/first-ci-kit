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



## jobInterfaces



Job Interfaces to define jobs\.



*Type:*
lazy attribute set of function that evaluates to a(n) lazy attribute set of module



*Default:*
` { } `

*Declared by:*
 - [job-interfaces/interface\.nix](job-interfaces/interface.nix)



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



Additional GitHub Actions ` with: ` inputs that are NOT forwarded
to the GitLab CI include\. Use this for GHA-only inputs such as
` profile ` (Nix dev-shell selector) or a dynamic ` run_deploy `
expression\.



*Type:*
attribute set of string



*Default:*
` { } `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.pipelineCall\.github-actions\.passSecrets



Whether to pass ` secrets: inherit ` to the called reusable
workflow\. Set to ` false ` to opt out, e\.g\. when calling a
public or cross-org workflow that does not accept inherited
secrets\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.pipelineCall\.gitlab-ci\.extraInputs



Additional GitLab CI ` inputs: ` values that are NOT forwarded to
GitHub Actions\. Use this for GitLab CI-only inputs such as
` plan_needs ` (an array of upstream job names)\.



*Type:*
attribute set of (string or list of string)



*Default:*
` { } `

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



## jobs\.\<name>\.pipelineCall\.inputs



Input values forwarded to the called pipeline on both GitHub
Actions (` with: `) and GitLab CI (` inputs: `)\. Changes-detection
inputs (` changes `, ` changes_key `) are injected automatically on
GitHub Actions when the job has
` branches.default.changes.paths ` configured\.



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


