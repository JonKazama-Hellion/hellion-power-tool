# Changelog - Hellion Power Tool

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt der [Semantischen Versionierung](https://semver.org/lang/de/).

---

## [7.1.5.2 "Baldur"] - 2025-09-10

### 🐛 CRITICAL BUGFIX RELEASE

#### 🔧 Kritische System-Reparaturen

- **Get-WinEvent Modul-Fehler behoben**: `Microsoft.PowerShell.Diagnostics` Import mit Fallback-Handling für driver-diagnostic.ps1
- **Doppelte Enter-Bestätigung entfernt**: Wiederherstellungspunkt-Modul zeigte doppelte "Press Enter" Prompts
- **TCP/IP Reset Fehler korrigiert**: Admin-Rechte-Prüfung und bessere Fehlerbehandlung für netsh-Befehle
- **Batch Unicode-Probleme gelöst**: Versteckte Unicode-Zeichen in simple-launcher.bat verursachten "etzt", "omatisches", "nd" Befehlsfehler
- **Update-Installer Escaping repariert**: Falsche `^>nul` → korrekte `^^^>nul` Batch-Escaping-Sequenzen

#### 🎯 System-Stabilität

- **Graceful Degradation**: Event Log Analyse funktioniert auch ohne PowerShell Diagnostics Modul
- **Robuste Fehlerbehandlung**: Netzwerk-Tools arbeiten auch bei partiellen Fehlern weiter
- **ASCII-Kompatibilität**: Alle Batch-Dateien nutzen ASCII-kompatible Zeichen statt Unicode

#### 📝 Entwickler-Notizen

- Unicode-BOM Probleme in Batch-Dateien können zu Parsing-Fehlern führen wo Wortteile als separate Befehle interpretiert werden
- Batch-Escaping erfordert dreifaches `^^^` für verschachtelte echo-Befehle in dynamisch erstellten Scripts

---

## [7.1.5.1 "Baldur"] - 2025-09-09

### 🎨 MAJOR UI/UX RELEASE - Community Bug Marathon

#### 🔥 Kritische Bugfixes (Community Reports)

- **Menü-System komplett repariert**: 7+ Switch-Case Zuordnungen waren falsch - Option 3-7 führten andere Funktionen aus als angezeigt
- **Fehlende Menü-Optionen hinzugefügt**: E, S, D, R Optionen waren nicht erreichbar trotz Anzeige im Hauptmenü  
- **Wiederherstellungspunkt-Manager**: Fehlende `Invoke-RestorePointManager` Funktion vollständig implementiert
- **NetTCPIP Module Loading Error**: Fallback auf System.Net.Sockets.TcpClient bei Get-NetTCPConnection Fehlern
- **24h Restore Point Limit Bypass**: Registry-Hack umgeht Windows 1440-Minuten Limitation
- **Winget Update Placeholders**: "Update0, Update1, Update2" durch echte Software-Namen ersetzt
- **Update-Checker UTF-8 Encoding**: Emoji-Darstellungsfehler in Batch-Dateien behoben
- **START.bat Auto-Close Issue**: Entfernt trailing pause für sauberen Launcher-Flow

#### 🎨 Komplette UI/UX Modernisierung

- **Einheitliches Menü-Design**: Alle 15+ Module auf konsistentes Cyan-Header Design umgestellt
- **Farbschema-Optimierung**: Übermäßige Buntheit reduziert - nur essenzielle Farben (Grün=Empfohlen, Rot=Abbruch/Vorsicht)
- **Hauptmenü-Header**: Moderne Cyan-Formatierung statt einfacher Text-Ausgabe
- **Submenu-Konsistenz**: Alle Untermenüs verwenden identisches Layout mit strukturierten Optionsanzeigen
- **ASCII-Kompatibilität**: Alle UTF-8 Emojis durch ASCII-sichere Zeichen ersetzt zur Encoding-Stabilität
- **Option-Styling**: Strukturierte [Nr] Beschreibung (Details) Formatierung durchgängig implementiert

#### 🛠️ Technische Verbesserungen

- **Desktop-Shortcut-System**: PNG→ICO Konvertierung mit Icon-Cache-Management implementiert
- **Auto-Mode-Beschreibungen**: Detaillierte Aktionslisten statt generischer "Modus A/B/C" Bezeichnungen  
- **Performance-Boost Korrekturen**: Switch-Case 2 führt nun korrekt Bereinigung + Optimierung aus
- **Module-Loading Fixes**: Korrekte .ps1 Modul-Referenzen in allen Hauptmenü-Optionen
- **Restore-Point Safety**: Auto-Mode abbricht bei Restore-Point-Fehlern statt riskante Fortsetzung
- **Network Connectivity Fallbacks**: Robuste Netzwerk-Tests mit mehreren Methoden

#### 📊 Community Feedback Integration

- **20 Bug Reports verarbeitet**: Systematische Behebung aller gemeldeten Probleme
- **15 UI/UX Verbesserungen**: Basierend auf "zu bunt" und "inconsistent" Feedback
- **Switch-Case Logik-Audit**: Vollständige Überprüfung aller Menü-zu-Funktion Zuordnungen
- **Encoding-Stabilität**: UTF-8 Probleme in Batch/PowerShell Dateien vollständig eliminiert

#### 🚀 Benutzerfreundlichkeit

- **Intuitive Navigation**: Menü-Optionen führen zu erwarteten Funktionen (nicht mehr falsche Module)
- **Konsistente Bedienung**: Einheitliche Menü-Struktur in allen Tool-Bereichen
- **Verbesserte Lesbarkeit**: Reduzierte Farbvielfalt erhöht Übersichtlichkeit
- **Funktionale Vollständigkeit**: Alle beworbenen Features sind tatsächlich erreichbar und funktional

**🎯 Problem gelöst**: Tool ist vollständig benutzbar - alle Menü-Optionen führen zu korrekten Funktionen

---

## [7.1.5.0 "Baldur"] - 2025-09-09

### 🆕 NEW FEATURE RELEASE - Erweiterte Treiber-Diagnose

#### ✨ Neue Features

- **🔍 Treiber-Diagnostik Modul**: Komplett neues Modul für erweiterte Driver-Analyse
  - ENE.SYS Spezial-Behandlung für Card Reader Probleme
  - Automatische Treiber-Reparatur mit Backup-System
  - Driver Store Bereinigung und Zwangs-Entfernung
  - WMI-basierte Hardware-Erkennung statt CSV-Parsing
  - Sicherheits-Whitelist verhindert versehentliche System-Treiber Löschung
- **🛡️ ENE-Hardware-Filterung**: Präzise Erkennung echter ENE-Hardware (Vendor ID 1524)
- **⚡ Force-Removal-Funktion**: Für problematische Treiber die nicht normal deinstalliert werden können
- **📋 Event-Log-Analyse**: Sucht automatisch nach treiber-bedingten Systemfehlern
- **🔧 Driver Verifier Integration**: Ermöglicht erweiterte Treiber-Tests

#### 🐛 Bugfixes

- **PSScriptAnalyzer Compliance**: Alle PowerShell-Funktionen verwenden genehmigte Verben
- **False-Positive Bluetooth**: Energiearme Bluetooth-Geräte werden nicht mehr als ENE-Hardware erkannt
- **Variable Optimization**: Entfernt ungenutzte Variablen für sauberen Code

#### 🔧 Technische Verbesserungen

- **Modulare Architektur**: `modules/driver-diagnostic.ps1` als eigenständiges System
- **WMI-Integration**: `Win32_SystemDriver` und `Win32_PnPEntity` für zuverlässige Hardware-Erkennung  
- **Registry-Backup-System**: Fallback wenn Windows Restore Points nicht verfügbar
- **AMD-ENE Treiber Support**: Spezielle Behandlung für AMD-signierte ENE-Treiber im Driver Store
- **Intelligente Pfad-Erkennung**: Automatische Suche nach Treiber-Dateien aus WMI-Daten

**🎯 Problem gelöst**: ENE.SYS Treiber-Crashes durch intelligente Force-Removal mit Windows Auto-Reinstall

**📊 Modul-Stats**: 944 Zeilen PowerShell-Code, 11 spezialisierte Funktionen, vollständige Error-Recovery

---

## [7.1.4.3 "Odin"] - 2025-09-09

### 🎉 MAJOR BUGFIX RELEASE - Update-Checker komplett neu programmiert

#### 🐛 Kritische Bugfixes

- **Update-Checker**: Komplett neuer `update-check.bat` (334 → 277 Zeilen sauberer Code)
- **False-Positive Updates**: Behebt falsches Update-Angebot bei identischen Versionen
- **LSS/GTR String-Vergleiche**: Ersetzt fehlerhafte Batch-Operatoren durch sichere String-Gleichheitsprüfung
- **Self-Delete Problem**: Separater Update-Installer verhindert Script-Selbstlöschung
- **Goto-Label Chaos**: Entfernt komplexe goto-Label Struktur zugunsten klarer if-else Logik

#### ✨ Neue Features

- **Timestamp-basierte Versionierung**: Präziser Versionsvergleich statt fehleranfällige Hybrid-Logik
- **Robustes Auto-Update-System**: Vollständiges Backup-System mit User-Settings Erhaltung
- **Separater Update-Installer**: Erstellt eigenständiges Update-Script zur sicheren Installation
- **Verbesserte Fehlerbehandlung**: Umfassende Validierung und Error-Recovery
- **User-Settings Merge**: Automatische Übernahme von config/settings.json bei Updates

#### 🔧 Technische Verbesserungen

- **Reine Timestamp-Methode**: Ersetzt buggy Hybrid-System (Legacy + neue Versionen)
- **String-Gleichheitsprüfung**: `==` statt LSS/GTR für zuverlässige Vergleiche
- **Cleanup-Optimierung**: Bessere Temp-Verzeichnis-Verwaltung
- **Backup-Strategie**: Timestamped Backups mit vollständiger Wiederherstellbarkeit

#### 🎯 Problem gelöst

**ENDLICH**: Update-Checker funktioniert zuverlässig ohne False-Positive Updates bei identischen Versionen!
**Entwicklungszeit**: 9 Stunden intensive Debugging-Session (v7.1.3 → v7.1.4.3)

---

## [7.1.4.2 "Odin"] - 2025-09-09

### 🔧 Update-Checker Timestamp-Vergleich Bugfixes

#### 🐛 Kritische Bugfixes (v7.1.4.2)

- **Doppelter Vergleich behoben**: Timestamp UND Legacy-Vergleich liefen gleichzeitig
  - **Jetzt**: Timestamp-Vergleich hat Vorrang, Legacy nur als Fallback
- **IF-Statement Struktur korrigiert**: Verschachtelte IF-Bedingungen richtig strukturiert
- **GOTO :VERSION_COMPARE_DONE**: Verhindert doppelte Ausführung
- **Identische Versionen Problem gelöst**: 71422509101155 == 71422509101155 = KEIN UPDATE (korrekt)
- **False-Positive Updates**: Behebt falsches Update-Angebot bei gleichen Versionen

#### 🔧 Technische Details

- **Neue Timestamp**: 71422509101155 (7142 = v7.1.4.2)  
- **Hybrid-System**: Funktioniert jetzt präzise
- **Abwärtskompatibilität**: Zu allen älteren Versionen erhalten

---

## [7.1.4.1 "Odin"] - 2025-09-09

### 📝 Dokumentation und Release-Fixes

#### 📋 Dokumentations-Updates

- **version.txt**: Auf 4 saubere Zeilen reduziert (Update-Checker kompatibel)
- **VERSION-FORMAT.md**: Detaillierte Versionsnummern-Dokumentation erstellt
- **Release-Notes**: Aktualisiert - Neue Features statt alter Bugs
- **README.md**: Auf v7.1.4.1 aktualisiert
- **Markdownlint-Fehler**: In Dokumentation behoben

#### 🔧 Version-System Korrekturen  

- **Version erhöht**: Auf 7.1.4.1 für Release-System Korrekturen
- **Timestamp-Format**: VVV → VVVV (714 → 7141)
- **Aktuelle Zeit**: 71412509101142 (10.09.2025 11:42)
- **GitHub Actions**: Release auf v7.1.4.1 aktualisiert
- **Vereinfachtes Release-System**: 1 ZIP statt 3

---

## [7.1.4 "Odin"] - 2025-09-09

### 🚀 Hybrid-Timestamp-Versionsystem Release

#### ✨ Neue Features (v7.1.4)

- **Timestamp-System**: Neue Versionierung (7142509101210) für minutengenaue Updates
- **Hybrid-Autoupdater**: Mit Abwärtskompatibilität zu alten Patchern  
- **"Odin" Codename**: Zur Codename-Whitelist hinzugefügt

#### 🔧 Verbesserungen

- **PowerShell Code Quality**: PSScriptAnalyzer-konforme Verbesserungen
- **YAML-Syntaxfehler**: In GitHub Actions behoben
- **Markdownlint-Standards**: In allen Dokumentationen umgesetzt

#### 🚨 Breaking Change

**BREAKING CHANGE**: Neue Timestamp-basierte Versionierung ab v7.1.4

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
- **Codename-Whitelist**: Bekannte Releases (Alpha, Beta, Gamma, Delta, Epsilon, Kazama, Beleandis, Monkey, Moon, Moon-Bugfix, Fenrir, Fenrir-Update, Odin)
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

---

## Frühe Entwicklungsversionen (Pre-GitHub Era)

### [5.0 "Kazama"] - 2025-08-XX

#### 🚀 Launcher-Konzept & AI-Unterstützung Überlegungen

- **Launcher-System Aufbau**: Entwicklung eines Launchers um nicht immer manuell die .ps1 starten zu müssen
- **Git & Release-Überlegungen**: Nachdenken über Git für Backup und Release falls sich jemand für das Tool interessiert  
- **AI-Assistent Evaluation**: Bei komplizierteren und größeren Problemen AI-Assistent zum Rate ziehen? Claude?
- **Code-Transparenz**: Dokumentiert dass der Code selbst geschrieben ist und AI nur zur Fehlersuche und bei Fixes komplizierterer Bugs zum Einsatz kommt

#### Entwicklungsnotizen

- Konzeptphase für Launcher-System
- Erste Überlegungen zur Automatisierung
- AI-Unterstützung als Debugging-Tool evaluiert

---

### [4.2 "Epsilon"] - 2025-08-XX

#### 🔧 Codename-Überarbeitung & Network-Tool Bugfixes

- **Codename-System Änderung**: Überarbeitung der Codename-Benennung (persönliche Präferenz)
- **Network-Tools Bugfixes**: Behebung einiger Bugs beim Ausführen von Network-Tools
- **Bitdefender-Trigger**: Bitdefender wurde durch Network-Tools getriggert - Anpassungen vorgenommen

#### Verbesserungen (v4.2)

- Stabilere Network-Funktionalität
- Verbesserte Antiviren-Kompatibilität
- Überarbeitetes Benennungsschema

---

### [4.0 "Delta"] - 2025-08-XX

#### 🛠️ Winget-Korrektur & False-Positive Fixes

- **Winget --unknown Korrektur**: Winget --unknown war nicht korrekt - Korrektur zum richtigen Befehl
- **False-Positive Behebung**: Verbesserungen zur Minimierung von Antiviren-False-Positives
- **Nummern-Anzeige**: Anzeige der Versionsnummern und Feedback-Verbesserungen

#### Korrekturen (v4.0)

- Korrekte Winget-Parameter implementiert
- Verbesserte Antiviren-Kompatibilität
- Enhanced User-Feedback

---

### [3.0 "Gamma"] - 2025-08-XX

#### 📦 Winget-Integration Experimente

- **Winget-Integration**: Winget hinzufügen und testen
- **Parameter-Experimente**: Vielleicht mit --unknown? (experimentelle Phase)
- **Testing-Phase**: Ausgiebiges Testen der neuen Software-Management-Features

#### Neue Features (v3.0)

- Erste Winget-Integration
- Experimentelle Software-Update-Funktionen
- Testing verschiedener Winget-Parameter

---

### [2.0 "Beta"] - 2025-07-XX

#### 🔍 Verfeinerung & Erweiterte Analyse

- **Ideen-Verfeinerung**: Verfeinerung der ursprünglichen Konzepte und Ansätze
- **Weitere Checks**: Erweiterte System-Checks und Validierungen  
- **Fehler-Analyse**: Tiefere Analyse von Systemfehlern und deren Behebung

#### Verbesserungen (v2.0)

- Erweiterte Diagnose-Funktionen
- Verbesserte Systemprüfungen
- Detailliertere Fehlerbehandlung

---

### [1.0 "Alpha"] - 2025-07-XX

#### 💡 Initiale Konzeption & Proof-of-Concept

- **Initial-Idee**: Erste Konzeption des Hellion Power Tools
- **Tool-Forschung**: Nachforschung verschiedener System-Tools und deren Möglichkeiten
- **Bitdefender-Testing**: Testing der Möglichkeiten ohne Bitdefender zu triggern
- **Proof-of-Concept**: Grundlegende Funktionalität und Machbarkeitsstudie

#### Grundstein (v1.0)

- Erste Systemoptimierungs-Tools
- Antiviren-kompatible Entwicklung
- Basis-Framework Entwicklung

---

## Entwicklungshistorie (Komplett)

- **v1.0 "Alpha"**: Initiale Idee und Proof-of-Concept
- **v2.0 "Beta"**: Verfeinerung und erweiterte Analyse
- **v3.0 "Gamma"**: Erste Winget-Integration Experimente  
- **v4.0 "Delta"**: Winget-Korrekturen und False-Positive Fixes
- **v4.2 "Epsilon"**: Codename-Überarbeitung und Network-Bugfixes
- **v5.0 "Kazama"**: Launcher-Konzept und AI-Unterstützung Evaluation
- **v6.1 "Beleandis"**: Grundstein und Neubau (GitHub Era beginnt)
- **v6.5 "Monkey"**: Erweiterte Features und Kompatibilität  
- **v7.0 "Moon"**: Komplette Überarbeitung mit Launcher-System
- **v7.0.1 "Moon-Bugfix"**: UAC-Fixes und Desktop-Integration
- **v7.0.2 "Moon-Bugfix"**: ZIP-Download Auto-Update-System
- **v7.0.3 "Moon-Hotfix"**: Kritische Bugfixes und Safe Adblock
- **v7.1.2 "Fenrir"**: Launcher Revolution und Auto-Update System
- **v7.1.3 "Fenrir-Update"**: Emergency-Update-System und Markdown-Standards
- **v7.1.4.3 "Odin"**: Update-Checker Neuentwicklung - False-Positive Problem endgültig gelöst

**Entwickelt von:** Hellion Online Media - Florian Wathling  
**Website:** [https://hellion-online-media.de](https://hellion-online-media.de)  
**Repository:** [https://github.com/JonKazama-Hellion/hellion-power-tool](https://github.com/JonKazama-Hellion/hellion-power-tool)  
**Support:** [support@hellion-online-media.de](mailto:support@hellion-online-media.de)
