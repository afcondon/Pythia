# UMAP FFI implementation for PurePy
# Requires: pip install umap-learn

import numpy as np
from umap import UMAP

def fitTransformImpl(vectors, n_neighbors, min_dist, n_components, metric):
    """
    Run UMAP dimensionality reduction.

    Args:
        vectors: List of high-dimensional vectors (list of lists of floats)
        n_neighbors: Number of neighbors for local structure (default 15)
        min_dist: Minimum distance between points in embedding (default 0.1)
        n_components: Output dimensions (usually 2)
        metric: Distance metric ('euclidean', 'cosine', etc.)

    Returns:
        List of low-dimensional coordinates
    """
    # Convert to numpy array
    X = np.array(vectors, dtype=np.float32)

    # Create and fit UMAP
    reducer = UMAP(
        n_neighbors=n_neighbors,
        min_dist=min_dist,
        n_components=n_components,
        metric=metric,
        random_state=42  # For reproducibility
    )

    embedding = reducer.fit_transform(X)

    # Convert back to list of dicts with x, y coordinates
    result = []
    for i, point in enumerate(embedding):
        if n_components == 2:
            result.append({"x": float(point[0]), "y": float(point[1])})
        elif n_components == 3:
            result.append({"x": float(point[0]), "y": float(point[1]), "z": float(point[2])})
        else:
            result.append({"coords": [float(c) for c in point]})

    return result


def projectWithLabelsImpl(data, n_neighbors, min_dist, metric):
    """
    Project labeled high-dimensional data to 2D.

    Args:
        data: List of {label: String, vector: [Float], category: String}
        n_neighbors, min_dist, metric: UMAP parameters

    Returns:
        List of {label: String, x: Float, y: Float, category: String}
    """
    # Extract vectors and metadata
    vectors = [item["vector"] for item in data]
    labels = [item["label"] for item in data]
    categories = [item.get("category", "") for item in data]

    # Run UMAP
    X = np.array(vectors, dtype=np.float32)
    reducer = UMAP(
        n_neighbors=min(n_neighbors, len(vectors) - 1),  # Can't exceed data size
        min_dist=min_dist,
        n_components=2,
        metric=metric,
        random_state=42
    )

    embedding = reducer.fit_transform(X)

    # Combine with metadata
    result = []
    for i, point in enumerate(embedding):
        result.append({
            "label": labels[i],
            "x": float(point[0]),
            "y": float(point[1]),
            "category": categories[i]
        })

    return result


def generateWordEmbeddings(word_categories):
    """
    Generate synthetic word embeddings that cluster by category.
    This simulates what you'd get from GloVe/Word2Vec.

    Args:
        word_categories: Dict mapping category name to list of words

    Returns:
        List of {label: String, vector: [Float], category: String}
    """
    np.random.seed(42)
    embedding_dim = 50

    result = []

    for cat_idx, (category, words) in enumerate(word_categories.items()):
        # Create a category center in high-dimensional space
        center = np.random.randn(embedding_dim) * 2

        for word in words:
            # Each word is near its category center with some noise
            vector = center + np.random.randn(embedding_dim) * 0.5
            result.append({
                "label": word,
                "vector": vector.tolist(),
                "category": category
            })

    return result


# Pre-defined word categories for demo
DEMO_WORD_CATEGORIES = {
    "animals": ["dog", "cat", "elephant", "lion", "tiger", "bear", "wolf", "fox", "rabbit", "mouse",
                "horse", "cow", "pig", "sheep", "goat", "deer", "monkey", "gorilla", "whale", "dolphin"],
    "colors": ["red", "blue", "green", "yellow", "orange", "purple", "pink", "brown", "black", "white",
               "gray", "cyan", "magenta", "gold", "silver", "crimson", "navy", "teal", "coral", "indigo"],
    "countries": ["france", "germany", "spain", "italy", "japan", "china", "india", "brazil", "canada", "australia",
                  "mexico", "russia", "egypt", "greece", "sweden", "norway", "poland", "turkey", "korea", "vietnam"],
    "food": ["pizza", "pasta", "sushi", "burger", "salad", "soup", "bread", "rice", "chicken", "fish",
             "cheese", "fruit", "cake", "coffee", "tea", "wine", "beer", "chocolate", "ice cream", "steak"],
    "sports": ["football", "basketball", "tennis", "golf", "swimming", "running", "cycling", "boxing", "skiing", "hockey",
               "baseball", "cricket", "rugby", "volleyball", "surfing", "climbing", "wrestling", "fencing", "rowing", "diving"],
    "emotions": ["happy", "sad", "angry", "excited", "nervous", "calm", "anxious", "proud", "jealous", "grateful",
                 "lonely", "hopeful", "fearful", "confused", "surprised", "bored", "curious", "peaceful", "frustrated", "content"],
    "professions": ["doctor", "lawyer", "teacher", "engineer", "artist", "chef", "pilot", "nurse", "scientist", "writer",
                    "musician", "architect", "farmer", "soldier", "journalist", "actor", "programmer", "designer", "manager", "athlete"]
}


# Pre-computed demo embeddings (evaluated at import time)
getDemoEmbeddings = generateWordEmbeddings(DEMO_WORD_CATEGORIES)
