# Workflows

## deploy-native-experimental.yml

This workflow builds and deploys an experimental version of the Flutter demo using native web elements (HTML renderer) instead of the default CanvasKit renderer.

### What it does:

1. **Checks out the demo repository**: Clones the `ComsIndeed/json_stream_parser_demo` repository
2. **Builds with HTML renderer**: Uses `flutter build web --web-renderer html` to build the app using native DOM/HTML/CSS instead of WebAssembly/CanvasKit
3. **Deploys to GitHub Pages**: Publishes the build to this repository's GitHub Pages at `/native-experimental/`

### Key differences from the main demo:

- **Renderer**: Uses HTML renderer (native web elements) vs CanvasKit (default)
- **Path**: Accessible at `/llm_json_stream/native-experimental/` 
- **Purpose**: Experimental build to test how the app works with native web elements

### When it runs:

- Automatically on push to `main` branch
- Manually via the Actions tab (workflow_dispatch)

### Accessing the demo:

Once deployed, the experimental build will be available at:
```
https://comsindeed.github.io/llm_json_stream/native-experimental/
```

The main demo (with CanvasKit) remains at:
```
https://comsindeed.github.io/json_stream_parser_demo/
```

### Setup required:

1. Enable GitHub Pages for this repository:
   - Go to Settings → Pages
   - Set Source to "GitHub Actions"
   - Save changes

2. The workflow will then run automatically on the next push to `main`

### Why native web elements?

The HTML renderer uses standard web technologies (HTML, CSS, DOM) instead of rendering everything to a canvas via WebAssembly. This can:
- Result in smaller bundle sizes
- Better accessibility with screen readers
- Native text selection and form controls
- Different performance characteristics
- May have visual differences from CanvasKit version

This experimental build allows comparison between the two rendering approaches.
