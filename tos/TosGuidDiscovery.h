#ifndef TOSGUIDDISCOVERY_H_
#define TOSGUIDDISCOVERY_H_

#include "IeeeEui64.h"

#define AMID_GUIDDISCOVERY 0xFC

enum GuidDiscoveryHeaders {
	GUIDDISCOVERY_REQUEST = 1,
	GUIDDISCOVERY_RESPONSE = 2
};

typedef struct GuidDiscovery_t {
	nx_uint8_t header;
	nx_uint8_t guid[IEEE_EUI64_LENGTH];
} GuidDiscovery_t;

#endif // TOSGUIDDISCOVERY_H_