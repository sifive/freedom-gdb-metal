# The default target
.PHONY: all package
all:
package:

# Make uses /bin/sh by default, ignoring the user's value of SHELL.
# Some systems now ship with /bin/sh pointing at dash, and this Makefile
# requires bash
SHELL = /bin/bash

POSTFIXPATH ?=
PREFIXPATH ?=
BINDIR := $(POSTFIXPATH)bin
OBJDIR := $(POSTFIXPATH)obj
SRCDIR := $(PREFIXPATH)src
SCRIPTSDIR := $(PREFIXPATH)scripts
PATCHESDIR := $(PREFIXPATH)patches

UBUNTU64 ?= x86_64-linux-ubuntu14
REDHAT ?= x86_64-linux-centos6
WIN64  ?= x86_64-w64-mingw32
DARWIN ?= x86_64-apple-darwin

-include /etc/lsb-release
ifneq ($(wildcard /etc/redhat-release),)
NATIVE ?= $(REDHAT)
NINJA ?= ninja-build
all: redhat
package: redhat-package
else ifeq ($(DISTRIB_ID),Ubuntu)
NATIVE ?= $(UBUNTU64)
all: ubuntu64
package: ubuntu64-package
all: win64
package: win64-package
else ifeq ($(shell uname),Darwin)
NATIVE ?= $(DARWIN)
LIBTOOLIZE ?= glibtoolize
TAR ?= gtar
SED ?= gsed
AWK ?= gawk
all: darwin
package: darwin-package
else
$(error Unknown host)
endif

LIBTOOLIZE ?= libtoolize
TAR ?= tar
SED ?= sed
AWK ?= awk
NINJA ?= ninja

OBJ_NATIVE   := $(OBJDIR)/$(NATIVE)
OBJ_UBUNTU64 := $(OBJDIR)/$(UBUNTU64)
OBJ_WIN64    := $(OBJDIR)/$(WIN64)
OBJ_DARWIN   := $(OBJDIR)/$(DARWIN)
OBJ_REDHAT   := $(OBJDIR)/$(REDHAT)

# Targets that don't build anything
.PHONY: clean
clean::
	rm -rf $(OBJDIR) $(BINDIR)
