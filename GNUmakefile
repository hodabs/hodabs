include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = hodabs
VERSION = 0.0.1

CC=clang

TOOL_NAME = HODABS

${TOOL_NAME}_OBJCFLAGS = -fobjc-arc
${TOOL_NAME}_BUNDLE_LIBS += -lobjc -lgnustep-base
${TOOL_NAME}_OBJC_FILES = main.m hodabs.m actions.m

include $(GNUSTEP_MAKEFILES)/tool.make
