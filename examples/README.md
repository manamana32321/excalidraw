# Example Files

This directory contains example .excalidraw files that demonstrate the format and can be used for testing.

## Files

- **sample.excalidraw**: A simple drawing with a rectangle, demonstrating the basic Excalidraw file format.

## File Format

Excalidraw files are JSON documents with the following structure:

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [
    // Array of drawing elements (rectangles, arrows, text, etc.)
  ],
  "appState": {
    // Application state (background color, grid settings, etc.)
  },
  "files": {
    // Embedded images and files
  }
}
```

## Using Example Files

### 1. Upload to Server

After deploying to Kubernetes, upload the example file:

```bash
# Method 1: Using kubectl cp
kubectl cp examples/sample.excalidraw \
  $(kubectl get pod -n excalidraw -l component=server -o jsonpath='{.items[0].metadata.name}'):/data/excalidraw/ \
  -n excalidraw

# Method 2: Using kubectl exec
kubectl exec -n excalidraw deployment/excalidraw-server -- \
  sh -c "cat > /data/excalidraw/sample.excalidraw" < examples/sample.excalidraw
```

### 2. Access via Browser

After uploading, access the file at:
```
https://your-domain.com/files/sample.excalidraw
```

### 3. View in Excalidraw

To open in the Excalidraw editor:

1. Go to `https://your-domain.com/`
2. Click "Open" in the menu
3. Use the JSON import feature
4. Paste the URL: `https://your-domain.com/files/sample.excalidraw`

Or directly load it using the URL parameter:
```
https://your-domain.com/?url=https://your-domain.com/files/sample.excalidraw
```

## Creating Your Own Files

### From Excalidraw UI

1. Create your drawing in the Excalidraw web interface
2. Click the menu (three dots)
3. Select "Save as..."
4. Choose "Save as .excalidraw"
5. Upload the file to your server using the methods above

### From API/Script

Create a new .excalidraw file programmatically:

```javascript
const drawing = {
  type: "excalidraw",
  version: 2,
  source: "https://excalidraw.com",
  elements: [
    {
      type: "text",
      version: 1,
      versionNonce: 1,
      isDeleted: false,
      id: "text-1",
      fillStyle: "hachure",
      strokeWidth: 1,
      strokeStyle: "solid",
      roughness: 1,
      opacity: 100,
      angle: 0,
      x: 100,
      y: 100,
      strokeColor: "#000000",
      backgroundColor: "transparent",
      width: 200,
      height: 25,
      seed: 1,
      groupIds: [],
      frameId: null,
      roundness: null,
      boundElements: [],
      updated: 1,
      link: null,
      locked: false,
      fontSize: 20,
      fontFamily: 1,
      text: "Hello from Kubernetes!",
      textAlign: "left",
      verticalAlign: "top",
      containerId: null,
      originalText: "Hello from Kubernetes!",
      lineHeight: 1.25,
      baseline: 18
    }
  ],
  appState: {
    gridSize: null,
    viewBackgroundColor: "#ffffff"
  },
  files: {}
};

// Save to file
const fs = require('fs');
fs.writeFileSync('myfile.excalidraw', JSON.stringify(drawing, null, 2));
```

## Organizing Files

Create subdirectories for organization:

```bash
# Create directories in the server pod
kubectl exec -n excalidraw deployment/excalidraw-server -- \
  mkdir -p /data/excalidraw/projects /data/excalidraw/drafts

# Upload files to specific directories
kubectl cp examples/sample.excalidraw \
  $(kubectl get pod -n excalidraw -l component=server -o jsonpath='{.items[0].metadata.name}'):/data/excalidraw/projects/ \
  -n excalidraw
```

Access organized files:
```
https://your-domain.com/files/projects/
https://your-domain.com/files/drafts/
```

## Bulk Operations

### Upload Multiple Files

```bash
#!/bin/bash
POD=$(kubectl get pod -n excalidraw -l component=server -o jsonpath='{.items[0].metadata.name}')

for file in examples/*.excalidraw; do
  echo "Uploading $file..."
  kubectl cp "$file" "$POD:/data/excalidraw/" -n excalidraw
done
```

### Download All Files

```bash
#!/bin/bash
POD=$(kubectl get pod -n excalidraw -l component=server -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n excalidraw "$POD" -- \
  tar -czf - /data/excalidraw | tar -xzf - -C ./backup/
```

## Notes

- All .excalidraw files are JSON and can be edited with any text editor
- Files are stored with UTF-8 encoding
- Large drawings with many elements may have large file sizes
- Embedded images in the `files` section are base64-encoded
