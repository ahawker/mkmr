# mkmr

[Make](https://www.gnu.org/software/make/) based command executor for simple monorepos.

## Install

In this example, we'll install into a `.mkmr` directory in the root if your current git repository.

```bash
MKMR_VER=0.0.1
MKMR_DST=$(git rev-parse --show-toplevel)/.mkmr

# Download specific version and extract into destination.
curl -sL "https://github.com/ahawker/mkmr/archive/refs/tags/v${MKMR_VER}.tar.gz" | \
    tar --strip-components=1 \
        -xz \
        -C "${MKMR_DST}" \
        'mkmr-${MKMR_VER}/Makefile'

# Confirm 'Makefile' is there.
ls -la "${MKMR_DST}/Makefile"
```

## Usage

Once installed, you'll need to `include` it in your repository `Makefile`.

```makefile
include $(shell git rev-parse --show-toplevel)/.mkmr/Makefile

.PHONY: build
build: mkmr-package ; @ ## Build packages

.PHONY: changelog
changelog: ## Rebuild CHANGELOG.md
    @echo 'TODO'
```

## Examples

See [examples](examples) directory for a working example.

## License

[Apache 2.0](LICENSE)
