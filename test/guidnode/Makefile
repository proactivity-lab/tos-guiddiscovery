COMPONENT ?= NodeC

MAKEFILE_LOCATION := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

$(info --------------------------------------------------------------------------------)
TOSH_DATA_LENGTH ?= 114
PFLAGS += -DTOSH_DATA_LENGTH=$(TOSH_DATA_LENGTH)
$(info TOSH_DATA_LENGTH=$(TOSH_DATA_LENGTH))
$(info --------------------------------------------------------------------------------)

PFLAGS += -DTASKLET_IS_TASK

PFLAGS += -I$(MAKEFILE_LOCATION)

PFLAGS += -I../../tos

GUID_DISCOVERY_PERIOD_MS ?= 0
ifneq ($(GUID_DISCOVERY_PERIOD_MS),0)
	PFLAGS += -DGUID_DISCOVERY_PERIOD_MS=$(GUID_DISCOVERY_PERIOD_MS)
endif

# Logging
PLATFORM_BAUDRATE ?= 500000UL
BASE_LOG_LEVEL ?= 0xFFFF

PFLAGS += -DSW_MAJOR_VERSION=0
PFLAGS += -DSW_MINOR_VERSION=0
PFLAGS += -DSW_PATCH_VERSION=0

# Radio conf
RADIO_CHANNEL ?= 25

$(info --------------------------------------------------------------------------------)
include $(TINYOS_ROOT_DIR)/Makefile.include
$(call TOSMake_include,extras/groundlib.extra)
$(call TOSMake_include,extras/watchdogs.extra)
$(info --------------------------------------------------------------------------------)
