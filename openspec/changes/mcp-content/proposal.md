# Proposal: MCP Content Extraction Server

## Summary

Build an MCP server that provides content extraction capabilities for AI agents, enabling summarization of PDFs, YouTube videos, and web pages.

## Motivation

### Problem Statement

AI agents frequently need to summarize or extract information from:
- PDF documents
- YouTube videos (via transcripts)
- Web pages (article content)

Currently, users must manually copy/paste content or use external tools. This creates friction in AI-assisted workflows.

### Solution

Create `mcp-content` - an MCP server that wraps existing CLI tools to provide content extraction as MCP tools:

- `extract_pdf` - Extract text from PDF files
- `extract_youtube` - Get transcripts from YouTube videos
- `extract_url` - Extract article content from web pages

## Proposed Implementation

### Package Structure

```
pkgs/mcp-content/
├── default.nix
└── src/
    ├── main.py           # MCP server entry point
    ├── tools/
    │   ├── pdf.py        # PDF extraction (poppler-utils)
    │   ├── youtube.py    # YouTube transcripts (yt-dlp + whisper)
    │   └── web.py        # Web content (readability-cli)
    └── utils.py          # Shared utilities
```

### MCP Tools

```typescript
// extract_pdf - Extract text content from PDF files
extract_pdf(params: {
  path: string;           // Path to PDF file
  pages?: string;         // Page range (e.g., "1-5", "1,3,5")
  format?: "text" | "markdown";  // Output format
}): {
  content: string;
  pages: number;
  metadata: {
    title?: string;
    author?: string;
    created?: string;
  };
};

// extract_youtube - Get transcript from YouTube video
extract_youtube(params: {
  url: string;            // YouTube URL or video ID
  language?: string;      // Preferred language (default: en)
  timestamps?: boolean;   // Include timestamps (default: false)
}): {
  content: string;
  title: string;
  channel: string;
  duration: string;
  language: string;
};

// extract_url - Extract article content from web page
extract_url(params: {
  url: string;            // Web page URL
  format?: "text" | "markdown";  // Output format
  includeImages?: boolean;       // Include image descriptions
}): {
  content: string;
  title: string;
  author?: string;
  published?: string;
  siteName?: string;
};
```

### Implementation Details

#### PDF Extraction

Uses `poppler-utils` (pdftotext):

```python
import subprocess

def extract_pdf(path: str, pages: str = None) -> dict:
    cmd = ["pdftotext", "-layout"]
    if pages:
        # Parse page range
        cmd.extend(["-f", first_page, "-l", last_page])
    cmd.extend([path, "-"])

    result = subprocess.run(cmd, capture_output=True, text=True)
    return {
        "content": result.stdout,
        "pages": get_page_count(path),
        "metadata": get_pdf_metadata(path)
    }
```

#### YouTube Transcripts

Uses `yt-dlp` for metadata and transcript extraction:

```python
import subprocess
import json

def extract_youtube(url: str, language: str = "en") -> dict:
    # Get video info
    info_cmd = ["yt-dlp", "--dump-json", "--no-download", url]
    info = json.loads(subprocess.run(info_cmd, capture_output=True).stdout)

    # Try to get subtitles first
    subs = get_subtitles(url, language)

    if not subs:
        # Fall back to whisper transcription
        audio_path = download_audio(url)
        subs = transcribe_with_whisper(audio_path)

    return {
        "content": subs,
        "title": info["title"],
        "channel": info["channel"],
        "duration": format_duration(info["duration"]),
        "language": language
    }
```

#### Web Content Extraction

Uses `readability-cli` or `trafilatura`:

```python
import subprocess

def extract_url(url: str, format: str = "markdown") -> dict:
    # Use readability-cli for article extraction
    cmd = ["readable", "--json", url]
    result = subprocess.run(cmd, capture_output=True, text=True)
    data = json.loads(result.stdout)

    content = data["content"]
    if format == "markdown":
        content = html_to_markdown(content)

    return {
        "content": content,
        "title": data["title"],
        "author": data.get("byline"),
        "siteName": data.get("siteName")
    }
```

### Dependencies

