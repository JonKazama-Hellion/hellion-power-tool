# 🚀 Launcher Directory - System-Start Komponenten

Dieser Ordner enthält alle Start- und Update-Komponenten des Hellion Power Tools.

---

## 📁 **Datei-Übersicht**

### 🎯 **`simple-launcher.bat`** - Haupt-Launcher

**Zweck**: Der intelligente Hauptlauncher mit PowerShell-Detection und Auto-Features  
**Gestartet von**: `START.bat` im Root-Verzeichnis  
**Features**:

- ✅ **PowerShell 7 Detection** - Automatischer Fallback zu Windows PowerShell
- ✅ **Update-Check Angebot** - Optionaler GitHub Update-Check vor Start
- ✅ **Parameter-Weiterleitung** - Debug-Modi (0=Normal, 1=Debug, 2=Dev)
- ✅ **UTF-8 Encoding** - Korrekte deutsche Umlaute
- ✅ **UAC-Elevation** - Automatische Admin-Rechte wenn nötig

**Aufruf-Beispiele**:

```batch
simple-launcher.bat 0        # Normal-Modus
simple-launcher.bat 1        # Debug-Modus  
simple-launcher.bat 2        # Developer-Modus
```

---

### 🔄 **`update-check.bat`** - GitHub Update-Checker

**Zweck**: Intelligent GitHub Version-Vergleich mit robuster Fehlerbehandlung  
**Gestartet von**: `simple-launcher.bat` (optional) oder manuell  
**Features**:

- ✅ **Git Auto-Installation** - Installiert Git automatisch via winget
- ✅ **Shallow Clone** - Effizienter `--depth 1` Download von GitHub
- ✅ **Timestamp-basierter Vergleich** - 14-stelliger Timestamp für präzise Versionierung
- ✅ **Intelligente Update-Logik** - Timestamp + Version-basierte Entscheidungen
- ✅ **Auto-Backup** - Automatisches Backup vor Update-Installation

**Update-Entscheidung**:

- **UPDATE**: Wenn GitHub-Version oder Timestamp neuer als lokal
- **HOTFIX**: Gleiche Version aber neuerer Timestamp
- **SKIP**: Lokale Version ist neuer als GitHub

---

### ⚙️ **`install-ps7.bat`** - PowerShell 7 Installer

**Zweck**: Automatische PowerShell 7 Installation für bessere Performance  
**Gestartet von**: `simple-launcher.bat` (bei PS7-Erkennung)  
**Features**:

- ✅ **Winget-basiert** - Nutzt Microsoft's Package Manager  
- ✅ **Interaktive Installation** - Benutzer-Bestätigung vor Download
- ✅ **Launcher-Restart** - Automatischer Neustart nach Installation
- ✅ **Fehlerbehandlung** - Graceful Fallback zu Windows PowerShell

**Installation-Flow**:

1. **Winget-Check** - Prüft ob winget verfügbar
2. **User-Consent** - [J/N] Abfrage vor Installation  
3. **Download** - `winget install Microsoft.PowerShell`
4. **Verification** - Test ob PS7 erfolgreich installiert
5. **Restart** - Launcher startet mit PS7 neu

---

### 🚨 **`emergency-update.bat`** - Notfall-Updater

**Zweck**: Repariert Auto-Update Crashes für Benutzer von v7.1.0/v7.1.1  
**Verwendung**: Manueller Download bei Update-Problemen  
**Features**:

- ✅ **Backup-Erstellung** - Sichert alte `update-check.bat`
- ✅ **Selective Download** - Lädt nur die reparierte Update-Datei
- ✅ **Auto-Test** - Führt reparierten Update-Check aus
- ✅ **Cleanup** - Automatische Bereinigung temporärer Dateien

**Wann verwenden**:

- ❌ Auto-Update crasht mit "Cannot compare" Fehlern
- ❌ Version-Vergleich schlägt fehl
- ❌ Datum-Parsing Probleme bei älteren Versionen

---

## 🔧 **Entwickler-Informationen**

### 🏗️ **Architektur-Flow**

```text
START.bat → simple-launcher.bat → hellion_tool_main.ps1
     ↓              ↓
Debug-Level    Update-Check (optional)
     ↓              ↓
Parameter    install-ps7.bat (falls nötig)
Weiterleitung
```

### 🛠️ **Parameter-System**

- **Level 0**: Normal-Modus (Standard-User)
- **Level 1**: Debug-Modus (Extended Logging)  
- **Level 2**: Developer-Modus (Full Debug + Module Info)

### 🔄 **Update-Check Logik**

```bash
# Datum-Vergleich (primär)
if LOCAL_DATE < GITHUB_DATE → UPDATE

# Version-Fallback (sekundär)  
if VERSIONS_DIFFERENT + INVALID_DATES → UPDATE

# Entwicklungsschutz
if UNKNOWN_CODENAME → SKIP
```

### ⚠️ **Bekannte Edge-Cases**

1. **v7.1.0/7.1.1 Kompatibilität** - Ungültige Datum-Formate
2. **Git-Installation** - Neustart der Konsole erforderlich
3. **PS7 vs PS5** - Encoding-Unterschiede bei Umlauten
4. **UAC-Elevation** - Parameter-Verlust bei Admin-Restart

---

## 📋 **Testing-Checkliste**

Für Entwickler und Tester:

### ✅ **Standard-Tests**

- [ ] `simple-launcher.bat 0` - Normal-Start funktioniert
- [ ] `simple-launcher.bat 1` - Debug-Output sichtbar
- [ ] `update-check.bat` - Version-Vergleich ohne Crash
- [ ] PowerShell 7 Installation - Falls nicht vorhanden

### ✅ **Edge-Case Tests**

- [ ] Offline-Modus - Git nicht verfügbar
- [ ] Alte Version - v7.1.0/7.1.1 Kompatibilität  
- [ ] Ungültige `version.txt` - Fallback-Mechanismus
- [ ] Unbekannter Codename - Skip-Logik

### ✅ **Integration-Tests**

- [ ] START.bat → Launcher → Hauptscript Parameter-Flow
- [ ] Update-Check → Git-Installation → Launcher-Restart
- [ ] Emergency-Update → Backup → Repair → Test

---

Letzte Aktualisierung: 2026-03-15 - Hellion Power Tool v7.2.0.0 "Heimdall"
