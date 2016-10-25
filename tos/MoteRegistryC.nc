/*
 * @author Raido Pahtma
 * @license MIT
 */
#include "MoteRegistry.h"
configuration MoteRegistryC {
	provides interface MoteRegistry;
}
implementation {

	components new MoteRegistryP(MOTEREGISTRY_SIZE);
	MoteRegistry = MoteRegistryP;

	components MainC;
	MainC.SoftwareInit -> MoteRegistryP.Init;
	MoteRegistryP.Boot -> MainC.Boot;

	components new TimerMilliC();
	MoteRegistryP.Timer -> TimerMilliC;

	components LocalTimeSecondC;
	MoteRegistryP.LocalTimeSecond -> LocalTimeSecondC;

	components LocalIeeeEui64C;
	MoteRegistryP.LocalIeeeEui64 -> LocalIeeeEui64C;

	components TosGuidDiscoveryC;
	MoteRegistryP.GuidDiscovery -> TosGuidDiscoveryC;

}
