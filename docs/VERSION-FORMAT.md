# 📋 Hellion Power Tool - Versionsnummern Erklärung

Diese Datei erklärt das Versionierungs-System des Hellion Power Tools.

## 📄 version.txt Format

Die Datei `config/version.txt` enthält genau 4 Zeilen:

```text
7.1.4.3
Odin
20250910
71432509101245
```

---

## 📊 Zeilen-Erklärung

### ZEILE 1: VERSION (Semantic Versioning)

**Format**: `MAJOR.MINOR.PATCH.BUILD`  
**Beispiel**: `7.1.5.2`

- **MAJOR (7)**: Große Änderungen, Breaking Changes
- **MINOR (1)**: Neue Features, abwärtskompatibel  
- **PATCH (4)**: Bugfixes, kleine Verbesserungen
- **BUILD (1)**: Build-System, Release-Korrekturen

### ZEILE 2: CODENAME (Thematisch)

**Aktuelle Serie**: Nordische Mythologie  
**Chronologie**: ... → Fenrir → Fenrir-Update → Odin → ...

### ZEILE 3: RELEASE-DATUM (Legacy-Format)

**Format**: `YYYYMMDD`  
**Beispiel**: `20250910`  
**Verwendung**: Für Abwärtskompatibilität zu alten Patchern

### ZEILE 4: TIMESTAMP (Neue Versionierung ab v7.1.4)

**Format**: `VVVVYYYYMMDDHHNN`  
**Beispiel**: `71432509101245`

**Aufbau**:

- **VVVV**: Version (7150 = 7.1.5.2)
- **YYYY**: Jahr (2025)
- **MM**: Monat (09)  
- **DD**: Tag (10)
- **HH**: Stunde (11)
- **NN**: Minute (42)

**Erklärung**: `71502509091645` = v7.1.5.2 vom 09.09.2025 um 16:45  
**Zweck**: Ermöglicht minutengenaue Updates am gleichen Tag

---

## 🔄 Update-System

### Hybrid-Vergleich

1. **Neue Versionen (ab v7.1.4)**: Timestamp-basiert (präzise)
2. **Alte Versionen (bis v7.1.3)**: Datum-basiert (kompatibel)

### Timestamp-Vorteile

- ✅ Minutengenaue Update-Erkennung
- ✅ Mehrere Updates pro Tag möglich  
- ✅ Numerischer Vergleich (7142 > 714)
- ✅ Abwärtskompatibilität erhalten

---

**Letzte Aktualisierung**: 2025-09-09 - Hellion Power Tool v7.1.5.2 "Baldur"
