# ------------------------------------------------------------------------------
# Taken from http://owensd.io/blog/swift-makefiles---take-2/ and adapted.
# ------------------------------------------------------------------------------
.SILENT:

# USER CONFIGURABLE SETTINGS ##
CONFIG       = debug
PLATFORM     = macosx
ARCH         = x86_64
MODULE_NAME  = main
MACH_O_TYPE  = mh_execute

## GLOBAL SETTINGS ##
ROOT_DIR            = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR           = $(ROOT_DIR)/bin
SRC_DIR             = $(ROOT_DIR)/Source
LIB_DIR             = $(ROOT_DIR)/lib
CLIBTIFF_DIR        = $(ROOT_DIR)/Packages/CLibTIFF-1.0.12
INCLUDE_DIR         = $(CLIBTIFF_DIR)/Source/include/ /usr/local/include
LIBRARY_DIR         = $(CLIBTIFF_DIR)/bin/CLibTIFF/bin/debug/macosx/ /usr/local/lib/

TOOLCHAIN           = Toolchains/swift-LOCAL-2016-04-12/usr/lib/swift/$(PLATFORM)
TOOLCHAIN_PATH      = /Library/Developer/

SWIFT               = $(shell xcrun -f swiftc) -frontend -c -color-diagnostics

## COMPILER SETTINGS ##
CFLAGS       = -g -Onone
SDK_PATH     = $(shell xcrun --show-sdk-path -sdk $(PLATFORM))

## LINKER SETTINGS ##
LD           = $(shell xcrun -f ld)
LDFLAGS      = -syslibroot $(SDK_PATH) -lSystem -arch $(ARCH) \
	       -macosx_version_min 10.10.0 \
	       -no_objc_category_merging -L $(TOOLCHAIN_PATH) \
	       -rpath $(TOOLCHAIN_PATH)
OBJ_EXT      = 
OBJ_PRE      =

ifeq (mh_dylib, $(MACH_O_TYPE))
    OBJ_EXT  = .dylib
    OBJ_PRE  = lib
    LDFLAGS += -dylib
endif

## BUILD LOCATIONS ##
PLATFORM_BUILD_DIR    = $(BUILD_DIR)/$(MODULE_NAME)/bin/$(CONFIG)/$(PLATFORM)
PLATFORM_OBJ_DIR      = $(BUILD_DIR)/$(MODULE_NAME)/obj/$(CONFIG)/$(PLATFORM)
PLATFORM_TEMP_DIR     = $(BUILD_DIR)/$(MODULE_NAME)/tmp/$(CONFIG)/$(PLATFORM)

SOURCE = $(notdir $(wildcard $(SRC_DIR)/*.swift))

## BUILD TARGETS ##
tool: setup $(SOURCE) link clibtiff

## COMPILE RULES FOR FILES ##

%.swift:
	$(SWIFT) $(CFLAGS) -primary-file $(SRC_DIR)/$@ \
	    $(addprefix $(SRC_DIR)/,$(filter-out $@,$(SOURCE))) -sdk $(SDK_PATH) \
	    -module-name $(MODULE_NAME) -o $(PLATFORM_OBJ_DIR)/$*.o -emit-module \
	    -emit-module-path $(PLATFORM_OBJ_DIR)/$*~partial.swiftmodule \
	    $(addprefix -L,$(LIBRARY_DIR)) \
	    $(addprefix -I,$(INCLUDE_DIR))

main.swift:
	$(SWIFT) $(CFLAGS) -primary-file $(SRC_DIR)/main.swift \
	    $(addprefix $(SRC_DIR)/,$(filter-out $@,$(SOURCE))) -sdk $(SDK_PATH) \
	    -module-name $(MODULE_NAME) -o $(PLATFORM_OBJ_DIR)/main.o -emit-module \
	    -emit-module-path $(PLATFORM_OBJ_DIR)/main~partial.swiftmodule \
	    $(addprefix -L,$(LIBRARY_DIR)) \
	    $(addprefix -I,$(INCLUDE_DIR))

clibtiff:
	make -C $(ROOT_DIR)/Packages/CLibTIFF*/

link:
	$(LD) $(LDFLAGS) $(wildcard $(PLATFORM_OBJ_DIR)/*.o) \
	    -o $(PLATFORM_BUILD_DIR)/$(OBJ_PRE)$(MODULE_NAME)$(OBJ_EXT) \
	    $(addprefix -L, $(LIBRARY_DIR)) -lCLibTIFF -ltiff \
	    -L /Library/Developer/Toolchains/swift-LOCAL-2016-04-12-a.xctoolchain/usr/lib/swift/macosx/ \
	    -rpath /Library/Developer/Toolchains/swift-LOCAL-2016-04-12-a.xctoolchain/usr/lib/swift/macosx/

setup:
	$(shell mkdir -p $(PLATFORM_BUILD_DIR))
	$(shell mkdir -p $(PLATFORM_OBJ_DIR))
	$(shell mkdir -p $(PLATFORM_TEMP_DIR))

