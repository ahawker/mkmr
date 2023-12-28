#!/usr/bin/env make

export MKMR_DEPENDENCIES = base
include $(shell git rev-parse --show-toplevel)/.mkmr/Makefile

clean:
	@sleep 1
	@echo "Cleaned package=$(shell basename $$(pwd))"
