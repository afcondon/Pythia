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
