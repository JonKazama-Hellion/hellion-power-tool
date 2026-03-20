# Hellion Power Tool v8.0.0.0 "Jörmungandr"

![Version](https://img.shields.io/badge/Version-8.0.0.0%20Jörmungandr-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207.x-blue?logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011%20%7C%20Server-green?logo=windows)
![License](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-orange)
![GUI](https://img.shields.io/badge/GUI-WPF%20Dark%20%26%20Light%20Mode-448f45)

Windows System-Wartungstool mit WPF-Oberfläche, modularer Architektur, intelligentem Launcher-System und automatischen Updates.
PowerShell-basiert, Defender-optimiert, vollständig Open Source.

Entwickelt von **[Hellion Online Media](https://hellion-media.de)** — JonKazama-Hellion.

![Dark Mode](https://img.shields.io/badge/Theme-Dark%20%26%20Light-448f45)

---

## GUI-Modus (NEU)

Das Hellion Power Tool verfügt über eine vollwertige **WPF-Oberfläche** mit Dark und Light Mode. Der Endnutzer tippt keinen einzigen Befehl — alles wird per Mausklick gesteuert.

### Starten

```text
START.bat doppelklicken
```

PowerShell 7 wird automatisch erkannt. Fallback auf PowerShell 5.1 falls nicht installiert. Admin-Rechte werden per UAC angefordert.

### GUI-Features

- **Dark & Light Mode** — Live-Umschaltung ohne Neustart, Hellion-Grün (#448f45) als Akzentfarbe
- **17 Modul-Karten** — Visuell gruppiert nach Kategorie mit Akzentlinie und Hover-Animation
- **Modul-Vorauswahl** — Module mit mehreren Modi (SFC, Bereinigung, CheckDisk, Adblock, Wiederherstellung) zeigen ein Auswahl-Overlay
- **Live Log-Panel** — Farbige Echtzeit-Ausgabe aller Modul-Streams (Info, Warning, Error, Progress)
- **System-Health-Bar** — CPU, RAM und Disk-Auslastung in Echtzeit (konfigurierbares Intervall)
- **Dashboard** — Tageszeit-abhängiger Gruß, Kategorie-Sektionen mit Icons und Modul-Anzahl
- **Animationen** — Gestaffeltes Fade-In der Karten, Hover-Zoom mit DropShadow, pulsierender Live-Dot
- **Software-Installer** — 76 Programme in 11 Kategorien per Checkbox installieren (Ninite-Style via Winget)
- **System-Info-Seite** — Hardware-Übersicht (CPU, GPU, RAM, Mainboard, Disks, OS) mit Export
- **Einstellungen** — Theme, Health-Intervall, Log-Aufbewahrung, Auto-Scroll, Debug-Level
- **Rechtliches** — Datenschutz, Impressum, Disclaimer, Hellion Online Media Links
- **Auto-Update-Checker** — Prüft beim Start asynchron gegen GitHub, Toast bei neuem Update
- **Toast-Benachrichtigungen** — Windows-native Benachrichtigung bei Modul-Abschluss
- **Log-Verlauf** — Automatische JSON-Speicherung in `logs/gui/`
- **GridSplitter** — Log-Panel-Breite per Drag anpassbar (200–600px)
- **Dev-Mode** — 3 Stufen (Normal, Debug, Developer) mit StatusBar-Badge und erweitertem Logging
- **Sidebar-Navigation** — Icons via Segoe MDL2 Assets, 6 Kategorien + Software + System + Settings + Legal

### Software-Installer

Die Software-Seite bietet 76 verifizierte Winget-Pakete in 11 Kategorien:

| Kategorie | Pakete | Beispiele |
| --------- | ------ | --------- |
| Browser | 6 | Chrome, Firefox, Brave, Opera GX |
| Gaming | 4 | Steam, Epic Games, GOG Galaxy |
| Kommunikation | 6 | Discord, Teams, Telegram, Signal |
| Media | 7 | VLC, Spotify, OBS Studio, Audacity |
| Office & PDF | 4 | LibreOffice, Notepad++, Sumatra PDF, PDF24 |
| Imaging | 5 | GIMP, Paint.NET, ShareX, Greenshot |
| Coding | 5 | Git, VS Code, Cursor, WinSCP |
| Tools | 6 | 7-Zip, Everything, TreeSize, Rufus |
| Utilities | 11 | PowerToys, HWiNFO, Windhawk, EarTrumpet |
| Security | 4 | Bitdefender, Malwarebytes, Bitwarden |
| Runtimes | 9 | .NET 8/10, VC++ Redist, Java, Python, Docker |

Quick-Select-Buttons: **Empfohlen** (12 DAU-freundliche Basics), **Alle**, **Keine**. Bereits installierte Software wird automatisch erkannt und ausgegraut. Bestätigungs-Overlay mit Disclaimer vor jeder Installation.

---

## CLI-Modus

Das klassische Terminal-Interface über `START.bat` mit Menü-Navigation.

```text
START.bat doppelklicken
```

### Features

#### System-Reparatur

- **SFC-Scan** — Windows Systemdateien prüfen und reparieren
- **DISM-Reparatur** — Windows Component Store wiederherstellen
- **CheckDisk** — Dateisystem auf Fehler prüfen
- **DLL-Integrität** — Kritische System-DLLs verifizieren
- **Kombinierter Modus** — SFC, CheckDisk und DISM nacheinander ausführen

#### System-Bereinigung

- **Umfassende Bereinigung** — Temp-Dateien, Cache, Logs, Browser-Daten (4 Modi)
- **Performance-Optimierung** — Services optimieren, Autostart bereinigen
- **Bloatware-Erkennung** — Vorinstallierte und ungenutzte Programme identifizieren
- **Schnell-Bereinigung** — Grundreinigung in unter 5 Minuten

#### Diagnose

- **System-Info** — Detaillierte Hardware- und Software-Analyse (CPU, RAM, Disk, Treiber)
- **Netzwerk-Test** — Internet-Konnektivität, DNS-Resolution, Download-Performance
- **Treiber-Diagnose** — Veraltete, problematische und unsignierte Treiber finden (inkl. ENE.sys)
- **Bluescreen-Analyse** — Crash-Logs auswerten, Ursachen identifizieren
- **RAM-Test** — Windows Memory Diagnostic mit Ergebnis-Auswertung
- **System-Report** — Vollständigen Analysebericht als Datei exportieren

#### Verwaltung

- **Wiederherstellungspunkte** — Erstellen, anzeigen, wiederherstellen, System Restore aktivieren
- **Winget-Integration** — Software-Updates prüfen, installieren, Software suchen
- **Netzwerk-Reset** — TCP/IP Stack, DNS-Cache, Winsock zurücksetzen
- **Safe Adblock** — DNS-basierter Werbeblocker via Hosts-Datei

#### Auto-Modi

- **Auto-Modus** — Vollautomatische Systembereinigung und -optimierung
- **Quick-Clean** — Schnelle Bereinigung ohne Rückfragen

---

## Launcher-System

- **Smart Launcher** — Erkennt PowerShell 7 automatisch (PATH, Direct Path, Store)
- **Auto-Update** — Versions-Check gegen GitHub, automatischer Download mit Backup
- **Emergency-Updater** — Repariert defekte Update-Systeme
- **PowerShell 7 Installation** — Ein-Klick-Installation via winget
- **Git Installation** — Ein-Klick-Installation via winget
- **Desktop-Verknüpfung** — Shortcut mit Custom-Icon erstellen

---

## Sicherheit

- **Defender-optimiert** — Code-Patterns minimieren False-Positive-Erkennung
- **Defender-Metadata** — Eingebettete Sicherheitsdeklarationen für AV-Scanner
- **UAC-Elevation** — Automatische Admin-Rechte-Anforderung mit Parameter-Weiterleitung
- **Wiederherstellungspunkt vor kritischen Aktionen** — PS5 und PS7 kompatibel
- **Keine Datenexfiltration** — Netzwerkzugriff nur für Konnektivitätstests und Updates

---

## Tech-Stack

| Komponente | Details |
| ---------- | ------- |
| Sprache | PowerShell 5.1 / 7.x (Dual-kompatibel) |
| GUI | WPF (Windows Presentation Foundation), .NET Framework 4.8 |
| Launcher | Batch (CMD), Delayed Expansion |
| Module | 18 PowerShell-Module (dot-sourced) |
| API-Aufrufe | CIM/WMI, Performance Counter, WinEvent |
| Updates | Git Clone (GitHub), Timestamp-Vergleich |
| Paketmanager | winget (Software-Installer, PS7/Git-Installation) |
| Konfiguration | JSON (settings.json, gui-settings.json, modules.json, software-catalog.json) |
| Logging | Dateibasiert + In-Memory-Buffer + GUI Log-Verlauf (JSON) |
| Theme-System | DynamicResource-Brushes, Runtime-Switch Dark/Light |
| Animationen | WPF DoubleAnimation, DropShadowEffect, ScaleTransform |
| Icons | Segoe MDL2 Assets (Windows-System-Font) |
| Benachrichtigungen | Windows WinRT Toast API (kein externes Modul) |
| Build | PS2EXE (optionale .exe-Kompilierung) |

---

## Architektur

```text
hellion-power-tool/
├── START.bat                       # GUI-Einstieg (PS7-Detection, Admin-Elevation)
├── src/
│   ├── hellion_gui.ps1             # GUI-Quellcode (WPF, ~2500 Zeilen)
│   ├── hellion_main.ps1            # CLI-Quellcode (Menü, Module laden, Debug-Modi)
│   ├── gui/
│   │   └── window.xaml             # WPF-Layout (Styles, Brushes, UI-Struktur)
│   ├── modules/                    # 18 PowerShell-Module
│   │   ├── auto-mode.ps1           # Auto- und Quick-Modus
│   │   ├── bloatware-detection-simple.ps1  # Bloatware-Erkennung
│   │   ├── config-utils.ps1        # Konfiguration laden/validieren
│   │   ├── crash-analyzer.ps1      # Bluescreen-Analyse
│   │   ├── defender-metadata.ps1   # AV-Sicherheitsdeklarationen
│   │   ├── defender-safe-launcher.ps1  # Defender-sichere Ausführung
│   │   ├── disk-maintenance.ps1    # SFC, DISM, CheckDisk
│   │   ├── dll-integrity.ps1       # DLL-Integritätsprüfung
│   │   ├── driver-diagnostic.ps1   # Treiber-Diagnose
│   │   ├── logging-utils.ps1       # Logging-System (3 Level)
│   │   ├── memory-diagnostic.ps1   # RAM-Test (mdsched.exe)
│   │   ├── network-tools.ps1       # Netzwerk-Tests und Reset
│   │   ├── security-tools.ps1      # Safe Adblock, Sicherheits-Features
│   │   ├── sfc-simple.ps1          # SFC-Scan (vereinfacht)
│   │   ├── system-cleanup.ps1      # Bereinigung und Performance
│   │   ├── system-info.ps1         # Hardware/Software-Analyse
│   │   ├── system-restore.ps1      # Wiederherstellungspunkte
│   │   └── winget-tools.ps1        # Software-Updates via winget
│   └── launcher/                   # Starter und Installationshelfer
│       ├── start-cli.bat           # CLI-Menü (für Power-User)
│       ├── simple-launcher.bat     # Intelligenter Launcher mit PS7-Detection
│       ├── update-check.bat        # GitHub Update-Checker mit Auto-Update
│       ├── emergency-update.bat    # Notfall-Updater für defekte Systeme
│       ├── install-ps7.bat         # PowerShell 7 Installation via winget
│       ├── install-git.bat         # Git Installation via winget
│       ├── create-desktop-shortcut.bat  # Desktop-Verknüpfung erstellen
│       └── create-shortcut.ps1     # Shortcut mit Icon-Support
├── config/
│   ├── version.txt                 # Version, Codename, Datum, Timestamp
│   ├── settings.json               # Feature-Flags und Einstellungen
│   ├── repository.txt              # GitHub-Repository-URL
│   ├── gui-settings.json           # Persistente GUI-Einstellungen
│   ├── modules.json                # 17 Modul-Definitionen (Id, Func, Options, Group)
│   └── software-catalog.json       # 76 Winget-Pakete in 11 Kategorien
├── assets/
│   ├── branding/                   # Hellion Online Media Logo-Dateien
│   └── icons/
│       └── Gmark.ico               # Tool-Icon
├── build/
│   └── build-exe.ps1               # PS2EXE Build-Script
├── tests/
│   ├── audit-project.py            # Projekt-Audit (Umlaute, Bugs, Encoding)
│   ├── fix-umlauts.py              # Automatische Umlaut-Korrektur
│   ├── check-winget-catalog.ps1    # Winget-Katalog-Verifikation
│   ├── syntax-check.ps1            # Syntax-Prüfung für Module
│   ├── syntax-check-gui.ps1        # Syntax-Prüfung für GUI
│   ├── launch-dev.ps1              # Dev-Launcher für Tests
│   └── launch-dev.cmd              # Dev-Launcher (CMD-Variante)
├── logs/
│   └── gui/                        # GUI Log-Verlauf (JSON, automatisch)
├── docs/
│   ├── CHANGELOG.md                # Versions-Historie
│   ├── CONTRIBUTORS.md             # Mitwirkende
│   ├── DEFENDER-WHITELIST.md       # Defender False-Positive Anleitung
│   ├── LEARNING-JOURNEY.md         # Entwicklungsgeschichte
│   └── VERSION-FORMAT.md           # Versionierungs-Schema
├── DISCLAIMER.md                   # Rechtlicher Hinweis / Haftungsausschluss
├── SECURITY.md                     # Sicherheits-Informationen
└── LICENSE                         # CC BY-NC-SA 4.0
```

### Design-Prinzipien

- **GUI-First** — Endnutzer arbeiten mit der WPF-Oberfläche, CLI bleibt als Alternative
- **Modular** — Jede Funktion ist ein eigenständiges PowerShell-Modul
- **Dual-kompatibel** — Läuft auf PowerShell 5.1 und 7.x ohne Anpassungen
- **Defender-safe** — Code-Patterns vermeiden heuristische AV-Erkennung
- **Self-Updating** — Automatischer Update-Check gegen GitHub mit Backup und Rollback
- **Fail-safe** — Wiederherstellungspunkte vor kritischen Operationen, Fehlerbehandlung in jedem Modul
- **Runspace-basiert** — Module laufen asynchron im Hintergrund, GUI bleibt responsiv

---

## Installation

### Option 1: ZIP-Download

```text
1. ZIP von GitHub herunterladen
2. Entpacken
3. START.bat doppelklicken (GUI) oder src\launcher\start-cli.bat (CLI)
```

### Option 2: Git Clone

```bash
git clone https://github.com/JonKazama-Hellion/hellion-power-tool.git
cd hellion-power-tool
START.bat
```

Admin-Rechte werden automatisch angefordert (UAC). PowerShell 7 wird bei Bedarf zur Installation angeboten.

---

## Debug-Modi

Verfügbar in GUI (Settings-Seite) und CLI (Parameter):

| Modus | Aktivierung | Ausgabe |
| ----- | ----------- | ------- |
| Normal (0) | Standard | Nur Ergebnisse |
| Debug (1) | `-DebugMode` oder Settings/Menü | Modul-Laufzeiten, Validierung, erweiterte Infos |
| Developer (2) | `-DevMode` oder Settings/Menü | Stream-Statistiken, Runspace-Details, Health-Erweiterungen |

```bash
# GUI starten (Standard-Einstieg)
START.bat

# CLI starten (für Power-User)
src\launcher\start-cli.bat

# Debug-Modus via PowerShell
pwsh -ExecutionPolicy Bypass -File src\hellion_main.ps1 -DebugMode

# Developer-Modus via PowerShell
pwsh -ExecutionPolicy Bypass -File src\hellion_main.ps1 -DevMode
```

---

## Update-System

Das Tool prüft via Git Clone gegen das GitHub-Repository auf neue Versionen. Der Vergleich basiert auf `config/version.txt` (Version + Timestamp).

**GUI:** Automatischer Check beim Start (asynchron, blockiert nicht). Manuell via Settings > "Auf Updates prüfen".

**CLI:** start-cli.bat > Option U

Bei verfügbarem Update:

1. Backup der aktuellen Installation in `backups/`
2. Download der neuen Version
3. User-Einstellungen werden übernommen
4. Separater Installer-Prozess ersetzt die Dateien

---

## EXE-Kompilierung (optional)

Die GUI kann als eigenständige `.exe` kompiliert werden:

```powershell
# PS2EXE installieren (einmalig)
gui\build-exe.ps1 -Install

# EXE erstellen
gui\build-exe.ps1
```

Erzeugt `hellion-gui.exe` mit Icon, ohne Konsolenfenster, mit Admin-Rechte-Anforderung.

---

## Windows Defender

Windows Defender kann dieses Tool als `Trojan:Script/Wacatac.B!ml` markieren. Das ist ein **False Positive**.

Ursache: Administrative PowerShell-Operationen, Registry-Analyse, UAC-Elevation und Netzwerk-Tests lösen heuristische Erkennung aus.

Lösung: Tool-Ordner als Defender-Ausnahme hinzufügen. Details in [DEFENDER-WHITELIST.md](docs/DEFENDER-WHITELIST.md).

Der vollständige Quellcode ist einsehbar. Keine Malware, keine Datenexfiltration, keine versteckten Funktionen.

---

## Lizenz

Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International

- Kostenlos für private Nutzung
- Teilen und Modifikation erlaubt mit Namensnennung
- Kommerzielle Nutzung ohne Erlaubnis verboten

Vollständige Lizenz: [LICENSE](LICENSE)

---

**Hellion Power Tool** — [Hellion Online Media](https://hellion-media.de) — JonKazama-Hellion
