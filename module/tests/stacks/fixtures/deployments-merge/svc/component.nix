{
  # Partial override: only "dev" is touched. Regression test for a bug where
  # setting any key of `deployments` in component.nix used to discard every
  # other filesystem-discovered deployment (here: "prod").
  deployments = {
    dev.branchDeploy = true;
  };
}
