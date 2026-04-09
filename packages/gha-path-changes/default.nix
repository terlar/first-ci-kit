{
  writeShellApplication,
  git,
  gnugrep,
  coreutils,
}:

writeShellApplication {
  name = "gha-path-changes";
  runtimeInputs = [
    git
    gnugrep
    coreutils
  ];
  text = builtins.readFile ./main.bash;
}
