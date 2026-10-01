# Turbo Vision for Cosmopolitan Libc — self-contained Makefile
#
# Lives in <project>/tv/, sources in <project>/tv/tvision/.
# ncurses is expected at <project>/ncurses/ and built on demand.
# Written with the assistance of Yuanbao (元宝), an AI assistant by Tencent.
#
#   make check            # environment self-test (run this first)
#   make                  # build x86_64 + aarch64 -> $(COSMOS_ROOT)/<arch>
#   make ARCHS=x86_64     # single arch
#   make WITH_EXAMPLES=1  # also build tvdemo/tvedit/tvhc
#   make SKIP_PATCH=1     # build the sources unmodified
#   make clean distclean
#
# minimal.diff works around Cosmopolitan's SysV constants: the ones whose value
# differs between host operating systems (SIGBUS, SIGTSTP, SA_*, ...) are
# objects in .piro.bss filled in at startup, not macros, so tvision's
# constexpr/switch/case uses of them do not compile. See the patch itself.
#
# minimal.diff also guards hotKeyStr() against empty strings: Cosmopolitan(4.0.2)'s
# memchr() loads an aligned vector from (uintptr_t)s & -16 before looking at
# 'n', so memchr(NULL, c, 0) — which menu separators reach via
# TMenuView::findItem — traps with SIGSEGV instead of returning NULL.
#
# That hunk touches source/tvision/tinputli.cpp, which is CRLF upstream. GNU
# patch reports "different line endings" and skips the hunk unless the patch
# and the file agree, and no single flag matches both ways, so the file is
# normalized to LF first and the patch is kept all-LF. See the patch rule.
#
# C++ needs CC_MODE=wrap: cosmocross adds -isystem .../include/third_party/libcxx
# and -lcxx for -*c++ invocations. raw mode would have to replicate both by hand.
#
# The shadow toolchain is created by <project>/ncurses/Makefile — same rule,
# different WRAP_ROOT, so both projects share one tree and cosmocc/ stays read-only.

SHELL := /bin/bash

CURDIR       := $(shell pwd)
PROJ_ROOT    := $(shell cd .. && pwd)
COSMOCC_ROOT := $(PROJ_ROOT)/cosmocc
COSMOCC_BIN  := $(COSMOCC_ROOT)/bin

CC_MODE ?= wrap

export COSMOPOLITAN_DISABLE_ZIPOS=1
export COSMOS

# ---- layout ---------------------------------------------------------------
NCURSES_DIR ?= $(PROJ_ROOT)/ncurses
# one sysroot for everything: tvision lands next to ncurses
# must agree with ncurses' OUT_ROOT
COSMOS_ROOT ?= $(PROJ_ROOT)/out

SRC_DIR    ?= $(CURDIR)/tvision
BUILD_ROOT := $(CURDIR)/build
PATCH      := $(CURDIR)/minimal.diff

# must agree with the WRAP_ROOT used when ncurses builds the shadow
WRAP_ROOT ?= $(PROJ_ROOT)/build/cosmocc-shadow
WRAP_DIR  := $(WRAP_ROOT)/bin

PATH := $(WRAP_DIR):$(COSMOCC_BIN):$(PATH)
export PATH

ARCHS   ?= x86_64 aarch64
MAXPROC ?= $(shell nproc 2>/dev/null || echo 1)
WITH_EXAMPLES ?= 1

# convenience links: <project>/build/<arch>/{lib,include/...} -> the sysroot
# Install locations are unchanged; this only adds shortcuts at the root.
LINK_ROOT ?= $(PROJ_ROOT)/build

# ---- toolchain: cc/c++ only exist as <arch>-unknown-cosmo-*,
#      binutils only as <arch>-linux-cosmo-* ---------------------------------
ifeq ($(CC_MODE),raw)
CC_X86_64   := $(COSMOCC_BIN)/x86_64-linux-cosmo-gcc
CXX_X86_64  := $(COSMOCC_BIN)/x86_64-linux-cosmo-g++
CC_AARCH64  := $(COSMOCC_BIN)/aarch64-linux-cosmo-gcc
CXX_AARCH64 := $(COSMOCC_BIN)/aarch64-linux-cosmo-g++
else
CC_X86_64   := $(WRAP_DIR)/x86_64-unknown-cosmo-cc
CXX_X86_64  := $(WRAP_DIR)/x86_64-unknown-cosmo-c++
CC_AARCH64  := $(WRAP_DIR)/aarch64-unknown-cosmo-cc
CXX_AARCH64 := $(WRAP_DIR)/aarch64-unknown-cosmo-c++
endif

