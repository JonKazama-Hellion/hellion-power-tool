# Hellion Power Tool v7.2.0.0 "Heimdall"

![Version](https://img.shields.io/badge/Version-7.2.0.0%20Heimdall-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207.x-blue?logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011%20%7C%20Server-green?logo=windows)
![License](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-orange)

Windows System-Wartungstool mit modularer Architektur, intelligentem Launcher-System und automatischen Updates.
PowerShell-basiert, Defender-optimiert, vollständig Open Source.

Entwickelt von **JonKazama-Hellion**.

---

## Features

### System-Reparatur

- **SFC-Scan** — Windows Systemdateien prüfen und reparieren
- **DISM-Reparatur** — Windows Component Store wiederherstellen
- **CheckDisk** — Dateisystem auf Fehler prüfen
- **DLL-Integrität** — Kritische System-DLLs verifizieren
- **Kombinierter Modus** — SFC, CheckDisk und DISM nacheinander ausführen

### System-Bereinigung

- **Umfassende Bereinigung** — Temp-Dateien, Cache, Logs, Browser-Daten
- **Performance-Optimierung** — Services optimieren, Autostart bereinigen
- **Bloatware-Erkennung** — Vorinstallierte und ungenutzte Programme identifizieren
- **Schnell-Bereinigung** — Grundreinigung in unter 5 Minuten

### Diagnose

- **System-Info** — Detaillierte Hardware- und Software-Analyse (CPU, RAM, Disk, Treiber)
- **Netzwerk-Test** — Internet-Konnektivität, DNS-Resolution, Download-Performance
- **Treiber-Diagnose** — Veraltete, problematische und unsignierte Treiber finden (inkl. ENE.sys)
- **Bluescreen-Analyse** — Crash-Logs auswerten, Ursachen identifizieren
- **RAM-Test** — Windows Memory Diagnostic mit Ergebnis-Auswertung
- **System-Report** — Vollständigen Analysebericht als Datei exportieren

### Verwaltung

- **Wiederherstellungspunkte** — Erstellen, anzeigen, wiederherstellen, System Restore aktivieren
- **Winget-Integration** — Software-Updates prüfen, installieren, Software suchen
- **Netzwerk-Reset** — TCP/IP Stack, DNS-Cache, Winsock zurücksetzen
- **Safe Adblock** — DNS-basierter Werbeblocker via Hosts-Datei

### Auto-Modi

- **Auto-Modus** — Vollautomatische Systembereinigung und -optimierung
- **Quick-Clean** — Schnelle Bereinigung ohne Rückfragen

### Launcher-System

- **Smart Launcher** — Erkennt PowerShell 7 automatisch (PATH, Direct Path, Store)
- **Auto-Update** — Versions-Check gegen GitHub, automatischer Download mit Backup
- **Emergency-Updater** — Repariert defekte Update-Systeme
- **PowerShell 7 Installation** — Ein-Klick-Installation via winget
- **Git Installation** — Ein-Klick-Installation via winget
- **Desktop-Verknüpfung** — Shortcut mit Custom-Icon erstellen

### Sicherheit

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
| Launcher | Batch (CMD), Delayed Expansion |
| Module | 18 PowerShell-Module (dot-sourced) |
| API-Aufrufe | CIM/WMI, Performance Counter, WinEvent |
| Updates | Git Clone (GitHub), Timestamp-Vergleich |
| Paketmanager | winget (für PS7/Git-Installation) |
| Konfiguration | JSON (settings.json, version.txt) |
| Logging | Dateibasiert + In-Memory-Buffer |

---

## Architektur

```text
hellion-power-tool/
├── START.bat                       # Hauptstarter (Menü, Optionen, Admin-Check)
├── hellion_tool_main.ps1           # Haupt-Script (Menü, Module laden, Debug-Modi)
├── Launcher/
│   ├── simple-launcher.bat         # Intelligenter Launcher mit PS7-Detection
│   ├── update-check.bat            # GitHub Update-Checker mit Auto-Update
│   ├── emergency-update.bat        # Notfall-Updater für defekte Systeme
│   ├── install-ps7.bat             # PowerShell 7 Installation via winget
│   └── install-git.bat             # Git Installation via winget
├── modules/
│   ├── auto-mode.ps1               # Auto- und Quick-Modus
│   ├── bloatware-detection-simple.ps1  # Bloatware-Erkennung
│   ├── config-utils.ps1            # Konfiguration laden/validieren
│   ├── crash-analyzer.ps1          # Bluescreen-Analyse
│   ├── defender-metadata.ps1       # AV-Sicherheitsdeklarationen
│   ├── defender-safe-launcher.ps1  # Defender-sichere Ausführung
│   ├── disk-maintenance.ps1        # SFC, DISM, CheckDisk
│   ├── dll-integrity.ps1           # DLL-Integritätsprüfung
│   ├── driver-diagnostic.ps1       # Treiber-Diagnose
│   ├── logging-utils.ps1           # Logging-System (3 Level)
│   ├── memory-diagnostic.ps1       # RAM-Test (mdsched.exe)
│   ├── network-tools.ps1           # Netzwerk-Tests und Reset
│   ├── security-tools.ps1          # Safe Adblock, Sicherheits-Features
│   ├── sfc-simple.ps1              # SFC-Scan (vereinfacht)
│   ├── system-cleanup.ps1          # Bereinigung und Performance
│   ├── system-info.ps1             # Hardware/Software-Analyse
│   ├── system-restore.ps1          # Wiederherstellungspunkte
│   └── winget-tools.ps1            # Software-Updates via winget
├── config/
│   ├── version.txt                 # Version, Codename, Datum, Timestamp
│   ├── settings.json               # Feature-Flags und Einstellungen
│   └── repository.txt              # GitHub-Repository-URL
├── assets/
│   ├── create-desktop-shortcut.bat # Desktop-Verknüpfung erstellen
│   ├── create-shortcut.ps1         # Shortcut mit Icon-Support
│   └── Gmark.ico                   # Tool-Icon
├── scripts/
│   ├── sign-local.ps1              # Code-Signierung (lokal)
│   └── test-signing.ps1            # Signatur-Verifikation
├── Debug/
│   ├── launch-dev.ps1              # Entwickler-Launcher
│   └── launch-dev.cmd              # CMD-Wrapper für Dev-Launcher
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

- **Modular** — Jede Funktion ist ein eigenständiges PowerShell-Modul
- **Dual-kompatibel** — Läuft auf PowerShell 5.1 und 7.x ohne Anpassungen
- **Defender-safe** — Code-Patterns vermeiden heuristische AV-Erkennung
- **Self-Updating** — Automatischer Update-Check gegen GitHub mit Backup und Rollback
- **Fail-safe** — Wiederherstellungspunkte vor kritischen Operationen, Fehlerbehandlung in jedem Modul

---

## Installation

### Option 1: ZIP-Download

```text
1. ZIP von GitHub herunterladen
2. Entpacken
3. START.bat doppelklicken
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

| Modus | Aktivierung | Ausgabe |
| ----- | ----------- | ------- |
| Normal (0) | Standard | Nur Ergebnisse |
| Debug (1) | `-DebugMode` oder Menü | Erweiterte Informationen |
| Developer (2) | `-DevMode` oder Menü | Alle Debug-, Verbose- und Trace-Meldungen |

```bash
# Normal starten
START.bat

# Debug-Modus via PowerShell
pwsh -ExecutionPolicy Bypass -File hellion_tool_main.ps1 -DebugMode

# Developer-Modus via PowerShell
pwsh -ExecutionPolicy Bypass -File hellion_tool_main.ps1 -DevMode

# Debug-Level direkt setzen
pwsh -ExecutionPolicy Bypass -File hellion_tool_main.ps1 -ForceDebugLevel 2
```

---

## Update-System

Das Tool prüft via Git Clone gegen das GitHub-Repository auf neue Versionen. Der Vergleich basiert auf `config/version.txt` (Version + Timestamp).

Bei verfügbarem Update:

1. Backup der aktuellen Installation in `backups/`
2. Download der neuen Version
3. User-Einstellungen (`settings.json`) werden übernommen
4. Separater Installer-Prozess ersetzt die Dateien

Manueller Update-Check: START.bat > Option U

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

**Hellion Power Tool** — JonKazama-Hellion
