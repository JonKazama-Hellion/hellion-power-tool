# Changelog — Hellion Power Tool

Alle wichtigen Änderungen an diesem Projekt dokumentiere ich in dieser Datei.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und das Projekt folgt der [Semantischen Versionierung](https://semver.org/lang/de/).

---

## [7.2.0.0 "Heimdall"] — 2026-03-15

### Hellion Online Media Branding & Professionalisierung

Komplette Überarbeitung des gesamten Projekts auf den neuen [Hellion Online Media](https://hellion-media.de) Markenstil.

#### Branding

- **Neues Farbschema**: `color 0A` (Grün auf Schwarz) als durchgängige Markenfarbe
- **Hellion Online Media Subtitle**: In allen Launcher-Headern und Menüs
- **Einheitlicher Header-Stil**: `================================================================` mit 3-Space Indent in allen Batch-Dateien
- **Menü-Redesign**: Strukturierte Sektionen mit `--- SEKTION ---` Überschriften
- **Aufgeräumte Ausgaben**: `[*]`, `[INFO]`, `[MENU]` Tag-Prefixe entfernt — saubererer Text

#### Launcher-Dateien (7 Dateien überarbeitet)

- **START.bat** — Neues Hauptmenü mit Sektionen (Optionen, Installation, Updates, Info)
- **simple-launcher.bat** — Erweiterte Optionen mit einheitlichem Layout
- **update-check.bat** — Farbe von Cyan (0B) auf Grün (0A), neuer Header
- **emergency-update.bat** — Header restyled, Rot (0C) beibehalten (Emergency)
- **install-git.bat** — Header restyled, Gelb (0E) beibehalten (Installation)
- **install-ps7.bat** — Header restyled, Magenta (0D) beibehalten (Installation)
- **create-desktop-shortcut.bat** — Farbe auf Grün (0A), neuer Header

#### Umlaut-Korrektur (22 Dateien)

- **Alle PowerShell-Module**: `ae` → `ä`, `oe` → `ö`, `ue` → `ü` in allen Ausgabetexten
- **Batch-Dateien bewusst ausgenommen**: Kein `chcp 65001` gesetzt, CMD verwendet CP850 — Umlaute würden dort als Sonderzeichen dargestellt
- **Syntaxprüfung**: Alle 22 PS1-Dateien nach der Umstellung auf korrekte Syntax geprüft — keine Parse-Fehler
- **Nur Display-Strings betroffen**: Keine Logik-Änderungen, nur `Write-Host`, `Write-Log`, `Write-Information`

#### Hauptmenü (hellion_tool_main.ps1)

- **Neues Farbschema**: Grüner Hellion-Media-Stil statt Cyan
- **Zweifarbige Menüeinträge**: Weiße Optionsnummern + DarkGray Beschreibungen
- **Kategorie-Header**: `--- SYSTEM ---`, `--- DIAGNOSE ---`, `--- VERWALTUNG ---`, `--- AUTO ---`
- **Hellion Online Media Subtitle**: Im ASCII-Header

#### Dokumentation

- **README.md** — Professionell umgeschrieben mit korrekten Umlauten und Du-Form
- **DISCLAIMER.md** — Rechtlicher Haftungsausschluss nach BGB §§ 516ff, § 521, § 524
- **SECURITY.md** — Professionell, Ich-Form, Links zu [hellion-media.de](https://hellion-media.de)
- **DEFENDER-WHITELIST.md** — Aufgeräumt, Links zu hellion-media.de
- **VERSION-FORMAT.md** — Aktualisiert auf v7.2.0.0, Tabellen-Format korrigiert
- **CHANGELOG.md** — Komplett aktualisiert mit allen v7.2.0.0 Änderungen

#### CI/CD

- **CodeQL-Job entfernt**: `security-analysis` Job aus `.github/workflows/security.yml` entfernt — Repository enthält kein JavaScript, CodeQL schlug fehl
- **PSScriptAnalyzer + Defender-Checks beibehalten**: Nur relevante Security-Checks laufen weiter

#### Website (hellion-media.de)

- **Hellion Power Tool als Referenz** auf der Referenz-Seite hinzugefügt
- **Eigene Produktseite** unter `/hellion-power-tool` mit Download-Button und Feature-Übersicht
- **Footer-Link** im Tools-Bereich hinzugefügt

---

## [7.1.5.3 "Baldur"] — 2025-09-13

### Bug Fixes

- **PowerShell.Diagnostics Modul-Laden**: Graceful Degradation wenn Modul nicht verfügbar
- **ForegroundColor Orange Fehler**: Auf DarkYellow geändert (gültiger PowerShell-Farbwert)
- **NT Object Manager Pfadfehler**: Korrekte Konvertierung von `\??\C:` Pfaden für Signaturprüfung
- **Treiber-Diagnose Robustheit**: Bessere Fehlerbehandlung bei Pfad- und Signaturproblemen

---

## [7.1.5.2 "Baldur"] — 2025-09-10

### Kritische Bugfixes

- **Get-WinEvent Modul-Fehler**: `Microsoft.PowerShell.Diagnostics` Import mit Fallback-Handling
- **Doppelte Enter-Bestätigung**: Im Wiederherstellungspunkt-Modul entfernt
- **TCP/IP Reset Fehler**: Admin-Rechte-Prüfung und bessere Fehlerbehandlung für netsh-Befehle
- **Batch Unicode-Probleme**: Versteckte Unicode-Zeichen in simple-launcher.bat verursachten Befehlsfehler
- **Update-Installer Escaping**: Falsche `^>nul` durch korrekte `^^^>nul` Batch-Escaping-Sequenzen ersetzt

### Stabilität

- **Graceful Degradation**: Event Log Analyse funktioniert auch ohne PowerShell Diagnostics Modul
- **Robuste Fehlerbehandlung**: Netzwerk-Tools arbeiten auch bei partiellen Fehlern weiter
- **ASCII-Kompatibilität**: Alle Batch-Dateien nutzen ASCII-kompatible Zeichen

---

## [7.1.5.1 "Baldur"] — 2025-09-09

### UI/UX Release — Community Bug Marathon

#### Kritische Bugfixes

- **Menü-System**: 7+ Switch-Case Zuordnungen waren falsch — Option 3–7 führten andere Funktionen aus als angezeigt
- **Fehlende Menü-Optionen**: E, S, D, R Optionen waren nicht erreichbar
- **Wiederherstellungspunkt-Manager**: Fehlende `Invoke-RestorePointManager` Funktion implementiert
- **NetTCPIP Module Loading**: Fallback auf `System.Net.Sockets.TcpClient`
- **24h Restore Point Limit**: Registry-Bypass für Windows 1440-Minuten Limitation
- **Winget Update Placeholders**: "Update0, Update1, Update2" durch echte Software-Namen ersetzt

#### UI/UX Modernisierung

- **Einheitliches Menü-Design**: Alle 15+ Module auf konsistentes Design umgestellt
- **Farbschema-Optimierung**: Übermäßige Buntheit reduziert — nur essenzielle Farben
- **ASCII-Kompatibilität**: Alle UTF-8 Emojis durch ASCII-sichere Zeichen ersetzt
- **20 Bug Reports** verarbeitet, **15 UI/UX Verbesserungen** umgesetzt

---

## [7.1.5.0 "Baldur"] — 2025-09-09

### Neue Features: Erweiterte Treiber-Diagnose

- **Treiber-Diagnostik Modul**: Komplett neues Modul für erweiterte Driver-Analyse
  - ENE.SYS Spezial-Behandlung für Card Reader Probleme
  - Automatische Treiber-Reparatur mit Backup-System
  - Driver Store Bereinigung und Zwangs-Entfernung
  - WMI-basierte Hardware-Erkennung statt CSV-Parsing
  - Sicherheits-Whitelist verhindert versehentliche System-Treiber Löschung
- **ENE-Hardware-Filterung**: Präzise Erkennung echter ENE-Hardware (Vendor ID 1524)
- **Force-Removal-Funktion**: Für problematische Treiber die nicht normal deinstalliert werden können
- **Event-Log-Analyse**: Sucht automatisch nach treiber-bedingten Systemfehlern
- **Driver Verifier Integration**: Erweiterte Treiber-Tests möglich

---

## [7.1.4.3 "Odin"] — 2025-09-09

### Update-Checker komplett neu programmiert

- **Update-Checker**: Komplett neuer `update-check.bat` (334 → 277 Zeilen)
- **False-Positive Updates behoben**: Kein falsches Update-Angebot mehr bei identischen Versionen
- **Timestamp-basierte Versionierung**: Präziser Vergleich statt fehleranfälliger Hybrid-Logik
- **Robustes Auto-Update-System**: Vollständiges Backup-System mit User-Settings Erhaltung
- **Separater Update-Installer**: Eigenständiges Update-Script verhindert Self-Delete Problem

---

## [7.1.4.2 "Odin"] — 2025-09-09

### Update-Checker Timestamp-Vergleich Bugfixes

- **Doppelter Vergleich behoben**: Timestamp UND Legacy-Vergleich liefen gleichzeitig
- **IF-Statement Struktur korrigiert**: Verschachtelte Bedingungen richtig strukturiert
- **Identische Versionen**: Korrektes Ergebnis bei gleichen Timestamps

---

## [7.1.4.1 "Odin"] — 2025-09-09

### Dokumentation und Release-Fixes

- **version.txt**: Auf 4 saubere Zeilen reduziert
- **VERSION-FORMAT.md**: Detaillierte Versionsnummern-Dokumentation erstellt
- **Timestamp-Format**: VVV → VVVV (714 → 7141)
- **Vereinfachtes Release-System**: 1 ZIP statt 3

---

## [7.1.4 "Odin"] — 2025-09-09

### Hybrid-Timestamp-Versionsystem Release

- **Timestamp-System**: Neue Versionierung für minutengenaue Updates
- **Hybrid-Autoupdater**: Mit Abwärtskompatibilität zu alten Patchern
- **PSScriptAnalyzer-konforme Verbesserungen**
- **YAML-Syntaxfehler in GitHub Actions behoben**

---

## [7.1.3 "Fenrir-Update"] — 2025-09-09

### Maintenance Release

- **Auto-Update-System**: Kritische Bugfixes für zuverlässige Update-Funktion
- **Emergency-Update-System**: Neues `emergency-update.bat` für zuverlässiges Patching
- **Automatische Backups**: Bei Emergency-Update vor dem Ersetzen der Dateien
- **Markdown-Standards**: Alle Dokumentationsdateien auf Markdownlint-Standards gebracht

**Known Bug**: update-check.bat stürzt beim Versionsvergleich ab — Workaround: `emergency-update.bat`

---

## [7.1.2 "Fenrir"] — 2025-09-08

### Launcher Revolution & Auto-Update System

- **Neues Launcher-System**: `START.bat` → `simple-launcher.bat` Workflow
- **PowerShell 7 Auto-Installation**: Automatisch via winget
- **Intelligenter Update-Check**: GitHub-Integration mit Versionsprüfung
- **Entwicklerschutz**: Update-Logik verhindert versehentliche Downgrades
- **Robuste PowerShell-Detection**: PS7 Fallback auf PS5
- **Codename-Whitelist**: Bekannte Releases für Update-Validierung

### Bugfixes

- DLL Integrity Checker auskommentiert (Syntax-Fehler)
- Count Property Fehler bei Null-Checks behoben
- DISM Parameter-Konflikt behoben
- Git-Erkennungslogik robuster implementiert

---

## [7.0.3 "Moon"] — 2025-09-07

### Initial Release — Production Ready

- **Universal Compatibility**: Funktioniert auf allen Windows 10/11 Systemen
- **Smart Launcher System**: Automatische Erkennung der besten Ausführungsmethode
- **Advanced PowerShell Detection**: Findet PowerShell auch bei beschädigtem PATH
- **Winget Integration**: Sichere Software-Updates mit Timeout-Behandlung
- **UAC Management**: Saubere Admin-Rechte-Behandlung
- **Safe Adblock**: Host-basierte Werbung/Tracking-Blockierung mit 25 Domains

---

## [7.0.2 "Moon-Bugfix"] — 2025-09-07

### Auto-Update Enhancement — ZIP-Download Support

- **ZIP-Download Auto-Update-System**: Automatische Git-Repository-Initialisierung
- **Intelligente Repository-Erkennung**: Erkennt fehlende `.git` Ordner
- **ZIP-Backup-System**: Sicherheitskopie vor Git-Initialisierung

---

## [7.0.1 "Moon-Bugfix"] — 2025-09-07

### Kritische Bugfixes — Hotfix Release

- **PowerShell-Erkennungslogik**: launcher.bat erkannte PS7 nicht korrekt
- **UAC-Doppelfenster-Problem**: Automatisches Schließen des Originalfensters
- **30-Tage-Wartungsempfehlung**: Intelligente Erinnerung
- **Desktop-Verknüpfung**: Automatisches Angebot mit professionellem Icon

---

## [7.0 "Moon"] — 2025-09-07

### Komplett überarbeitete Version

- **Launcher-System v7.0**: Neues `launcher.bat` mit automatischer Installation
- **Automatische Abhängigkeiten**: Winget + PowerShell 7 Auto-Installation
- **Intelligente Ordnerstruktur**: Automatische Erstellung aller Verzeichnisse
- **Git-Integration**: Automatische Updates über GitHub Repository
- **Backup-System**: Automatische Backups vor Updates mit Versionierung
- **Dateibasiertes Logging**: Tägliche Log-Dateien mit automatischer Rotation

---

## [6.5 "Monkey"] — 2025-08-01

### Enhanced Edition

- **Winget Integration**: Vollständig in Auto-Modus integriert
- **Erweiterte Treiber-Erkennung**: Detaillierte Hardware-Informationen
- **Multi-Windows-Kompatibilität**: Windows 10/11/Server Unterstützung
- **Performance-Optimierungen**: Geschwindigkeitsverbesserungen

---

## [6.1 "Beleandis"] — 2025-09-06

### Initialer Neubau — Grundstein-Version

- **Basis-Framework**: Komplette Neuentwicklung des Power Tools
- **Admin-Rechte-System**: Automatische UAC-Behandlung mit Self-Elevation
- **Core-Funktionalitäten**: Grundlegende Systemoptimierungstools
- **ASCII-Kompatibilität**: Encoding-sichere Implementierung
- **Safe Adblock**: Konservative Whitelist-basierte Implementierung

---

## Frühe Entwicklungsversionen (Pre-GitHub)

### [5.0 "Kazama"] — 2025-08-XX

- Launcher-System Konzept entwickelt
- Git & Release-Überlegungen für Community-Distribution
- AI-Assistent als Debugging-Hilfsmittel evaluiert

### [4.2 "Epsilon"] — 2025-08-XX

- Codename-System überarbeitet
- Network-Tools Bugfixes
- Bitdefender-Kompatibilität verbessert

### [4.0 "Delta"] — 2025-08-XX

- Winget `--unknown` Korrektur
- False-Positive Minimierung
- Versionsnummern-Anzeige verbessert

### [3.0 "Gamma"] — 2025-08-XX

- Erste Winget-Integration
- Experimentelle Software-Update-Funktionen

### [2.0 "Beta"] — 2025-07-XX

- Verfeinerung der ursprünglichen Konzepte
- Erweiterte System-Checks und Validierungen
- Tiefere Fehler-Analyse

### [1.0 "Alpha"] — 2025-07-XX

- Initiale Konzeption des Hellion Power Tools
- Proof-of-Concept und Machbarkeitsstudie
- Antiviren-kompatible Entwicklung getestet

---

## Entwicklungshistorie

| Version              | Codename       | Meilenstein                                     |
| -------------------- | -------------- | ----------------------------------------------- |
| v1.0                 | Alpha          | Initiale Idee und Proof-of-Concept              |
| v2.0                 | Beta           | Verfeinerung und erweiterte Analyse              |
| v3.0                 | Gamma          | Erste Winget-Integration                         |
| v4.0                 | Delta          | Winget-Korrekturen und False-Positive Fixes      |
| v4.2                 | Epsilon        | Network-Bugfixes                                 |
| v5.0                 | Kazama         | Launcher-Konzept und AI-Evaluation               |
| v6.1                 | Beleandis      | Neubau — GitHub Era beginnt                      |
| v6.5                 | Monkey         | Erweiterte Features und Kompatibilität           |
| v7.0                 | Moon           | Komplette Überarbeitung mit Launcher-System      |
| v7.0.1–v7.0.3        | Moon-Bugfix    | UAC-Fixes, ZIP-Support, Safe Adblock             |
| v7.1.2               | Fenrir         | Launcher Revolution und Auto-Update              |
| v7.1.3               | Fenrir-Update  | Emergency-Update-System                          |
| v7.1.4–v7.1.4.3      | Odin           | Update-Checker Neuentwicklung                    |
| v7.1.5.0–v7.1.5.3    | Baldur         | Treiber-Diagnose, UI/UX, Bugfixes               |
| **v7.2.0.0**         | **Heimdall**   | **Hellion Online Media Branding**                |

---

**Entwickelt von:** [Hellion Online Media](https://hellion-media.de) — Florian Wathling
**Repository:** [github.com/JonKazama-Hellion/hellion-power-tool](https://github.com/JonKazama-Hellion/hellion-power-tool)
**Download:** [hellion-media.de/hellion-power-tool](https://hellion-media.de/hellion-power-tool)
