![](AppIcon.svg)

# PPT Remote

Turn your iPhone into a PowerPoint remote. A macOS menu-bar app serves a control page over Wi-Fi — open it on your phone and you get slide navigation, a laser pointer toggle, and a touch pad that moves the Mac cursor.

PowerPoint is driven by AppleScript; cursor movement goes through `CGEvent`.

## Features

- Menu-bar app (no Dock icon) with a QR code / URL for quick connecting
- Built-in HTTP server (port `8080`)
- Start/End Show, Prev/Next slide buttons
- Laser pointer toggle + full-screen drag pad to move the cursor
- WebSocket for low-latency cursor movement; falls back to HTTP automatically

## Running the app

An app is available under [releases](https://github.com/gglanzani/ppt-remote/releases/latest) but you can build it with `./build.sh`

On first launch macOS may warn that the app is from an unidentified developer.

If so, you can unquarantine it with

```
xattr -d com.apple.quarantine /Applications/PPT\ Remote.app  
```

### Granting required permissions

The app needs two permissions before it can control PowerPoint:

**1. Accessibility** (required for the cursor/laser pad)

> System Settings → Privacy & Security → Accessibility

Toggle **PPT Remote** on. Without this the drag pad does nothing.

**2. Automation → Microsoft PowerPoint** (required for slide control)

> System Settings → Privacy & Security → Automation → PPT Remote

Enable **Microsoft PowerPoint** and **System Events**.

**3. Local Network** (macOS 15+ only)

If prompted, allow network access so the app can be reached over Wi-Fi.

### Connecting your phone

1. Make sure your Mac and phone are on the **same Wi-Fi network**.
2. Click the PPT Remote icon in the menu bar — it shows the URL and a QR code.
3. Scan the QR code

## Building from source

Requires Xcode 15+ (or Swift 5.9+ CLI tools) and macOS 13+.

```sh
./build.sh
open "dist/PPT Remote.app"
```

For development / quick iteration:

```sh
swift run
```

`build.sh` compiles a release binary, assembles the `.app` bundle, and ad-hoc signs it. For wider distribution, replace the `codesign --sign -` step with your Developer ID identity and notarize:

```sh
xcrun notarytool submit "dist/PPT Remote.app" --wait
```
## Troubleshooting

**Buttons do nothing / "Error" appears**
- Check that Automation permission is granted for Microsoft PowerPoint and System Events (see above).
- Make sure Microsoft PowerPoint is open.

**Laser pad doesn't move the cursor**
- Accessibility permission is missing. Go to System Settings → Privacy & Security → Accessibility and enable PPT Remote.

**Phone can't reach the app**
- Confirm both devices are on the same Wi-Fi network (guest networks often isolate devices from each other).
- Check that no firewall rule is blocking port 8080.
- On macOS 15+, confirm Local Network permission was granted.

**"Unidentified developer" warning on launch**
- System Settings → Privacy & Security → scroll down → **Open Anyway**.
