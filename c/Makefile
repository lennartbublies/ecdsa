# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
# Portions Copyright (C) Philipp Kewisch, 2016

CFLAGS ?= -Wall -Werror -g
CC ?= clang
VALGRIND ?= valgrind
VALGRINDFLAGS ?= --track-origins=yes --leak-check=full --show-reachable=yes
KEYSIZE ?= 25

BUILDDIR = build
TESTSRC = src/eccprint.c src/eccmath.c src/eccmemory.c src/ecdsa.c src/sha256.c test/test_check.c

ifdef TEST_VERBOSE
DEFINES += -DTEST_VERBOSE
endif
ifdef KEYSIZE
DEFINES += -DKEYSIZE=$(KEYSIZE)
endif

HDR = $(wildcard include/*.h)
TESTOBJ = $(TESTSRC:%.c=%.o)

CFLAGS_INCLUDES = -Isrc -Iinclude

all: test

.PHONY: test testbuild clean run valgrind

%.o: %.c
	$(CC) $(CFLAGS) $(CFLAGS_INCLUDES) $(LDFLAGS) $(DEFINES) -c $< -o $(BUILDDIR)/$(notdir $@)

clean:
	$(RM) -r $(BUILDDIR)/* ecc *.dSYM

testbuild: $(HDR) $(TESTOBJ)
	$(CC) $(CFLAGS) $(CFLAGS_INCLUDES) $(LDFLAGS) -o $(BUILDDIR)/test $(DEFINES)  $(addprefix $(BUILDDIR)/,$(notdir $(TESTOBJ)))

test: testbuild
	$(BUILDDIR)/test
test-%: testbuild
	$(BUILDDIR)/test $*

valgrind:
	$(VALGRIND) $(VALGRINDFLAGS) $(BUILDDIR)/test
