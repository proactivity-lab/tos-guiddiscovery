generic configuration GuidDiscovererC(uint32_t period_ms) { }
implementation {

	components new GuidDiscovererP(period_ms);

	components new TimerMilliC();
	GuidDiscovererP.Timer -> TimerMilliC;

	components TosGuidDiscoveryC;
	GuidDiscovererP.GuidDiscovery -> TosGuidDiscoveryC;

	components MainC;
	GuidDiscovererP.Boot -> MainC;

}
