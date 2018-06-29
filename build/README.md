# Build SD2E-CLI

## Building `SD2E-CLI`
* [build](build.sh) Builds `sd2e-cli` (run from root level of this repo).

* [docker](docker.sh) Build, push, or delete a Docker container with `sd2e-cli`
  built into it.


## Utility Scripts to Build `SD2E-CLI`
* [config](config.sh) Create or delete the necessary files to build `sd2e-cli`.

* [customize](customize.sh) Package code from submodules along with `sd2e-cli`. 

* [submodules](submodules.sh) Update and get a given branch for any submodules
  included at the root level of this repo.

* [clear tags](cleartags.sh) Delete a git tag. Useful in case of an accidental
  tag while executing make.
  
## Testing a Build of `SD2E-CLI`
* [develop](develop.sh) Make a "develop" version of `sd2e-cli`.
