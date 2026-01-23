# Tasks: Streamlined Flatpak Installation

## Status: Backlog

## Overview

Enable one-click Flatpak installation from Flathub website without requiring a full app store like KDE Discover.

---

## Phase 1: Research

### Task 1.1: Analyze Flathub Install Flow
- [ ] Visit Flathub, click "Install" on an app
- [ ] Determine what file/URI is triggered
- [ ] Check browser download behavior
- [ ] Document MIME types involved

### Task 1.2: Research Existing Solutions
- [ ] Check how Fedora Silverblue handles this
- [ ] Look for minimal flatpak installer tools
- [ ] Review `flatpak-xdg-utils` capabilities
- [ ] Check if xdg-desktop-portal handles this

### Task 1.3: Evaluate Handler Options
- [ ] Test terminal-based handler approach
- [ ] Test notification + background approach
- [ ] Evaluate zenity/kdialog for minimal GUI
- [ ] Decision: Choose approach

---

## Phase 2: Implementation

### Task 2.1: Create Handler
- [ ] Write handler script or package
- [ ] Handle `.flatpakref` files
- [ ] Handle `flatpak://` URIs (if applicable)
- [ ] Include error handling

### Task 2.2: Create NixOS Module
- [ ] Add to `modules/desktop/flatpak.nix` (or new file)
- [ ] Register MIME handler
- [ ] Ensure XDG integration

### Task 2.3: Browser Integration
- [ ] Verify Brave handles the file type
- [ ] Test "Open with" behavior
- [ ] Ensure seamless handoff

---

## Phase 3: Polish

### Task 3.1: User Experience
- [ ] Add progress indication
- [ ] Add success/failure notification
- [ ] Test error cases (network, permissions)

### Task 3.2: Optional: Flathub PWA
- [ ] Consider adding Flathub desktop entry
- [ ] Quick access to app discovery

---

## Phase 4: Documentation & Finalization

### Task 4.1: Documentation
- [ ] Update relevant specs
- [ ] Document in MODULE_REFERENCE.md

### Task 4.2: Archive
- [ ] Archive this change directory

---

## Blocked By

None - ready for research when prioritized.

## Priority

**Low** - Nice-to-have UX improvement. Current workaround: use `flatpak install` CLI.
