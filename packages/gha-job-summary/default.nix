{
  writeShellApplication,
  curl,
  gawk,
}:

writeShellApplication {
  name = "gha-job-summary";
  runtimeInputs = [
    curl
    gawk
  ];
  text = builtins.readFile ./main.bash;
}
