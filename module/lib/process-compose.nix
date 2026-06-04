{ lib }:

{
  # Build a depends_on attrset from a list of needs, filtered to enabled
  # process-compose jobs. The condition reflects optional/runAlways semantics.
  mkDependsOn =
    {
      jobs,
      needs,
      runAlways,
    }:
    lib.pipe needs [
      (lib.filter (need: jobs.${need.job}.enable && jobs.${need.job}.process-compose.enable))
      (map (
        need:
        lib.nameValuePair need.job {
          # Use process_completed (run regardless of dep outcome) when:
          # - the dep is optional (don't block on its failure), or
          # - this job should always run (equivalent to GitLab's when: always)
          condition =
            if need.optional || runAlways then "process_completed" else "process_completed_successfully";
        }
      ))
      lib.listToAttrs
    ];
}
