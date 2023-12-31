# mkmr

[Make](https://www.gnu.org/software/make/) based command executor for simple monorepos.

## Install

In this example, we'll install into a `.mkmr` directory in the root if your current git repository.

```bash
MKMR_VERSION=0.0.6
MKMR_INSTALL_PATH=$(git rev-parse --show-toplevel)/.mkmr

# Download specific version and extract into destination.
mkdir -p "${MKMR_INSTALL_PATH}" && \
curl -sL "https://github.com/ahawker/mkmr/archive/refs/tags/v${MKMR_VERSION}.tar.gz" | \
  tar --strip-components=1 -xz -C "${MKMR_INSTALL_PATH}" "mkmr-${MKMR_VERSION}/Makefile"
```

## Updating

Once you have `mkmr` installed for your project, simply use `make mkmr-installer` to update
your local copy to the latest version.

## Usage

Once installed, you'll need to `include` it in your repository `Makefile`.

```makefile
# Makefile
export MKMR_INSTALL_PATH=$(shell git rev-parse --show-toplevel)/.mkmr/Makefile
include $(MKMR_INSTALL_PATH)

.PHONY: build
build: mkmr-package ; @ ## Build packages

.PHONY: changelog
changelog: ## Rebuild CHANGELOG.md
    @echo 'TODO'
```

```makefile
# packages/example/Makefile

ifdef MKMR_INSTALL_PATH
include $(MKMR_INSTALL_PATH)
endif

build:
    @docker build ...
```

## Examples

See [examples](examples) directory for a working example.

## License

[Apache 2.0](LICENSE)
