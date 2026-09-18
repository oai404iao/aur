SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

PACKAGES := dingtalk-bin shardbrowser
BUILD_TARGETS := $(addprefix build-,$(PACKAGES))

.PHONY: help check srcinfo $(BUILD_TARGETS)

help:
	@printf '%s\n' \
		'make check                 Check syntax, metadata and launcher tests (offline)' \
		'make srcinfo               Regenerate .SRCINFO for both packages' \
		'make build-dingtalk-bin    Build DingTalk without installing it' \
		'make build-shardbrowser    Build ShardX Launcher without installing it'

check:
	@for package in $(PACKAGES); do \
		bash -n "$$package/PKGBUILD"; \
		(cd "$$package" && makepkg --printsrcinfo) | diff -u "$$package/.SRCINFO" -; \
	done
	@bash -n dingtalk-bin/dingtalk.sh shardbrowser/update-pkgbuild.sh shardbrowser/shardx-launcher-bin.install
	@desktop-file-validate dingtalk-bin/com.alibabainc.dingtalk.desktop
	@umask 077; \
		scratch_root="$$HOME/.local/state/agents/tmp"; \
		mkdir -p "$$scratch_root"; \
		task_dir=$$(mktemp -d "$$scratch_root/aur-check.XXXXXXXX"); \
		printf 'Test fixtures: %s\n' "$$task_dir"; \
		TMPDIR="$$task_dir" uv run --no-project python dingtalk-bin/tests/test-wrapper.py

srcinfo:
	@for package in $(PACKAGES); do \
		info=$$(cd "$$package" && makepkg --printsrcinfo); \
		printf '%s\n' "$$info" > "$$package/.SRCINFO"; \
	done

$(BUILD_TARGETS): build-%:
	cd "$*" && makepkg
