#!/usr/bin/env make
#
# Make based command executor for simple monorepos.
#
# License: https://github.com/ahawker/mkmr/blob/main/LICENSE
# Source: https://github.com/ahawker/mkmr
# Issues: https://github.com/ahawker/mkmr/issues
.SUFFIXES:
.DEFAULT_GOAL ?= help

# Binaries.
AWK      ?= awk
BASENAME ?= basename
CURL     ?= curl
DIRNAME  ?= dirname
ECHO     ?= echo
ENV      ?= env
FIND     ?= find
GREP     ?= grep
HEAD     ?= head
MKDIR    ?= mkdir
PRINTF   ?= printf
PWD_     ?= pwd
REALPATH ?= realpath
SED      ?= sed
SHELL    ?= $(SHELL)
SORT     ?= sort
TAR      ?= tar
XARGS    ?= xargs

# References to 'make' state.
MKMR_DEFAULT_GOAL = $(.DEFAULT_GOAL)
MKMR_GOALS        = $(MAKECMDGOALS)
MKMR_LEVEL        = $(MAKELEVEL)
MKMR_MAKEFILES    = $(MAKEFILE_LIST)

# "Constants" but available for customization in rare cases.
export MKMR_INSTALL_PATH      ?= $(shell git rev-parse --show-toplevel)/.mkmr
export MKMR_VERSION           ?= 0.0.6
MKMR_PREFIX                   ?= mkmr
MKMR_MAKE_FILE                ?= Makefile
MKMR_VARS_FILE                ?= Makefile.vars
MKMR_PACKAGES_DIR             ?= packages
MKMR_DEFAULT_TARGET_NAME      ?= standard
MKMR_PACKAGE_TARGET_NAME      ?= $(MKMR_PREFIX)-package
MKMR_PROXY_TARGET_NAME        ?= $(MKMR_PREFIX)-proxy
MKMR_CHILD_TARGET_NAME        ?= $(MKMR_PREFIX)-child
MKMR_DEPENDENCIES_TARGET_NAME ?= $(MKMR_PREFIX)-dependencies
MKMR_TARGET_REGEX             ?= '^[%a-zA-Z0-9/_-]+:'
MKMR_HELP_REGEX               ?= '$(MKMR_TARGET_REGEX).*?\#\# .*$$'
MKMR_HELP_AWK_FS              ?= ":.*?\#\# "

# Load user-defined variables/customizations.
ifneq ($(strip $(wildcard $(MKMR_VARS_FILE))),)
ifeq ($(filter $(MKMR_DEFAULT_GOAL),$(MKMR_GOALS)),)
$(info ==> [$(MKMR_PREFIX)] Include path=$(shell $(REALPATH) $(MKMR_VARS_FILE)))
endif
include $(MKMR_VARS_FILE)
export $(shell $(GREP) -v '^\#' $(MKMR_VARS_FILE) | $(SED) 's/[?: ]=.*//')
endif

# References for tracking 'root' state (initial location of invocation).
export MKMR_ROOT_PATH             ?= $(shell $(PWD_))
export MKMR_ROOT_MAKE             ?= $(shell $(REALPATH) $(firstword $(MAKEFILE_LIST)))
export MKMR_ROOT_NAME             ?= $(shell $(BASENAME) $(MKMR_ROOT_PATH))
export MKMR_ROOT_CHILDREN_PATH    ?= $(MKMR_ROOT_PATH)/$(MKMR_PACKAGES_DIR)
export MKMR_ROOT_STANDARD_TARGETS ?= $(shell $(GREP) -E $(MKMR_TARGET_REGEX) $(MKMR_ROOT_MAKE) | $(GREP) -vE "$(MKMR_PREFIX)" | $(AWK) 'BEGIN {FS = $(MKMR_HELP_AWK_FS)}; {$(PRINTF) "%s\n", $$1}')
export MKMR_ROOT_MKMR_TARGETS     ?= $(shell $(GREP) -E $(MKMR_TARGET_REGEX) $(MKMR_ROOT_MAKE) | $(GREP) -E "$(MKMR_PREFIX)" | $(AWK) 'BEGIN {FS = $(MKMR_HELP_AWK_FS)}; {$(PRINTF) "%s\n", $$1}')
export MKMR_ROOT_PACKAGES         ?= $(sort $(shell $(FIND) $(MKMR_ROOT_CHILDREN_PATH) -type f -depth 2 -name $(MKMR_MAKE_FILE) -exec $(SHELL) -c "$(DIRNAME) {} | $(XARGS) $(BASENAME)" \; 2>/dev/null))

