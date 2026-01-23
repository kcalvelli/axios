# Tasks: MCP Content Extraction Server

## Overview

Build an MCP server that provides content extraction capabilities for AI agents (PDF, YouTube, web pages).

---

## Phase 1: Package Setup

### Task 1.1: Create Package Structure
- [ ] Create `pkgs/mcp-content/` directory
- [ ] Create `default.nix`
- [ ] Create `src/` directory

```bash
mkdir -p pkgs/mcp-content/src/tools
touch pkgs/mcp-content/default.nix
touch pkgs/mcp-content/src/__init__.py
touch pkgs/mcp-content/src/main.py
```

### Task 1.2: Define Nix Package
- [ ] Write `default.nix` with all dependencies
- [ ] Include: poppler-utils, yt-dlp, readability-cli, whisper-cpp

```nix
# pkgs/mcp-content/default.nix
{ pkgs, ... }:

let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    mcp
    httpx
    beautifulsoup4
  ]);
in
pkgs.stdenv.mkDerivation {
  pname = "mcp-content";
  version = "0.1.0";

  src = ./src;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  buildInputs = [
    pythonEnv
    pkgs.poppler_utils    # pdftotext, pdfinfo
    pkgs.yt-dlp           # YouTube download
    pkgs.whisper-cpp      # Audio transcription
    pkgs.readability-cli  # Web article extraction
  ];

  installPhase = ''
    mkdir -p $out/bin $out/lib
    cp -r . $out/lib/mcp-content

    makeWrapper ${pythonEnv}/bin/python $out/bin/mcp-content \
      --add-flags "$out/lib/mcp-content/main.py" \
      --prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.poppler_utils
        pkgs.yt-dlp
        pkgs.whisper-cpp
        pkgs.readability-cli
      ]}
  '';

  meta = {
    description = "MCP server for content extraction (PDF, YouTube, web)";
    license = pkgs.lib.licenses.mit;
  };
}
```

---

## Phase 2: PDF Extraction

### Task 2.1: Implement extract_pdf Tool
- [ ] Create `src/tools/pdf.py`
- [ ] Use `pdftotext` for text extraction
- [ ] Use `pdfinfo` for metadata
- [ ] Support page range selection

```python
# src/tools/pdf.py
import subprocess
import json

def extract_pdf(path: str, pages: str = None, format: str = "text") -> dict:
    """Extract text content from PDF file."""

    # Get page count
    info_result = subprocess.run(
        ["pdfinfo", path],
        capture_output=True, text=True
    )
    page_count = parse_page_count(info_result.stdout)

    # Build pdftotext command
    cmd = ["pdftotext", "-layout"]
    if pages:
        first, last = parse_page_range(pages)
        cmd.extend(["-f", str(first), "-l", str(last)])
    cmd.extend([path, "-"])

    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        raise Exception(f"pdftotext failed: {result.stderr}")

    return {
        "content": result.stdout,
        "pages": page_count,
        "metadata": get_pdf_metadata(path)
    }

def get_pdf_metadata(path: str) -> dict:
    """Extract PDF metadata using pdfinfo."""
    result = subprocess.run(["pdfinfo", path], capture_output=True, text=True)
    metadata = {}
    for line in result.stdout.split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)
            metadata[key.strip().lower()] = value.strip()
    return metadata
```

### Task 2.2: Add Page Limit Protection
- [ ] Add configurable max pages (default 100)
- [ ] Return error for oversized PDFs
- [ ] Allow override via parameter

---

## Phase 3: YouTube Extraction

### Task 3.1: Implement extract_youtube Tool
- [ ] Create `src/tools/youtube.py`
- [ ] Get video metadata via yt-dlp
- [ ] Try automatic captions first
- [ ] Fall back to whisper transcription

