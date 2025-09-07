# Hellion Power Tool Launcher v7.0 "Moon"

## 🚀 Überblick

Der neue Launcher.bat v7.0 "Moon" bietet ein vollständig überarbeitetes Startsystem für das Hellion Power Tool mit erweiterten Features für Konfiguration, Logging und Auto-Updates.

## 📁 Ordnerstruktur

```text
hellion-power-tool/
├── launcher.bat              # Hauptlauncher (NEU)
├── hellion_tool_v70_moon.ps1 # Hauptscript
├── config/
│   ├── settings.json         # Haupt-Konfiguration
│   ├── repository.txt        # GitHub Repository URL
│   └── version.txt           # Aktuelle Version
├── logs/
│   ├── 2025-09-07_startup.log
│   ├── 2025-09-07_error.log
│   └── 2025-09-07_actions.log
├── backups/
│   └── hellion_tool_backup_20250907_1430.ps1
├── old-versions/
│   ├── v6.5_monkey.ps1
│   └── v6.1_original.ps1
└── temp/
```

## ⚙️ Neue Features

### 🔧 Automatische Ordnerstruktur

- Erstellt automatisch alle benötigten Ordner
- Intelligente Strukturprüfung beim Start

### 📊 Erweiterte Konfiguration

- **settings.json**: Vollständige Konfiguration
- **Debug-Modus**: Detaillierte Ausgaben
- **Auto-Update**: Automatische GitHub-Integration

### 📝 Verbessertes Logging

- Tägliche Log-Dateien mit Zeitstempel
- Separate Startup- und Error-Logs
- Automatische Log-Bereinigung (30 Tage)

### 🔄 Automatische Updates

- Git-Integration für automatische Updates
- Intelligente Backup-Erstellung vor Updates
- Versionierung alter Dateien

### 🛠 PowerShell-Erkennung

- Automatische Erkennung von PowerShell 7 vs Windows PowerShell
- Intelligente Auswahl der besten verfügbaren Version

## 🎛️ Konfiguration

### settings.json - Hauptkonfiguration

```json
{
  "version": "7.0",
  "codename": "Moon", 
  "debug_mode": false,     # Debug-Modus ein/aus
  "auto_update": true,     # Auto-Updates aktivieren
  "log_level": "INFO",     # Logging-Level
  "max_backups": 10,       # Max. Anzahl Backups
  "repository_url": "https://github.com/JonKazama-Hellion/hellion-power-tool.git",
  "script_name": "hellion_tool_v70_moon.ps1"
}
```

### Debug-Modus aktivieren

```json
"debug_mode": true
```

**Zeigt an:**

- Detaillierte Startup-Informationen
- PowerShell-Versionsdetails
- Git-Status und Update-Informationen
- Pfad- und Dateisystem-Details

## 🚀 Verwendung

### Standard-Start

```batch
launcher.bat
```

### Features

1. **Automatische Ordnererstellung**
2. **PowerShell-Erkennung und -Auswahl**
3. **Config-System-Initialisierung**
4. **Git-Update-Check (optional)**
5. **Intelligente Script-Erkennung**
6. **Vollständiges Logging**

## 🔄 Auto-Update-System

### Funktionsweise

1. **Git-Check**: Prüft auf verfügbare Updates
2. **Backup**: Erstellt automatisch Backups vor Updates
3. **Update**: Lädt neue Version herunter
4. **Cleanup**: Bereinigt alte Backups (max. 10)

### Manuell deaktivieren

```json
"auto_update": false
```

## 📋 Logs

### Log-Dateien

- **startup.log**: Launcher-Aktivitäten
- **error.log**: Fehler und Warnungen  
- **actions.log**: PowerShell-Script-Logs

### Log-Format

```text
================================================================
HELLION LAUNCHER v7.0 Moon - START
Zeitstempel: 07.09.2025 14:30:15
Build: 20250907
================================================================
```

## 🐛 Fehlerbehandlung

### Häufige Probleme

**PowerShell nicht gefunden:**

```text
[ERROR] Keine PowerShell-Version gefunden!
LÖSUNG: Installieren Sie PowerShell 7 oder Windows PowerShell
```

**Script nicht gefunden:**

```text
[ERROR] Kein PowerShell-Script gefunden!  
LÖSUNG: Laden Sie das Hellion Tool herunter
```

**Git-Fehler:**

```text
[WARNING] Git nicht verfügbar - Keine Updates möglich
```

## 🔧 Erweiterte Features

### Backup-System

- Automatische Backups vor Updates
- Zeitstempel-basierte Benennung
- Automatische Bereinigung alter Backups

### Intelligente Script-Erkennung

1. Sucht nach `hellion_tool_v70_moon.ps1`
2. Fallback auf `hellion_tool_v*.ps1`
3. Fehlerbehandlung bei fehlenden Scripts

### Log-Bereinigung

- Automatisches Löschen von Logs älter als 30 Tage
- Konfigurierbar über `settings.json`

## 📈 Version History

### v7.0 "Moon" (Aktuell)

- ✅ Vollständiges Config-System
- ✅ Auto-Update mit Git
- ✅ Erweiterte Fehlerbehandlung  
- ✅ Debug-Modus
- ✅ Automatische Ordnerstruktur

### v6.5 "Monkey" (Alt)

- Basic PowerShell-Erkennung
- Einfacher Launcher

## 🎯 Geplante Features

- [ ] GUI-Konfiguration
- [ ] Update-Benachrichtigungen
- [ ] Erweiterte Backup-Optionen
- [ ] Remote-Konfiguration

---

**Entwickelt von:** Hellion Online Media - Florian Wathling  
**Website:** [https://hellion-online-media.de](https://hellion-online-media.de)  
**Support:** [support@hellion-online-media.de](mailto:support@hellion-online-media.de)
