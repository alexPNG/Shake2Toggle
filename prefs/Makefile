ARCHS = armv7 arm64 arm64e
TARGET = iphone:clang::7.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Shake2Toggle
Shake2Toggle_FILES = $(wildcard *.m)
Shake2Toggle_INSTALL_PATH = /Library/PreferenceBundles
Shake2Toggle_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/$(BUNDLE_NAME).plist$(ECHO_END)
