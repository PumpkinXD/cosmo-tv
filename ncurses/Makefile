# ncurses for Cosmopolitan Libc — self-contained Makefile
#
# Lives in <project>/ncurses/, toolchain at <project>/cosmocc/.
#
#   make check          # environment self-test (run this first)
#   make                # build x86_64 + aarch64 -> out/<arch>
#   make ARCHS=x86_64   # single arch
#   make CC_MODE=raw    # drive <arch>-linux-cosmo-gcc directly (see below)
#   make BUILD_CC=cc    # build tic/make_hash/... with host cc
#                       #   (avoids needing an APE loader / qemu)
#   make clean distclean
#
# CC_MODE:
#   wrap (default) — use cosmocross, which injects the cosmo flags
#       (-nostdinc, -isystem .../include, crt.o, ape.lds, -lcosmo, ...).
#       cosmocross derives the arch from $0: PROG=${0##*/}; ARCH=${PROG%%-*}.
#       Some cosmocc packages ship <arch>-unknown-cosmo-cc as a shell wrapper
#       rather than a symlink, so $0 collapses to .../cosmocross (no '-') and
#       it dies with "cosmocross must be run via cross compiler".
#       Fix: copy cosmocross to 4 correctly named files in a shadow tree
#       (build/cosmocc-shadow by default, override with WRAP_ROOT) that also
#       mirrors include/ and <arch>-linux-cosmo/ as symlinks, because
#       cosmocross resolves $BIN/../include. Nothing is written to cosmocc/,
#       so it may be a symlink to a toolchain owned by someone else.
#   raw — call <arch>-linux-cosmo-gcc and pass the cosmo flags by hand.

SHELL := /bin/bash

CURDIR       := $(shell pwd)
PROJ_ROOT    := $(shell cd .. && pwd)
COSMOCC_ROOT := $(PROJ_ROOT)/cosmocc
COSMOCC_BIN  := $(COSMOCC_ROOT)/bin

CC_MODE ?= wrap

export COSMOPOLITAN_DISABLE_ZIPOS=1
export COSMOS

# ---- sources / layout -----------------------------------------------------
NCURSES_VERSION ?= 6.4
NCURSES_URL     ?= https://mirrors.ocf.berkeley.edu/gnu/ncurses/ncurses-6.4.tar.gz
NCURSES_SHA256  ?= 6931283d9ac87c5073f30b6290c4c75f21632bb4fc3603ac8100812bed248159

SRC_DIR := $(CURDIR)/ncurses-6.4
TARBALL := $(CURDIR)/ncurses-6.4.tar.gz
PATCH   := $(CURDIR)/minimal.diff

OUT_ROOT   := $(CURDIR)/out
BUILD_ROOT := $(CURDIR)/build

# shadow tree for wrap mode; lives under build/, never inside cosmocc/
WRAP_ROOT ?= $(BUILD_ROOT)/cosmocc-shadow
WRAP_DIR  := $(WRAP_ROOT)/bin

PATH := $(WRAP_DIR):$(COSMOCC_BIN):$(PATH)
export PATH

ARCHS   ?= x86_64 aarch64
MAXPROC ?= $(shell nproc 2>/dev/null || echo 1)

# ---- binutils: only ever named <arch>-linux-cosmo-* -----------------------
LD_X86_64      := $(COSMOCC_BIN)/x86_64-linux-cosmo-ld
AR_X86_64      := $(COSMOCC_BIN)/x86_64-linux-cosmo-ar
RANLIB_X86_64  := $(COSMOCC_BIN)/x86_64-linux-cosmo-ranlib
STRIP_X86_64   := $(COSMOCC_BIN)/x86_64-linux-cosmo-strip
LD_AARCH64     := $(COSMOCC_BIN)/aarch64-linux-cosmo-ld
AR_AARCH64     := $(COSMOCC_BIN)/aarch64-linux-cosmo-ar
RANLIB_AARCH64 := $(COSMOCC_BIN)/aarch64-linux-cosmo-ranlib
STRIP_AARCH64  := $(COSMOCC_BIN)/aarch64-linux-cosmo-strip

# ---- physical compiler (CC_MODE=raw) --------------------------------------
GCC_X86_64  := $(COSMOCC_BIN)/x86_64-linux-cosmo-gcc
GXX_X86_64  := $(COSMOCC_BIN)/x86_64-linux-cosmo-g++
GCC_AARCH64 := $(COSMOCC_BIN)/aarch64-linux-cosmo-gcc
GXX_AARCH64 := $(COSMOCC_BIN)/aarch64-linux-cosmo-g++

