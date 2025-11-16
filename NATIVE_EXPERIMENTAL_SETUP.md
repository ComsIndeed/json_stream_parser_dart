# Native Experimental Build Setup Guide

This repository now includes a workflow to host an experimental Flutter web build using native web elements (HTML renderer).

## Overview

The `deploy-native-experimental.yml` workflow builds and deploys a version of the Flutter demo that uses the HTML renderer instead of the default CanvasKit renderer. This allows you to test and compare how the application works with native DOM/HTML/CSS elements.

## What's Different?

### HTML Renderer vs CanvasKit

| Feature | CanvasKit (Default) | HTML Renderer (Experimental) |
|---------|---------------------|------------------------------|
| **Rendering** | WebAssembly canvas | Native DOM/HTML/CSS |
| **Bundle Size** | Larger (~2MB) | Smaller (~1MB) |
| **Performance** | Better for complex graphics | Better for simple UIs |
| **Accessibility** | Limited | Better (native elements) |
| **Text Selection** | Custom implementation | Native browser behavior |
| **Compatibility** | Requires WebAssembly | Works on more browsers |

## Setup Instructions

### 1. Enable GitHub Pages (One-time setup)

1. Go to your repository on GitHub: https://github.com/ComsIndeed/llm_json_stream
2. Click on **Settings** tab
3. Navigate to **Pages** in the left sidebar
4. Under **Source**, select **GitHub Actions**
5. Save the changes

### 2. Trigger the Deployment

The workflow will automatically run when:
- You push to the `main` branch
- You manually trigger it from the Actions tab

**To manually trigger:**
1. Go to the **Actions** tab
2. Select **Deploy Native Experimental Build** workflow
3. Click **Run workflow**
4. Select the branch and click the green **Run workflow** button

### 3. Access the Experimental Build

Once deployed, the experimental build will be available at:
```
https://comsindeed.github.io/llm_json_stream/native-experimental/
```

The root URL will redirect to the experimental build:
```
https://comsindeed.github.io/llm_json_stream/
```

## Comparison with Main Demo

| Demo | Renderer | URL |
|------|----------|-----|
| **Main Demo** | CanvasKit | https://comsindeed.github.io/json_stream_parser_demo/ |
| **Experimental** | HTML (Native) | https://comsindeed.github.io/llm_json_stream/native-experimental/ |

Both demos use the same source code from the `json_stream_parser_demo` repository, but with different rendering engines.

## Testing Checklist

After deployment, test the following to compare behavior:

- [ ] **Page Load Performance**: Compare initial load times
- [ ] **Bundle Size**: Check network tab for download sizes
- [ ] **Text Rendering**: Check font smoothness and selection
- [ ] **Scrolling Performance**: Test smooth scrolling behavior
- [ ] **Animations**: Verify any UI animations work correctly
- [ ] **Accessibility**: Test with screen readers
- [ ] **Form Controls**: Check input fields and buttons
- [ ] **Mobile Experience**: Test on mobile devices
- [ ] **Browser Compatibility**: Test on different browsers

## Troubleshooting

### Workflow fails?
1. Check the Actions tab for error logs
2. Ensure GitHub Pages is enabled in Settings → Pages
3. Verify the demo repository is accessible

### Site not loading?
1. Wait 1-2 minutes after first deployment
2. Clear browser cache (Ctrl+F5 / Cmd+Shift+R)
3. Check the Actions tab to confirm successful deployment

### Different visual appearance?
This is expected! The HTML renderer may render some elements differently than CanvasKit. This is precisely what this experimental build is testing.

## Technical Details

### Build Command

The workflow uses the following Flutter build command:
```bash
flutter build web --release --web-renderer html --base-href /llm_json_stream/native-experimental/
```

### Key Flags:
- `--web-renderer html`: Forces use of HTML renderer instead of auto/canvaskit
- `--base-href /llm_json_stream/native-experimental/`: Sets the base path for assets

### Workflow Features:
- **Concurrent Builds**: Won't cancel in-progress deployments
- **Separate Concurrency Group**: Doesn't interfere with other workflows
- **Automatic Triggers**: Runs on push to main
- **Manual Triggers**: Can be run on-demand from Actions tab

## Modifying the Workflow

### Change the Flutter Version

Edit `.github/workflows/deploy-native-experimental.yml`:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    channel: 'stable'  # Change to 'stable', 'beta', or specific version
    cache: true
```

### Change the Deployment Path

Update the `--base-href` in the build command:
```yaml
- name: Build web with HTML renderer
  run: |
    flutter build web \
      --release \
      --web-renderer html \
      --base-href /llm_json_stream/your-custom-path/
```

And update the directory preparation:
```yaml
- name: Prepare deployment directory
  run: |
    mkdir -p deploy/your-custom-path
    cp -r build/web/* deploy/your-custom-path/
```

### Change Trigger Conditions

Modify the `on:` section to change when the workflow runs:
```yaml
on:
  push:
    branches:
      - main
      - develop  # Add more branches
  pull_request:  # Run on PRs
  schedule:  # Run on a schedule
    - cron: '0 0 * * 0'  # Weekly
```

## Benefits of Native Web Elements

1. **Smaller Bundle**: HTML renderer produces smaller bundles
2. **Native Accessibility**: Screen readers work better with DOM elements
3. **Text Selection**: Native browser text selection behavior
4. **SEO**: Better for search engine indexing
5. **Browser Compatibility**: Works on older browsers without WebAssembly

## Limitations of Native Web Elements

1. **Visual Consistency**: May look different across browsers
2. **Performance**: Slower for complex graphics/animations
3. **Widget Fidelity**: Some Flutter widgets may not render identically
4. **Layout Precision**: CSS layout vs Canvas precision differences

## Next Steps

1. Enable GitHub Pages in repository settings
2. Trigger the workflow manually or push to main
3. Wait for deployment to complete (~2-3 minutes)
4. Access the experimental build at the URL above
5. Compare with the main demo to evaluate differences
6. Provide feedback on which renderer works better for this use case

## Support

For issues or questions:
- Check the Actions tab for workflow logs
- Review the [Flutter web deployment docs](https://docs.flutter.dev/deployment/web)
- Review the [GitHub Pages docs](https://docs.github.com/en/pages)
