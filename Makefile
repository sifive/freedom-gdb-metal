# Setup the Freedom build script environment
include scripts/Freedom.mk

# Include version identifiers to build up the full version string
include Version.mk
PACKAGE_WORDING := Bare Metal GDB
PACKAGE_HEADING := riscv64-unknown-elf-gdb
PACKAGE_VERSION := $(RISCV_GDB_VERSION)-$(FREEDOM_GDB_METAL_ID)$(EXTRA_SUFFIX)

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
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gdb-py/build.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/install.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	mkdir -p $(dir $@)
	mkdir -p $(dir $@)/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).bundle/features
	git log --format="[%ad] %s" > $(abspath $($@_INSTALL))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).changelog
	cp README.md $(abspath $($@_INSTALL))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).readme.md
	tclsh scripts/generate-feature-xml.tcl "$(PACKAGE_WORDING)" "$(PACKAGE_HEADING)" "$(RISCV_GDB_VERSION)" "$(FREEDOM_GDB_METAL_ID)" $($@_TARGET) $(abspath $($@_INSTALL))
	tclsh scripts/generate-chmod755-sh.tcl $(abspath $($@_INSTALL))
	tclsh scripts/generate-site-xml.tcl "$(PACKAGE_WORDING)" "$(PACKAGE_HEADING)" "$(RISCV_GDB_VERSION)" "$(FREEDOM_GDB_METAL_ID)" $($@_TARGET) $(abspath $(dir $@))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).bundle
	tclsh scripts/generate-bundle-mk.tcl $(abspath $($@_INSTALL)) RISCV_TAGS "$(FREEDOM_GDB_METAL_RISCV_TAGS)" TOOLS_TAGS "$(FREEDOM_GDB_METAL_TOOLS_TAGS)"
	cp $(abspath $($@_INSTALL))/bundle.mk $(abspath $(dir $@))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).bundle
	cd $($@_INSTALL); zip -rq $(abspath $(dir $@))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).bundle/features/$(PACKAGE_HEADING)_$(FREEDOM_GDB_METAL_ID)_$(RISCV_GDB_VERSION).jar *
	tclsh scripts/check-maximum-path-length.tcl $(abspath $($@_INSTALL)) "$(PACKAGE_HEADING)" "$(RISCV_GDB_VERSION)" "$(FREEDOM_GDB_METAL_ID)"
	tclsh scripts/check-same-name-different-case.tcl $(abspath $($@_INSTALL))
	echo $(PATH)
	date > $@

# We might need some extra target libraries for this package
$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/install.stamp
	date > $@

$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/install.stamp
	-$(WIN64)-gcc -print-search-dirs | grep ^programs | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libwinpthread*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	-$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libgcc_s_seh*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	-$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libstdc*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	-$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libssp*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp:
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	tclsh scripts/check-naming-and-version-syntax.tcl "$(PACKAGE_WORDING)" "$(PACKAGE_HEADING)" "$(RISCV_GDB_VERSION)" "$(FREEDOM_GDB_METAL_ID)"
	rm -rf $($@_INSTALL)
	mkdir -p $($@_INSTALL)
	rm -rf $($@_REC)
	mkdir -p $($@_REC)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	git log > $($@_REC)/$(PACKAGE_HEADING)-git-commit.log
	cp .gitmodules $($@_REC)/$(PACKAGE_HEADING)-git-modules.log
	git remote -v > $($@_REC)/$(PACKAGE_HEADING)-git-remote.log
	git submodule status > $($@_REC)/$(PACKAGE_HEADING)-git-submodule.log
	cd $($@_REC); curl -L -f -s -o expat-2.2.0.tar.bz2 https://github.com/libexpat/libexpat/releases/download/R_2_2_0/expat-2.2.0.tar.bz2
	cd $(dir $@); $(TAR) -xf $($@_REC)/expat-2.2.0.tar.bz2
	cd $(dir $@); mv expat-2.2.0 expat
	mkdir -p $($@_INSTALL)/python
	cd $(dir $@); curl -L -f -s -o python-3.7.7-$($@_TARGET).tar.gz https://github.com/sifive/freedom-tools-resources/releases/download/v0-test1/python-3.7.7-$($@_TARGET).tar.gz
	cd $($@_INSTALL)/python; $(TAR) -xf $(abspath $(dir $@))/python-3.7.7-$($@_TARGET).tar.gz
	cd $(dir $@); rm python-3.7.7-$($@_TARGET).tar.gz
	cp $(PATCHESDIR)/pyconfig-x86_64-apple-darwin.sh $($@_INSTALL)/python
	cp $(PATCHESDIR)/pyconfig-x86_64-linux-centos6.sh $($@_INSTALL)/python
	cp $(PATCHESDIR)/pyconfig-x86_64-linux-ubuntu14.sh $($@_INSTALL)/python
	cp $(PATCHESDIR)/pyconfig-x86_64-w64-mingw32.sh $($@_INSTALL)/python
	cp -a $(SRCPATH_GDB) $(dir $@)
	$(SED) -E -i -f $(PATCHESDIR)/python-c-gdb.sed $(dir $@)/$(SRCNAME_GDB)/gdb/python/python.c
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
	rm -f $(abspath $($@_INSTALL))/lib/libexpat*.dylib*
	rm -f $(abspath $($@_INSTALL))/lib/libexpat*.so*
	rm -f $(abspath $($@_INSTALL))/lib64/libexpat*.so*
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
	# Workaround for CentOS random build fail issue
	#
	# Corresponding bugzilla entry on upstream:
	# https://sourceware.org/bugzilla/show_bug.cgi?id=22941
	touch $(abspath $($@_BUILD))/$(SRCNAME_GDB)/intl/plural.c