```python
# src/tools/youtube.py
import subprocess
import json
import tempfile
import os

def extract_youtube(url: str, language: str = "en", timestamps: bool = False) -> dict:
    """Extract transcript from YouTube video."""

    # Get video info
    info_cmd = ["yt-dlp", "--dump-json", "--no-download", url]
    info_result = subprocess.run(info_cmd, capture_output=True, text=True)
    info = json.loads(info_result.stdout)

    # Try to get subtitles
    transcript = get_subtitles(url, language)

    if not transcript:
        # Fall back to whisper transcription
        transcript = transcribe_with_whisper(url, language)

    if not timestamps:
        transcript = remove_timestamps(transcript)

    return {
        "content": transcript,
        "title": info.get("title", "Unknown"),
        "channel": info.get("channel", "Unknown"),
        "duration": format_duration(info.get("duration", 0)),
        "language": language
    }

def get_subtitles(url: str, language: str) -> str:
    """Try to get existing subtitles."""
    with tempfile.TemporaryDirectory() as tmpdir:
        cmd = [
            "yt-dlp",
            "--write-auto-sub",
            "--sub-lang", language,
            "--skip-download",
            "--output", f"{tmpdir}/video",
            url
        ]
        subprocess.run(cmd, capture_output=True)

        # Check for subtitle file
        for f in os.listdir(tmpdir):
            if f.endswith('.vtt') or f.endswith('.srt'):
                with open(os.path.join(tmpdir, f)) as sf:
                    return parse_subtitles(sf.read())
    return None

def transcribe_with_whisper(url: str, language: str) -> str:
    """Download audio and transcribe with whisper."""
    with tempfile.TemporaryDirectory() as tmpdir:
        audio_path = f"{tmpdir}/audio.wav"

        # Download audio
        cmd = [
            "yt-dlp",
            "-x",
            "--audio-format", "wav",
            "--output", audio_path,
            url
        ]
        subprocess.run(cmd, capture_output=True)

        # Transcribe with whisper
        result = subprocess.run(
            ["whisper-cpp", "-m", "base", "-f", audio_path],
            capture_output=True, text=True
        )
        return result.stdout
```

### Task 3.2: Handle Whisper Model Path
- [ ] Determine where whisper models are stored
- [ ] Make model configurable (tiny, base, small, medium)
- [ ] Document model download if needed

---

## Phase 4: Web Extraction

### Task 4.1: Implement extract_url Tool
- [ ] Create `src/tools/web.py`
- [ ] Use readability-cli for article extraction
- [ ] Convert HTML to markdown if requested

```python
# src/tools/web.py
import subprocess
import json

def extract_url(url: str, format: str = "markdown", include_images: bool = False) -> dict:
    """Extract article content from web page."""

    # Use readability-cli
    cmd = ["readable", "--json", url]
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        raise Exception(f"readability failed: {result.stderr}")

    data = json.loads(result.stdout)
    content = data.get("content", "")

    if format == "markdown":
        content = html_to_markdown(content)
    elif format == "text":
        content = html_to_text(content)

    return {
        "content": content,
        "title": data.get("title", ""),
        "author": data.get("byline"),
        "published": data.get("publishedTime"),
        "siteName": data.get("siteName")
    }

def html_to_markdown(html: str) -> str:
    """Convert HTML to Markdown."""
    # Use simple conversion or html2text
    from bs4 import BeautifulSoup
    soup = BeautifulSoup(html, 'html.parser')
    # Basic conversion - could use html2text for better results
    return soup.get_text()
```

### Task 4.2: Handle Edge Cases
- [ ] Paywalled sites (graceful failure)
- [ ] JavaScript-heavy sites (document limitation)
- [ ] Rate limiting (add delay option)

---

## Phase 5: MCP Server Implementation

### Task 5.1: Create Main Server
- [ ] Create `src/main.py`
- [ ] Register all tools
- [ ] Handle errors gracefully

