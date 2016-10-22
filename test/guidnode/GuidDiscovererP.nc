generic module GuidDiscovererP(uint32_t g_period_ms) {
	uses {
		interface GuidDiscovery;
		interface Timer<TMilli>;
		interface Boot;
	}
}
implementation {

	#define __MODUUL__ "gdcr"
	#define __LOG_LEVEL__ ( LOG_LEVEL_GuidDiscovererP & BASE_LOG_LEVEL )
	#include "log.h"

	am_addr_t m_addr = 0;

	event void Boot.booted() {
		call Timer.startPeriodic(g_period_ms);
	}

	event void Timer.fired() {
		info1("discover %04X", m_addr);
		call GuidDiscovery.discoverGuid(m_addr);
		m_addr++;
	}

	event void GuidDiscovery.discovered(ieee_eui64_t* guid, am_addr_t addr) {
		infob1("discovered %04X", guid->data, sizeof(guid->data), addr);
	}

}