LD_X86_64      := $(COSMOCC_BIN)/x86_64-linux-cosmo-ld
AR_X86_64      := $(COSMOCC_BIN)/x86_64-linux-cosmo-ar
RANLIB_X86_64  := $(COSMOCC_BIN)/x86_64-linux-cosmo-ranlib
STRIP_X86_64   := $(COSMOCC_BIN)/x86_64-linux-cosmo-strip
LD_AARCH64     := $(COSMOCC_BIN)/aarch64-linux-cosmo-ld
AR_AARCH64     := $(COSMOCC_BIN)/aarch64-linux-cosmo-ar
RANLIB_AARCH64 := $(COSMOCC_BIN)/aarch64-linux-cosmo-ranlib
STRIP_AARCH64  := $(COSMOCC_BIN)/aarch64-linux-cosmo-strip

export CC_X86_64 CXX_X86_64 LD_X86_64 AR_X86_64 RANLIB_X86_64 STRIP_X86_64
export CC_AARCH64 CXX_AARCH64 LD_AARCH64 AR_AARCH64 RANLIB_AARCH64 STRIP_AARCH64

# ---- cmake args -----------------------------------------------------------
# Install into the shared sysroot. CMAKE_INSTALL_LIBDIR=lib because
# GNUInstallDirs may otherwise pick lib64 (Fedora) and break the link path.
ifeq ($(WITH_EXAMPLES),1)
EXAMPLES_FLAG := -DTV_BUILD_EXAMPLES=ON
else
EXAMPLES_FLAG := -DTV_BUILD_EXAMPLES=OFF
endif

# $(1)=arch lowercase  $(2)=arch uppercase suffix
define CMAKE_ARGS
-G "Unix Makefiles" \
-DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/toolchain-cosmo.cmake \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INSTALL_PREFIX=$$(COSMOS.$(1)) \
-DCMAKE_PREFIX_PATH=$$(COSMOS.$(1)) \
-DCMAKE_INSTALL_LIBDIR=lib \
-DTV_BUILD_USING_GPM=OFF \
-DTV_BUILD_TESTS=OFF \
-DTV_OPTIMIZE_BUILD=OFF \
$(EXAMPLES_FLAG) \
-DCMAKE_CXX_FLAGS="-Os"
endef

.DEFAULT_GOAL := all

.PHONY: all check patch wrappers wrappers-clean configure configure-x86_64 configure-aarch64 \
        build build-x86_64 build-aarch64 \
        install install-x86_64 install-aarch64 \
        links links-clean clean distclean

all: build install links

# ===========================================================================
#  shadow toolchain + ncurses, both delegated to the ncurses makefile
# ===========================================================================
WRAP_STAMP := $(WRAP_ROOT)/.stamp

# cosmocross shells out to <arch>-linux-cosmo-gcc / -g++ next to itself, so
# those must resolve inside the shadow. Its stamp only tracks cosmocross, so a
# shadow whose symlinks dangle (project copied or moved, toolchain replaced by
# whatever manages cosmocc/) would otherwise be reused as-is.
WRAP_REQUIRED := $(foreach a,$(ARCHS),$(addprefix $(a)-linux-cosmo-,gcc g++))

# phony so the completeness check runs every time; without it the stamp file
# alone would mark the target up to date and never notice broken symlinks
.PHONY: wrappers-check
wrappers-check:
	@for f in $(notdir $(WRAP_REQUIRED)); do \
	  test -e "$(WRAP_DIR)/$$f" || { \
	    echo "=== shadow incomplete ($$f), rebuilding ==="; \
	    rm -rf $(WRAP_ROOT); break; }; \
	done

$(WRAP_STAMP): wrappers-check
	$(MAKE) -C $(NCURSES_DIR) wrappers WRAP_ROOT=$(WRAP_ROOT)
	@for f in $(notdir $(WRAP_REQUIRED)); do \
	  test -e "$(WRAP_DIR)/$$f" || { \
	    echo "shadow still missing $$f; check $(COSMOCC_BIN)" >&2; exit 1; }; \
	done

wrappers: $(WRAP_STAMP)

wrappers-clean:
	@rm -rf $(WRAP_ROOT)

