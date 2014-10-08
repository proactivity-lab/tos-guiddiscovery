COMPONENT=GuidNodeC

$(info --------------------------------------------------------------------------------)
ifndef DIR_SHARED_TOS
    $(error Please define DIR_SHARED_TOS)
endif

$(info DIR_SHARED_TOS:      $(DIR_SHARED_TOS))
$(info --------------------------------------------------------------------------------)

# Include .extra files from root directory
TOSMAKE_PATH=.

CFLAGS += -I$(PWD)
CFLAGS += -I../../tos

TOSH_DATA_LENGTH ?= 110

# Logging
PLATFORM_BAUDRATE ?= 500000UL
BASE_LOG_LEVEL ?= 0xFFFF

# Radio conf
RADIO_CHANNEL ?= 25

CFLAGS += -DTASKLET_IS_TASK

$(info --------------------------------------------------------------------------------)

include $(DIR_SHARED_TOS)/include.mk
