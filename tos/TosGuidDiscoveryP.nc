/**
 * @author Raido Pahtma
 * @license MIT
*/
generic module TosGuidDiscoveryP() {
	provides {
		interface GuidDiscovery;
	}
	uses {
		interface Receive;
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface Pool<message_t> as MessagePool;

		interface LocalIeeeEui64;
	}
}
implementation {

	#define __MODUUL__ "gdds"
	#define __LOG_LEVEL__ ( LOG_LEVEL_TosGuidDiscoveryP & BASE_LOG_LEVEL )
	#include "log.h"

	#include "TosGuidDiscovery.h"

	bool m_sending = FALSE;

	uint8_t createResponse(message_t* msg) {
		GuidDiscovery_t* resp = (GuidDiscovery_t*)call AMSend.getPayload(msg, sizeof(GuidDiscovery_t));
		if(resp != NULL) {
			ieee_eui64_t id = call LocalIeeeEui64.getId();
			resp->header = GUIDDISCOVERY_RESPONSE;
			memcpy(resp->guid, id.data, IEEE_EUI64_LENGTH);
			return sizeof(GuidDiscovery_t);
		}

		err3("gPl(%u)", sizeof(GuidDiscovery_t));
		return 0;
	}

	bool isBroadcastGuid(uint8_t guid[IEEE_EUI64_LENGTH]) {
		uint8_t i;
		for(i=0;i<IEEE_EUI64_LENGTH;i++) {
			if(guid[i] != 0xFF) {
				return FALSE;
			}
		}
		return TRUE;
	}

	bool isMyGuid(uint8_t guid[IEEE_EUI64_LENGTH]) {
		ieee_eui64_t id = call LocalIeeeEui64.getId();
		return memcmp(id.data, guid, IEEE_EUI64_LENGTH) == 0;
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(GuidDiscovery_t)) {
			GuidDiscovery_t* p = (GuidDiscovery_t*)payload;
			if(p->header == GUIDDISCOVERY_REQUEST) {
				// Destination broadcast and specific GUID
				// Destination unicast and broadcast GUID
				// Destination broadcast and broadcast GUID
				if(isBroadcastGuid((uint8_t*)(p->guid)) || isMyGuid((uint8_t*)(p->guid))) {
					if(m_sending == FALSE) {
						message_t* response = call MessagePool.get();
						if(response != NULL) {
							uint8_t length = createResponse(response);
							if(length > 0) {
								error_t err = call AMSend.send(call AMPacket.source(msg), response, length);
								if(err == SUCCESS) {
									debug1("snd %p", response);
									m_sending = TRUE;
									return msg;
								}
								else warn1("snd %p %u", response, err);
							}
							else warn1("rsp");

							call MessagePool.put(response);
						}
						else warn1("pool");
					}
					else warn1("bsy");
				}
				else debugb1("!4me %04X", p->guid, IEEE_EUI64_LENGTH, call AMPacket.destination(msg));
			}
			else if(p->header == GUIDDISCOVERY_RESPONSE) {
				ieee_eui64_t guid;
				am_addr_t addr = call AMPacket.source(msg);
				memcpy(guid.data, p->guid, IEEE_EUI64_LENGTH);
				debugb1("guid %04X", guid.data, IEEE_EUI64_LENGTH, addr);
				signal GuidDiscovery.discovered(&guid, addr);
			}
			else warn1("hdr %u", p->header);
		}
		else warn1("len %u != %u", len, sizeof(GuidDiscovery_t));

		return msg;
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		logger(error == SUCCESS ? LOG_DEBUG1 : LOG_WARN1, "snt(%p, %u)", msg, error);
		call MessagePool.put(msg);
		m_sending = FALSE;
	}

	error_t sendQuery(ieee_eui64_t* guid, am_addr_t addr) {
		if(m_sending == FALSE) {
			message_t* msg = call MessagePool.get();
			if(msg != NULL) {
				error_t err;
				GuidDiscovery_t* qry = (GuidDiscovery_t*)call AMSend.getPayload(msg, sizeof(GuidDiscovery_t));
				if(qry != NULL) {
					qry->header = GUIDDISCOVERY_REQUEST;
					memcpy(qry->guid, guid->data, IEEE_EUI64_LENGTH);

					err = call AMSend.send(addr, msg, sizeof(GuidDiscovery_t));
					if(err == SUCCESS) {
						debug1("qry %p", msg);
						m_sending = TRUE;
						return SUCCESS;
					}
					else warn1("snd %p %u", msg, err);
				}
				else {
					err = EINVAL;
					err3("gPl(%u)", sizeof(GuidDiscovery_t));
				}

				call MessagePool.put(msg);
				return err;
			}
			return ENOMEM;
		}
		return EBUSY;
	}

	command error_t GuidDiscovery.discoverAddress(ieee_eui64_t* guid) {
		return sendQuery(guid, AM_BROADCAST_ADDR);
	}

	command error_t GuidDiscovery.discoverGuid(am_addr_t addr) {
		if(addr != 0 && addr != AM_BROADCAST_ADDR) {
			ieee_eui64_t guid;
			memset(guid.data, 0xFF, IEEE_EUI64_LENGTH);
			return sendQuery(&guid, addr);
		}
		err3("%04X", addr);
		return EINVAL;
	}

	default event void GuidDiscovery.discovered(ieee_eui64_t* guid, am_addr_t addr) { }

}
