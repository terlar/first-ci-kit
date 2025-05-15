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



## jobs\.\<name>\.branches



Branch configuration for job\.



*Type:*
attribute set of (Job branch configuration)



*Default:*
` { } `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.branches\.\<name>\.changes\.paths



Paths affecting the job\.



*Type:*
list of string



*Default:*
` [ ] `

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



## jobs\.\<name>\.gitlab-ci



Job configuration targeting GitLab CI\.



*Type:*
YAML value



*Default:*
` { } `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.image



Image to use for job\.



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.needs



Jobs needed by the job\.



*Type:*
list of (Job needs configuration)



*Default:*
` [ ] `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.needs\.\*\.artifacts



Whether artifacts from dependency is used\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.needs\.\*\.job



Name of the needed job\.



*Type:*
string

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



## jobs\.\<name>\.tags



Tags associated with the job\.



*Type:*
list of string



*Default:*
` [ ] `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## jobs\.\<name>\.triggers



Jobs triggering the job\.



*Type:*
list of string



*Default:*
` [ ] `

*Declared by:*
 - [jobs/job/interface\.nix](jobs/job/interface.nix)



## pipeline\.github-actions\.defaultRunsOn



The default runs-on to use for jobs



*Type:*
null or string or list of string



*Default:*
` null `

*Declared by:*
 - [interface\.nix](interface.nix)



## pipeline\.github-actions\.settings



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



## pipeline\.github-actions\.transformJobName



A function to transform job names



*Type:*
function that evaluates to a(n) string



*Default:*
` <function> `

*Declared by:*
 - [interface\.nix](interface.nix)



## pipeline\.gitlab-ci\.defaultStage



The default stage to use for jobs



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [interface\.nix](interface.nix)



## pipeline\.gitlab-ci\.settings



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



## pipeline\.gitlab-ci\.transformJobName



A function to transform job names



*Type:*
function that evaluates to a(n) string



*Default:*
` <function> `

*Declared by:*
 - [interface\.nix](interface.nix)


