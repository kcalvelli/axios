# Tasks: TTS Integration

## Overview

Add text-to-speech capabilities to axios using piper-tts, with optional MCP tool for AI-initiated speech.

---

## Phase 1: Module Definition

### Task 1.1: Add TTS Options to AI Module
- [ ] Add `services.ai.tts.enable` option
- [ ] Add `services.ai.tts.engine` option (piper/espeak)
- [ ] Add `services.ai.tts.piper.*` options
- [ ] Add `services.ai.tts.mcp.enable` option

```nix
# In modules/ai/default.nix, add to options:
tts = {
  enable = lib.mkEnableOption "Text-to-speech capabilities";

  engine = lib.mkOption {
    type = lib.types.enum [ "piper" "espeak" ];
    default = "piper";
    description = ''
      TTS engine:
      - "piper": High-quality neural TTS (recommended)
      - "espeak": Lightweight, robotic but fast
    '';
  };

  piper = {
    voice = lib.mkOption {
      type = lib.types.str;
      default = "en_US-lessac-medium";
      description = "Piper voice model name";
      example = "en_GB-alan-medium";
    };

    speed = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = "Speech speed multiplier";
    };
  };

  mcp = {
    enable = lib.mkEnableOption "MCP tool for AI-initiated speech" // {
      default = false;
    };
  };
};
```

### Task 1.2: Implement TTS Config Block
- [ ] Install piper-tts when enabled
- [ ] Install espeak-ng as fallback
- [ ] Create axios-speak wrapper script

```nix
# In config section
(lib.mkIf (cfg.enable && cfg.tts.enable) {
  environment.systemPackages = with pkgs; [
    piper-tts
    alsa-utils  # aplay
  ]
  ++ lib.optional (cfg.tts.engine == "espeak") espeak-ng;

  # Create axios-speak wrapper
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "axios-speak" ''
      TEXT="$*"
      if [ -z "$TEXT" ]; then
        TEXT=$(cat)
      fi

      ${if cfg.tts.engine == "piper" then ''
        echo "$TEXT" | ${pkgs.piper-tts}/bin/piper \
          --model "${cfg.tts.piper.voice}" \
          --output-raw | \
          ${pkgs.alsa-utils}/bin/aplay -r 22050 -f S16_LE -t raw -
      '' else ''
        ${pkgs.espeak-ng}/bin/espeak-ng "$TEXT"
      ''}
    '')
  ];
})
```

---

## Phase 2: Voice Model Management

### Task 2.1: Research Piper Voice Models
- [ ] Determine where piper stores/looks for models
- [ ] Document model download process
- [ ] Consider pre-downloading default model

### Task 2.2: Add Voice Model Documentation
- [ ] List popular voice options
- [ ] Document how to change voice
- [ ] Document model download location

```markdown
## Voice Models

Piper voices are downloaded automatically on first use.

Popular options:
- `en_US-lessac-medium` - US English (default)
- `en_US-amy-medium` - US English female
- `en_GB-alan-medium` - British English
- `en_US-ryan-medium` - US English male

Models stored in: `~/.local/share/piper/`
```

---

## Phase 3: MCP TTS Server (Optional)

### Task 3.1: Create MCP Server Package
- [ ] Create `pkgs/mcp-tts/` directory
- [ ] Create simple server with `speak` tool

```bash
mkdir -p pkgs/mcp-tts/src
touch pkgs/mcp-tts/default.nix
```

### Task 3.2: Implement speak Tool
- [ ] Accept text, voice, speed parameters
- [ ] Call piper or espeak based on config
- [ ] Return success/duration

