"""guidapp.py: GUID discovery application for TinyOS devices."""

from queue import Queue
import datetime
import threading
import signal
import struct
import time

import argparse
from argconfparse.argconfparse import ConfigArgumentParser, arg_hex2int, arg_check_hex16str

from moteconnection.connection import Connection
from moteconnection.message import MessageDispatcher, Message, AM_BROADCAST_ADDR

import logging
log = logging.getLogger(__name__)

__author__ = "Raido Pahtma"
__license__ = "MIT"


AMID_GUIDDISCOVERY = 0xFC


def printred(s):
    print("\033[91m{}\033[0m".format(s))


def printgreen(s):
    print("\033[92m{}\033[0m".format(s))


class DiscoPacket(object):
    GUIDDISCOVERY_REQUEST = 1
    GUIDDISCOVERY_RESPONSE = 2
    structformat = "!B8s"
    structsize = struct.calcsize(structformat)
    # typedef struct GuidDiscovery_t {
    #    nx_uint8_t header;
    #    nx_uint8_t guid[IEEE_EUI64_LENGTH];
    # } GuidDiscovery_t;

    def __init__(self, header=0, guid="0000000000000000"):
        self.header = header
        self._guid = None
        self.guid = guid

    @property
    def guid(self):
        return self._guid.encode("hex").upper()

    @guid.setter
    def guid(self, guid):
        self._guid = guid.decode("hex")

    def serialize(self):
        return struct.pack(self.structformat, self.header, self._guid)

    def deserialize(self, payload):
        if len(payload) == self.structsize:
            self.header, self._guid = struct.unpack(self.structformat, payload)

            if (self.header != self.GUIDDISCOVERY_REQUEST) and (self.header != self.GUIDDISCOVERY_RESPONSE):
                raise ValueError("bad header {}".format(self.header))
        else:
            raise ValueError("payload too short {}".format(len(payload)))

    def __str__(self):
        if self.header == self.GUIDDISCOVERY_REQUEST:
            header = "REQ"
        elif self.header == self.GUIDDISCOVERY_RESPONSE:
            header = "RES"
        else:
            header = "???"

        return "{:s} {:s}".format(header, self.guid)


class GUIDDisco(object):

    def __init__(self, connection, args):
        self._dest = args.dest
        self._guid = args.guid
        self._response = args.response

        self._incoming = Queue()
        self._dispatcher = MessageDispatcher(args.address, args.group)
        self._dispatcher.register_receiver(AMID_GUIDDISCOVERY, self._incoming)

        assert isinstance(connection, Connection)
        self._connection = connection
        self._connection.register_dispatcher(self._dispatcher)

    def run(self):
        while not self._incoming.empty():
            self.receive(self._incoming.get())
        self._send()

    @staticmethod
    def _ts_now():
        now = datetime.datetime.utcnow()
        s = now.strftime("%Y-%m-%d %H:%M:%S")
        return s + ".%03uZ" % (now.microsecond / 1000)

    def _send(self):
        self._start = time.time()

        p = DiscoPacket(DiscoPacket.GUIDDISCOVERY_REQUEST, self._guid)

        if self._response:
            p.header = DiscoPacket.GUIDDISCOVERY_RESPONSE

        packet = Message()
        packet.destination = self._dest
        packet.source = self._dispatcher.address
        packet.type = AMID_GUIDDISCOVERY
        packet.payload = p.serialize()

        print("{} disco {:04X}->{:04X} {:s}".format(self._ts_now(), self._dispatcher.address, self._dest, p))

        self._connection.send(packet)

    def receive(self, packet):
        try:
            p = DiscoPacket()
            p.deserialize(packet.payload)

            printgreen("{} reply {:04X}->{:04X} {:s}".format(self._ts_now(), packet.source, packet.destination, p))

        except ValueError as e:
            printred("{} error {:04X}->{:04X} {}".format(self._ts_now(), packet.source, packet.destination, e.message))


def main():
    parser = ConfigArgumentParser("TosPingPong", description="Application arguments",
                                  formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument("--dest", default=AM_BROADCAST_ADDR, type=arg_hex2int,
                        help="Discover GUID of destination address")
    parser.add_argument("--guid", default="FFFFFFFFFFFFFFFF", type=arg_check_hex16str,
                        help="Discover address of GUID")

    parser.add_argument("--connection", default="sf@localhost:9002")
    parser.add_argument("--address", default=0xFFFE, type=arg_hex2int, help="Local address")
    parser.add_argument("--group", default=0x22, type=arg_hex2int, help="Local group")

    parser.add_argument("--response", action="store_true", default=False,
                        help="Send a response packet instead of a request")

    parser.add_argument("--debug", action="store_true", default=False)

    args = parser.parse_args()

    if args.debug:
        # todo setup moteconnection logging
        pass

    interrupted = threading.Event()

    def kbi_handler(sig, frm):
        del sig, frm
        interrupted.set()

    signal.signal(signal.SIGINT, kbi_handler)

    con = Connection()
    con.connect(args.connection, reconnect=5.0)

    disco = GUIDDisco(con, args)
    # disco.start()

    time.sleep(1)
    while not interrupted.is_set():
        disco.run()
        time.sleep(1)

    # disco.join()

    con.disconnect()
    con.join()

    print("done")


if __name__ == '__main__':
    main()
