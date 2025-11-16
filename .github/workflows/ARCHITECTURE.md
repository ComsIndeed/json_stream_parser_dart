# Architecture: Native Experimental Deployment

## Deployment Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions Workflow                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Trigger: Push to main or Manual                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 1: Checkout Demo Repository                           │
│  - Repository: ComsIndeed/json_stream_parser_demo           │
│  - Branch: main                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 2: Setup Flutter                                       │
│  - Channel: master                                           │
│  - Cache: enabled                                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 3: Install Dependencies                                │
│  - Command: flutter pub get                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 4: Build Web (HTML Renderer)                          │
│  - Command: flutter build web --web-renderer html           │
│  - Base href: /llm_json_stream/native-experimental/         │
│  - Output: build/web/                                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 5: Prepare Deployment Structure                       │
│  - Create: deploy/native-experimental/                      │
│  - Copy: build/web/* → deploy/native-experimental/          │
│  - Create: deploy/index.html (redirect)                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 6: Upload Artifact                                     │
│  - Path: deploy/                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 7: Deploy to GitHub Pages                             │
│  - Uses: actions/deploy-pages@v4                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│           GitHub Pages Hosting                               │
│  URL: https://comsindeed.github.io/llm_json_stream/         │
│  Path: /native-experimental/                                 │
└─────────────────────────────────────────────────────────────┘
```

## Repository Structure

```
ComsIndeed/
├── llm_json_stream/                    (This repository - Dart package)
│   ├── .github/
│   │   └── workflows/
│   │       ├── deploy-native-experimental.yml  ← The workflow
│   │       ├── README.md
│   │       ├── QUICK_START.md
│   │       └── ARCHITECTURE.md                 ← This file
│   ├── NATIVE_EXPERIMENTAL_SETUP.md
│   └── lib/                                    (Package source code)
│
└── json_stream_parser_demo/            (Separate repository - Flutter app)
    ├── .github/
    │   └── workflows/
    │       └── deploy.yml                      ← Main demo workflow
    ├── lib/                                    (Flutter app source)
    └── web/                                    (Web files)
```

## Two Independent Deployments

### Main Demo (Existing)
```
Repository: ComsIndeed/json_stream_parser_demo
Workflow:   .github/workflows/deploy.yml
Renderer:   CanvasKit (default)
URL:        https://comsindeed.github.io/json_stream_parser_demo/
Pages:      Deployed from json_stream_parser_demo repo
```

### Native Experimental (New)
```
Repository: ComsIndeed/llm_json_stream
Workflow:   .github/workflows/deploy-native-experimental.yml
Renderer:   HTML (native web elements)
URL:        https://comsindeed.github.io/llm_json_stream/native-experimental/
Pages:      Deployed from llm_json_stream repo (but builds demo repo code)
```

## Deployment Directory Structure

After deployment, the GitHub Pages site looks like:

```
https://comsindeed.github.io/llm_json_stream/
│
├── index.html                          (Redirect to /native-experimental/)
│
└── native-experimental/
    ├── index.html                      (Flutter app entry point)
    ├── flutter.js
    ├── flutter_bootstrap.js
    ├── main.dart.js                    (HTML renderer bundle)
    ├── assets/
    │   └── ...
    └── ...
```

## Key Design Decisions

### 1. **Separate Repository Deployment**
- Main demo stays in its own repo (`json_stream_parser_demo`)
- Experimental build deploys from this repo (`llm_json_stream`)
- **Benefit**: No conflicts, independent workflows

### 2. **Cross-Repository Build**
- Workflow checks out demo repo code
- Builds it with different renderer
- Deploys to different GitHub Pages site
- **Benefit**: Single source of truth for app code

### 3. **Subdirectory Deployment**
- Uses `/native-experimental/` path
- Root redirects to subdirectory
- **Benefit**: Clean URL structure, easy to remember

### 4. **HTML Renderer Flag**
- `--web-renderer html` instead of default `auto` or `canvaskit`
- **Benefit**: Forces use of native DOM elements

### 5. **Independent Concurrency Group**
- Group: `pages-native-experimental`
- **Benefit**: Won't block or be blocked by other workflows

## Renderer Comparison

### CanvasKit (Main Demo)
```
Flutter → Skia (C++) → WebAssembly → Canvas API
         [Compiled]    [Binary]      [Browser]
```
- Everything rendered to `<canvas>` element
- Pixel-perfect across platforms
- Larger bundle size (~2MB WASM)

### HTML Renderer (Experimental)
```
Flutter → HTML/CSS/DOM → Browser Native Rendering
         [Generated]    [Browser]
```
- Uses native HTML elements (`<div>`, `<span>`, etc.)
- CSS for styling
- Smaller bundle size (~1MB JS)

## Security Considerations

✅ **Permissions**: Read-only checkout, limited to pages deployment  
✅ **Concurrency**: Safe concurrent deployment group  
✅ **Artifact**: Uses official GitHub Pages actions  
✅ **Repository**: Public repo checkout only  
✅ **CodeQL**: No security alerts detected  

## Maintenance

### Update Flutter Version
Edit `deploy-native-experimental.yml`:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    channel: 'stable'  # or '3.27.x' for specific version
```

### Update Demo Source
The workflow always pulls latest from `json_stream_parser_demo` main branch.
No action needed unless you want to pin to a specific commit.

### Update Deployment Path
Update these locations:
1. `--base-href` in build command
2. Directory creation in prepare step
3. Copy destination path
4. Documentation URLs

## Troubleshooting

### Workflow fails on checkout
- Check that `json_stream_parser_demo` repo is accessible
- Verify the `main` branch exists

### Build fails
- Check Flutter version compatibility
- Review build logs in Actions tab
- Verify demo app builds successfully in its own repo

### Deployment fails
- Ensure GitHub Pages is enabled (Settings → Pages → GitHub Actions)
- Check workflow permissions
- Verify artifact upload succeeded

### Site not accessible
- Wait 1-2 minutes after first deployment
- Check Actions tab for successful deployment
- Verify URL: `https://comsindeed.github.io/llm_json_stream/native-experimental/`

## Future Enhancements

Possible improvements:
1. **Matrix builds**: Build both renderers in one workflow
2. **Performance comparison**: Automated lighthouse scores
3. **Visual diff**: Screenshot comparison between renderers
4. **Multiple branches**: Deploy from feature branches
5. **Scheduled builds**: Regular rebuilds to get latest demo updates

## References

- [Flutter Web Renderers](https://docs.flutter.dev/platform-integration/web/renderers)
- [GitHub Pages Deployment](https://docs.github.com/en/pages)
- [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Flutter Build Web Command](https://docs.flutter.dev/deployment/web)
