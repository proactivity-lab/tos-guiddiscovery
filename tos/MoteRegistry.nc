/*
 * @author Raido Pahtma
 * @license MIT
 */
#include "MoteRegistry.h"
interface MoteRegistry {

	// Return 0 if mote not known.
	command am_addr_t getAddr(local_mote_id_t mote);

	// Return NULL if mote not known.
	command ieee_eui64_t* getGuid(ieee_eui64_t* guid, local_mote_id_t mote);

	// Returns pointer to array of 0 if mote not known
	// This should only be used for debugging / printing.
	command uint8_t* getGuidBuffer(local_mote_id_t mote);

	// Set guid to NULL for addr based lookup, set addr to 0 for guid based lookup.
	command local_mote_id_t getMote(ieee_eui64_t* guid, am_addr_t addr);

	// Register link for mote, get an ID assignment.
	// Returns < 0 if unsuccessful.
	command local_mote_id_t registerMote(ieee_eui64_t* guid);

	// deregister mote link, allow mote info to be garbage-collected.
	command void deregisterMote(local_mote_id_t mote);

}