# CC_FOR_TARGET is required for the ld testsuite.
	cd $(dir $@) && CC_FOR_TARGET=$(BARE_METAL_CC_FOR_TARGET) $(abspath $($@_BUILD))/$(SRCNAME_GDB)/configure \
		--target=$(BARE_METAL_TUPLE) \
		$($($@_TARGET)-gdb-host) \
		--prefix=$(abspath $($@_INSTALL)) \
		--with-pkgversion="SiFive GDB-Metal $(PACKAGE_VERSION)" \
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
		--with-guile=no \
		CFLAGS="-O2" \
		CXXFLAGS="-O2" &>$($@_REC)/build-gdb-make-configure.log
	$(MAKE) -C $(dir $@) &>$($@_REC)/build-gdb-make-build.log
	$(MAKE) -C $(dir $@) -j1 install install-pdf install-html &>$($@_REC)/build-gdb-make-install.log
	rm -f $(abspath $($@_INSTALL))/share/doc/gdb/frame-apply.html
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-gdb
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gdb-py/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gdb/build.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gdb-py/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/build-gdb-py/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILD := $(patsubst %/build/$(PACKAGE_HEADING)/build-gdb-py/build.stamp,%/build/$(PACKAGE_HEADING),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/build-gdb-py/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	# Workaround for CentOS random build fail issue
	#
	# Corresponding bugzilla entry on upstream:
	# https://sourceware.org/bugzilla/show_bug.cgi?id=22941
	touch $(abspath $($@_BUILD))/$(SRCNAME_GDB)/intl/plural.c
# CC_FOR_TARGET is required for the ld testsuite.
	cd $(dir $@) && CC_FOR_TARGET=$(BARE_METAL_CC_FOR_TARGET) $(abspath $($@_BUILD))/$(SRCNAME_GDB)/configure \
		--target=$(BARE_METAL_TUPLE) \
		$($($@_TARGET)-gdb-host) \
		--prefix=$(abspath $($@_INSTALL)) \
		--with-pkgversion="SiFive GDB-Metal $(PACKAGE_VERSION)" \
		--with-bugurl="https://github.com/sifive/freedom-tools/issues" \
		--disable-werror \
		--with-python="$(abspath $($@_INSTALL))/python/pyconfig-$($@_TARGET).sh" \
		--program-prefix="$(BARE_METAL_TUPLE)-" \
		--program-suffix="-py" \
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
		--with-guile=no \
		CFLAGS="-O2" \
		CXXFLAGS="-O2" &>$($@_REC)/build-gdb-py-make-configure.log
	$(MAKE) -C $(dir $@) &>$($@_REC)/build-gdb-py-make-build.log
	$(MAKE) -C $(dir $@) -j1 install install-pdf install-html &>$($@_REC)/build-gdb-py-make-install.log
	rm -f $(abspath $($@_INSTALL))/share/doc/gdb/frame-apply.html
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-gdb-py
	date > $@

$(OBJDIR)/$(NATIVE)/test/$(PACKAGE_HEADING)/test.stamp: \
		$(OBJDIR)/$(NATIVE)/test/$(PACKAGE_HEADING)/launch.stamp
	mkdir -p $(dir $@)
	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) riscv64-unknown-elf-gdb -v
	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) riscv64-unknown-elf-gdb-py -v
	@echo "Finished testing $(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE).tar.gz tarball"
	date > $@
