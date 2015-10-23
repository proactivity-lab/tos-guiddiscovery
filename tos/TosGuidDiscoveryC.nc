/**
 * @author Raido Pahtma
 * @license MIT
*/
configuration TosGuidDiscoveryC { }
implementation {

	#include "TosGuidDiscovery.h"

	components new TosGuidDiscoveryP();

	components new AMSenderC(AMID_GUIDDISCOVERY);
	TosGuidDiscoveryP.AMSend -> AMSenderC;
	TosGuidDiscoveryP.AMPacket -> AMSenderC;
	TosGuidDiscoveryP.Packet -> AMSenderC;

	components new AMReceiverC(AMID_GUIDDISCOVERY);
	TosGuidDiscoveryP.Receive -> AMReceiverC;

	components GlobalPoolC;
	TosGuidDiscoveryP.MessagePool -> GlobalPoolC;

	components LocalIeeeEui64C;
	TosGuidDiscoveryP.LocalIeeeEui64 -> LocalIeeeEui64C;

}
