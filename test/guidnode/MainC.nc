#include "hardware.h"
configuration MainC {
	provides interface Boot;
	uses interface Init as SoftwareInit;
}
implementation {

	#warning "guiddisco MainC"

	components RealMainP;
	SoftwareInit = RealMainP.SoftwareInit;

	components PlatformC;
	RealMainP.PlatformInit -> PlatformC;

	components TinySchedulerC;
	RealMainP.Scheduler -> TinySchedulerC;

	#if (defined(PRINTF_PORT) && !defined(TOSSIM))
		#warning "PRINTF enabled"
		#ifndef START_PRINTF_DELAY
			#warning "default START_PRINTF_DELAY 1024"
			#define START_PRINTF_DELAY 1024
		#endif
		components new StartPrintfC(START_PRINTF_DELAY) as Logging;
	#else
		components new DummyBootC() as Logging;
	#endif
		Logging.SysBoot -> RealMainP.Boot;

	components new BootAddressFromIeeeEui64C(2, 1);
	BootAddressFromIeeeEui64C.SysBoot -> Logging.Boot;

	Boot = BootAddressFromIeeeEui64C.Boot;

}
