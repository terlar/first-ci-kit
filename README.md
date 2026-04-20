<p align="center">
  <img src="https://github.com/user-attachments/assets/e994e52a-bcea-4eb3-9ca8-ab25e73e7a59" />
</p>
<h1  align="center">first-ci-kit</h1>

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

- Strategy for how pipeline should be generated?
