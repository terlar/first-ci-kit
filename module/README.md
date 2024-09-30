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
module



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



## jobs



Jobs to run in pipeline\.



*Type:*
lazy attribute set of (Job configuration)



*Default:*
` { } `

*Declared by:*
 - [jobs/interface\.nix](jobs/interface.nix)



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
  stages = ["validate" "test" "build" "deploy"];
  default.tags = ["gke-runner"];
}

```

*Declared by:*
 - [interface\.nix](interface.nix)


