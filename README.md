# 🔧 Hellion Power Tool v7.0 "Moon"

## Professionelles Windows-Systemoptimierungstool mit automatischer Installation

[![Version](https://img.shields.io/badge/Version-7.0%20Moon-blue.svg)](https://github.com/JonKazama-Hellion/hellion-power-tool)
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

### Manueller Download

1. Repository als ZIP herunterladen
2. Entpacken in gewünschten Ordner  
3. `launcher.bat` ausführen

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