# User parameters.
MKMR_PACKAGE      ?=
MKMR_PACKAGES     ?= $(MKMR_ROOT_PACKAGES)
MKMR_DEPENDENCIES ?=
unexport MKMR_PACKAGE
unexport MKMR_PACKAGES
unexport MKMR_DEPENDENCIES

# References for tracking 'current' and 'child' state based on execution context (package, dependency, etc).
MKMR_CURRENT_MAKE := $(shell $(REALPATH) $(firstword $(MAKEFILE_LIST)))
MKMR_CURRENT_PATH := $(shell $(DIRNAME) $(MKMR_CURRENT_MAKE))
ifeq ($(MKMR_LEVEL),0) # Root Makefile
MKMR_CURRENT_NAME             = $(MKMR_ROOT_NAME)
MKMR_CURRENT_STANDARD_TARGETS = $(MKMR_ROOT_STANDARD_TARGETS)
MKMR_CURRENT_MKMR_TARGETS     = $(MKMR_ROOT_MKMR_TARGETS)
MKMR_CHILDREN_DIR             = $(MKMR_PACKAGES_DIR)
MKMR_CHILDREN_PATH            = $(MKMR_CURRENT_PATH)/$(MKMR_CHILDREN_DIR)
MKMR_CHILDREN                 = $(MKMR_ROOT_PACKAGES)
else # Package/child Makefile
MKMR_CURRENT_NAME             = $(patsubst $(MKMR_ROOT_PATH)/$(MKMR_PACKAGES_DIR)/%,%,$(MKMR_CURRENT_PATH))
MKMR_CURRENT_STANDARD_TARGETS = $(shell $(GREP) -E $(MKMR_TARGET_REGEX) $(MKMR_CURRENT_MAKE) | $(GREP) -vE "$(MKMR_PREFIX)" | $(AWK) 'BEGIN {FS = $(MKMR_HELP_AWK_FS)}; {$(PRINTF) "%s\n", $$1}')
MKMR_CURRENT_MKMR_TARGETS     = $(shell $(GREP) -E $(MKMR_TARGET_REGEX) $(MKMR_CURRENT_MAKE) | $(GREP) -E "$(MKMR_PREFIX)" | $(AWK) 'BEGIN {FS = $(MKMR_HELP_AWK_FS)}; {$(PRINTF) "%s\n", $$1}')
MKMR_CHILDREN_DIR             =
MKMR_CHILDREN_PATH            = $(MKMR_CURRENT_PATH)
MKMR_CHILDREN                 = $(sort $(patsubst $(MKMR_CHILDREN_PATH)/%,%,$(shell $(FIND) $(MKMR_CHILDREN_PATH) -type f -mindepth 2 -name $(MKMR_MAKE_FILE) -exec $(SHELL) -c "$(DIRNAME) {}" \; 2>/dev/null)))
endif
MKMR_CURRENT_MISSING_TARGETS  = $(filter-out $(MKMR_CURRENT_STANDARD_TARGETS) $(MKMR_CURRENT_MKMR_TARGETS) $(MKMR_DEFAULT_GOAL),$(MKMR_GOALS))

