{ lib, ... }:

{
  jobToNeed = job: {
    inherit job;
    artifacts = false;
    optional = true;
  };

  replaceVariables =
    variables:
    let
      from = lib.pipe variables [
        builtins.attrNames
        (map (x: "{${x}}"))
      ];
      to = builtins.attrValues variables;
    in
    map (builtins.replaceStrings from to);
}
