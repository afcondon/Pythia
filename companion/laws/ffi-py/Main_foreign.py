# Probes for the Python.Kwargs laws. These stand in for the real thing: a
# library entry point that takes keyword arguments.

def _probe(**kw):
    # Report exactly what Python received, so the assertion is about the
    # CALL, not about the dict we handed over.
    if len(kw) == 1 and "only" in kw:
        return repr(kw["only"])
    return "|".join(k + "=" + repr(v) for k, v in sorted(kw.items()))


def probeImpl(kw):
    return _probe(**kw)


def _fixed_arity(algorithm="default", init="flat"):
    # No **kwargs: an unexpected key is a TypeError at call time, exactly as
    # it would be calling pandapower or umap. Defaults show that an omitted
    # Maybe really is absent rather than an explicit None.
    return "algorithm=" + str(algorithm) + " init=" + str(init)


def fixedArityImpl(kw):
    return _fixed_arity(**kw)