# ---- compiler selection ---------------------------------------------------
ifeq ($(CC_MODE),raw)
CC_X86_64   := $(GCC_X86_64)
CXX_X86_64  := $(GXX_X86_64)
CC_AARCH64  := $(GCC_AARCH64)
CXX_AARCH64 := $(GXX_AARCH64)
else
CC_X86_64   := $(WRAP_DIR)/x86_64-unknown-cosmo-cc
CXX_X86_64  := $(WRAP_DIR)/x86_64-unknown-cosmo-c++
CC_AARCH64  := $(WRAP_DIR)/aarch64-unknown-cosmo-cc
CXX_AARCH64 := $(WRAP_DIR)/aarch64-unknown-cosmo-c++
endif

# ---- flags for raw mode, mirroring what cosmocross injects ----------------
LIB_X86_64  := $(COSMOCC_ROOT)/x86_64-linux-cosmo/lib
LIB_AARCH64 := $(COSMOCC_ROOT)/aarch64-linux-cosmo/lib

RAW_CPPFLAGS_X86_64 := -D__COSMOPOLITAN__ -D__COSMOCC__ -fno-pie -nostdinc \
	-isystem $(COSMOCC_ROOT)/include -include libc/integral/normalize.inc -mno-red-zone
RAW_CFLAGS_X86_64 := -Os -fportcosmo -fno-semantic-interposition \
	-mno-tls-direct-seg-refs -Wno-implicit-int -std=gnu17
RAW_LDFLAGS_X86_64 := -static -no-pie -nostdlib -fuse-ld=bfd -Wl,-z,noexecstack \
	-Wl,-T,$(LIB_X86_64)/ape.lds -L$(LIB_X86_64) \
	-Wl,-z,common-page-size=4096 -Wl,-z,max-page-size=16384 \
	$(LIB_X86_64)/ape-no-modify-self.o $(LIB_X86_64)/crt.o
RAW_LIBS_X86_64 := -lcosmo

# aarch64 differs: -fsigned-char instead of -mno-red-zone, fixed regs,
# aarch64.lds, 16k pages
RAW_CPPFLAGS_AARCH64 := -D__COSMOPOLITAN__ -D__COSMOCC__ -fno-pie -nostdinc \
	-isystem $(COSMOCC_ROOT)/include -include libc/integral/normalize.inc -fsigned-char
RAW_CFLAGS_AARCH64 := -Os -fportcosmo -fno-semantic-interposition \
	-ffixed-x18 -ffixed-x28 -Wno-implicit-int -std=gnu17
RAW_LDFLAGS_AARCH64 := -static -no-pie -nostdlib -fuse-ld=bfd -Wl,-z,noexecstack \
	-Wl,-T,$(LIB_AARCH64)/aarch64.lds -L$(LIB_AARCH64) \
	-Wl,-z,common-page-size=16384 -Wl,-z,max-page-size=16384 \
	$(LIB_AARCH64)/crt.o
RAW_LIBS_AARCH64 := -lcosmo

ifeq ($(CC_MODE),raw)
CPPFLAGS_X86_64  := $(RAW_CPPFLAGS_X86_64)
CFLAGS_X86_64    := $(RAW_CFLAGS_X86_64)
LDFLAGS_X86_64   := $(RAW_LDFLAGS_X86_64)
LIBS_X86_64      := $(RAW_LIBS_X86_64)
CPPFLAGS_AARCH64 := $(RAW_CPPFLAGS_AARCH64)
CFLAGS_AARCH64   := $(RAW_CFLAGS_AARCH64)
LDFLAGS_AARCH64  := $(RAW_LDFLAGS_AARCH64)
LIBS_AARCH64     := $(RAW_LIBS_AARCH64)
else
# wrap mode: cosmocross adds all of it, only -Os is ours
CPPFLAGS_X86_64 :=
CFLAGS_X86_64   := -Os
LDFLAGS_X86_64  :=
LIBS_X86_64     :=
CPPFLAGS_AARCH64 :=
CFLAGS_AARCH64   := -Os
LDFLAGS_AARCH64  :=
LIBS_AARCH64     :=
endif

# exported so `check` can indirect through ${!n}
export CC_X86_64 CXX_X86_64 LD_X86_64 AR_X86_64 RANLIB_X86_64 STRIP_X86_64
export CC_AARCH64 CXX_AARCH64 LD_AARCH64 AR_AARCH64 RANLIB_AARCH64 STRIP_AARCH64
export CFLAGS_X86_64 CPPFLAGS_X86_64 LDFLAGS_X86_64 LIBS_X86_64
export CFLAGS_AARCH64 CPPFLAGS_AARCH64 LDFLAGS_AARCH64 LIBS_AARCH64

