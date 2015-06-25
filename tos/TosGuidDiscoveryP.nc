/**
 * @author Raido Pahtma
 * @license MIT
*/
generic module TosGuidDiscoveryP() {
	uses {
		interface Receive;
		interface Packet;
		interface AMPacket;
		interface AMSend;

		interface LocalIeeeEui64;
	}
}
implementation {

	#define __MODUUL__ "gdds"
	#define __LOG_LEVEL__ ( LOG_LEVEL_GuidDiscovery & BASE_LOG_LEVEL )
	#include "log.h"

	#include "TosGuidDiscovery.h"

	bool m_sending = FALSE;

	message_t m_msg;

	error_t createResponse(message_t* msg, am_addr_t destination)
	{
		GuidDiscovery_t* resp = call AMSend.getPayload(msg, sizeof(GuidDiscovery_t));
		if(resp != NULL)
		{
			ieee_eui64_t id = call LocalIeeeEui64.getId();
			resp->header = GUIDDISCOVERY_RESPONSE;
			memcpy(resp->guid, id.data, IEEE_EUI64_LENGTH);
			call Packet.setPayloadLength(msg, sizeof(GuidDiscovery_t));
			call AMPacket.setDestination(msg, destination);
			return SUCCESS;
		}
		else err3("gPl(%u)", sizeof(GuidDiscovery_t));

		return FAIL;
	}

	task void send()
	{
		if(m_sending == FALSE)
		{
			error_t err = call AMSend.send(call AMPacket.destination(&m_msg), &m_msg, call Packet.payloadLength(&m_msg));
			if(err == SUCCESS)
			{
				debug1("snd %p", &m_msg);
				m_sending = TRUE;
			}
			else warn1("snd %p %u", &m_msg, err);
		}
	}

	bool isBroadcastGuid(uint8_t guid[IEEE_EUI64_LENGTH])
	{
		uint8_t i;
		for(i=0;i<IEEE_EUI64_LENGTH;i++)
		{
			if(guid[i] != 0xFF)
			{
				return FALSE;
			}
		}
		return TRUE;
	}

	bool isMyGuid(uint8_t guid[IEEE_EUI64_LENGTH])
	{
		ieee_eui64_t id = call LocalIeeeEui64.getId();
		return memcmp(id.data, guid, IEEE_EUI64_LENGTH) == 0;
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
	{
		if(len == sizeof(GuidDiscovery_t))
		{
			GuidDiscovery_t* p = (GuidDiscovery_t*)payload;
			if(p->header == GUIDDISCOVERY_REQUEST)
			{
				if(m_sending == FALSE)
				{
					// Destination broadcast and specific GUID
					// Destination unicast and broadcast GUID
					// Destination broadcast and broadcast GUID
					if(isBroadcastGuid((uint8_t*)(p->guid)) || isMyGuid((uint8_t*)(p->guid)))
					{
						if(createResponse(&m_msg, call AMPacket.source(msg)) == SUCCESS)
						{
							post send();
						}
					}
					else debugb1("!4me %04X", p->guid, IEEE_EUI64_LENGTH, call AMPacket.destination(msg));
				}
				else warn1("bsy");
			}
			else if(p->header == GUIDDISCOVERY_RESPONSE)
			{
				warn1("Response TODO");
			}
			else warn1("hdr %u", p->header);
		}
		else warn1("len %u != %u", len, sizeof(GuidDiscovery_t));

		return msg;
	}

	event void AMSend.sendDone(message_t* msg, error_t error)
	{
		logger(error == SUCCESS ? LOG_DEBUG1 : LOG_WARN1, "snt(%p, %u)", msg, error);
		m_sending = FALSE;
	}

}