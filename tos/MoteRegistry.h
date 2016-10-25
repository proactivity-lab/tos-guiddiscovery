#ifndef MOTEREGISTRY_H_
#define MOTEREGISTRY_H_

#ifndef MOTEREGISTRY_SIZE
#define MOTEREGISTRY_SIZE 32
#endif // MOTEREGISTRY_SIZE

/**
 * Locally assigned partner identifier. Self is 0, < 0 means unknown.
 */
typedef int16_t local_mote_id_t;

#endif /* MOTEREGISTRY_H_ */