```nix
# default.nix
{ pkgs, ... }:

pkgs.python3Packages.buildPythonApplication {
  pname = "mcp-content";
  version = "0.1.0";

  propagatedBuildInputs = with pkgs; [
    poppler_utils      # pdftotext
    yt-dlp             # YouTube download
    whisper-cpp        # Audio transcription (already in AI module)
    readability-cli    # Web content extraction
    python3Packages.mcp  # MCP SDK
  ];

  # ...
}
```

### MCP Server Registration

Add to `home/ai/mcp.nix`:

```nix
settings.servers.content = {
  command = "${pkgs.mcp-content}/bin/mcp-content";
  # No special configuration needed
};
```

## Configuration

### Module Options

```nix
services.ai.mcp.content = {
  enable = lib.mkEnableOption "Content extraction MCP server" // {
    default = true;  # Enabled by default with MCP
  };

  youtube = {
    preferWhisper = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Prefer whisper transcription over YouTube's auto-captions.
        More accurate but slower and uses local GPU.
      '';
    };

    whisperModel = lib.mkOption {
      type = lib.types.str;
      default = "base";
      description = "Whisper model size (tiny, base, small, medium, large)";
    };
  };

  pdf = {
    maxPages = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = "Maximum pages to extract (prevents huge PDFs)";
    };
  };
};
```

## Sample AI Interactions

```
User: "Summarize this PDF" [attaches paper.pdf]

AI: [Uses mcp-content/extract_pdf path="paper.pdf"]

This is a research paper titled "Attention Is All You Need" by Vaswani et al.

Key points:
- Introduces the Transformer architecture
- Replaces recurrence with self-attention mechanisms
- Achieves state-of-the-art results on translation tasks
- ...
```

```
User: "What does this YouTube video explain?"
      https://youtube.com/watch?v=example

AI: [Uses mcp-content/extract_youtube url="..."]

This video by 3Blue1Brown explains neural networks:

1. Introduction to neurons as mathematical functions
2. How layers connect and transform data
3. The role of weights and biases
4. ...
```

```
User: "Summarize this article"
      https://example.com/article

AI: [Uses mcp-content/extract_url url="..."]

This article from TechCrunch discusses recent AI developments:

- OpenAI announced GPT-5 capabilities
- Focus on reasoning and tool use
- ...
```

## Impact Analysis

### Benefits

- Enables AI to work with PDFs, videos, web content
- Leverages existing tools (poppler, yt-dlp, whisper)
- Integrates with axios's whisper-cpp already installed
- Works with all MCP-compatible AI agents

### Resource Considerations

- YouTube whisper transcription can be GPU-intensive
- Large PDFs may take time to process
- Web extraction depends on site structure

## Testing Requirements

- [ ] PDF extraction works with various formats
- [ ] YouTube transcript extraction (with captions)
- [ ] YouTube whisper fallback (without captions)
- [ ] Web content extraction from news sites
- [ ] Web content extraction from blogs
- [ ] Error handling for invalid URLs/paths
- [ ] Page limit enforcement for PDFs
- [ ] MCP server appears in mcp-cli

## Dependencies

- **Requires**: AI module enabled
- **Uses**: whisper-cpp (already in AI module)
- **Packages**: poppler-utils, yt-dlp, readability-cli

## Alternatives Considered

### Alternative 1: Separate MCP servers per content type

Three separate servers: mcp-pdf, mcp-youtube, mcp-web.

**Rejected**: More servers to manage, content extraction is a cohesive concept.

### Alternative 2: Use cloud APIs

Use cloud services for transcription/extraction.

**Rejected**: Privacy concerns, axios philosophy favors local processing.

### Alternative 3: Browser extension approach

Use browser to extract content.

**Rejected**: Doesn't work for CLI AI agents, requires browser context.

## Future Enhancements

- OCR for scanned PDFs (tesseract integration)
- Image description in web content (vision model)
- Audio file transcription (extend YouTube capability)
- Document format support (DOCX, EPUB)

## References

- poppler-utils: https://poppler.freedesktop.org/
- yt-dlp: https://github.com/yt-dlp/yt-dlp
- whisper.cpp: https://github.com/ggerganov/whisper.cpp
- readability-cli: https://gitlab.com/gardenappl/readability-cli
- MCP specification: https://modelcontextprotocol.io/
