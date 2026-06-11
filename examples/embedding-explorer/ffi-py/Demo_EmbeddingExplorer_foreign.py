# FFI for EmbeddingExplorer demo

def getCategories(items):
    """Extract unique categories from items."""
    seen = set()
    categories = []
    for item in items:
        cat = item.get("category", "")
        if cat and cat not in seen:
            seen.add(cat)
            categories.append(cat)
    return categories


def getSplomData(n):
    """First n dimensions of each point, for the SPLOM panel.
    (Missing from the first incarnation's shim - the strict per-name
    foreign import caught it at import time.)"""
    def go(items):
        return [{"label": it["label"], "dims": it["vector"][:n], "category": it["category"]}
                for it in items]
    return go