# ===========================================================================
#  patch — stamp lives in build/ so the source checkout stays clean
# ===========================================================================
PATCH_STAMP := $(BUILD_ROOT)/.patched

ifeq ($(SKIP_PATCH),1)
$(PATCH_STAMP):
	@echo "=== patching skipped (SKIP_PATCH=1) ==="
	@mkdir -p $(BUILD_ROOT)
	@touch $@
else
# git apply can tell clean / already-applied / partially-applied apart, so
# prefer it; patch(1) is the fallback and, unlike git, drops *.rej files into
# the source tree whenever it skips a hunk.
#
# source/tvision/tinputli.cpp is CRLF upstream while the patch is LF. GNU
# patch reports "different line endings" and skips the hunk when they
# disagree; --binary keeps the patch's CRs and plain mode strips them, so
# neither matches a file whose convention is unknown at authoring time.
# Normalizing the file to LF up front makes one attempt enough and works
# whatever the checkout does.
$(PATCH_STAMP): $(PATCH)
	@echo "=== patching tvision ==="
	@mkdir -p $(BUILD_ROOT)
	@sed -i 's/\r$$//' $(SRC_DIR)/source/tvision/tinputli.cpp
	@if git -C $(SRC_DIR) rev-parse --git-dir >/dev/null 2>&1; then \
	  if git -C $(SRC_DIR) apply --check $(PATCH) 2>/dev/null; then \
	    git -C $(SRC_DIR) apply $(PATCH); \
	  elif git -C $(SRC_DIR) apply --check -R $(PATCH) 2>/dev/null; then \
	    echo "  (already applied)"; \
	  else \
	    echo "  (partially applied)" >&2; \
	    cd $(SRC_DIR) && patch -p1 --forward --batch < $(PATCH) || true; \
	    git -C $(SRC_DIR) apply --check -R $(PATCH) 2>/dev/null \
	      || echo "  WARNING: patch may be incomplete" >&2; \
	  fi; \
	else \
	  cd $(SRC_DIR) && patch -p1 --forward --batch < $(PATCH) || true; \
	fi
# '|| true' above makes a skipped hunk non-fatal, and the warning is easy to
# miss in a long build. Fail loudly instead: 's.empty()' occurs only in the
# hotKeyStr guard this patch adds (the file otherwise has just 'p.empty()').
	@grep -q 's\.empty()' $(SRC_DIR)/source/tvision/tinputli.cpp \
	  || { echo "  ERROR: hotKeyStr guard not applied" >&2; exit 1; }
	@find $(SRC_DIR) \( -name '*.rej' -o -name '*.orig' \) -delete
	@touch $@
endif

patch: $(PATCH_STAMP)

# ===========================================================================
#  self-test
# ===========================================================================
check: wrappers
	@echo "=== cmake ==="
	@command -v cmake >/dev/null || { echo "cmake not found" >&2; exit 1; }
	@cmake --version | head -1
	@echo "=== sources: $(SRC_DIR) ==="
	@test -f $(SRC_DIR)/CMakeLists.txt || { echo "missing $(SRC_DIR)/CMakeLists.txt" >&2; exit 1; }
	@echo "=== compiler / binutils ==="
	@for t in CC CXX LD AR RANLIB STRIP; do \
	  for a in $(ARCHS); do \
	    u=$$(echo $$a | tr a-z A-Z); \
	    n="$${t}_$$u"; f="$${!n}"; \
	    test -x "$$f" || { echo "missing $$n = $$f" >&2; exit 1; }; \
	    echo "  $$n = $$f"; \
	  done; \
	done
	@echo "=== shadow toolchain ==="
	@for f in $(notdir $(WRAP_REQUIRED)); do \
	  if [ -e "$(WRAP_DIR)/$$f" ]; then echo "  $$f ok"; \
	  else echo "missing $(WRAP_DIR)/$$f" >&2; exit 1; fi; \
	done
	@echo "=== ncurses in sysroot ==="
	@for a in $(ARCHS); do \
	  p=$(COSMOS_ROOT)/$$a; \
	  for l in libncursesw.a libtinfow.a; do \
	    test -f $$p/lib/$$l || { echo "missing $$p/lib/$$l (run: make -C $(NCURSES_DIR))" >&2; exit 1; }; \
	  done; \
	  test -f $$p/include/ncursesw/ncurses.h || { echo "missing $$p/include/ncursesw/ncurses.h" >&2; exit 1; }; \
	  echo "  $$a ok"; \
	done

