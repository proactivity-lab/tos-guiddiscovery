/*
 * @author Raido Pahtma
 * @license MIT
 */
generic module MoteRegistryP(uint8_t registry_size) {
	provides {
		interface Init;
		interface MoteRegistry;
	}
	uses {
		interface Timer<TMilli>;
		interface LocalTime<TSecond> as LocalTimeSecond;
		interface GuidDiscovery;
		interface LocalIeeeEui64;
		interface Boot;
	}
}
implementation {

	#define __MODUUL__ "mreg"
	#define __LOG_LEVEL__ ( LOG_LEVEL_MoteRegistryP & BASE_LOG_LEVEL )
	#include "log.h"

	typedef struct registered_mote {
		ieee_eui64_t guid;
		am_addr_t addr;
		uint32_t contact;
		uint8_t count;
	} registered_mote_t;

	registered_mote_t m_motes[registry_size];

	uint8_t m_null[IEEE_EUI64_LENGTH];

	command error_t Init.init() {
		uint8_t i;
		for(i=0;i<registry_size;i++) {
			memset(m_motes[i].guid.data, 0, sizeof(m_motes[i].guid.data));
			m_motes[i].addr = 0;
			m_motes[i].contact = 0;
			m_motes[i].count = 0;
		}
		memset(m_null, 0, sizeof(m_null));
		return SUCCESS;
	}

	event void Boot.booted() {
		m_motes[0].guid = call LocalIeeeEui64.getId();
		m_motes[0].addr = TOS_NODE_ID;
		call Timer.startPeriodic(60*1000UL);
	}

	event void Timer.fired() {
		uint8_t discover = 0;
		uint32_t last = UINT32_MAX;
		uint8_t i;
		for(i=1;i<registry_size;i++) { // Find the oldes undiscovered entry
			if((m_motes[i].count > 0)&&(m_motes[i].addr == 0)) {
				if(m_motes[i].contact < last) {
					discover = i;
					last = m_motes[i].contact;
				}
			}
		}
		if(last < UINT32_MAX) {
			debugb1("dsc", m_motes[discover].guid.data, IEEE_EUI64_LENGTH);
			if(call GuidDiscovery.discoverAddress(&(m_motes[discover].guid)) == SUCCESS) {
				m_motes[discover].contact = call LocalTimeSecond.get();
			}
			else warn1("bsy");
			call Timer.startOneShot(5*1000UL);
			return;
		}
		debug1("none");
		call Timer.startOneShot(60*1000UL);
	}

	event void GuidDiscovery.discovered(ieee_eui64_t* guid, am_addr_t addr) {
		uint8_t i;
		for(i=1;i<registry_size;i++) {
			if(memcmp(guid->data, m_motes[i].guid.data, IEEE_EUI64_LENGTH) == 0) {
				m_motes[i].addr = addr;
				m_motes[i].contact = call LocalTimeSecond.get();
			}
			else if(m_motes[i].addr == addr) { // other nodes cannot have this address
				m_motes[i].addr = 0;
			}
			break;
		}
		for(;i<registry_size;i++) { // check remaining nodes for address conflicts
			if(m_motes[i].addr == addr) {
				m_motes[i].addr = 0;
			}
		}
	}

	command am_addr_t MoteRegistry.getAddr(local_mote_id_t mote) {
		if((mote >= 0) && (mote <= registry_size)) {
			return m_motes[mote].addr;
		}
		return 0;
	}

	command ieee_eui64_t* MoteRegistry.getGuid(ieee_eui64_t* guid, local_mote_id_t mote) {
		if((mote >= 0) && (mote <= registry_size)) {
			if(memcmp(m_motes[mote-1].guid.data, m_null, IEEE_EUI64_LENGTH) != 0) {
				memcpy(guid->data, m_motes[mote-1].guid.data, IEEE_EUI64_LENGTH);
				return guid;
			}
		}
		return NULL;
	}

	command uint8_t* MoteRegistry.getGuidBuffer(local_mote_id_t mote) {
		if((mote >= 0) && (mote <= registry_size)) {
			return m_motes[mote].guid.data;
		}
		return m_null;
	}

	command local_mote_id_t MoteRegistry.getMote(ieee_eui64_t* guid, am_addr_t addr) {
		uint8_t i;
		if(guid != NULL) {
			for(i=0;i<registry_size;i++) {
				if(memcmp(guid->data, m_motes[i].guid.data, IEEE_EUI64_LENGTH) == 0) {
					return i;
				}
			}
		}
		else if(addr != 0) {
			for(i=0;i<registry_size;i++) {
				if(m_motes[i].addr == addr) { // other nodes cannot have this address
					m_motes[i].addr = 0;
				}
			}
		}
		return -1;
	}

	command local_mote_id_t MoteRegistry.registerMote(ieee_eui64_t* guid) {
		if(guid != NULL) {
			uint8_t i;
			for(i=0;i<registry_size;i++) {
				if(memcmp(guid->data, m_motes[i].guid.data, IEEE_EUI64_LENGTH) == 0) {
					m_motes[i].count++;
					return i;
				}
			}
			for(i=1;i<registry_size;i++) {
				if(memcmp(m_null, m_motes[i].guid.data, IEEE_EUI64_LENGTH) == 0) {
					memcpy(m_motes[i].guid.data, guid->data, IEEE_EUI64_LENGTH);
					m_motes[i].addr = 0;
					m_motes[i].count = 1;
					m_motes[i].contact = call LocalTimeSecond.get();
					return i;
				}
			}
		}
		return -1;
	}

	command void MoteRegistry.deregisterMote(local_mote_id_t mote) {
		if((mote > 0)&&(mote <= registry_size)) { // don't bother with self
			if(m_motes[mote].count > 0) {
				m_motes[mote].count--;
			}
			if(m_motes[mote].count == 0) {
				memset(m_motes[mote].guid.data, 0, IEEE_EUI64_LENGTH);
			}
		}
	}

}
