## github-actions\.checkoutAction

The default checkout action to use for jobs



*Type:*
string



*Default:*
` "actions/checkout@v6" `



*Example:*
` "actions/checkout@v5" `

*Declared by:*
 - [interface\.nix](interface.nix)



## github-actions\.defaultRunsOn



The default runs-on to use for jobs



*Type:*
null or string or list of string



*Default:*
` null `

*Declared by:*
 - [interface\.nix](interface.nix)



## github-actions\.downloadArtifactAction



The download-artifact action to use for artifact download steps



*Type:*
string



*Default:*
` "actions/download-artifact@v8" `



*Example:*
` "actions/download-artifact@v3" `

*Declared by:*
 - [interface\.nix](interface.nix)



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
 - [interface\.nix](interface.nix)



## github-actions\.transformJobName



A function to transform job names



*Type:*
function that evaluates to a(n) string



*Default:*
` <function> `

*Declared by:*
 - [interface\.nix](interface.nix)



## github-actions\.uploadArtifactAction



The upload-artifact action to use for artifact upload steps



*Type:*
string



*Default:*
` "actions/upload-artifact@v7" `



*Example:*
` "actions/upload-artifact@v3" `

*Declared by:*
 - [interface\.nix](interface.nix)



## gitlab-ci\.defaultStage



The default stage to use for jobs



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [interface\.nix](interface.nix)



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
 - [interface\.nix](interface.nix)



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
 - [interface\.nix](interface.nix)



## gitlab-ci\.transformJobName



A function to transform job names



*Type:*
function that evaluates to a(n) string



*Default:*
` <function> `

*Declared by:*
 - [interface\.nix](interface.nix)



## imageRegistry



Image registry with image names



*Type:*
lazy attribute set of string



*Default:*
` { } `

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



## process-compose\.cli



CLI configuration of process-compose to be passed to process-compose-flake cli\.



*Type:*
raw value



*Default:*
` { } `

*Declared by:*
 - [interface\.nix](interface.nix)



## process-compose\.settings



Configuration of process-compose to be passed to process-compose-flake settings\.



*Type:*
module



*Default:*
` { } `

*Declared by:*
 - [interface\.nix](interface.nix)


