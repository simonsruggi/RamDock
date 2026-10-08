# ProcDock

App macOS da barra dei menu (in alto a destra, niente icona nel Dock: `LSUIElement`) che mostra CPU e RAM dei processi e permette di chiuderli.

- SwiftUI `MenuBarExtra` stile `.window`, SPM, zero dipendenze, macOS 14+.
- Dati: `proc_listallpids` + `proc_pid_rusage(RUSAGE_INFO_V4)`. CPU % = delta user+system tra due campioni (2 s), come Monitoraggio Attività (100% = un core); RAM = `ri_phys_footprint` (colonna "Memoria" di Monitoraggio Attività). In alto la CPU totale divisa per il numero di core.
- Campiona **solo a pannello aperto** (`onAppear`/`onDisappear`): chiuso sta a 0% CPU, ~36 MB.
- Visibili solo i processi dell'utente (quelli di root/altri utenti `proc_pid_rusage` non li legge e comunque non si possono chiudere senza privilegi).
- Chiusura: ✕ = SIGTERM, ⌥+clic o menu contestuale "Forza chiusura" = SIGKILL.
- Build: `./build-app.sh --install` → `build/ProcDock.app` universale, firmata Developer ID se c'è, copiata in `/Applications`.
- Icona: `swift icon/make-icon.swift out.png` → iconset → `ProcDock/Resources/AppIcon.icns`.
