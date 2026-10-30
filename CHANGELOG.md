# Changelog

## 1.1.0

- **MCP server**: Claude, Cursor and other MCP clients can ask RamDock about memory, CPU and the heaviest processes (`RamDock --mcp`). Read-only: an AI can't quit processes

## 1.0.0

- System RAM and CPU usage in the menu bar, colored from green to red as the load rises
- Click for every process with its CPU and memory, sortable by RAM or CPU, searchable by name or PID
- Quit any of your processes from the list; ⌥-click or right-click → Force Quit sends SIGKILL
- Settings: show RAM, CPU or both, text size, label and value colors, live preview
- This Mac: model, chip, CPU and GPU cores, memory, storage, macOS version, uptime
- Open at login, automatic updates through Sparkle
