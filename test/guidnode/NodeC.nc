/**
 * @author Raido Pahtma
 * @license MIT
*/
#include "logger.h"
configuration NodeC { }
implementation {

	components BootInfoC;
	components MCUSRInfoC;

	components new TimerWatchdogC(5000);

	components TosGuidDiscoveryC;

#ifdef GUID_DISCOVERY_PERIOD_MS
	components new GuidDiscovererC(GUID_DISCOVERY_PERIOD_MS);
#endif // GUID_DISCOVERY_PERIOD_MS

	components MainC;

	components ActiveMessageC as Radio;

	components new Boot2SplitControlC("slbt", "rdo");
	Boot2SplitControlC.Boot -> MainC.Boot;
	Boot2SplitControlC.SplitControl -> Radio;

}
