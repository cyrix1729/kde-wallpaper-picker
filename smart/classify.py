"""Smart mood detection: matches wallpapers against each mood's text descriptions with CLIP.

Run by wallpaper-picker inside the optional venv (install.sh --smart). Reads JSON on stdin:
    {"images": [paths], "moods": {mood: [descriptions]}, "cache": path, "models": dir}
and prints {path: {"mood": best mood, "conf": its share of the vote (0..1)}} as JSON.

Image embeddings are cached by path + mtime + size, so each image is only analysed once;
editing the descriptions only re-runs the cheap text side.
"""
import json
import math
import os
import sys

from fastembed import ImageEmbedding, TextEmbedding

IMAGE_MODEL = "Qdrant/clip-ViT-B-32-vision"
TEXT_MODEL = "Qdrant/clip-ViT-B-32-text"
LOGIT_SCALE = 100  # CLIP's own temperature for turning similarities into probabilities


def normalise(vec):
    length = math.sqrt(sum(x * x for x in vec)) or 1.0
    return [x / length for x in vec]


def stamp(path):
    st = os.stat(path)
    return f"{st.st_mtime_ns}:{st.st_size}"


def load_cache(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def main():
    job = json.load(sys.stdin)
    cache_path = job["cache"]
    cache = load_cache(cache_path)
    images = [p for p in job["images"] if os.path.isfile(p)]

    todo = [p for p in images if cache.get(p, {}).get("stamp") != stamp(p)]
    if todo:
        model = ImageEmbedding(model_name=IMAGE_MODEL, cache_dir=job["models"])
        for path, vec in zip(todo, model.embed(todo)):
            cache[path] = {"stamp": stamp(path), "vec": [round(float(x), 5) for x in normalise(vec)]}
        cache = {p: v for p, v in cache.items() if os.path.isfile(p)}
        os.makedirs(os.path.dirname(cache_path), exist_ok=True)
        with open(cache_path + ".tmp", "w") as f:
            json.dump(cache, f)
        os.replace(cache_path + ".tmp", cache_path)

    moods = {m: d for m, d in job["moods"].items() if d}
    if not moods or not images:
        print("{}")
        return
    text = TextEmbedding(model_name=TEXT_MODEL, cache_dir=job["models"])
    flat = [(mood, desc) for mood, descs in moods.items() for desc in descs]
    vecs = [normalise(v) for v in text.embed([desc for _, desc in flat])]

    results = {}
    for path in images:
        img = cache[path]["vec"]
        best = {}
        for (mood, _), vec in zip(flat, vecs):
            sim = sum(a * b for a, b in zip(img, vec))
            best[mood] = max(best.get(mood, -1.0), sim)
        top = max(best.values())
        weights = {m: math.exp(LOGIT_SCALE * (s - top)) for m, s in best.items()}
        total = sum(weights.values())
        mood = max(weights, key=weights.get)
        results[path] = {"mood": mood, "conf": round(weights[mood] / total, 3)}
    print(json.dumps(results))


if __name__ == "__main__":
    main()