# Dynamically create targets for each known package of the current context. These
# will be used for root packages and calling necessary cross-package dependencies.
#
# Example:
#
# .PHONY: mkmr-package-shared
# mkmr-package-shared:
#	make -c <root>/packages/shared <goals>
#
define MKMR_TMPL_PACKAGE
.PHONY: $(MKMR_PREFIX)-package-$(1)
$(MKMR_PREFIX)-package-$(1):
ifdef MKMR_TRACE
	@$(ECHO) "==> [$(MKMR_PREFIX)] Traverse goals=$(MKMR_GOALS) current=$(MKMR_CURRENT_NAME) next=$(1)"
endif
	@$(MAKE) -C $(MKMR_ROOT_CHILDREN_PATH)/$(1) $(MKMR_GOALS)
endef

# Dynamically create targets for each known child Makefile of the current context that
# forward calls that file with the prefix removed.
#
# Example:
#
# .PHONY: mkmr-child-deploy/docker
# mkmr-child-deploy/docker:
#	make -c <root>/deploy/docker build
#
define MKMR_TMPL_CHILD
.PHONY: $(MKMR_PREFIX)-child-$(1)
$(MKMR_PREFIX)-child-$(1):
ifdef MKMR_TRACE
	@$(ECHO) "==> [$(MKMR_PREFIX)] Traverse goals=$(patsubst $(1)/%,%,$(MKMR_GOALS)) current=$(MKMR_CURRENT_NAME) next=$(1)"
endif
	@$(MAKE) -C $(MKMR_CHILDREN_PATH)/$(1) $(patsubst $(1)/%,%,$(MKMR_GOALS))
endef

# Dynamically create no-op targets for all necessary values.
# This allows make to "silently" resolve the targets w/o warnings and users may define
# the targets with an "opt-in" strategy.
#
# Example:
#
# .PHONY: mkmr-default-clean
# mkmr-default-clean:
#	@true
#
# .PHONY: clean
# clean: mkmr-proxy mkmr-default-clean
#
#
# @1 - Name of target
# @2 - Name of prerequisite
define MKMR_TMPL_DYNAMIC_TARGET
.PHONY: $(MKMR_PREFIX)-default-$(1)
$(MKMR_PREFIX)-default-$(1):
ifdef MKMR_TRACE
	@$(ECHO) "==> [$(MKMR_PREFIX)] Execute goal=$(1) current=$(MKMR_CURRENT_NAME)"
endif
	@true

ifdef MKMR_TRACE
$(info ==> [$(MKMR_PREFIX)] Create dynamic target "$(1): $(2) $(MKMR_PREFIX)-default-$(1)")
endif

.PHONY: $(1)
$(1): $(2) $(MKMR_PREFIX)-default-$(1)
endef

# Create all dynamic targets.
ifeq ($(MKMR_LEVEL),0) # Root Makefile
$(foreach package,$(MKMR_PACKAGES),$(eval $(call MKMR_TMPL_PACKAGE,$(package))))
$(foreach target,$(MKMR_CURRENT_MISSING_TARGETS),$(eval $(call MKMR_TMPL_DYNAMIC_TARGET,$(target),$(MKMR_PACKAGE_TARGET_NAME))))
else # Package/child Makefile
$(foreach package,$(MKMR_PACKAGES),$(eval $(call MKMR_TMPL_PACKAGE,$(package))))
$(foreach child,$(MKMR_CHILDREN),$(eval $(call MKMR_TMPL_CHILD,$(child))))
$(foreach target,$(MKMR_CURRENT_MISSING_TARGETS),$(eval $(call MKMR_TMPL_DYNAMIC_TARGET,$(target),$(MKMR_PROXY_TARGET_NAME))))
endif

# 'mkmr-child' target added to user-defined targets as prerequisite to identify them as
# targets that should forward the call to another Makefile located within the package.
#
# This is commonly used with '/' prefixed targets, e.g.
# `build/container/build -> make -C (package root)/build/container/Makefile build`
#
# Example:
#
# .PHONY: build/container/%
# build/container/%: mkmr-child ## Run container commands.
#
$(MKMR_CHILD_TARGET_NAME): $(MKMR_CHILDREN:%=$(MKMR_PREFIX)-child-%)

