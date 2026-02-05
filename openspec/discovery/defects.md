# Defect Tracker

## Purpose

Lightweight tracking of discovered defects. This log serves as:
- Historical context for future proposals
- Reference when investigating related issues
- Input for prioritizing fix work

Defects here don't require immediate action. When a fix is planned, create a proposal in `openspec/changes/` and reference the defect ID.

## Status Legend

- **open** - Reported, not yet addressed
- **investigating** - Root cause being determined
- **proposal** - Fix planned in `openspec/changes/`
- **resolved** - Fixed and verified
- **wontfix** - Decided not to fix (with rationale)
- **upstream** - Issue in external dependency, not axiOS

## Defect Log

<!-- Template for new entries:
### DEF-XXX: Short description
- **Status**: open
- **Reported**: YYYY-MM-DD
- **Source**: github-issue / user-report / internal
- **Component**: module or area affected
- **Symptoms**: What the user observes
- **Context**: Relevant logs, error messages, or reproduction steps
- **Proposal**: (when fix is planned) openspec/changes/xxx/
- **Resolution**: (when resolved) Brief description of fix
-->

### DEF-001: Browser audio not playing
- **Status**: upstream
- **Reported**: 2026-02-04
- **Source**: user-report
- **Component**: desktop / audio
- **Symptoms**: Audio does not play from browser applications
- **Context**: WirePlumber fails to create HDMI sink at boot time due to race condition. Log shows: `s-monitors: Failed to create alsa_output.pci-0000_2f_00.1.hdmi-stereo-extra2: Object activation aborted: PipeWire proxy destroyed`. Audio routes to wrong sink (USB microphone instead of HDMI).
- **Proposal**: N/A - upstream WirePlumber/PipeWire issue
- **Resolution**: Workaround: `systemctl --user restart pipewire pipewire-pulse wireplumber`. HDMI sink initializes correctly on restart. Root cause is boot-time race in WirePlumber HDMI detection.

---

## Metrics

| Status | Count |
|--------|-------|
| open | 0 |
| investigating | 0 |
| proposal | 0 |
| resolved | 0 |
| wontfix | 0 |
| upstream | 1 |
| **Total** | 1 |

## Cross-References

- **GitHub Issues**: https://github.com/kcalvelli/axios/issues
- **Unknowns**: `openspec/discovery/unknowns.md`
- **Concerns**: `openspec/discovery/concerns.md`
