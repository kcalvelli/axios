# Tasks: MCP Screenshot Server

## Overview

Build a lightweight MCP server that provides screenshot capabilities for AI agents, wrapping grim/slurp for Wayland.

**Depends On**: Desktop module (provides grim/slurp)

---

## Phase 1: Package Setup

### Task 1.1: Create Package Structure
- [ ] Create `pkgs/mcp-screenshot/` directory
- [ ] Create `default.nix`
- [ ] Create `src/main.py`

```bash
mkdir -p pkgs/mcp-screenshot/src
touch pkgs/mcp-screenshot/default.nix
touch pkgs/mcp-screenshot/src/main.py
```

### Task 1.2: Define Nix Package
- [ ] Write `default.nix`
- [ ] Include: grim, slurp, Python MCP SDK

```nix
# pkgs/mcp-screenshot/default.nix
{ pkgs, ... }:

let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    mcp
    pillow  # For image dimension reading
  ]);
in
pkgs.stdenv.mkDerivation {
  pname = "mcp-screenshot";
  version = "0.1.0";

  src = ./src;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  buildInputs = [
    pythonEnv
    pkgs.grim   # Wayland screenshot
    pkgs.slurp  # Region selection
  ];

  installPhase = ''
    mkdir -p $out/bin $out/lib
    cp -r . $out/lib/mcp-screenshot

    makeWrapper ${pythonEnv}/bin/python $out/bin/mcp-screenshot \
      --add-flags "$out/lib/mcp-screenshot/main.py" \
      --prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.grim
        pkgs.slurp
      ]}
  '';

  meta = {
    description = "MCP server for screenshot capture on Wayland";
    license = pkgs.lib.licenses.mit;
  };
}
```

---

## Phase 2: Implement Screenshot Tools

### Task 2.1: Implement capture_screen
- [ ] Use grim to capture full screen or specific output
- [ ] Return base64-encoded image
- [ ] Include dimensions in response

```python
# src/main.py (partial)
import subprocess
import base64
import io
from PIL import Image

def capture_screen(output: str = None, format: str = "png", quality: int = 90) -> dict:
    """Capture entire screen or specific monitor."""

    cmd = ["grim", "-t", format]
    if output:
        cmd.extend(["-o", output])
    if format == "jpeg":
        cmd.extend(["-q", str(quality)])
    cmd.append("-")  # Output to stdout

    result = subprocess.run(cmd, capture_output=True)

    if result.returncode != 0:
        raise Exception(f"grim failed: {result.stderr.decode()}")

    # Get dimensions
    img = Image.open(io.BytesIO(result.stdout))
    width, height = img.size

    return {
        "image": base64.b64encode(result.stdout).decode(),
        "width": width,
        "height": height,
        "format": format
    }
```

### Task 2.2: Implement capture_window
- [ ] Use grim to capture focused window
- [ ] Note: May need compositor-specific approach

```python
def capture_window(format: str = "png", quality: int = 90) -> dict:
    """Capture the focused window."""

    # For Niri, we may need to use specific window targeting
    # grim doesn't have built-in window capture - may need slurp workaround
    # or Niri IPC

    # Fallback: Use slurp to select window
    slurp_result = subprocess.run(
        ["slurp", "-o"],  # -o for output selection
        capture_output=True, text=True
    )
    geometry = slurp_result.stdout.strip()

    cmd = ["grim", "-t", format, "-g", geometry]
    if format == "jpeg":
        cmd.extend(["-q", str(quality)])
    cmd.append("-")

    result = subprocess.run(cmd, capture_output=True)
    # ... rest similar to capture_screen
```

### Task 2.3: Implement capture_region
- [ ] Use slurp for interactive region selection
- [ ] Pass geometry to grim

```python
def capture_region(format: str = "png", quality: int = 90) -> dict:
    """Interactive region selection and capture."""

    # Get region from slurp
    slurp_result = subprocess.run(["slurp"], capture_output=True, text=True)

    if slurp_result.returncode != 0:
        raise Exception("Region selection cancelled")

    geometry = slurp_result.stdout.strip()

    cmd = ["grim", "-t", format, "-g", geometry]
    if format == "jpeg":
        cmd.extend(["-q", str(quality)])
    cmd.append("-")

    result = subprocess.run(cmd, capture_output=True)

    img = Image.open(io.BytesIO(result.stdout))
    width, height = img.size

    # Parse geometry for region info
    # Format: "x,y widthxheight"
    region = parse_geometry(geometry)

    return {
        "image": base64.b64encode(result.stdout).decode(),
        "width": width,
        "height": height,
        "format": format,
        "region": region
    }

def parse_geometry(geometry: str) -> dict:
    """Parse slurp geometry string."""
    # Format: "x,y widthxheight"
    pos, size = geometry.split(' ')
    x, y = map(int, pos.split(','))
    w, h = map(int, size.split('x'))
    return {"x": x, "y": y, "width": w, "height": h}
```

### Task 2.4: Implement capture_to_file
- [ ] Save screenshot to file instead of returning base64
- [ ] Useful for large screenshots

```python
def capture_to_file(path: str, type: str = "screen", output: str = None,
                    format: str = "png") -> dict:
    """Save screenshot directly to file."""

    if type == "region":
        slurp_result = subprocess.run(["slurp"], capture_output=True, text=True)
        geometry = slurp_result.stdout.strip()
        cmd = ["grim", "-t", format, "-g", geometry, path]
    else:
        cmd = ["grim", "-t", format]
        if output:
            cmd.extend(["-o", output])
        cmd.append(path)

    result = subprocess.run(cmd, capture_output=True)

    if result.returncode != 0:
        raise Exception(f"grim failed: {result.stderr.decode()}")

    img = Image.open(path)
    width, height = img.size

    return {
        "path": path,
        "width": width,
        "height": height
    }
```

