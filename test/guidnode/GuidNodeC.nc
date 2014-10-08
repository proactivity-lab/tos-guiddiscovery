/**
 * @author Raido Pahtma
 * @license MIT
*/
#include "logger.h"
configuration GuidNodeC {

}
implementation {

	components TosGuidDiscoveryC;

	components MainC;

	components ActiveMessageC as Radio;

	components new Boot2SplitControlC("slbt", "rdo");
	Boot2SplitControlC.Boot -> MainC.Boot;
	Boot2SplitControlC.SplitControl -> Radio;

}