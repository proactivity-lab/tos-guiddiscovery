/**
 * @author Raido Pahtma
 * @license MIT
 */
interface GuidDiscovery {

	command error_t discoverAddress(ieee_eui64_t* guid);
	command error_t discoverGuid(am_addr_t addr);

	/*
	 * Discovered events may be fired spontaneously and may signal
	 * information that is already known.
	 * It should be assumed that one GUID does not match more than one address
	 * and one address does not match more than one GUID, so
	 */
	event void discovered(ieee_eui64_t* guid, am_addr_t addr);

}
