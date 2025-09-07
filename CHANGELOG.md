# Changelog - Hellion Power Tool

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt der [Semantischen Versionierung](https://semver.org/lang/de/).

---

## [7.0.1 "Moon-Bugfix"] - 2025-09-07

### 🐛 Kritische Bugfixes - Hotfix Release

#### Fixed
- **PowerShell-Erkennungslogik**: Behoben - launcher.bat erkannte PowerShell 7 nicht korrekt
- **UAC-Doppelfenster-Problem**: UAC-Restart schließt jetzt das ursprüngliche Fenster automatisch
- **Signal-Datei-System**: Intelligentes Signal-System für nahtlose UAC-Behandlung ohne Benutzerinteraktion
- **Launcher-Warteaufforderung**: "Drücken Sie eine beliebige Taste" nach UAC-Restart entfernt

#### Added
- **30-Tage-Wartungsempfehlung**: Intelligente Erinnerung für regelmäßige Tool-Ausführung
- **Desktop-Verknüpfung**: Automatisches Angebot zur Erstellung einer Desktop-Verknüpfung mit professionellem Icon
- **Erweiterte Winget-Integration**: Verlängerte Timeout (60 Min), benutzerfreundliche Warnungen und animierte Fortschrittsanzeige
- **Intelligente Shortcut-Verwaltung**: Speichert Benutzer-Präferenz und verhindert wiederholte Nachfragen

#### Technical Details
- PowerShell-Variable `USE_POWERSHELL` wird jetzt direkt bei Erkennung gesetzt
- UAC-Restart verwendet Signal-Datei `temp/uac_restart.signal` für saubere Kommunikation
- `[Environment]::Exit(0)` mit Signal-Datei statt Exit-Code für bessere Batch-Kompatibilität
- Automatische Signal-Datei-Bereinigung beim normalen Admin-Start
- Desktop-Verknüpfung verwendet PowerShell COM-Objekt `WScript.Shell` mit Windows system icon (shell32.dll,21)
- 30-Tage-Reminder mit `config/last_run.txt` Tracking-System
- Winget-Timeout von 30 auf 60 Minuten erhöht für umfangreiche Updates
- Benutzerfreundliche Winget-Warnungen in Cyan statt aggressiven roten Meldungen

---

## [7.0 "Moon"] - 2025-09-07

### 🚀 Initialer Release - Komplett überarbeitete Version

#### Added

- **Launcher-System v7.0**: Neues `launcher.bat` mit automatischer Installation
- **Automatische Abhängigkeiten**: Winget + PowerShell 7 Auto-Installation
- **Intelligente Ordnerstruktur**: Automatische Erstellung aller benötigten Ordner
- **Erweiterte Konfiguration**: Vollständiges `config/settings.json` System
- **Git-Integration**: Automatische Updates über GitHub Repository
- **Backup-System**: Automatische Backups vor Updates mit Versionierung
- **Dateibasiertes Logging**: Tägliche Log-Dateien mit automatischer Rotation
- **Debug-Modus**: Detaillierte Ausgaben für Entwicklung und Fehlerbehebung
- **Checkdisk-Integration**: Manuelle Dateisystem-Prüfung hinzugefügt
- **PowerShell-Erkennung**: Intelligente Auswahl zwischen PS7 und PS5
- **Auto-Update-System**: Automatische Updates via Git mit Backup-Erstellung

#### Fixed

- **SFC Parameter-Konflikt**: Behoben - `-WindowStyle Hidden` mit `-NoNewWindow` Inkompatibilität
- **PSScriptAnalyzer Warnungen**: Alle Unapproved Verbs und ungenutzte Variablen behoben
- **DISM Sicherheit**: Verwendung von `Start-Process -Verb RunAs` für erhöhte Sicherheit
- **Logging-System**: Komplett überarbeitetes System mit Datei-Output

#### Changed

- **Projektstruktur**: Vollständige Reorganisation mit config/, logs/, backups/ Ordnern
- **Repository**: Umzug zu GitHub JonKazama-Hellion/hellion-power-tool
- **Dokumentation**: Vollständige README.md und README_Launcher.md Überarbeitung
- **Code-Qualität**: Markdownlint-konforme Dokumentation

#### Technical Details

- Neue Ordnerstruktur: config/, logs/, backups/, old-versions/, temp/
- JSON-basierte Konfiguration mit Debug-Modus
- Automatische Log-Bereinigung (30 Tage)
- Intelligente Script-Erkennung mit Fallback-System
- Git-basiertes Auto-Update-System

---

## [6.5 "Monkey"] - 2025-08-01

### 🐒 Enhanced Edition - Erweiterte Funktionalität

#### Neue Features

- **Winget Integration**: Vollständig in Auto-Modus integriert
- **Erweiterte Treiber-Erkennung**: Detaillierte Hardware-Informationen
- **Enhanced Debug-Modus**: Präzise Fehlermeldungen und Diagnose
- **Antiviren-Optimierungen**: Spezielle Anpassungen für Bitdefender & Windows Defender
- **Multi-Windows-Kompatibilität**: Unterstützung für Windows 10/11/Server
- **Erweiterte Logging-Funktionalität**: Verbesserte Protokollierung
- **Performance-Optimierungen**: Geschwindigkeitsverbesserungen
- **Verbesserte Benutzerführung**: Intuitivere Menüs und Hilfetexte

#### Verbesserungen

- Komplett überarbeitete Winget-Integration
- Verbesserte Systemkompatibilität
- Optimierte Antiviren-Erkennung
- Enhanced Error Handling

#### Technische Details

- Antiviren-freundlicher Startup mit Delay
- Sichere Defaults und StrictMode
- Globale Konfigurationsvariablen
- Verbesserte UAC-Behandlung

---

## [6.1 "Beleandis"] - 2025-09-06  

### 🌟 Initialer Neubau - Grundstein-Version

#### Grundfunktionen

- **Basis-Framework**: Komplette Neuentwicklung des Power Tools
- **Admin-Rechte-System**: Automatische UAC-Behandlung mit Self-Elevation  
- **Core-Funktionalitäten**: Grundlegende Systemoptimierungstools
- **Unicode-Kompatibilität**: ASCII-kompatible Zeichensatz-Unterstützung
- **Sichere Adblock-Funktion**: Konservative Whitelist-basierte Implementierung
- **Basis-Fehlerbehandlung**: Grundlegende Error-Handling-Mechanismen
- **Vollständige Funktionsbasis**: Alle ursprünglichen Kernfunktionen

#### Korrekturen

- **Encoding-Probleme**: Alle Unicode-Zeichen durch ASCII-Alternativen ersetzt
- **Adblock-Sicherheit**: Sicherere Implementierung mit konservativer Whitelist
- **Basis-Stabilität**: Verbesserte Grundstabilität

#### Implementierung

- Erstellungsdatum: 06.09.2025
- Unicode-Fix für bessere Kompatibilität  
- Encoding-Problem-Behebung
- ALLE ursprünglichen Funktionen beibehalten
- Automatische Admin-Rechte-Erkennung
- Self-Elevation-Mechanismus

---

## Entwicklungshistorie

- **v6.1 "Beleandis"**: Grundstein und Neubau
- **v6.5 "Monkey"**: Erweiterte Features und Kompatibilität  
- **v7.0 "Moon"**: Komplette Überarbeitung mit Launcher-System

**Entwickelt von:** Hellion Online Media - Florian Wathling  
**Website:** [https://hellion-online-media.de](https://hellion-online-media.de)  
**Repository:** [https://github.com/JonKazama-Hellion/hellion-power-tool](https://github.com/JonKazama-Hellion/hellion-power-tool)  
**Support:** [support@hellion-online-media.de](mailto:support@hellion-online-media.de)
