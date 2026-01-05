# -*- encoding: utf-8 -*-
"""
keri.kli.commands.oobi module

"""
import argparse

from hio.base import doing

from keri import help
from keri.app.cli.common.parsing import Parsery
import keri.app.oobiing
from keri.app import habbing, oobiing
from keri.app.cli.common import existing
from keri.db import basing
from keri.help import helping

logger = help.ogler.getLogger()

parser = argparse.ArgumentParser(description="Resolve the provided OOBI", 
                                 parents=[Parsery.keystore()])
parser.set_defaults(handler=lambda args: resolve(args))
parser.add_argument("--oobi", "-o", help="out-of-band introduciton to load", required=True)
parser.add_argument("--oobi-alias", dest="oobiAlias", help="alias for AID resolved from out-of-band introduciton",
                    required=False, default=None)
parser.add_argument('--force', action="store_true", required=False,
                    help='True means to resolve OOBI even if it has already been previously resolved')


def resolve(args):
    """ command line method for resolving oobies

    Parameters:
        args(Namespace): parse args namespace object

    """
    name = args.name
    base = args.base
    bran = args.bran
    oobi = args.oobi
    oobiAlias = args.oobiAlias
    force = args.force

    icpDoer = OobiDoer(name=name, oobi=oobi, bran=bran, base=base, oobiAlias=oobiAlias, force=force)

    doers = [icpDoer]
    return doers


class OobiDoer(doing.DoDoer):
    """ DoDoer for loading oobis and waiting for the results """

    def __init__(self, name, oobi, oobiAlias, force=False, bran=None, base=None):

        self.processed = 0
        self.oobi = oobi
        self.force = force
        self.hby = existing.setupHby(name=name, base=base, bran=bran)
        self.hbyDoer = habbing.HaberyDoer(habery=self.hby)

        obr = basing.OobiRecord(date=helping.nowIso8601())
        if oobiAlias is not None:
            obr.oobialias = oobiAlias

        self.hby.db.oobis.put(keys=(oobi,), val=obr)

        self.obi = keri.app.oobiing.Oobiery(hby=self.hby)
        self.authn = oobiing.Authenticator(hby=self.hby)
        doers = [self.hbyDoer, doing.doify(self.waitDo)]

        super(OobiDoer, self).__init__(doers=doers)

    def waitDo(self, tymth, tock=0.0, **kwa):
        ## XXX: This doc comment states it returns a Callable, but no such statement exists
        """ Waits for oobis to load

        Parameters:
            tymth (function): injected function wrapper closure returned by .tymen() of
                Tymist instance. Calling tymth() returns associated Tymist .tyme.
            tock (float): injected initial tock value

        Returns:  doifiable Doist compatible generator method for loading oobis using
        the Oobiery
        """
        ## XXX: This sounds like a good candidate for eventual rewriting using the context manager protocol ('with' blocks)
        # enter context
        self.wind(tymth)
        self.tock = tock
        _ = (yield self.tock)

        ## XXX: Loop counter and max timeout values
        count: int = 0
        loop_max: int = 60 # With a .25s wait, this is 15s, not counting any applicable timeouts further in the call chain

        if self.force:  # if --force specified, remove previous record of OOBI resolution
            self.hby.db.roobi.rem(keys=(self.oobi,))

        self.extend(self.obi.doers)
        self.extend(self.authn.doers)

        ## XXX: Is there an error/timeout cutoff?
        while not self.obi.hby.db.roobi.get(keys=(self.oobi,)):
            if count < loop_max:
                logger.info(f"Entered 'oobiDoer.waitDo()' loop, iteration #{count}/{loop_max}")
                yield 0.25
                count += 1
            else:
                raise Exception(f"OOBI Resolution Timed out after {loop_max} tries")

        ## XXX: This mechod chain makes no sense without additional context, looks like a call to the habitat to do a database lookup for the given key
        obr = self.obi.hby.db.roobi.get(keys=(self.oobi,))
        if self.force:
            while obr.cid not in self.hby.kevers:
                self.hby.kvy.processEscrows()
                yield 0.25

        print(self.oobi, obr.state)

        self.remove([self.hbyDoer, *self.obi.doers, *self.authn.doers])
