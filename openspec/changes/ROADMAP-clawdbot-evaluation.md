# OpenSpec Proposals Roadmap

## Origin

These proposals emerged from evaluating [nix-clawdbot](https://github.com/clawdbot/nix-clawdbot) for potential axios integration.

**Conclusion**: Rather than adopting clawdbot (which would utilize only ~40% of its features due to macOS-centric design), we identified feature gaps and designed native axios solutions that:

- Extend existing infrastructure (vdirsyncer, MCP ecosystem)
- Follow established patterns (server/client roles, Tailscale serve, PWAs)
- Integrate with axios's MCP-centric architecture
- Provide better value for Linux-first users

---

## Proposals by Priority (DVF Order)

| # | Proposal | DVF | Status | Directory |
|---|----------|-----|--------|-----------|
| 1 | [AI Module Server/Client Refactor](#1-ai-module-serverclient-refactor) | HIGH | Draft | `ai-server-client-refactor/` |
| 2 | [Open WebUI Integration](#2-open-webui-integration) | HIGH | Draft | `open-webui-integration/` |
| 3 | [Port Registry Governance](#3-port-registry-governance) | MED | Draft | `port-registry-governance/` |
| 4 | [MCP Calendar](#4-mcp-calendar) | HIGH | Draft | `mcp-calendar/` |
| 5 | [axios Portal PWA](#5-axios-portal-pwa) | MED | Draft | `axios-portal/` |
| 6 | [MCP Content Extraction](#6-mcp-content-extraction) | MED | Draft | `mcp-content/` |
| 7 | [MCP Screenshot](#7-mcp-screenshot) | LOW | Draft | `mcp-screenshot/` |
| 8 | [TTS Integration](#8-tts-integration) | LOW | Draft | `tts-integration/` |

---

## Dependency Graph

```
                    ┌─────────────────────────┐
                    │  AI Module Refactor (#1) │
                    │  (server/client roles)   │
                    └───────────┬─────────────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
              ▼                 ▼                 ▼
┌─────────────────────┐ ┌─────────────┐ ┌─────────────────┐
│ Open WebUI (#2)     │ │ Port Reg(#3)│ │ Ollama Tailscale│
│ (AI chat PWA)       │ │ (governance)│ │ (part of #1)    │
└──────────┬──────────┘ └──────┬──────┘ └─────────────────┘
           │                   │
           └─────────┬─────────┘
                     │
                     ▼
           ┌─────────────────┐
           │ axios Portal(#5)│
           │ (service disco) │
           └─────────────────┘

Independent:
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ MCP Calendar(#4)│  │ MCP Content(#6) │  │ MCP Screenshot  │
│ (extends vdir)  │  │ (PDF/YT/Web)    │  │ (#7)            │
└─────────────────┘  └─────────────────┘  └─────────────────┘

                     ┌─────────────────┐
                     │ TTS (#8)        │
                     │ (piper-tts)     │
                     └─────────────────┘
```

---

## Proposal Summaries

### 1. AI Module Server/Client Refactor

**Directory**: `ai-server-client-refactor/`

**Purpose**: Enable lightweight laptop configurations that use remote Ollama.

**Key Changes**:
- Add `services.ai.local.role = "server" | "client"`
- Server: Run Ollama locally with GPU, expose via Tailscale
- Client: Configure `OLLAMA_HOST` to remote, no local GPU required

**Why First**: Foundational for Open WebUI, Portal, and laptop use cases.

---

### 2. Open WebUI Integration

**Directory**: `open-webui-integration/`

**Purpose**: Mobile-friendly AI chat interface for local LLMs.

**Key Changes**:
- Add `services.ai.webui` module
- Server/client roles (matching axios-ai-mail pattern)
- Tailscale serve on port 8444
- PWA desktop entry "Axios AI Chat"

**Depends On**: #1 (AI Module Refactor)

---

### 3. Port Registry Governance

**Directory**: `port-registry-governance/`

**Purpose**: Document and standardize port allocations.

**Key Changes**:
- Create `openspec/specs/networking/ports.md`
- Document: 8080-8089 (web), 8443-8459 (Tailscale HTTPS)
- Establish conventions for new services

**Depends On**: None (governance document)

---

### 4. MCP Calendar

**Directory**: `mcp-calendar/`

**Purpose**: AI-powered calendar management extending vdirsyncer.

**Key Changes**:
- Phase 1: Declarative vdirsyncer config (Nix → config generation)
- Phase 2: Enable two-way sync
- Phase 3: Build mcp-calendar MCP server
- Phase 4: AI module integration

**Depends On**: None (extends existing infrastructure)

---

### 5. axios Portal PWA

**Directory**: `axios-portal/`

**Purpose**: Service discovery dashboard for axios ecosystem.

**Key Changes**:
- Add `services.portal` module
- Auto-discover configured axios services
- Visual dashboard with status indicators
- PWA "Axios Portal" on port 8445

**Depends On**: #2 (Open WebUI), #3 (Port Registry)

---

### 6. MCP Content Extraction

**Directory**: `mcp-content/`

**Purpose**: Extract content from PDFs, YouTube, web pages for AI summarization.

**Key Changes**:
- Build `pkgs/mcp-content` MCP server
- Tools: `extract_pdf`, `extract_youtube`, `extract_url`
- Wrap: poppler-utils, yt-dlp, whisper-cpp, readability-cli

**Depends On**: None

---

### 7. MCP Screenshot

**Directory**: `mcp-screenshot/`

**Purpose**: Programmatic screenshot capture for AI vision workflows.

**Key Changes**:
- Build `pkgs/mcp-screenshot` MCP server
- Tools: `capture_screen`, `capture_window`, `capture_region`
- Wrap: grim, slurp (Wayland screenshot tools)

**Depends On**: Desktop module (for grim/slurp)

---

### 8. TTS Integration

**Directory**: `tts-integration/`

**Purpose**: Text-to-speech for accessibility and voice feedback.

**Key Changes**:
- Add `services.ai.tts` module
- Integrate piper-tts (high-quality neural TTS)
- `axios-speak` CLI command
- Optional MCP tool for AI-initiated speech

**Depends On**: None

---

## Port Allocation Summary

| Service | Local Port | Tailscale Port | Proposal |
|---------|------------|----------------|----------|
| axios-ai-mail | 8080 | 8443 | Existing |
| Open WebUI | 8081 | 8444 | #2 |
| axios Portal | 8082 | 8445 | #5 |
| axios-calendar | 8083 | 8446 | #4 (future) |
| Ollama API | 11434 | 8447 | #1 |

---

## Icon Requirements

All PWAs follow axios icon pattern (NixOS snowflake + axios colors + center element):

| Service | Center Element | File |
|---------|----------------|------|
| axios-ai-mail | Envelope | `axios-ai-mail.png` (exists) |
| Axios AI Chat | Chat bubble | `axios-ai-chat.png` (new) |
| axios Portal | Grid/dashboard | `axios-portal.png` (new) |
| axios Calendar | Calendar | `axios-calendar.png` (future) |

---

## Implementation Order Recommendation

### Wave 1 (Foundation)
1. **AI Module Refactor** - Enables everything else
2. **Port Registry** - Governance, quick win

### Wave 2 (Mobile Ecosystem)
3. **Open WebUI** - Mobile AI access
4. **MCP Calendar** - Can be parallel with #3

### Wave 3 (Polish)
5. **axios Portal** - Ties ecosystem together
6. **MCP Content** - Enhances AI capabilities

### Wave 4 (Nice to Have)
7. **MCP Screenshot** - Visual workflows
8. **TTS** - Accessibility

---

## What We Decided NOT To Do

| Rejected Option | Reason |
|-----------------|--------|
| Adopt clawdbot | 60% feature waste, macOS-centric, separate plugin architecture |
| Telegram bot | Open WebUI provides better UX |
| Matrix bridge | Complexity not justified |
| Webhook receiver | Open WebUI covers this better |
| Cloud TTS | Privacy, cost, axios philosophy |

---

## Next Steps

1. Review and approve proposals
2. Prioritize Wave 1 implementation
3. Create tasks.md for each approved proposal
4. Begin implementation

---

*Generated from clawdbot evaluation session, January 2026*
