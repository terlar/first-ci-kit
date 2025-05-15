# first-ci-kit

CI pipeline abstraction using the Nix module system. It introduces high-level pipeline concepts and building-blocks that can be used to generate pipelines for various CI systems. The thought is that you can provide abstractions/modules on top of this to get an interface that matches your use-case.

For example a concept of services and then a filesystem integration module can abstract things so you just have to create files in directories and the pipelines will be dynamically generated.

See [the module documentation](./module/README.md).

Generation targets:
- GitLab CI (Usable)
- GitHub Actions (WIP)
- process-compose (WIP)

## Concepts
- Job
  - Steps
  - Commands
  - Features
    - checkout
    - nix
    - nix cache
  - Image
  - Tags
- JobSet
  - Tags
- JobInterface

- Stacks
- Components
- Deployments

- Strategy
- Stages