```python
# src/main.py
import asyncio
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

from tools.pdf import extract_pdf
from tools.youtube import extract_youtube
from tools.web import extract_url

app = Server("mcp-content")

@app.list_tools()
async def list_tools():
    return [
        Tool(
            name="extract_pdf",
            description="Extract text content from a PDF file",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Path to PDF file"},
                    "pages": {"type": "string", "description": "Page range (e.g., '1-5')"},
                    "format": {"type": "string", "enum": ["text", "markdown"]}
                },
                "required": ["path"]
            }
        ),
        Tool(
            name="extract_youtube",
            description="Extract transcript from YouTube video",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {"type": "string", "description": "YouTube URL"},
                    "language": {"type": "string", "default": "en"},
                    "timestamps": {"type": "boolean", "default": False}
                },
                "required": ["url"]
            }
        ),
        Tool(
            name="extract_url",
            description="Extract article content from web page",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {"type": "string", "description": "Web page URL"},
                    "format": {"type": "string", "enum": ["text", "markdown"]}
                },
                "required": ["url"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict):
    try:
        if name == "extract_pdf":
            result = extract_pdf(**arguments)
        elif name == "extract_youtube":
            result = extract_youtube(**arguments)
        elif name == "extract_url":
            result = extract_url(**arguments)
        else:
            raise ValueError(f"Unknown tool: {name}")

        return [TextContent(type="text", text=json.dumps(result, indent=2))]
    except Exception as e:
        return [TextContent(type="text", text=f"Error: {str(e)}")]

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream)

if __name__ == "__main__":
    asyncio.run(main())
```

---

## Phase 6: AI Module Integration

### Task 6.1: Add to MCP Servers
- [ ] Add content server to `home/ai/mcp.nix`

```nix
settings.servers.content = {
  command = "${pkgs.mcp-content}/bin/mcp-content";
};
```

### Task 6.2: Add Module Options
- [ ] Add `services.ai.mcp.content.enable` option
- [ ] Add configuration for YouTube whisper model
- [ ] Add PDF page limit option

---

## Phase 7: Documentation

### Task 7.1: Update MCP Documentation
- [ ] Add content tools to `docs/MCP_REFERENCE.md`
- [ ] Document each tool with examples

### Task 7.2: Update System Prompt
- [ ] Add content extraction to axios system prompt
- [ ] Document tool capabilities and limitations

---

## Phase 8: Testing

### Task 8.1: PDF Tests
- [ ] Test: Extract text from simple PDF
- [ ] Test: Extract with page range
- [ ] Test: Handle encrypted PDFs (error gracefully)
- [ ] Test: Metadata extraction

### Task 8.2: YouTube Tests
- [ ] Test: Video with auto-captions
- [ ] Test: Video without captions (whisper fallback)
- [ ] Test: Invalid URL handling
- [ ] Test: Timestamps option

### Task 8.3: Web Tests
- [ ] Test: News article extraction
- [ ] Test: Blog post extraction
- [ ] Test: Invalid URL handling
- [ ] Test: Markdown output

### Task 8.4: MCP Tests
- [ ] Test: Server starts correctly
- [ ] Test: Tools appear in mcp-cli
- [ ] Test: Claude Code can use tools

---

## Phase 9: Finalization

### Task 9.1: Code Review
- [ ] Error handling is comprehensive
- [ ] Timeouts prevent hangs
- [ ] Resource cleanup (temp files)

### Task 9.2: Merge
- [ ] Archive change directory

---

## Files to Create

| File | Purpose |
|------|---------|
| `pkgs/mcp-content/default.nix` | Nix package |
| `pkgs/mcp-content/src/main.py` | MCP server |
| `pkgs/mcp-content/src/tools/pdf.py` | PDF extraction |
| `pkgs/mcp-content/src/tools/youtube.py` | YouTube extraction |
| `pkgs/mcp-content/src/tools/web.py` | Web extraction |

## Files to Modify

| File | Changes |
|------|---------|
| `home/ai/mcp.nix` | Add content server |
| `docs/MCP_REFERENCE.md` | Document tools |

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: Package Setup | 1 hour |
| Phase 2: PDF Extraction | 2 hours |
| Phase 3: YouTube Extraction | 3 hours |
| Phase 4: Web Extraction | 2 hours |
| Phase 5: MCP Server | 2 hours |
| Phase 6: AI Integration | 1 hour |
| Phase 7: Documentation | 1 hour |
| Phase 8: Testing | 3 hours |
| Phase 9: Finalization | 30 min |
| **Total** | **~16 hours** |

---

## Open Questions

1. **Whisper model location**: Where are whisper models stored? Need to ensure they're accessible.

2. **Rate limiting**: Should we add delays for YouTube/web extraction to avoid rate limits?

3. **Caching**: Should we cache extracted content to avoid re-processing?
