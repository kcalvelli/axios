# Proposal: MCP Screenshot Server

## Summary

Build a lightweight MCP server that provides screenshot capabilities for AI agents, enabling visual context in AI-assisted debugging and documentation workflows.

## Motivation

### Problem Statement

AI agents with vision capabilities (Claude, GPT-4V) can analyze images, but have no programmatic way to capture screenshots. Users must:

1. Manually take screenshot
2. Save to file
3. Provide path to AI

This breaks the flow of AI-assisted work, especially for:
- Visual debugging ("What's wrong with this UI?")
- Documentation ("Document what's on screen")
- Accessibility ("Describe what's displayed")

### Solution

Create `mcp-screenshot` - a simple MCP server wrapping Wayland screenshot tools (grim/slurp) that axios desktop already provides.

## Proposed Implementation

### Package Structure

```
pkgs/mcp-screenshot/
├── default.nix
└── src/
    └── main.py         # Simple MCP server
```

### MCP Tools

```typescript
// capture_screen - Capture entire screen or specific monitor
capture_screen(params: {
  output?: string;        // Monitor name (default: focused)
  format?: "png" | "jpeg"; // Image format
  quality?: number;       // JPEG quality (1-100)
}): {
  image: string;          // Base64-encoded image data
  width: number;
  height: number;
  format: string;
};

// capture_window - Capture focused or specific window
capture_window(params: {
  format?: "png" | "jpeg";
  quality?: number;
}): {
  image: string;
  width: number;
  height: number;
  format: string;
  title: string;          // Window title
};

// capture_region - Interactive region selection
capture_region(params: {
  format?: "png" | "jpeg";
  quality?: number;
}): {
  image: string;
  width: number;
  height: number;
  format: string;
  region: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
};

// capture_to_file - Save screenshot to file (for large images)
capture_to_file(params: {
  path: string;           // Where to save
  type: "screen" | "window" | "region";
  output?: string;        // Monitor name (for screen)
  format?: "png" | "jpeg";
}): {
  path: string;
  width: number;
  height: number;
};
```

### Implementation

Uses grim (screenshot) and slurp (region selection):

```python
import subprocess
import base64
import json

def capture_screen(output: str = None, format: str = "png") -> dict:
    cmd = ["grim", "-t", format]
    if output:
        cmd.extend(["-o", output])
    cmd.append("-")  # Output to stdout

    result = subprocess.run(cmd, capture_output=True)

    # Get dimensions from image
    width, height = get_image_dimensions(result.stdout)

    return {
        "image": base64.b64encode(result.stdout).decode(),
        "width": width,
        "height": height,
        "format": format
    }

def capture_region(format: str = "png") -> dict:
    # Get region from slurp
    slurp = subprocess.run(["slurp"], capture_output=True, text=True)
    geometry = slurp.stdout.strip()  # "x,y widthxheight"

    # Capture region with grim
    cmd = ["grim", "-t", format, "-g", geometry, "-"]
    result = subprocess.run(cmd, capture_output=True)

    return {
        "image": base64.b64encode(result.stdout).decode(),
        "width": width,
        "height": height,
        "format": format,
        "region": parse_geometry(geometry)
    }
```

### Dependencies

```nix
{ pkgs, ... }:

pkgs.python3Packages.buildPythonApplication {
  pname = "mcp-screenshot";
  version = "0.1.0";

  propagatedBuildInputs = with pkgs; [
    grim                   # Wayland screenshot
    slurp                  # Region selection
    python3Packages.mcp    # MCP SDK
    python3Packages.pillow # Image dimension reading
  ];
}
```

### MCP Server Registration

Add to `home/ai/mcp.nix`:

```nix
settings.servers.screenshot = lib.mkIf config.programs.niri.enable {
  command = "${pkgs.mcp-screenshot}/bin/mcp-screenshot";
  # Only available on Wayland desktop
};
```

## Configuration

Minimal configuration needed - tool uses system defaults:

```nix
services.ai.mcp.screenshot = {
  enable = lib.mkEnableOption "Screenshot MCP server" // {
    default = true;  # Enabled by default on desktop
  };

  defaultFormat = lib.mkOption {
    type = lib.types.enum [ "png" "jpeg" ];
    default = "png";
  };

  jpegQuality = lib.mkOption {
    type = lib.types.int;
    default = 90;
  };
};
```

## Sample AI Interactions

```
User: "What's wrong with this dialog box?"

AI: [Uses mcp-screenshot/capture_window]
    [Analyzes returned image]

I can see the dialog box. The issue is:
- The "Cancel" button is truncated, showing only "Canc..."
- The text is overflowing the container
- Recommendation: Increase dialog width or use text ellipsis
```

```
User: "Document the current screen layout for the README"

AI: [Uses mcp-screenshot/capture_screen]
    [Analyzes image]

I've captured the screen. Here's a description for documentation:

The workspace shows a tiled layout with:
- Left: VS Code editor with Rust code
- Right top: Terminal running cargo build
- Right bottom: Web browser with documentation

I can save this to docs/screenshots/ if you'd like.
```

```
User: "Can you see this error message?" [user points at screen]

AI: [Uses mcp-screenshot/capture_region]
    [User selects the error area]

I can see the error. It says:
"Connection refused: localhost:5432"

This indicates PostgreSQL isn't running. Try:
sudo systemctl start postgresql
```

## Impact Analysis

### Benefits

- Enables visual AI assistance workflows
- Simple implementation (wraps existing tools)
- Low overhead (no daemon, on-demand only)
- Privacy-preserving (local only, no cloud upload)

### Considerations

- Requires Wayland (grim/slurp are Wayland-only)
- Region selection is interactive (requires user input)
- Large screenshots may be slow to base64 encode

### Security

- Only works locally (MCP server runs on user's machine)
- No network transmission of screenshots
- User initiates all captures (no background surveillance)

## Testing Requirements

- [ ] Screen capture returns valid image
- [ ] Window capture gets focused window
- [ ] Region selection works with slurp
- [ ] JPEG quality setting works
- [ ] File output saves correctly
- [ ] MCP server appears in mcp-cli
- [ ] Works with Claude Code vision
- [ ] Error handling when no display

## Dependencies

- **Requires**: Desktop module (provides grim/slurp)
- **Requires**: Wayland compositor (Niri)
- **Optional**: AI module for MCP integration

## Alternatives Considered

### Alternative 1: Use existing filesystem MCP

User takes screenshot manually, AI reads file.

**Rejected**: Breaks workflow, requires manual intervention.

### Alternative 2: Use Niri's screenshot bindings

Leverage existing Mod+Shift+S bindings.

**Rejected**: Not programmatically accessible, still requires manual save.

### Alternative 3: Screen recording instead

Provide video capture capabilities.

**Rejected**: Overkill for most use cases, much more complex.

## Future Enhancements

- Monitor selection UI (for multi-monitor)
- Annotation support (highlight areas before capture)
- OCR integration (extract text from screenshots)
- Diff capture (compare two screenshots)
- X11 support (for non-Wayland systems)

## References

- grim: https://sr.ht/~emersion/grim/
- slurp: https://github.com/emersion/slurp
- Niri screenshot config: `home/desktop/niri-keybinds.nix`
- MCP specification: https://modelcontextprotocol.io/