# ---- --host / --with-build-cc --------------------------------------------
# HOST_*: empty means autoconf treats host==build, so conftest is compiled by
#   cosmocc and run locally — probes report cosmo libc, not host glibc
#   (this is what superconfigure does). Set e.g. x86_64-linux-musl to force
#   cross mode: all runtime probes skipped in favour of ncurses' guesses.
HOST_X86_64  ?=
HOST_AARCH64 ?=
# BUILD_CC: ncurses runs make_hash/make_keys/tic while building.
#   empty = build them with CC (needs APE loader; qemu for aarch64)
#   cc/gcc = build them with the host compiler instead
BUILD_CC ?=

define HOST_ARGS
$(if $($(1)),--host=$($(1)),)
endef

# ---- configure args (verbatim from superconfigure) ------------------------
# CFLAGS/CPPFLAGS/LDFLAGS/LIBS are passed per-arch below, not here,
# because raw mode needs to inject a lot more than -Os.
define NCURSES_CONFIG_ARGS_COMMON
--without-libtool \
--without-shared \
--with-normal \
--without-debug \
--disable-relink \
--disable-rpath \
--disable-termcap \
--disable-mixed-case \
--without-ada \
--without-cxx \
--without-cxx-binding \
--without-tests \
--with-termlib \
--with-ticlib \
--without-dlsym \
--without-pcre2 \
--with-sysmouse \
--without-manpages \
--without-tack \
--with-curses-h \
--disable-stripping \
--enable-widec \
--enable-ext-colors \
--enable-ext-mouse \
--enable-sp-funcs \
--enable-colorfgbg \
--enable-tcap-names \
--with-pkg-config \
--enable-pc-files \
--with-fallbacks=xterm,xterm-256color,screen-256color,linux,vt100,ansi77
endef

.DEFAULT_GOAL := all

.PHONY: all check wrappers wrappers-clean download extract patch bootstrap \
        configure configure-x86_64 configure-aarch64 \
        build build-x86_64 build-aarch64 \
        install install-x86_64 install-aarch64 \
        install-symlinks install-symlinks-x86_64 install-symlinks-aarch64 \
        clean distclean

all: build install

# ===========================================================================
#  shadow toolchain — only needed by wrap mode
#  Mirrors cosmocc/ into $(WRAP_ROOT) with symlinks, then replaces the four
#  compiler entries with real copies of cosmocross so $0 carries the arch.
#  Nothing is written under $(COSMOCC_ROOT).
# ===========================================================================
WRAP_STAMP := $(WRAP_ROOT)/.stamp

$(WRAP_STAMP): $(COSMOCC_BIN)/cosmocross
	@echo "=== creating toolchain shadow in $(WRAP_ROOT) ==="
	@rm -rf $(WRAP_ROOT)
	@mkdir -p $(WRAP_DIR)
	@cd $(COSMOCC_ROOT) && for f in *; do \
		[ "$$f" = bin ] && continue; \
		ln -sf "$(COSMOCC_ROOT)/$$f" "$(WRAP_ROOT)/$$f"; \
	done
	@cd $(COSMOCC_BIN) && for f in *; do \
		case "$$f" in *-unknown-cosmo-cc|*-unknown-cosmo-c++) continue ;; esac; \
		ln -sf "$(COSMOCC_BIN)/$$f" "$(WRAP_DIR)/$$f"; \
	done
	@for a in x86_64 aarch64; do \
		for s in cc c++; do \
			cp "$(COSMOCC_BIN)/cosmocross" "$(WRAP_DIR)/$$a-unknown-cosmo-$$s" || exit 1; \
			chmod +x "$(WRAP_DIR)/$$a-unknown-cosmo-$$s"; \
		done; \
	done
	@touch $@

wrappers: $(WRAP_STAMP)

wrappers-clean:
	@rm -rf $(WRAP_ROOT)

# ===========================================================================
#  self-test
# ===========================================================================
check:
	@echo "=== cosmocc: $(COSMOCC_ROOT) ==="
	@test -x $(COSMOCC_BIN)/cosmocc || { echo "not found: $(COSMOCC_BIN)/cosmocc" >&2; exit 1; }
	@$(COSMOCC_BIN)/cosmocc --version 2>&1 | head -1
	@echo "=== CC_MODE = $(CC_MODE) ==="
ifeq ($(CC_MODE),wrap)
	@$(MAKE) --no-print-directory wrappers