# 'mkmr-dependencies' target added to user-defined targets as prerequisite to identify them as
# targets that should call all dependencies prior to executing the target.
#
# This is commonly used for "building dependencies" prior to your own.
#
# Example:
#
# .PHONY: build
# build: mkmr-dependencies ## Build project.
#
.PHONY: $(MKMR_DEPENDENCIES_TARGET_NAME)
$(MKMR_DEPENDENCIES_TARGET_NAME): $(MKMR_DEPENDENCIES:%=$(MKMR_PREFIX)-package-%)

# 'mkmr-proxy' target added to user-defined targets as prerequisite to identify them as
# targets that should call all dependencies and forward the call to a child.
#
# This is just a helper for common pattern of combining 'mkmr-dependencies' and 'mkmr-child'.
#
# Example:
#
# .PHONY: test/%
# test/%: mkmr-proxy ## Run test commands.
#
.PHONY: $(MKMR_PROXY_TARGET_NAME)
$(MKMR_PROXY_TARGET_NAME): $(MKMR_DEPENDENCIES_TARGET_NAME) $(MKMR_CHILD_TARGET_NAME)

# 'mkmr-package' target added to user-defined targets as prerequisite to identify them as
# targets that should be defined/applied within all packages in the repository.
#
# This should only be used on the 'root' Makefile entrypoint for the repository.
#
# If you wish to cross-call another package from your own, you'll want to use
# the 'dependencies' functionality.
#
# Example:
#
# .PHONY: build
# build: mkmr-package ## Build package.
#
ifdef MKMR_PACKAGE
.PHONY: $(MKMR_PACKAGE_TARGET_NAME)
$(MKMR_PACKAGE_TARGET_NAME): $(MKMR_PREFIX)-package-$(MKMR_PACKAGE)
else
.PHONY: $(MKMR_PACKAGE_TARGET_NAME)
$(MKMR_PACKAGE_TARGET_NAME): $(MKMR_PACKAGES:%=$(MKMR_PREFIX)-package-%)
endif

.PHONY: help
help: ## Show help/usage.
	@$(GREP) -E $(MKMR_HELP_REGEX) $(MKMR_CURRENT_MAKE) | $(SORT) -u | $(GREP) -Ev "$(MKMR_PACKAGE_TARGET_NAME)" | $(AWK) 'BEGIN {FS = $(MKMR_HELP_AWK_FS)}; {$(PRINTF) "\033[36m%-40s\033[0m $(MKMR_DEFAULT_TARGET_NAME)     | %s\n", $$1, $$2}'
	@$(GREP) -E $(MKMR_HELP_REGEX) $(MKMR_CURRENT_MAKE) | $(SORT) -u | $(GREP) -E  "$(MKMR_PACKAGE_TARGET_NAME)" | $(AWK) 'BEGIN {FS = $(MKMR_HELP_AWK_FS)}; {$(PRINTF) "\033[36m%-40s\033[0m $(MKMR_PACKAGE_TARGET_NAME) | %s\n", $$1, $$2}'

.PHONY: $(MKMR_PREFIX)-installer
$(MKMR_PREFIX)-installer: ## Install/update 'mkmr'.
	$(MKDIR) -p "${MKMR_INSTALL_PATH}" && \
	$(CURL) -sL "https://github.com/ahawker/mkmr/archive/refs/tags/v${MKMR_VERSION}.tar.gz" | \
		$(TAR) --strip-components=1 -xz -C "${MKMR_INSTALL_PATH}" "mkmr-${MKMR_VERSION}/Makefile"

# Set MKMR_DEBUG=1 to view all the helpful variables/context.
ifdef MKMR_DEBUG
$(foreach v, $(sort $(filter-out MKMR_TMPL_%,$(filter MKMR_%,$(.VARIABLES)))), $(info [$(MKMR_PREFIX)] $(v) = $($(v))))
endif
