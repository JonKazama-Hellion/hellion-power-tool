# 🔧 Hellion Power Tool v7.1.5.4 "Baldur"

**Ein Windows System-Tool, zur Optimirung und Reinigung** ⚡

[![Version](https://img.shields.io/badge/Version-7.1.5.4%20Baldur-blue.svg)](https://github.com/JonKazama-Hellion/hellion-power-tool)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207.0%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-green.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-orange.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

---

## 👀 **TL;DR - Was ist das?**

Ein powervolles Windows-Wartungstool mit smartem Launcher, das sich selbst updated und dein System repariert.
**Kein Corporate-Bloat, nur Tools die funktionieren.** 🎯

### **Hauptfunktionen**

- 🛠️ **System reparieren**: SFC, DISM, CheckDisk - alles automatisch
- 🧹 **PC aufräumen**: Intelligente Cleanup + Bloatware-Erkennung  
- 📦 **Software managen**: Winget-Integration für Updates
- 🚀 **Smart Launcher**: Erkennt PowerShell 7, updated sich selbst
- 🛡️ **Defender-safe**: Optimiert um False-Positives zu vermeiden

---

## ⚠️ **Windows Defender False-Positive Warnung**

[![Security Status](https://img.shields.io/badge/Security-Verified%20Safe-green)](SECURITY.md)
[![False Positive](https://img.shields.io/badge/Defender-False%20Positive%20Warning-yellow)](DEFENDER-WHITELIST.md)
[![Open Source](https://img.shields.io/badge/Source-Fully%20Available-blue)](https://github.com/JonKazama-Hellion/hellion-power-tool)

**Windows Defender kann dieses Tool fälschlicherweise als "Trojan:Script/Wacatac.B!ml" markieren.**

🛡️ **Das ist ein FALSE POSITIVE!** Dieses Tool ist ein legitimes Open-Source System-Wartungs-Utility.

**📋 Lösung:**

1. **Vor Download**: [DEFENDER-WHITELIST.md](DEFENDER-WHITELIST.md) lesen
2. **Defender-Ausnahme hinzufügen**: Tool-Ordner zur Whitelist hinzufügen  
3. **Signierte Version verwenden**: Releases mit digitaler Signatur bevorzugen

**🔍 Sicherheit:** Vollständiger Quellcode verfügbar • Keine Malware • Legitimes Admin-Tool

---

## 🚀 **Installation & Start**

### Option 1: Schnellstart (empfohlen)

```text
1. ZIP runterladen und entpacken
2. START.bat doppelklicken (automatische Admin-Rechte)
3. Fertig!
```

### Option 2: Git Clone

```bash
git clone https://github.com/JonKazama-Hellion/hellion-power-tool.git
cd hellion-power-tool
# Starten (automatische Admin-Elevation):
START.bat
```

**Das Tool installiert automatisch PowerShell 7 wenn nötig** ⚡

---

## 🛠️ **Was kann es alles?**

### **System-Reparatur**

- **[1] SFC Check**: Windows Systemdateien prüfen & reparieren  
- **[2] DISM Repair**: Windows-Image reparieren
- **[3] CheckDisk**: Festplatte auf Fehler prüfen
- **[4] DLL Integrity**: Wichtige System-DLLs prüfen

### **System-Bereinigung**

- **[5] Umfassende Bereinigung**: Temp-Dateien, Cache, Logs
- **[6] Performance-Optimierung**: Services optimieren, Autostart aufräumen
- **[7] Bloatware finden**: Ungenutzte Programme erkennen

### **Diagnose & Info**

- **[8] System-Info**: Detaillierte Hardware/Software-Analyse
- **[9] Netzwerk-Test**: Internet-Konnektivität prüfen  
- **[10] Treiber-Status**: Veraltete/problematische Treiber finden
- **[11] System-Report**: Vollständigen Bericht erstellen

### **Erweiterte Tools**

- **[12] Netzwerk zurücksetzen**: TCP/IP Stack, DNS, Winsock reset
- **[13] Winget Updates**: Software-Updates verwalten
- **[14] RAM-Test**: Speicher-Diagnose mit Neustart

### **Schnell-Aktionen** ⚡

- **[A] Auto-Modus**: Vollautomatische Systembereitung
- **[Q] Quick-Clean**: Schnelle Bereinigung ohne Nachfragen
- **[W] Winget-Manager**: Software-Updates mit einem Klick

---

## 📁 **Repository-Struktur**

```text
hellion-power-tool/
├── START.bat                    # 🚀 Hauptstarter - hier doppelklicken!
├── hellion_tool_main.ps1        # 💻 Haupt-PowerShell-Script  
├── README.md                    # 📖 Diese Dokumentation
├── SECURITY.md                  # 🔐 Sicherheits-Informationen
├── LICENSE                      # 📄 Open Source Lizenz
├── Launcher/
│   ├── simple-launcher.bat      # 🎯 Intelligenter Launcher mit PS7 Support
│   └── update-check.bat         # 🔄 GitHub Update-Checker
├── modules/                     # 🧩 Modulare Tool-Sammlung (11 Module)
│   ├── system-cleanup.ps1       # 🧹 Bereinigung & Performance
│   ├── disk-maintenance.ps1     # 🛠️ SFC, DISM, CheckDisk Tools
│   ├── system-info.ps1          # 📊 System-Analyse & Reports
│   ├── network-tools.ps1        # 🌐 Netzwerk-Tests & Reset  
│   ├── winget-tools.ps1         # 📦 Software-Management
│   ├── security-tools.ps1       # 🛡️ Sicherheits-Features
│   ├── crash-analyzer.ps1       # 🔍 Bluescreen-Analyse
│   ├── system-restore.ps1       # ⏪ Wiederherstellungspunkte
│   ├── bloatware-detection.ps1  # 🗑️ Bloatware-Erkennung
│   ├── memory-diagnostic.ps1    # 🧠 RAM-Test & Diagnose
│   └── logging-utils.ps1        # 📝 Logging & Debug-System
├── config/
│   ├── version.txt              # 📌 Aktuelle Version (7.1.5.4 Baldur)
│   └── settings.json            # ⚙️ Konfiguration & Feature-Flags
├── scripts/                     # 🔧 Entwickler-Scripts
│   ├── sign-local.ps1           # ✍️ Code-Signierung (lokal)
│   └── test-signing.ps1         # ✅ Signatur-Verifikation
├── Debug/
│   └── launch-dev.ps1           # 🔧 Entwickler-Launcher mit Debug-Modi
└── docs/                        # 📚 Öffentliche Dokumentation
    ├── CHANGELOG.md             # 📝 Versions-Historie
    └── DEFENDER-WHITELIST.md    # 🛡️ Defender False-Positive Hilfe
```

---

## 🎮 **Debug-Modi für Nerds**

```batch
# Normal starten (automatische Admin-Rechte)
START.bat

# Mit Debug-Infos  
Debug\launch-dev.ps1 -DebugMode

# Vollständiger Developer-Modus
Debug\launch-dev.ps1 -DevMode

# PowerShell direkt (für Profis)
powershell -ExecutionPolicy Bypass -File hellion_tool_main.ps1 -ForceDebugLevel 2
```

---

## 🤝 **Support & Entwicklung**

- **Problem gefunden?** → [Issues melden](https://github.com/JonKazama-Hellion/hellion-power-tool/issues)
- **Neue Idee?** → [Diskussion starten](https://github.com/JonKazama-Hellion/hellion-power-tool/discussions)
- **Code verbessern?** → Pull Requests sind willkommen!

Das Tool ist modular aufgebaut - jede Funktion ist ein eigenes Modul. Macht es einfach zu erweitern und anzupassen. 🧩

---

## ⚖️ **Lizenz**

Creative Commons BY-NC-SA 4.0

- ✅ **Kostenlos** für private Nutzung
- ✅ **Teilen** und modifizieren erlaubt  
- ✅ **Quellcode** bleibt offen
- ❌ **Kommerzielle Nutzung** ohne Erlaubnis verboten

[Vollständige Lizenz](LICENSE)

---

## 🏆 **Credits**

**Entwicklung:** JonKazama-Hellion  
**Community:** Allen die Issues gemeldet und getestet haben 🙏  
**Inspiration:** Die Frustration mit Windows-Tools die nicht funktionieren 😤  

---

Viel Erfolg beim System-Optimieren! 🚀

Das Tool updated sich selbst - ihr müsst euch also nicht um neue Versionen kümmern. ⚡