endif
	@echo "--- compiler / binutils ---"
	@for t in CC CXX LD AR RANLIB STRIP; do \
	  for a in $(ARCHS); do \
	    u=$$(echo $$a | tr a-z A-Z); \
	    n="$${t}_$$u"; f="$${!n}"; \
	    test -x "$$f" || { echo "missing $$n = $$f" >&2; exit 1; }; \
	    echo "  $$n = $$f"; \
	  done; \
	done
	@echo "--- --version (wrap mode: passing here means \$0 is right) ---"
	@for a in $(ARCHS); do \
	  u=$$(echo $$a | tr a-z A-Z); \
	  n="CC_$$u"; c="$${!n}"; \
	  printf "  %-8s " "$$a"; \
	  $$c --version 2>&1 | head -1 || { echo "failed" >&2; exit 1; }; \
	done
	@echo "--- compile and run a hello (configure dies if this fails) ---"
	@printf '#include <stdio.h>\nint main(void){printf("hi\\n");return 0;}\n' > /tmp/.ape_probe.c
	@for a in $(ARCHS); do \
	  u=$$(echo $$a | tr a-z A-Z); \
	  n="CC_$$u";       c="$${!n}"; \
	  n="CFLAGS_$$u";   cf="$${!n}"; \
	  n="LDFLAGS_$$u";  ldf="$${!n}"; \
	  n="LIBS_$$u";     lb="$${!n}"; \
	  n="CPPFLAGS_$$u"; cpf="$${!n}"; \
	  printf "  %-8s " "$$a"; \
	  if $$c $$cpf $$cf $$ldf /tmp/.ape_probe.c $$lb -o /tmp/.ape_probe.$$a >/tmp/.ape_probe.$$a.log 2>&1 && \
	     /tmp/.ape_probe.$$a 2>&1 | grep -q hi; then echo "compile+run OK"; \
	  else \
	    echo "FAILED, log:" >&2; sed 's/^/    /' /tmp/.ape_probe.$$a.log >&2; \
	    echo "    ('cannot find -lc'/'crt1.o' -> raw-mode flags are wrong)" >&2; \
	    echo "    ('exec format error'/'unable to find an interpreter' -> install APE loader)" >&2; \
	    exit 1; \
	  fi; \
	done
	@rm -f /tmp/.ape_probe.*

# raw mode needs no wrappers
ifeq ($(CC_MODE),raw)
WRAP_DEP :=
else
WRAP_DEP := $(WRAP_STAMP)
endif

# ===========================================================================
#  download / extract / patch
# ===========================================================================
$(TARBALL):
	@echo "=== downloading ncurses ==="
	@if command -v curl >/dev/null 2>&1; then \
		curl -fL -o $@ $(NCURSES_URL); \
	elif command -v wget >/dev/null 2>&1; then \
		wget -O $@ $(NCURSES_URL); \
	else \
		echo "need curl or wget" >&2; exit 1; \
	fi

download: $(TARBALL)

$(SRC_DIR)/.extracted: $(TARBALL)
	@echo "=== extracting ==="
	@if [ "$(SKIP_SHA)" = "1" ]; then \
		echo "  (SKIP_SHA=1, checksum skipped)"; \
	else \
		echo "$(NCURSES_SHA256)  $(TARBALL)" | sha256sum --check - || { \
			echo "sha256 mismatch; use SKIP_SHA=1 to override" >&2; exit 1; }; \
	fi
	@rm -rf $(SRC_DIR)
	@tar -xzf $(TARBALL) -C $(CURDIR)
	@touch $@

extract: $(SRC_DIR)/.extracted

# minimal.diff paths are ncurses-6.4/ncurses/curses.priv.h,
# so -p1 inside the source dir == -p0 from its parent
$(SRC_DIR)/.patched: $(SRC_DIR)/.extracted $(PATCH)
	@echo "=== patching ==="
	cd $(SRC_DIR) && patch -p1 --forward < $(PATCH)
	@touch $@

patch: $(SRC_DIR)/.patched

bootstrap: download extract patch

# ===========================================================================
#  per arch: configure -> build -> install -> symlinks
#  $(1)=arch lowercase  $(2)=arch uppercase suffix
# ===========================================================================
define ARCH_RULES
PREFIX.$(1) := $(OUT_ROOT)/$(1)
BUILDD.$(1) := $(BUILD_ROOT)/$(1)

