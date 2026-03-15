# Hellion Power Tool — Versionsnummern-Schema

Diese Datei erklärt das Versionierungs-System des Hellion Power Tools.

---

## version.txt Format

Die Datei `config/version.txt` enthält genau 4 Zeilen:

```text
7.2.0.0
Heimdall
20260315
72002603151430
```

---

## Zeilen-Erklärung

### Zeile 1: Version (Semantic Versioning)

**Format**: `MAJOR.MINOR.PATCH.BUILD`

| Stelle | Bedeutung                          | Beispiel |
| ------ | ---------------------------------- | -------- |
| MAJOR  | Große Änderungen, Breaking Changes | 7        |
| MINOR  | Neue Features, abwärtskompatibel   | 2        |
| PATCH  | Bugfixes, kleine Verbesserungen    | 0        |
| BUILD  | Build-System, Release-Korrekturen  | 0        |

### Zeile 2: Codename (thematisch)

**Aktuelle Serie**: Nordische Mythologie

Bisherige Codenamen (chronologisch):
Alpha → Beta → Gamma → Delta → Epsilon → Kazama → Beleandis → Monkey → Moon → Moon-Bugfix → Fenrir → Fenrir-Update → Odin → Baldur → **Heimdall**

### Zeile 3: Release-Datum (Legacy-Format)

**Format**: `YYYYMMDD`

Ich verwende dieses Format weiterhin für Abwärtskompatibilität zu älteren Update-Checkern.

### Zeile 4: Timestamp (präzise Versionierung ab v7.1.4)

**Format**: `VVVVYYYYMMDDHHNN`

**Aufbau**:

| Segment | Bedeutung                            | Beispiel |
| ------- | ------------------------------------ | -------- |
| VVVV    | Version komprimiert (7200 = 7.2.0.0) | 7200     |
| YYYY    | Jahr                                 | 2026     |
| MM      | Monat                                | 03       |
| DD      | Tag                                  | 15       |
| HH      | Stunde                               | 14       |
| NN      | Minute                               | 30       |

Beispiel: `72002603151430` = v7.2.0.0 vom 15.03.2026 um 14:30

Der Timestamp ermöglicht minutengenaue Update-Erkennung, sodass ich mehrere Updates am selben Tag veröffentlichen kann.

---

## Update-System

### Hybrid-Vergleich

Das Update-System vergleicht Versionen in zwei Modi:

1. **Neue Versionen (ab v7.1.4)** — Timestamp-basiert (präzise, minutengenau)
2. **Alte Versionen (bis v7.1.3)** — Datum-basiert (kompatibel)

### Vorteile des Timestamp-Systems

- Minutengenaue Update-Erkennung
- Mehrere Updates pro Tag möglich
- Numerischer Vergleich (7200 > 7154)
- Abwärtskompatibilität zu älteren Versionen bleibt erhalten

---

Letzte Aktualisierung: 2026-03-15 — Hellion Power Tool v7.2.0.0 "Heimdall"
Entwickelt von [Hellion Online Media](https://hellion-media.de)
