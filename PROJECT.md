# RamDock

App macOS da barra dei menu (in alto a destra, niente icona nel Dock: `LSUIElement`). Nella barra: `RAM xx%  CPU yy%` di sistema, con le percentuali colorate dal verde al rosso; al clic, popover con CPU e RAM dei processi e bottone per chiuderli.

- Barra: `NSStatusItem` con `attributedTitle` (un `MenuBarExtra` rende l'etichetta come template monocromatico e perde i colori), aggiornata ogni 3 s da `SystemStats`: RAM = app + wired + compressa ("Memoria utilizzata" di Monitoraggio Attività), CPU = media di tutti i core da `HOST_CPU_LOAD_INFO`. Colore in `LoadColor`: RAM verde fino al 50%, rossa dal 92%; CPU verde fino al 15%, rossa dall'85%.

- Pannello ordinato per RAM di default .
- Popover SwiftUI (`NSPopover` + `NSHostingController`), SPM, zero dipendenze, macOS 14+.
- Dati: `proc_listallpids` + `proc_pid_rusage(RUSAGE_INFO_V4)`. CPU % = delta user+system tra due campioni (2 s), come Monitoraggio Attività (100% = un core); RAM = `ri_phys_footprint` (colonna "Memoria" di Monitoraggio Attività).
- Campiona **solo a pannello aperto** (`onAppear`/`onDisappear`): chiuso resta solo il titolo della barra ogni 3 s.
- Visibili solo i processi dell'utente (quelli di root/altri utenti `proc_pid_rusage` non li legge e comunque non si possono chiudere senza privilegi).
- Chiusura: ✕ = SIGTERM, ⌥+clic o menu contestuale "Forza chiusura" = SIGKILL.
- Build: `./build-app.sh --install` → `build/RamDock.app` universale, firmata Developer ID se c'è, copiata in `/Applications`.
- Icona: `swift icon/make-icon.swift out.png` → iconset → `RamDock/Resources/AppIcon.icns`.
- Interfaccia **solo in inglese** (`CFBundleDevelopmentRegion` en). I nomi delle app vengono da `NSRunningApplication.localizedName`, quindi seguono la lingua di sistema (es. "Terminale").
- **Settings** (ingranaggio accanto alla ricerca): cosa mostra la barra, `BarDisplay` = RAM and CPU / RAM only / CPU only, chiave `barDisplay` in UserDefaults. La barra si ridisegna subito via `UserDefaults.didChangeNotification` con gli ultimi valori campionati.
- Settings → **Menu bar**: anche dimensione del testo (9–18 pt, `barFontSize`), colore delle etichette (`barLabelColor`, "" = System) e dei valori (`barValueColor`, "" = By load, cioè verde→rosso). Colori salvati come `#RRGGBB` in sRGB (`BarStyle`).
- Settings → **This Mac** (`MacInfo`): modello commerciale da `IODeviceTree:/product` `product-name`, chip da `machdep.cpu.brand_string`, core per livello da `hw.perflevelN.*`, GPU e core da `AGXAccelerator` (`model`, `gpu-core-count`), RAM, disco libero/totale, macOS e build, uptime. Letti una volta all'apertura, in background.
- **Design delle Settings** (rifatte 09/10 perché il `Form` grouped era brutto): niente `Form` né popup, ma card su misura (`SettingsCard`), anteprima live della barra (`BarPreview`, legge `BarReadings` condiviso con lo status item), controllo segmentato Both/RAM/CPU, colori come pallini (`ColorSwatches`: automatico + 7 preset + pallino arcobaleno che apre `NSColorPanel` via `ColorPanelBridge`; il `ColorPicker` SwiftUI su macOS 26+ è una pillola larga), scheda Mac con riquadri (`SpecTile`) e barra del disco. Numeri in formato inglese.
