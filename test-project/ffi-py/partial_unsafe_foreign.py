# FFI for Partial.Unsafe
__all__ = ['_unsafePartial']

def _unsafePartial(f):
    # Pass None as the unused Partial dictionary
    return f(None)
