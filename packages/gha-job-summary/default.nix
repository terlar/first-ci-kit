{
  writeShellApplication,
  gh,
  jq,
}:

writeShellApplication {
  name = "gha-job-summary";
  runtimeInputs = [
    gh
    jq
  ];
  text = builtins.readFile ./main.bash;
}
