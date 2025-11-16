# Quick Start - Native Experimental Build

## 🚀 Three Steps to Deploy

### Step 1: Enable GitHub Pages
Go to: **Settings** → **Pages** → Set Source to **"GitHub Actions"**

### Step 2: Run the Workflow
Go to: **Actions** → **Deploy Native Experimental Build** → **Run workflow**

### Step 3: Access Your Site
Visit: `https://comsindeed.github.io/llm_json_stream/native-experimental/`

---

## 🆚 Two Demos Comparison

| Demo | Renderer | URL |
|------|----------|-----|
| **Main** | CanvasKit | https://comsindeed.github.io/json_stream_parser_demo/ |
| **Experimental** | HTML Native | https://comsindeed.github.io/llm_json_stream/native-experimental/ |

---

## 📖 Full Documentation

For detailed information, see [NATIVE_EXPERIMENTAL_SETUP.md](../../NATIVE_EXPERIMENTAL_SETUP.md)

## ❓ What's the Difference?

**HTML Renderer (Native Web Elements)**:
- ✅ Smaller bundle size
- ✅ Better accessibility 
- ✅ Native text selection
- ✅ Works without WebAssembly
- ⚠️ May look different across browsers

**CanvasKit Renderer (Default)**:
- ✅ Pixel-perfect consistency
- ✅ Better performance for graphics
- ✅ Full Flutter widget support
- ⚠️ Larger bundle size
- ⚠️ Requires WebAssembly

---

## 🔧 The Workflow Does This:

1. Checks out `ComsIndeed/json_stream_parser_demo`
2. Builds with `flutter build web --web-renderer html`
3. Deploys to GitHub Pages at `/native-experimental/`
4. Keeps the main demo unchanged

**That's it!** No changes to your main demo, no conflicts, just a parallel experimental build. 🎉
