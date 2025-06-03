ifeq ($(SIMULATOR),1)
	ARCHS = arm64
	TARGET = simulator:clang:latest:15.0
else
    export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/
	TARGET = iphone:clang:14.5:13.0
	ARCHS = arm64 arm64e
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoSwiftAtRuntime

$(TWEAK_NAME)_FILES = Tweak.x
ifeq ($(SIMULATOR),1)
$(TWEAK_NAME)_FRAMEWORKS = UIKit
$(TWEAK_NAME)_EXTRA_FRAMEWORKS = CydiaSubstrate
$(TWEAK_NAME)_USE_SUBSTRATE = 1
endif

include $(THEOS_MAKE_PATH)/tweak.mk

ifeq ($(SIMULATOR),1)
setup:: clean all
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject/$(TWEAK_NAME).plist
endif
