# Tap d20

A twenty-sided die you tap to roll. It's a single web page that installs to a phone's home screen and works offline.

**Play it:** https://digitalduquette.github.io/d20/

On iPhone, open that link in Safari, tap Share, then Add to Home Screen.

## Run it locally

```
python3 -m http.server 8000
```

Then open http://localhost:8000. Opening `index.html` straight from disk works for rolling, but the offline cache needs it to be served.

## What's here

- `index.html`: the whole app (3D die built with three.js, rolls use `crypto.getRandomValues`).
- `sw.js`: offline cache. Bump `VERSION` whenever a cached file changes, or installed copies keep the old one.
- `manifest.webmanifest` and `icons/`: home-screen install.
- `vendor/three.min.js`: three.js r128 (MIT).
- `fonts/`: Cinzel and Figtree (SIL Open Font License).

## License

MIT. See `LICENSE`. Vendored code and fonts keep their own licenses, listed
above.
