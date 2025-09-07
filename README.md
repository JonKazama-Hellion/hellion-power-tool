# 🔧 Hellion Power Tool v7.0.2 "Moon-Bugfix"

## Professionelles Windows-Systemoptimierungstool mit automatischer Installation

[![Version](https://img.shields.io/badge/Version-7.0.2%20Moon--Bugfix-blue.svg)](https://github.com/JonKazama-Hellion/hellion-power-tool)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.0%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-green.svg)](https://www.microsoft.com/windows)

---

## 🚀 Was ist das Hellion Power Tool?

Das **Hellion Power Tool** ist eine vollständige Windows-Systemoptimierungslösung, die automatisch alle benötigten Abhängigkeiten installiert und Ihr System mit einem Klick optimiert.

### ✨ Hauptfeatures

- 🔄 **Auto-Installation:** Winget + PowerShell 7 automatisch
- 🛠 **System-Reparatur:** SFC, DISM, Checkdisk
- 🧹 **Intelligente Bereinigung:** Temp-Dateien, Caches, Registry
- 📦 **Software-Updates:** Automatische Winget-Integration
- 🔧 **Performance-Optimierung:** Dienste, Autostart, RAM
- 📊 **Detailliertes Logging:** Debug-Modus und Fehleranalyse

---

## 📥 Installation & Start

### Git Clone

```bash
git clone https://github.com/JonKazama-Hellion/hellion-power-tool.git
cd hellion-power-tool
launcher.bat
```

### Manueller Download (⚡ NEU: Auto-Update für ZIP-Downloads!)

1. Repository als ZIP herunterladen
2. Entpacken in gewünschten Ordner  
3. `launcher.bat` ausführen
4. **AUTOMATISCH:** Git-Repository wird initialisiert für Auto-Updates! 🔄

> **💡 Neu in v7.0.2:** Auch ZIP-Downloads erhalten automatisch das Auto-Update-System!

---

## 🔄 Auto-Update-System

### Für alle Download-Methoden verfügbar!

Das Hellion Power Tool v7.0.2 bietet ein **intelligentes Auto-Update-System** für beide Download-Methoden:

#### 🔧 Git Clone (Standard)
- Updates werden automatisch bei jedem Start geprüft
- `git pull` lädt neueste Version
- Backup-System erstellt Sicherheitskopien

#### 📦 ZIP-Download (⚡ NEU!)
- **Automatische Git-Initialisierung** beim ersten Start
- Erkennt fehlenden `.git` Ordner und richtet Repository ein
- Benutzergeführtes Setup mit Sicherheitskopie
- Nach Setup: Identische Auto-Update-Funktionalität wie Git Clone

### Ablauf bei ZIP-Download:
1. **Tool-Start** → Erkennt ZIP-Download (kein `.git` Ordner)
2. **🔧 GIT AUTO-UPDATE SETUP** → Interaktives Setup startet
3. **Repository-Initialisierung** → Verbindung zu GitHub
4. **Update-Prüfung** → Zeigt verfügbare Updates
5. **User-Auswahl** → "Erstes Update jetzt durchführen? [J/N]"
6. **Auto-Update** → Tool lädt neueste Version und startet neu

> **✨ Vorteil:** Einmalig einrichten - danach automatische Updates für immer!

---

## 🎯 Schnellstart

```batch
launcher.bat
```

Der Launcher installiert automatisch:

- ✅ Winget (falls nicht vorhanden)
- ✅ PowerShell 7 (falls nicht vorhanden)  
- ✅ Erstellt Ordnerstruktur
- ✅ Startet das Tool

---

## 📁 Projektstruktur

```text
hellion-power-tool/
├── launcher.bat              # 🚀 Hauptlauncher
├── hellion_tool_v70_moon.ps1 # 🔧 Hauptscript
├── config/
│   ├── settings.json         # ⚙️ Konfiguration
│   └── repository.txt        # 🔗 GitHub URL
├── logs/                     # 📝 Logs
├── backups/                  # 💾 Backups
└── temp/                     # 🗂 Temp
```

---

## 🔧 Features

### System-Reparatur

- **SFC:** Systemdatei-Reparatur
- **DISM:** Windows Image-Reparatur  
- **Checkdisk:** Dateisystem-Prüfung

### Software-Management

- **Winget-Integration:** Automatische Updates
- **Bulk-Updates:** Alle Updates auf einmal

### Debug-Modus

```json
"debug_mode": true
```

---

## 🤝 Support

**Entwickelt von:** Hellion Online Media - Florian Wathling  
**Website:** [https://hellion-online-media.de](https://hellion-online-media.de)  
**Kontakt:** [florian@hellion-online-media.de](mailto:florian@hellion-online-media.de)

---

## 📜 Lizenz

MIT License