```python
# pkgs/mcp-tts/src/main.py
import asyncio
import subprocess
import os
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

app = Server("mcp-tts")

@app.list_tools()
async def list_tools():
    return [
        Tool(
            name="speak",
            description="Convert text to speech and play audio",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {"type": "string", "description": "Text to speak"},
                    "voice": {"type": "string", "description": "Override default voice"},
                    "speed": {"type": "number", "description": "Speed multiplier"},
                    "wait": {"type": "boolean", "default": True, "description": "Wait for speech to complete"}
                },
                "required": ["text"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict):
    if name != "speak":
        return [TextContent(type="text", text=f"Unknown tool: {name}")]

    text = arguments["text"]
    voice = arguments.get("voice", os.environ.get("PIPER_VOICE", "en_US-lessac-medium"))
    wait = arguments.get("wait", True)

    # Estimate duration (rough: ~150 words per minute)
    word_count = len(text.split())
    estimated_duration = word_count / 150 * 60

    # Run piper
    piper_cmd = f'echo "{text}" | piper --model {voice} --output-raw | aplay -r 22050 -f S16_LE -t raw -'

    if wait:
        subprocess.run(piper_cmd, shell=True)
    else:
        subprocess.Popen(piper_cmd, shell=True)

    return [TextContent(type="text", text=f'{{"success": true, "duration": {estimated_duration:.1f}}}')]

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream)

if __name__ == "__main__":
    asyncio.run(main())
```

### Task 3.3: Add MCP Server to Config
- [ ] Conditional on `services.ai.tts.mcp.enable`
- [ ] Pass voice config via environment

```nix
# In home/ai/mcp.nix
settings.servers.tts = lib.mkIf (osConfig.services.ai.tts.mcp.enable or false) {
  command = "${pkgs.mcp-tts}/bin/mcp-tts";
  env = {
    PIPER_VOICE = osConfig.services.ai.tts.piper.voice;
  };
};
```

---

## Phase 4: Shell Integration

### Task 4.1: Add Shell Aliases
- [ ] Add convenient aliases for TTS

```nix
# In home module
programs.bash.shellAliases = lib.mkIf ttsCfg.enable {
  say = "axios-speak";
  speak = "axios-speak";
};

programs.zsh.shellAliases = lib.mkIf ttsCfg.enable {
  say = "axios-speak";
  speak = "axios-speak";
};
```

### Task 4.2: Document Usage Examples
- [ ] Pipe command output to speech
- [ ] Speak notifications
- [ ] Integration with AI tools

```bash
# Examples
echo "Hello world" | axios-speak
axios-speak "Build complete"
fortune | axios-speak

# Speak last command output
!! | axios-speak
```

---

## Phase 5: Documentation

### Task 5.1: Update AI Module Docs
- [ ] Add TTS section to `docs/MODULE_REFERENCE.md`
- [ ] Document configuration options
- [ ] List available voices

### Task 5.2: Update MCP Documentation
- [ ] Add speak tool to `docs/MCP_REFERENCE.md` (if MCP enabled)

---

## Phase 6: Testing

### Task 6.1: Basic Tests
- [ ] Test: piper-tts installed
- [ ] Test: axios-speak command works
- [ ] Test: Voice model downloads on first use
- [ ] Test: espeak fallback works

### Task 6.2: MCP Tests (if enabled)
- [ ] Test: MCP server starts
- [ ] Test: speak tool appears in mcp-cli
- [ ] Test: AI can trigger speech

### Task 6.3: Audio Tests
- [ ] Test: Works with PipeWire
- [ ] Test: Works with PulseAudio
- [ ] Test: Handles no audio device gracefully

---

## Phase 7: Finalization

### Task 7.1: Code Review
- [ ] Options follow axios patterns
- [ ] Error handling for audio issues
- [ ] Voice model path correct

### Task 7.2: Merge
- [ ] Archive change directory

---

## Files to Create

| File | Purpose |
|------|---------|
| `pkgs/mcp-tts/default.nix` | MCP server package (optional) |
| `pkgs/mcp-tts/src/main.py` | MCP server (optional) |

## Files to Modify

| File | Changes |
|------|---------|
| `modules/ai/default.nix` | Add TTS options and config |
| `home/ai/mcp.nix` | Add TTS MCP server (optional) |
| `docs/MODULE_REFERENCE.md` | Document TTS |

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: Module Definition | 1 hour |
| Phase 2: Voice Models | 1 hour |
| Phase 3: MCP Server | 2 hours |
| Phase 4: Shell Integration | 30 min |
| Phase 5: Documentation | 30 min |
| Phase 6: Testing | 1 hour |
| Phase 7: Finalization | 30 min |
| **Total** | **~7 hours** |

---

## Open Questions

1. **Voice model storage**: Confirm piper model download location and process.

2. **Audio backend**: PipeWire vs PulseAudio - does aplay work with both?

3. **Speed adjustment**: Does piper support speed adjustment natively, or need post-processing?

4. **Async speech**: For long text, should we stream or queue?