# ===========================================================================
#  per arch: cmake configure -> build -> install
#  $(1)=arch lowercase  $(2)=arch uppercase suffix
# ===========================================================================
define ARCH_RULES
COSMOS.$(1)    := $(COSMOS_ROOT)/$(1)
BUILDD.$(1)    := $(BUILD_ROOT)/$(1)
NCURSES.$(1)   := $$(COSMOS.$(1))/.installed

# ncurses is a real prerequisite, not a documented one
$$(NCURSES.$(1)): $(WRAP_STAMP)
	$(MAKE) -C $(NCURSES_DIR) ARCHS=$(1) WRAP_ROOT=$(WRAP_ROOT) install

$$(BUILDD.$(1))/.configured: $$(NCURSES.$(1)) $(PATCH_STAMP)
	@echo "=== configure $(1) ==="
	@mkdir -p $$(BUILDD.$(1))
	cd $$(BUILDD.$(1)) && \
	  ARCH=$(1) MODE=$(1) \
	  CC="$(CC_$(2))" CXX="$(CXX_$(2))" \
	  AR="$(AR_$(2))" RANLIB="$(RANLIB_$(2))" \
	  LD="$(LD_$(2))" STRIP="$(STRIP_$(2))" \
	  COSMOS=$$(COSMOS.$(1)) COSMOCC=$(COSMOCC_ROOT) \
	  PKG_CONFIG_LIBDIR=$$(COSMOS.$(1))/lib/pkgconfig \
	  cmake $(SRC_DIR) $(call CMAKE_ARGS,$(1))
	@touch $$@

configure-$(1): $$(BUILDD.$(1))/.configured

$$(BUILDD.$(1))/.built: $$(BUILDD.$(1))/.configured
	@echo "=== build $(1) ==="
	cd $$(BUILDD.$(1)) && \
	  export COSMOS=$$(COSMOS.$(1)) && \
	  cmake --build . --parallel $(MAXPROC)
	@touch $$@

build-$(1): $$(BUILDD.$(1))/.built

$$(COSMOS.$(1))/.tvision-installed: $$(BUILDD.$(1))/.built
	@echo "=== install $(1) -> $$(COSMOS.$(1)) ==="
	cd $$(BUILDD.$(1)) && \
	  export COSMOS=$$(COSMOS.$(1)) && \
	  cmake --install .
	@touch $$@

install-$(1): $$(COSMOS.$(1))/.tvision-installed

endef

$(eval $(call ARCH_RULES,x86_64,X86_64))
$(eval $(call ARCH_RULES,aarch64,AARCH64))

configure: $(foreach a,$(ARCHS),configure-$(a))
build:     $(foreach a,$(ARCHS),build-$(a))
install:   $(foreach a,$(ARCHS),install-$(a))

# ===========================================================================
#  links — shortcuts at the project root, pointing back into the sysroot
# ===========================================================================
links: install
	@echo "=== linking tvision into $(LINK_ROOT)/<arch> ==="
	@for a in $(ARCHS); do \
	  mkdir -p $(LINK_ROOT)/$$a/lib $(LINK_ROOT)/$$a/include; \
	  for f in libtvision.a; do \
	    f=$(COSMOS_ROOT)/$$a/lib/$$f; \
	    [ -e "$$f" ] || { echo "missing $$f" >&2; exit 1; }; \
	    ln -sf "$$f" $(LINK_ROOT)/$$a/lib/; \
	  done; \
	  ln -sfn $(COSMOS_ROOT)/$$a/include/tvision $(LINK_ROOT)/$$a/include/tvision; \
	done

links-clean:
	@echo "=== removing tvision links from $(LINK_ROOT)/<arch> ==="
	@for a in $(ARCHS); do \
	  rm -f $(LINK_ROOT)/$$a/lib/libtvision.a $(LINK_ROOT)/$$a/include/tvision; \
	done

clean:
	@echo "=== removing build/ ==="
	@rm -rf $(BUILD_ROOT)

distclean: clean
	@echo "=== removing installed tvision from sysroot ==="
	@for a in $(ARCHS); do \
	  rm -f $(COSMOS_ROOT)/$$a/lib/libtvision.a $(COSMOS_ROOT)/$$a/.tvision-installed; \
	  rm -rf $(COSMOS_ROOT)/$$a/include/tvision $(COSMOS_ROOT)/$$a/lib/cmake/tvision; \
	done
