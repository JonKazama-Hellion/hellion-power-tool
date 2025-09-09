# Changelog - Hellion Power Tool

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt der [Semantischen Versionierung](https://semver.org/lang/de/).

---

## [7.1.3 "Fenrir-Update"] - 2025-09-09

### 🔧 Maintenance Release - Auto-Update Bugfixes & Emergency-Update System

#### 🐛 Behobene Bugs

- **Auto-Update-System**: Kritische Bugfixes im Autoupdater für zuverlässige Update-Funktion
- **Update-Mechanismus**: Verbesserte Update-Logik und Fehlerbehandlung

#### 🚨 Neue Funktionen

- **Emergency-Update-System**: Neues `emergency-update.bat` für zuverlässiges Tool-Patching
- **Automatische Backups**: Emergency-Update erstellt Backups aller alten Dateien vor Update
- **Fail-Safe-Update**: Verlässliche Update-Methode als Fallback bei Autoupdater-Problemen

#### 📝 Dokumentation

- **Markdown-Standards**: Alle README.md, SECURITY.md und Dokumentationsdateien auf aktuelle Markdownlint-Standards gebracht
- **Konsistente Formatierung**: Einheitliches und wartbares Gesamtbild der Dokumentation
- **EMERGENCY-FIX.md**: Neue Anleitung zur Verwendung des Emergency-Update-Systems

#### 🛠️ Technische Verbesserungen

- **Verbesserte Update-Stabilität**: Robustere Update-Mechanismen
- **Dokumentations-Qualität**: Professionelle, einheitliche Markdown-Formatierung
- **Wartbarkeit**: Bessere Code- und Dokumentationsstruktur

#### 🚨 KNOWN BUGS

- **update-check.bat**: Der normale Auto-Update-Checker stürzt beim Versionsvergleich ab
  - **Workaround**: Nutze `emergency-update.bat` für zuverlässige Updates
  - **Status**: Fix geplant für nächstes Release

---

## [7.1.2 "Fenrir"] - 2025-09-08

### 🚀 Major Release - Launcher Revolution & Auto-Update System

#### 🎯 Neue Hauptfunktionen

- **Revolutionäres Launcher-System**: Komplett neuer `START.bat` → `simple-launcher.bat` Workflow
- **PowerShell 7 Auto-Installation**: Automatische Installation via winget mit benutzerfreundlicher Abfrage
- **Intelligenter Update-Check**: GitHub-Integration mit automatischer Versionsprüfung
- **Entwicklerschutz**: Intelligente Update-Logik verhindert versehentliche Downgrades
- **Launcher-Restart-System**: Automatischer Neustart nach PowerShell 7 Installation

#### 🔧 Launcher-Verbesserungen

- **Einfache Architektur**: Ein Starter, ein Launcher - keine komplexen Multi-Launcher mehr
- **PowerShell-Detection**: Robuste Erkennung von PowerShell 7 und Fallback auf PowerShell 5
- **Parameter-Passing**: Saubere Parameterweiterleitung durch UAC-Restart
- **Debug-Level-System**: Erweiterte Debug-Modi (0=Normal, 1=Debug, 2=Developer)

#### 🔄 Auto-Update-System

- **GitHub-Integration**: Direkter Zugriff auf JonKazama-Hellion/hellion-power-tool Repository
- **Intelligente Versionsprüfung**: Vergleicht Version, Codename und Datum
- **Entwicklungsversions-Erkennung**: Erkennt lokale Entwicklungsversionen und überspringt Updates
- **Codename-Whitelist**: Bekannte Releases (Alpha, Beta, Gamma, Delta, Epsilon, Kazama, Beleandis, Monkey, Moon, Moon-Bugfix, Fenrir)
- **Git-Auto-Installation**: Automatische Git-Installation via winget wenn benötigt

#### 🛠️ Technische Verbesserungen (v7.1.2)

- **Robuste Fehlerbehandlung**: Script stürzt nicht mehr ab bei Git/Internet-Problemen
- **Shallow Git Clone**: Effizienter Repository-Download mit `--depth 1`
- **Temporäre Verzeichnisse**: Sichere Temp-Ordner für Update-Checks
- **Cleanup-System**: Automatische Bereinigung nach Update-Prüfung

#### 🐛 Behobene Bugs (v7.1.2)

- **DLL Integrity Checker**: Komplett auskommentiert (verursachte Syntax-Fehler)
- **Count Property Fehler**: Null-Checks für PowerShell Strict Mode hinzugefügt
- **DISM Parameter Konflikt**: Behoben - `-RedirectStandardOutput` Inkompatibilität mit `-Verb RunAs`
- **Checkdisk Count Error**: Null-Referenz beim Zugriff auf chkdskResult.Length behoben
- **Git-Erkennungslogik**: Robuste Git-Verfügbarkeit-Prüfung implementiert
- **Version-Parsing-Crashes**: Sichere Datei-Parsing ohne delayed expansion

#### 📋 Update-Check-Logik

- **Datum-basiert**: Primäre Entscheidung basiert auf Veröffentlichungsdatum
- **Version-Schutz**: Verhindert Downgrades bei neueren lokalen Versionen
- **Codename-Validation**: Nur bekannte Releases werden für Updates berücksichtigt
- **Entwickler-Modus**: Überspringt Updates bei unbekannten Codenamen

#### 🎨 Benutzererfahrung

- **Optionaler Update-Check**: Benutzer kann Update-Prüfung überspringen
- **Klare Ausgaben**: Verständliche Meldungen ohne Debug-Spam
- **PowerShell-Version-Info**: Anzeige der verwendeten PowerShell-Version
- **Fehler-Recovery**: Graceful Degradation bei Netzwerk-/Git-Problemen

#### 🏗️ Architektur-Änderungen

- **Vereinfachte Launcher-Struktur**: Weg von komplexen Multi-Launcher-Systemen
- **Modulare Update-Checks**: Separates `update-check.bat` Modul
- **Git-basierte Updates**: Vorbereitung für zukünftige automatische Updates
- **Robuste Basis**: Crashsichere Implementierung mit umfassendem Error-Handling

#### 📝 Entwickler-Notizen

- **DLL-Check Rewrite erforderlich**: Für zukünftige Releases geplant
- **Repository-URL**: Korrekt auf JonKazama-Hellion/hellion-power-tool aktualisiert
- **Version-Tracking**: Automatisierte Versionsverfolgung in config/version.txt

---

## [7.0.3 "Moon"] - 2025-09-07

### 🎉 Initial Release - Production Ready

#### Core Features

- **Universal Compatibility**: Funktioniert auf allen Windows 10/11 Systemen auch bei PATH-Problemen oder Defender-Blockaden
- **Smart Launcher System**: Automatische Erkennung der besten Ausführungsmethode mit Fallback-Modi
- **Advanced PowerShell Detection**: Findet PowerShell auch bei beschädigtem PATH oder alternativen Installationspfaden
- **Winget Integration**: Sichere Software-Updates mit intelligenter Timeout-Behandlung
- **UAC Management**: Saubere Administrator-Rechte-Behandlung ohne Doppelfenster
- **Safe Adblock**: Host-basierte Werbung/Tracking-Blockierung mit 25 sicheren Domains

#### Added

- **Safe Adblock-Funktion**: Vollständig implementierte Host-Datei-basierte Werbung/Tracking-Blockierung
- **Erweiterte Adblock-Domainliste**: 25 sichere Tracking/Werbung-Domains von Google, Facebook, Microsoft, Amazon etc.
- **Intelligente Host-Datei-Verwaltung**: Prüft bestehende Einträge und fügt nur fehlende Domains hinzu
- **Auto-Modus Adblock-Integration**: Safe Adblock läuft automatisch in Schritt 7 des Enhanced Auto-Modus

#### Technical Details

- **UAC-Signal-System**: `temp/uac_restart.signal` Datei für saubere Launcher-Kommunikation
- **PowerShell UAC-Restart**: `[Environment]::Exit(0)` mit Signal-Datei statt einfachem `exit`
- **Intelligente Domain-Erkennung**: Regex-basierte Prüfung existierender Host-Einträge
- **Host-Datei-Backup**: Automatische Sicherung vor jeder Adblock-Modifikation als `.hellion.backup`
- **Non-Destructive Updates**: Host-Datei wird erweitert, nie überschrieben
- **DNS-Cache-Management**: Automatisches `ipconfig /flushdns` nach Adblock-Updates
- **Frühe Desktop-Verknüpfung**: Launcher fragt vor Script-Start nach Desktop-Icon
- **Smart Launcher Logic**: Automatische Erkennung von Defender-Blockaden mit Fallback-System
- **PowerShell Job-Timeout**: Background Jobs mit Wait-Job für hängende Winget-Prozesse
- **Erweiterte Pfad-Suche**: Windows-weite Suche nach PowerShell in System32, SysWOW64 und alternativen Pfaden
- **Debug-Tool-Suite**: Vollständige Diagnose-Tools für PowerShell-, Defender- und PATH-Probleme

#### Enhanced User Experience

- **Kein UAC-Doppelfenster**: Original-Fenster schließt sich automatisch nach Admin-Restart
- **Smart Adblock-Updates**: "X neue Domains hinzugefügt" vs "Alle X Domains bereits blockiert"
- **Desktop-Icon vor UAC**: Verknüpfung wird erstellt bevor UAC das Fenster schließt  
- **Detaillierte Adblock-Logs**: Präzise Informationen über blockierte Domains
- **Sichere Update-Policy**: Nur noch vertrauenswürdige Software-Updates über Winget
- **Universelle Kompatibilität**: Funktioniert auch bei PATH-Problemen, Defender-Blockaden und langsamen Systemen
- **Intelligente Timeout-Meldungen**: Benutzer werden über Wartezeiten informiert ("Dies kann 30-60 Sekunden dauern...")
- **Automatischer Fallback**: Nahtloser Übergang zwischen Update-Modus und Safe-Modus je nach Systemkonfiguration
- **Strukturierte Debug-Hilfe**: Organisierte Debug-Tools mit README-Anleitungen für Problemdiagnose

#### Blocked Domains (Safe Adblock)

Blockiert 25 sichere Tracking/Werbung-Domains:

- **Google**: doubleclick.net, googleadservices.com, googlesyndication.com, google-analytics.com
- **Facebook/Meta**: facebook.com/tr, connect.facebook.net, analytics.facebook.com  
- **Microsoft**: msads.net, ads.msn.com, rad.msn.com
- **Amazon**: amazon-adsystem.com, assoc-amazon.com
- **Tracking-Services**: scorecardresearch.com, quantserve.com, outbrain.com, taboola.com
- **Weitere**: 2mdn.net, adsafeprotected.com, adsrvr.org, turn.com, rubiconproject.com

---

## [7.0.2 "Moon-Bugfix"] - 2025-09-07

### 🔧 Auto-Update Enhancement - ZIP-Download Support

#### Added (v7.0.2)

- **ZIP-Download Auto-Update-System**: Vollständig automatische Git-Repository-Initialisierung für ZIP-Downloads
- **Intelligente Repository-Erkennung**: Erkennt fehlende `.git` Ordner und initialisiert Auto-Update-System
- **Benutzergeführtes Setup**: Interaktives Setup mit Sicherheitskopie und User-Auswahl für initiales Update
- **Automatischer Tool-Neustart**: Nach erfolgreichem Update wird das Tool automatisch mit neuester Version neu gestartet
- **ZIP-Backup-System**: Erstellt Sicherheitskopie aller ZIP-Dateien in `temp\zip-backup\` vor Git-Initialisierung

#### Technical Details (v7.0.2)

- Neue `InitializeGitRepo` Funktion für automatische Repository-Initialisierung
- Git-Repository wird automatisch mit `git init` und `git remote add origin` konfiguriert  
- Branch-Setup mit `git branch -M main` und Upstream-Tracking
- Intelligente Update-Prüfung mit `git rev-list --count` für verfügbare Commits
- Lokale Änderungen werden automatisch gestaged mit "Initial ZIP download state" commit

#### User Experience (v7.0.2)

- Klare Kommunikation: "🔧 GIT AUTO-UPDATE SETUP" Interface
- User-Choice für initiales Update mit J/N Auswahl
- Automatische Tool-Neustart-Funktionalität nach Update
- Nahtloser Übergang von ZIP-Download zu Git-basiertem Auto-Update-System

---

## [7.0.1 "Moon-Bugfix"] - 2025-09-07

### 🐛 Kritische Bugfixes - Hotfix Release

#### Fixed (v7.0.1)

- **PowerShell-Erkennungslogik**: Behoben - launcher.bat erkannte PowerShell 7 nicht korrekt
- **UAC-Doppelfenster-Problem**: UAC-Restart schließt jetzt das ursprüngliche Fenster automatisch
- **Signal-Datei-System**: Intelligentes Signal-System für nahtlose UAC-Behandlung ohne Benutzerinteraktion
- **Launcher-Warteaufforderung**: "Drücken Sie eine beliebige Taste" nach UAC-Restart entfernt

#### Added (v7.0.1)

- **30-Tage-Wartungsempfehlung**: Intelligente Erinnerung für regelmäßige Tool-Ausführung
- **Desktop-Verknüpfung**: Automatisches Angebot zur Erstellung einer Desktop-Verknüpfung mit professionellem Icon
- **Erweiterte Winget-Integration**: Verlängerte Timeout (60 Min), benutzerfreundliche Warnungen und animierte Fortschrittsanzeige
- **Intelligente Shortcut-Verwaltung**: Speichert Benutzer-Präferenz und verhindert wiederholte Nachfragen

#### Technical Details (v7.0.1)

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

#### Added (v7.0)

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

#### Fixed (v7.0)

- **SFC Parameter-Konflikt**: Behoben - `-WindowStyle Hidden` mit `-NoNewWindow` Inkompatibilität
- **PSScriptAnalyzer Warnungen**: Alle Unapproved Verbs und ungenutzte Variablen behoben
- **DISM Sicherheit**: Verwendung von `Start-Process -Verb RunAs` für erhöhte Sicherheit
- **Logging-System**: Komplett überarbeitetes System mit Datei-Output

#### Changed (v7.0)

- **Projektstruktur**: Vollständige Reorganisation mit config/, logs/, backups/ Ordnern
- **Repository**: Umzug zu GitHub JonKazama-Hellion/hellion-power-tool
- **Dokumentation**: Vollständige README.md und README_Launcher.md Überarbeitung
- **Code-Qualität**: Markdownlint-konforme Dokumentation

#### Technical Details (v7.0)

- Neue Ordnerstruktur: config/, logs/, backups/, old-versions/, temp/
- JSON-basierte Konfiguration mit Debug-Modus
- Automatische Log-Bereinigung (30 Tage)
- Intelligente Script-Erkennung mit Fallback-System
- Git-basiertes Auto-Update-System

---

## [6.5 "Monkey"] - 2025-08-01

### 🐒 Enhanced Edition - Erweiterte Funktionalität

#### Neue Features (v6.5)

- **Winget Integration**: Vollständig in Auto-Modus integriert
- **Erweiterte Treiber-Erkennung**: Detaillierte Hardware-Informationen
- **Enhanced Debug-Modus**: Präzise Fehlermeldungen und Diagnose
- **Antiviren-Optimierungen**: Spezielle Anpassungen für Bitdefender & Windows Defender
- **Multi-Windows-Kompatibilität**: Unterstützung für Windows 10/11/Server
- **Erweiterte Logging-Funktionalität**: Verbesserte Protokollierung
- **Performance-Optimierungen**: Geschwindigkeitsverbesserungen
- **Verbesserte Benutzerführung**: Intuitivere Menüs und Hilfetexte

#### Verbesserungen (v6.5)

- Komplett überarbeitete Winget-Integration
- Verbesserte Systemkompatibilität
- Optimierte Antiviren-Erkennung
- Enhanced Error Handling

#### Technische Details (v6.5)

- Antiviren-freundlicher Startup mit Delay
- Sichere Defaults und StrictMode
- Globale Konfigurationsvariablen
- Verbesserte UAC-Behandlung

---

## [6.1 "Beleandis"] - 2025-09-06  

### 🌟 Initialer Neubau - Grundstein-Version

#### Grundfunktionen (v6.1)

- **Basis-Framework**: Komplette Neuentwicklung des Power Tools
- **Admin-Rechte-System**: Automatische UAC-Behandlung mit Self-Elevation  
- **Core-Funktionalitäten**: Grundlegende Systemoptimierungstools
- **Unicode-Kompatibilität**: ASCII-kompatible Zeichensatz-Unterstützung
- **Sichere Adblock-Funktion**: Konservative Whitelist-basierte Implementierung
- **Basis-Fehlerbehandlung**: Grundlegende Error-Handling-Mechanismen
- **Vollständige Funktionsbasis**: Alle ursprünglichen Kernfunktionen

#### Korrekturen (v6.1)

- **Encoding-Probleme**: Alle Unicode-Zeichen durch ASCII-Alternativen ersetzt
- **Adblock-Sicherheit**: Sicherere Implementierung mit konservativer Whitelist
- **Basis-Stabilität**: Verbesserte Grundstabilität

#### Implementierung (v6.1)

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
- **v7.0.1 "Moon-Bugfix"**: UAC-Fixes und Desktop-Integration
- **v7.0.2 "Moon-Bugfix"**: ZIP-Download Auto-Update-System
- **v7.0.3 "Moon-Hotfix"**: Kritische Bugfixes und Safe Adblock
- **v7.1.2 "Fenrir"**: Launcher Revolution und Auto-Update System

**Entwickelt von:** Hellion Online Media - Florian Wathling  
**Website:** [https://hellion-online-media.de](https://hellion-online-media.de)  
**Repository:** [https://github.com/JonKazama-Hellion/hellion-power-tool](https://github.com/JonKazama-Hellion/hellion-power-tool)  
**Support:** [support@hellion-online-media.de](mailto:support@hellion-online-media.de)
