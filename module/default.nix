{ lib, config, ... }:

{
  imports = [
    ./interface.nix

    ./github-actions.nix
    ./gitlab-ci.nix
    ./process-compose.nix

    ./jobs
    ./job-factories
    ./job-sets
    ./pipelines
  ];

  config = {
    _module.args.ci-lib = import ./lib { inherit lib; };

    gitlab-ci.fileDocuments = lib.mkMerge [
      (lib.mkIf (config.gitlab-ci.inputs != { }) [
        { spec = { inherit (config.gitlab-ci) inputs; }; }
      ])
      [ config.gitlab-ci.settings ]
    ];
  };
}
