# Setup the Freedom build script environment
include scripts/Freedom.mk

# Include version identifiers to build up the full version string
include Version.mk
PACKAGE_HEADING := freedom-gdb-metal
PACKAGE_VERSION := $(RISCV_GDB_VERSION)-$(FREEDOM_GDB_METAL_ID)

# Source code directory references
SRCNAME_GDB := riscv-gdb
SRCPATH_GDB := $(SRCDIR)/$(SRCNAME_GDB)
BARE_METAL_TUPLE := riscv64-unknown-elf
BARE_METAL_CC_FOR_TARGET ?= $(BARE_METAL_TUPLE)-gcc
BARE_METAL_CXX_FOR_TARGET ?= $(BARE_METAL_TUPLE)-g++

# Some special package configure flags for specific targets
$(WIN64)-gdb-host            := --host=$(WIN64)
$(WIN64)-expat-configure     := --host=$(WIN64)
$(UBUNTU64)-gdb-host         := --host=x86_64-linux-gnu
$(UBUNTU64)-expat-configure  := --host=x86_64-linux-gnu
$(DARWIN)-gdb-host           := --with-liblzma-prefix=/usr
$(DARWIN)-expat-configure    := --disable-shared --enable-static

# Setup the package targets and switch into secondary makefile targets
# Targets $(PACKAGE_HEADING)/install.stamp and $(PACKAGE_HEADING)/libs.stamp
include scripts/Package.mk

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gdb/build.stamp
	mkdir -p $(dir $@)
	date > $@

# We might need some extra target libraries for this package
$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/install.stamp
	date > $@

$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/install.stamp
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp:
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	rm -rf $($@_INSTALL)
	mkdir -p $($@_INSTALL)
	rm -rf $($@_REC)
	mkdir -p $($@_REC)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cd $($@_REC); curl -L -f -s -o expat-2.2.0.tar.bz2 https://github.com/libexpat/libexpat/releases/download/R_2_2_0/expat-2.2.0.tar.bz2
	cd $(dir $@); $(TAR) -xf $($@_REC)/expat-2.2.0.tar.bz2
	cd $(dir $@); mv expat-2.2.0 expat
	cp -a $(SRCPATH_GDB) $(dir $@)
	date > $@

# OpenOCD requires a GDB that's been build with expat support so it can read
# the target XML files.
$(OBJDIR)/%/build/$(PACKAGE_HEADING)/expat/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/expat/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/expat/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/expat/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	cd $(dir $@); ./configure --prefix=$(abspath $($@_INSTALL)) $($($@_TARGET)-expat-configure) &>$($@_REC)/expat-make-configure.log
	$(MAKE) -C $(dir $@) buildlib &>$($@_REC)/expat-make-buildlib.log
	$(MAKE) -C $(dir $@) -j1 installlib &>$($@_REC)/expat-make-installlib.log
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gdb/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/expat/build.stamp \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gdb/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/build-gdb/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILD := $(patsubst %/build/$(PACKAGE_HEADING)/build-gdb/build.stamp,%/build/$(PACKAGE_HEADING),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/build-gdb/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
# CC_FOR_TARGET is required for the ld testsuite.
	cd $(dir $@) && CC_FOR_TARGET=$(BARE_METAL_CC_FOR_TARGET) $(abspath $($@_BUILD))/$(SRCNAME_GDB)/configure \
		--target=$(BARE_METAL_TUPLE) \
		$($($@_TARGET)-gdb-host) \
		--prefix=$(abspath $($@_INSTALL)) \
		--with-pkgversion="SiFive GDB Metal $(PACKAGE_VERSION)" \
		--with-bugurl="https://github.com/sifive/freedom-tools/issues" \
		--disable-werror \
		--with-python=no \
		--enable-gdb \
		--disable-gas \
		--disable-binutils \
		--disable-ld \
		--disable-gold \
		--disable-gprof \
		--with-included-gettext \
		--with-mpc=no \
		--with-mpfr=no \
		--with-gmp=no \
		--with-expat=yes \
		CFLAGS="-O2" \
		CXXFLAGS="-O2" &>$($@_REC)/build-gdb-make-configure.log
	$(MAKE) -C $(dir $@) &>$($@_REC)/build-gdb-make-build.log
	$(MAKE) -C $(dir $@) -j1 install install-pdf install-html &>$($@_REC)/build-gdb-make-install.log
	date > $@
