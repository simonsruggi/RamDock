# RamDock — architecture notes

Menu bar app (`LSUIElement`, no Dock icon). The status item shows system-wide `RAM xx%  CPU yy%`; clicking it opens a panel with per-process CPU and memory and a button to quit each process.

## Layout

- `main.swift` — starts `NSApplication` with `StatusBarController` as delegate. Pure AppKit, no SwiftUI.
- `MenuBar/StatusBarController` — status item, 3 s timer, opens/closes the panel.
- `MenuBar/DropdownPanel` — the panel: a borderless `NSPanel` with an `NSVisualEffectView` (`.popover` material), anchored under the status item, closed by a click in another app (global event monitor) or Esc.
- `Views/PanelViewController` — swaps the process list and Settings.
- `Views/List/*` — process list (`NSTableView`, reused `ProcessCellView` rows, context menu).
- `Views/Settings/*` — settings cards, live preview of the status item, color swatches, About, This Mac.
- `Services/*` — everything that isn't a view: sampling, system stats, colors, settings storage, Sparkle, launch at login, hardware info.

## Data

- **Status item**: `SystemStats` every 3 s. RAM = app memory + wired + compressed (Activity Monitor's "Memory Used"); CPU = average of all cores from `HOST_CPU_LOAD_INFO`. `BarTitle` builds the attributed string for both the status item and the Settings preview; the title is only reassigned when it changes.
- **Colors** (`LoadColor`): RAM green up to 50%, red from 92%; CPU green up to 15%, red from 85%.
- **Processes** (`ProcessSampler`): `proc_listallpids` + `proc_pid_rusage(RUSAGE_INFO_V4)` every 2 s, **only while the panel is open**. CPU % = delta of user+system time between two samples (100% = one core, as in Activity Monitor); memory = `ri_phys_footprint` (Activity Monitor's "Memory" column). Only the current user's processes are readable without privileges, and only those can be quit anyway.
- **Names**: one `NSWorkspace.runningApplications` call per refresh for registered apps, `proc_pidpath` / `proc_name` for everything else. Icons are flattened to 36 px bitmaps (`IconCache`).
- **Quit**: ✕ sends SIGTERM; ⌥-click or "Force Quit" sends SIGKILL.

## Settings (UserDefaults)

| Key | Values |
|---|---|
| `barDisplay` | `both`, `memory`, `cpu` |
| `barFontSize` | 9–18 (default 12) |
| `barLabelColor` | `""` = system, or `#RRGGBB` |
| `barValueColor` | `""` = by load, or `#RRGGBB` |
| `sortKey` | `RAM`, `CPU` |

The status item redraws on `UserDefaults.didChangeNotification`, using the last sampled values.

## Hardware info (`MacInfo`)

Marketing model from `IODeviceTree:/product` → `product-name`; chip from `machdep.cpu.brand_string`; cores per cluster from `hw.perflevelN.*`; GPU name and core count from the `AGXAccelerator` service (`model`, `gpu-core-count`); disk from the root volume's resource values. Read once, off the main thread.

## Why it's this light

Measured with `footprint`:

- An `NSPopover` keeps ~25 MB alive after its first open **even with an empty view**; a translucent `NSPanel` with real controls costs ~18 MB. Hence `DropdownPanel` instead of `NSPopover`.
- SwiftUI was not the main cost, but AppKit avoids its caches; the SwiftUI version lives in the `swiftui` branch for reference.
- Calling `NSRunningApplication(processIdentifier:)` for each of ~600 pids left ~6 MB behind; one `runningApplications` call per refresh doesn't.
- A closed `NSPopover` keeps its SwiftUI view alive, so `onDisappear` never fired and sampling ran forever: sampling is now started and stopped by the panel itself, and the panel is rebuilt on every open and released on close.

Result: ~13 MB at launch, ~27–35 MB after using the panel, ~0.15 s of CPU per minute while closed.

## Build and release

- `./build-app.sh [--install]` → universal `build/RamDock.app`, signed with a Developer ID when available (ad-hoc otherwise), optionally copied to `/Applications`.
- `RAMDOCK_SCREENSHOT=1` renders the panel opaque, for README screenshots.
- `./release.sh <version> <build>` (local, gitignored): build, sign (Sparkle framework inside out), notarize, staple, Sparkle EdDSA signature, `appcast.xml`, GitHub release, Homebrew cask bump. Release notes go in `release-notes/<version>.html`.
- Icon: `swift icon/make-icon.swift out.png` → iconset → `RamDock/Resources/AppIcon.icns`.