$$(BUILDD.$(1))/.configured: $(SRC_DIR)/.patched $(WRAP_DEP)
	@echo "=== configure $(1) ==="
	@mkdir -p $$(BUILDD.$(1)) $$(PREFIX.$(1))
	cd $$(BUILDD.$(1)) && \
		export CC="$(CC_$(2))" CXX="$(CXX_$(2))" \
		       LD="$(LD_$(2))" AR="$(AR_$(2))" \
		       RANLIB="$(RANLIB_$(2))" STRIP="$(STRIP_$(2))" \
		       COSMOS=$$(PREFIX.$(1)) && \
		$(SRC_DIR)/configure \
			--prefix=$$(PREFIX.$(1)) \
			--with-default-terminfo-dir=$$(PREFIX.$(1))/share/terminfo \
			--with-pkgconfig-libdir=$$(PREFIX.$(1))/lib/pkgconfig \
			$(call HOST_ARGS,HOST_$(2)) \
			$(if $(BUILD_CC),--with-build-cc=$(BUILD_CC),) \
			$(NCURSES_CONFIG_ARGS_COMMON) \
			CFLAGS="$(CFLAGS_$(2))" \
			CPPFLAGS="$(CPPFLAGS_$(2))" \
			LDFLAGS="$(LDFLAGS_$(2))" \
			LIBS="$(LIBS_$(2))"
	@touch $$@

configure-$(1): $$(BUILDD.$(1))/.configured

$$(BUILDD.$(1))/.built: $$(BUILDD.$(1))/.configured
	@echo "=== build $(1) ==="
	cd $$(BUILDD.$(1)) && \
		export COSMOS=$$(PREFIX.$(1)) && \
		$(MAKE) -j$(MAXPROC)
	@touch $$@

build-$(1): $$(BUILDD.$(1))/.built

$$(PREFIX.$(1))/.installed: $$(BUILDD.$(1))/.built
	@echo "=== install $(1) -> $$(PREFIX.$(1)) ==="
	@mkdir -p $$(PREFIX.$(1))
	cd $$(BUILDD.$(1)) && \
		export COSMOS=$$(PREFIX.$(1)) && \
		$(MAKE) install -j$(MAXPROC)
	@echo "=== symlinks $(1) ==="
	@mkdir -p $$(PREFIX.$(1))/lib $$(PREFIX.$(1))/include
	@ln -sf libncursesw.a $$(PREFIX.$(1))/lib/libncurses.a
	@ln -sf libformw.a    $$(PREFIX.$(1))/lib/libform.a
	@ln -sf libmenuw.a    $$(PREFIX.$(1))/lib/libmenu.a
	@ln -sf libpanelw.a   $$(PREFIX.$(1))/lib/libpanel.a
	@ln -sf libticw.a     $$(PREFIX.$(1))/lib/libtic.a
	@ln -sf libtinfow.a   $$(PREFIX.$(1))/lib/libtinfo.a
	@cd $$(PREFIX.$(1))/include && rm -rf ncurses && ln -sf ncursesw ncurses
	@touch $$@

install-$(1): $$(PREFIX.$(1))/.installed

install-symlinks-$(1):
	@echo "=== re-creating $(1) symlinks ==="
	@mkdir -p $$(PREFIX.$(1))/lib $$(PREFIX.$(1))/include
	@ln -sf libncursesw.a $$(PREFIX.$(1))/lib/libncurses.a
	@ln -sf libformw.a    $$(PREFIX.$(1))/lib/libform.a
	@ln -sf libmenuw.a    $$(PREFIX.$(1))/lib/libmenu.a
	@ln -sf libpanelw.a   $$(PREFIX.$(1))/lib/libpanel.a
	@ln -sf libticw.a     $$(PREFIX.$(1))/lib/libtic.a
	@ln -sf libtinfow.a   $$(PREFIX.$(1))/lib/libtinfo.a
	@cd $$(PREFIX.$(1))/include && rm -rf ncurses && ln -sf ncursesw ncurses

endef

$(eval $(call ARCH_RULES,x86_64,X86_64))
$(eval $(call ARCH_RULES,aarch64,AARCH64))

configure: $(foreach a,$(ARCHS),configure-$(a))
build:     $(foreach a,$(ARCHS),build-$(a))
install:   $(foreach a,$(ARCHS),install-$(a))
install-symlinks: $(foreach a,$(ARCHS),install-symlinks-$(a))

clean:
	@echo "=== removing build/ ==="
	@rm -rf $(BUILD_ROOT)

distclean: clean
	@echo "=== removing out/, sources and tarball ==="
	@rm -rf $(OUT_ROOT) $(SRC_DIR) $(TARBALL)
