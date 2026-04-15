# Proposal: Text-to-Speech Integration

## Summary

Add text-to-speech capabilities to axios, enabling AI agents to speak responses and providing accessibility features for users.

## Motivation

### Problem Statement

axios currently has speech-to-text (whisper-cpp) but no text-to-speech. This limits:

1. **Accessibility**: Users with visual impairments can't have responses read aloud
2. **Hands-free workflows**: Can't listen to AI responses while doing other tasks
3. **Personal assistant UX**: Voice interaction is one-way only

### Solution

Integrate piper-tts - a fast, high-quality, local TTS engine - with optional MCP tool for AI-initiated speech.

## Proposed Implementation

### Module Options

```nix
services.ai.tts = {
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

  # Piper-specific options
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

  # MCP integration
  mcp = {
    enable = lib.mkEnableOption "MCP tool for AI-initiated speech" // {
      default = false;  # Opt-in, can be intrusive
    };
  };
};
```

### Packages Installed

```nix
config = lib.mkIf cfg.tts.enable {
  environment.systemPackages = with pkgs; [
    piper-tts           # Neural TTS engine
    # Voice models are downloaded on first use or can be pre-installed
  ]
  ++ lib.optional (cfg.tts.engine == "espeak") espeak-ng;

  # Pre-download configured voice model
  # (piper downloads models to ~/.local/share/piper-voices/)
};
```

### CLI Wrapper

Create a simple `axios-speak` command:

```bash
#!/usr/bin/env bash
# axios-speak - Speak text using configured TTS engine

TEXT="$*"
if [ -z "$TEXT" ]; then
  TEXT=$(cat)  # Read from stdin
fi

echo "$TEXT" | piper \
  --model "${PIPER_VOICE:-en_US-lessac-medium}" \
  --output-raw | \
  aplay -r 22050 -f S16_LE -t raw -
```

Usage:
```bash
echo "Hello, world" | axios-speak
axios-speak "The build completed successfully"
```

### MCP Tool (Optional)

```typescript
// speak - Convert text to speech and play audio
speak(params: {
  text: string;           // Text to speak
  voice?: string;         // Override default voice
  speed?: number;         // Speed multiplier
  wait?: boolean;         // Wait for speech to complete (default: true)
}): {
  success: boolean;
  duration: number;       // Speech duration in seconds
};
```

Implementation:

```python
import subprocess

def speak(text: str, voice: str = None, speed: float = 1.0) -> dict:
    voice = voice or os.environ.get("PIPER_VOICE", "en_US-lessac-medium")

    # Generate audio with piper
    piper_cmd = [
        "piper",
        "--model", voice,
        "--output-raw"
    ]

    # Play with aplay
    aplay_cmd = ["aplay", "-r", "22050", "-f", "S16_LE", "-t", "raw", "-"]

    piper = subprocess.Popen(piper_cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    aplay = subprocess.Popen(aplay_cmd, stdin=piper.stdout)

    piper.stdin.write(text.encode())
    piper.stdin.close()
    aplay.wait()

    return {"success": True, "duration": estimate_duration(text)}
```

### Integration Points

#### 1. Notification Integration

```nix
# Speak important notifications
services.dunst.settings.global.script = ''
  case "$DUNST_URGENCY" in
    CRITICAL) axios-speak "$DUNST_SUMMARY: $DUNST_BODY" ;;
  esac
'';
```

#### 2. AI Shell Aliases

```bash
# Speak last AI response
alias speak-last='tail -1 ~/.cache/claude-code/last-response.txt | axios-speak'
```

#### 3. Terminal Bell Replacement

```bash
# In .bashrc/.zshrc
command_not_found_handler() {
  axios-speak "Command not found: $1"
}
```

## Sample AI Interactions

With MCP TTS enabled:

```
User: "Read me today's calendar"

AI: [Uses mcp-calendar/list_events]
    [Uses mcp-tts/speak]

*Speaking*: "You have 3 events today. 9 AM: Team standup.
12 PM: Lunch with Sarah at Cafe Roma. 3 PM: Dentist appointment."

Your calendar for today has been read aloud.
```

```
User: "Announce when the build finishes"

AI: [Starts build in background]
    [When complete, uses mcp-tts/speak]

*Speaking*: "Build completed successfully in 2 minutes 34 seconds."

The build has finished and I've announced it.
```

## Configuration Example

### Basic Setup

```nix
{
  services.ai = {
    enable = true;

    tts = {
      enable = true;
      engine = "piper";
      piper.voice = "en_US-lessac-medium";
    };
  };
}
```

### With MCP Tool

```nix
{
  services.ai = {
    enable = true;

    tts = {
      enable = true;
      piper.voice = "en_GB-alan-medium";  # British voice

      mcp.enable = true;  # Allow AI to speak
    };
  };
}
```

## Voice Options

Popular piper voices:

| Voice | Language | Quality | Size |
|-------|----------|---------|------|
| en_US-lessac-medium | US English | High | 65MB |
| en_US-amy-medium | US English (female) | High | 65MB |
| en_GB-alan-medium | British English | High | 65MB |
| en_US-ryan-medium | US English (male) | High | 65MB |

Users can install additional voices from: https://github.com/rhasspy/piper/releases

## Impact Analysis

### Benefits

- Accessibility for visually impaired users
- Hands-free AI interaction
- Notification enhancement
- Local processing (no cloud)

### Considerations

- Audio output required (speakers/headphones)
- Voice models are ~65MB each
- May be intrusive if not configured carefully

## Testing Requirements

- [ ] piper-tts installed and working
- [ ] axios-speak command works
- [ ] Voice model downloads correctly
- [ ] Speed adjustment works
- [ ] MCP tool speaks (when enabled)
- [ ] Works with PipeWire/PulseAudio
- [ ] espeak fallback works

## Dependencies

- **Requires**: Audio output (PipeWire/PulseAudio)
- **Optional**: AI module (for MCP integration)
- **Packages**: piper-tts, alsa-utils (aplay)

## Alternatives Considered

### Alternative 1: espeak-ng only

Lightweight but robotic sounding.

**Partially adopted**: Available as fallback engine.

### Alternative 2: Festival

Classic Unix TTS.

**Rejected**: Lower quality than piper, more complex setup.

### Alternative 3: Cloud TTS (Google, Amazon)

Higher quality options available.

**Rejected**: Privacy concerns, requires internet, costs money.

### Alternative 4: Coqui TTS

Another neural TTS option.

**Rejected**: Heavier than piper, less maintained.

## Future Enhancements

- Voice cloning (train on user's voice)
- SSML support (control pronunciation)
- Multiple voice profiles
- Integration with voice assistants
- Streaming TTS for long text

## References

- piper-tts: https://github.com/rhasspy/piper
- espeak-ng: https://github.com/espeak-ng/espeak-ng
- Voice samples: https://rhasspy.github.io/piper-samples/
- MCP specification: https://modelcontextprotocol.io/
