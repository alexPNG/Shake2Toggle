INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = armv7 arm64 arm64e
TARGET = iphone:clang::7.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Shake2Toggle
Shake2Toggle_FILES = Tweak.xm
Shake2Toggle_CFLAGS = -fobjc-arc
Shake2Toggle_FRAMEWORKS = AVFoundation
Shake2Toggle_PRIVATE_FRAMEWORKS = MediaRemote AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
