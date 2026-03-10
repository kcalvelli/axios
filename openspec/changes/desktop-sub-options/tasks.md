## 1. Add Sub-Option Declarations

- [x] 1.1 Add `desktop.media.enable`, `desktop.office.enable`, `desktop.streaming.enable`, `desktop.social.enable` options to `modules/desktop/default.nix`, all defaulting to `true`

## 2. Restructure Package List

- [x] 2.1 Wrap media packages (gwenview, tauon, ffmpeg, wf-recorder, swappy, krita) in `lib.mkIf config.desktop.media.enable`
- [x] 2.2 Wrap office packages (libreoffice-qt, ghostwriter, okular, qalculate-qt, filelight) in `lib.mkIf config.desktop.office.enable`
- [x] 2.3 Wrap streaming packages (obs-studio-gamemode wrapper, discord) in `lib.mkIf config.desktop.streaming.enable`
- [x] 2.4 Wrap social packages (materialgram, spotify, zenity) in `lib.mkIf config.desktop.social.enable`
- [x] 2.5 Keep remaining packages in the core `desktop.enable` block

## 3. Remove Packages

- [x] 3.1 Remove profanity from `modules/desktop/default.nix`
- [x] 3.2 Remove c64term from `modules/desktop/default.nix`
- [x] 3.3 Remove gajim from `modules/desktop/default.nix`

## 4. Validation

- [x] 4.1 Run `nix fmt .` to format all modified files
- [x] 4.2 Run `nix flake check --all-systems` to verify no evaluation errors
