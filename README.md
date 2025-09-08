# 🔧 Hellion Power Tool v7.1.0 "Fenrir"

## Revolutionäres Windows-Tool mit intelligentem Launcher-System und Auto-Update

[![Version](https://img.shields.io/badge/Version-7.1.0%20Fenrir-blue.svg)](https://github.com/JonKazama-Hellion/hellion-power-tool)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207.0%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-green.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-orange.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
[![Auto-Update](https://img.shields.io/badge/Auto--Update-GitHub-brightgreen.svg)](https://github.com/JonKazama-Hellion/hellion-power-tool)

---

## 🚀 Was ist das Hellion Power Tool?

Das **Hellion Power Tool v7.1.0 "Fenrir"** revolutioniert Windows-Systemoptimierung mit einem komplett neuen Launcher-System, automatischen Updates und crashsicherer Architektur.

> **🎉 NEW in Fenrir:** Revolutionäres START.bat → simple-launcher.bat System, PowerShell 7 Auto-Installation, intelligenter GitHub Update-Check mit Entwicklerschutz, und crashsichere Implementierung.

### ✨ Hauptfeatures v7.1.0 "Fenrir"

#### 🚀 Launcher Revolution
- 🎯 **Einfaches START.bat → simple-launcher.bat System:** Ein Starter, ein Launcher - keine Komplexität
- ⚡ **PowerShell 7 Auto-Installation:** Automatische Installation via winget mit Launcher-Restart  
- 🔄 **Intelligente PowerShell-Detection:** PS7 → PS5 Fallback mit robuster Erkennung
- 📋 **Saubere Parameter-Weiterleitung:** Debug-Modi korrekt durch UAC übertragen

#### 🔄 Auto-Update-System  
- 🌐 **GitHub-Integration:** Direkter Zugriff auf offizielle Releases
- 🛡️ **Entwicklerschutz:** Verhindert versehentliche Downgrades
- 📝 **Codename-Whitelist:** Erkennt legitime vs. Entwicklungsversionen
- 🔧 **Git-Auto-Installation:** Installiert Git automatisch wenn benötigt

#### 🛠️ Bewährte System-Tools
- 🛡️ **System-Reparatur:** SFC, DISM, Checkdisk mit Timeout-Schutz
- 🧹 **Intelligente Bereinigung:** Temp-Dateien, Caches, Registry
- 📦 **Safe Software-Updates:** Winget-Integration mit Hängen-Schutz  
- 🚫 **Safe Adblock:** Host-basierte Werbung/Tracking-Blockierung
- 🔧 **Performance-Optimierung:** Dienste, Autostart, RAM

---

## 📥 Installation & Start

### 🚀 Einfachster Start (Empfohlen)

1. **Repository als ZIP herunterladen** von GitHub
2. **Entpacken** in gewünschten Ordner  
3. **`START.bat` ausführen** - Das war's! 🎉

> **✨ Neues Launcher-System:** START.bat → Debug-Level wählen → simple-launcher.bat → Optional: Update-Check → Tool startet!

### 🔧 Git Clone (Für Entwickler)

```bash
git clone https://github.com/JonKazama-Hellion/hellion-power-tool.git
cd hellion-power-tool
START.bat
```

## 🚀 Neues Launcher-System v7.1.0

### 📋 Launcher-Flow
1. **START.bat** - Benutzerfreundlicher Starter mit Debug-Level Auswahl
2. **launcher/simple-launcher.bat** - Intelligente PowerShell-Detection  
3. **Optional: launcher/update-check.bat** - GitHub Update-Prüfung
4. **hellion_tool_main.ps1** - Hauptscript mit korrekten Parametern

### 🎯 Automatische Features
- ✅ **PowerShell 7 Detection:** Erkennt PS7, fallback auf PS5
- ✅ **PowerShell 7 Installation:** Automatisch via winget mit Neustart
- ✅ **Update-Check:** Optional, erkennt neue GitHub-Releases  
- ✅ **Entwicklerschutz:** Verhindert versehentliche Downgrades
- ✅ **Parameter-Passing:** Debug-Modi korrekt übertragen

### 🔄 Auto-Update-Logik
```
Wenn Lokales_Datum < GitHub_Datum → UPDATE verfügbar
Wenn Lokales_Datum >= GitHub_Datum → Kein Update nötig  
Wenn Unbekannter_Codename → Update überspringen (Dev-Version)
```

## 🛡️ Kompatibilität & Problemlösung

### Das Tool funktioniert **immer** - auch bei:
- ❌ **Windows Defender blockiert Launcher** → Automatischer Safe-Mode
- ❌ **PowerShell nicht im PATH** → Erweiterte Windows-Suche  
- ❌ **Winget hängt sich auf** → 60s Timeout mit Fallback
- ❌ **Beschädigte PowerShell-Installation** → Multi-Pfad-Erkennung
- ❌ **Firmen-PC mit Einschränkungen** → Defender-sichere Ausführung

### 🔍 Bei Problemen:
Verwende die **Debug-Tools** im `Debug/` Ordner für detaillierte Diagnose.

---

## 📁 Repository-Struktur

```
hellion-power-tool/
├── launcher.bat                    # 🚀 HAUPTLAUNCHER - Smart & Universal
├── hellion_tool_v70_moon.ps1      # 💾 Core PowerShell Tool
├── LICENSE                        # ⚖️ CC BY-NC-SA 4.0 (Non-Commercial)
├── README.md                      # 📖 Diese Datei
├── CHANGELOG.md                   # 📋 Vollständige Versionshistorie
│
├── Debug/                         # 🔍 Diagnose-Tools bei Problemen
│   ├── README.md                  # 📖 Debug-Tool Anleitung
│   ├── simple-debug.bat          # 🎯 Haupt-Debug-Tool (Empfohlen)
│   ├── defender-test.bat         # 🛡️ Windows Defender Diagnose
│   ├── powershell-diagnose.bat   # 🔧 PowerShell PATH-Probleme
│   └── ...                       # 📊 Weitere Diagnose-Tools
│
├── Launcher/                      # ⚙️ Alternative Launcher-Versionen
│   ├── README.md                  # 📖 Launcher-Dokumentation
│   ├── launcher-full.bat         # 🔄 Erweiterte Version (mit Updates)
│   └── launcher-safe.bat         # 🛡️ Defender-sichere Version
│
├── config/                       # ⚙️ Konfigurationsdateien
│   ├── settings.json             # 🎛️ Tool-Einstellungen
│   └── version.txt               # 🏷️ Versionsinformationen
│
└── old Versions/                 # 📚 Entwicklungshistorie
    └── ...                       # 🗂️ Ältere Versionen zur Referenz
```

## 🚀 Smart Launcher System

Das **v7.0.3 Smart Launcher System** wählt automatisch die beste Ausführungsmethode:

### 🎯 Automatische Launcher-Auswahl:
1. **Standard-Launcher** (`launcher.bat`) startet
2. **Kompatibilitätsprüfung** - Erkennt Defender-Blockaden
3. **Automatischer Fallback** - Wechselt zu Safe-Mode bei Problemen
4. **Universal-Modus** - Funktioniert auf **allen** Windows-Systemen

### 🛠 Manuelle Launcher-Auswahl:
- **`launcher.bat`** → Smart Auto-Auswahl (⭐ **Empfohlen**)
- **`Launcher/launcher-full.bat`** → Erweiterte Version mit Updates
- **`Launcher/launcher-safe.bat`** → Defender-sichere Version

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

**Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License**

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

### Was ist erlaubt:
- ✅ **Kostenlose private Nutzung**
- ✅ **Anpassen für eigene Zwecke**  
- ✅ **Teilen und Weiterverbreiten**

### Was ist NICHT erlaubt:
- ❌ **Kommerzielle Nutzung** (Verkauf, bezahlte Dienstleistungen)
- ❌ **Proprietäre Ableger** (ShareAlike-Pflicht)
- ❌ **Verwendung ohne Attribution**

> **💡 Schutz vor kommerzieller Ausbeutung:** Diese Lizenz verhindert, dass jemand das Tool nimmt und verkauft, während es für alle anderen frei nutzbar bleibt.

---

## ⭐ Gefällt dir das Tool?

Wenn das Hellion Power Tool dir geholfen hat:
- 🌟 **Gib dem Repository einen Stern** auf GitHub
- 📢 **Teile es mit Freunden** die auch Windows optimieren möchten
- 🐛 **Melde Bugs** über GitHub Issues

**Danke für deine Unterstützung!** 🙏