---

## Phase 3: MCP Server Implementation

### Task 3.1: Create Main Server
- [ ] Register all tools
- [ ] Handle errors gracefully
- [ ] Return appropriate MCP responses

```python
# src/main.py (complete)
import asyncio
import json
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

# Import tool implementations
from screenshot import capture_screen, capture_window, capture_region, capture_to_file

app = Server("mcp-screenshot")

@app.list_tools()
async def list_tools():
    return [
        Tool(
            name="capture_screen",
            description="Capture entire screen or specific monitor",
            inputSchema={
                "type": "object",
                "properties": {
                    "output": {"type": "string", "description": "Monitor name"},
                    "format": {"type": "string", "enum": ["png", "jpeg"], "default": "png"},
                    "quality": {"type": "integer", "minimum": 1, "maximum": 100, "default": 90}
                }
            }
        ),
        Tool(
            name="capture_window",
            description="Capture the focused window",
            inputSchema={
                "type": "object",
                "properties": {
                    "format": {"type": "string", "enum": ["png", "jpeg"], "default": "png"},
                    "quality": {"type": "integer", "minimum": 1, "maximum": 100, "default": 90}
                }
            }
        ),
        Tool(
            name="capture_region",
            description="Interactive region selection and capture",
            inputSchema={
                "type": "object",
                "properties": {
                    "format": {"type": "string", "enum": ["png", "jpeg"], "default": "png"},
                    "quality": {"type": "integer", "minimum": 1, "maximum": 100, "default": 90}
                }
            }
        ),
        Tool(
            name="capture_to_file",
            description="Save screenshot to file",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Output file path"},
                    "type": {"type": "string", "enum": ["screen", "window", "region"], "default": "screen"},
                    "output": {"type": "string", "description": "Monitor name (for screen)"},
                    "format": {"type": "string", "enum": ["png", "jpeg"], "default": "png"}
                },
                "required": ["path"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict):
    try:
        if name == "capture_screen":
            result = capture_screen(**arguments)
        elif name == "capture_window":
            result = capture_window(**arguments)
        elif name == "capture_region":
            result = capture_region(**arguments)
        elif name == "capture_to_file":
            result = capture_to_file(**arguments)
        else:
            raise ValueError(f"Unknown tool: {name}")

        return [TextContent(type="text", text=json.dumps(result))]
    except Exception as e:
        return [TextContent(type="text", text=f"Error: {str(e)}")]

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream)

if __name__ == "__main__":
    asyncio.run(main())
```

---

## Phase 4: AI Module Integration

### Task 4.1: Add to MCP Servers
- [ ] Add screenshot server to `home/ai/mcp.nix`
- [ ] Conditional on desktop module enabled

```nix
# In home/ai/mcp.nix
settings.servers.screenshot = lib.mkIf (osConfig.programs.niri.enable or false) {
  command = "${pkgs.mcp-screenshot}/bin/mcp-screenshot";
};
```

### Task 4.2: Add Module Option
- [ ] Add `services.ai.mcp.screenshot.enable` option
- [ ] Default to true when desktop enabled

---

## Phase 5: Documentation

### Task 5.1: Update MCP Documentation
- [ ] Add screenshot tools to `docs/MCP_REFERENCE.md`
- [ ] Document Wayland requirement

### Task 5.2: Update System Prompt
- [ ] Add screenshot capability to axios system prompt
- [ ] Note: Interactive region selection requires user action

---

## Phase 6: Testing

### Task 6.1: Tool Tests
- [ ] Test: capture_screen returns valid image
- [ ] Test: capture_region works with slurp
- [ ] Test: capture_to_file saves correctly
- [ ] Test: JPEG quality setting works
- [ ] Test: Error when no display

### Task 6.2: MCP Tests
- [ ] Test: Server starts correctly
- [ ] Test: Tools appear in mcp-cli
- [ ] Test: Claude Code can use tools

---

## Phase 7: Finalization

### Task 7.1: Code Review
- [ ] Error handling comprehensive
- [ ] Works without display (graceful error)

### Task 7.2: Merge
- [ ] Archive change directory

---

## Files to Create

| File | Purpose |
|------|---------|
| `pkgs/mcp-screenshot/default.nix` | Nix package |
| `pkgs/mcp-screenshot/src/main.py` | MCP server |

## Files to Modify

| File | Changes |
|------|---------|
| `home/ai/mcp.nix` | Add screenshot server |
| `docs/MCP_REFERENCE.md` | Document tools |

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: Package Setup | 30 min |
| Phase 2: Implement Tools | 2 hours |
| Phase 3: MCP Server | 1 hour |
| Phase 4: AI Integration | 30 min |
| Phase 5: Documentation | 30 min |
| Phase 6: Testing | 1 hour |
| Phase 7: Finalization | 30 min |
| **Total** | **~6 hours** |

---

## Open Questions

1. **Window capture**: grim doesn't have native window capture. Need to investigate Niri IPC or alternative approach.

2. **Multi-monitor**: How to handle multi-monitor setups? List available outputs?

3. **Headless**: Should server work when no display available? (Probably just error gracefully)
