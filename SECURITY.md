# Security Policy

## Sicherheitsinformationen

### Legitime Software-Deklaration

**Hellion Power Tool** ist ein legitimes Windows System-Wartungstool, entwickelt von [Hellion Online Media](https://hellion-media.de). Es dient ausschließlich der lokalen Systemwartung und -diagnose:

- System-Bereinigung und Performance-Optimierung
- Hardware- und Software-Diagnose
- Registry-Optimierung (nur nach Benutzerbestätigung)
- Netzwerk-Konnektivitätstests (lokal)
- Wiederherstellungspunkt-Verwaltung
- Automatische Updates via GitHub (Git Clone)

Der vollständige Quellcode ist Open Source und jederzeit einsehbar.

---

## Windows Defender False Positive

### Das Problem

Dieses Tool kann von Windows Defender als **"Trojan:Script/Wacatac.B!ml"** erkannt werden. Das ist ein **False Positive** — keine echte Bedrohung.

Die heuristische Erkennung reagiert auf Muster, die bei administrativen PowerShell-Tools unvermeidbar sind:

- PowerShell-Systemverwaltungsfunktionen (legitim)
- UAC-Elevation für Admin-Rechte (benutzerbestätigt)
- Registry-Analyse (nur Lese-Zugriff + bestätigte Änderungen)
- Netzwerk-Konnektivitätstests (nur lokal)

### Gegenmaßnahmen

1. **Quellcode prüfen** — Der gesamte Code ist öffentlich einsehbar
2. **Defender-Ausnahme hinzufügen** — Anleitung in [DEFENDER-WHITELIST.md](docs/DEFENDER-WHITELIST.md)
3. **Nur von offiziellen Quellen laden** — GitHub Repository oder [hellion-media.de](https://hellion-media.de/hellion-power-tool)

---

## Was dieses Tool tut

- Führt Standard-Windows-Wartungsaufgaben aus
- Fordert explizite Benutzerbestätigung vor Systemänderungen
- Verwendet ausschließlich eingebaute Windows-Werkzeuge
- Arbeitet lokal (Netzwerkzugriff nur für Konnektivitätstests und GitHub-Updates)
- Protokolliert alle Operationen in Log-Dateien

## Was dieses Tool nicht tut

- Lädt keinen fremden Code herunter oder aus (Updates sind Git Clones vom offiziellen Repository)
- Greift nicht auf persönliche Daten oder Anmeldeinformationen zu
- Ändert keine Systemdateien ohne Benutzerbestätigung
- Kommuniziert nicht mit externen Servern (außer Konnektivitätstests und GitHub-Updates)
- Installiert keine zusätzliche Software ohne explizite Benutzeraktion
- Enthält keinen schädlichen Code

---

## Sicherheitslücken melden

Ich nehme Sicherheit ernst. Falls du eine Schwachstelle findest:

- **GitHub Issues**: Issue mit dem Label `security` erstellen
- **E-Mail**: [kontakt@hellion-media.de](mailto:kontakt@hellion-media.de)
- **Reaktionszeit**: 48–72 Stunden
- **Offenlegung**: Koordinierte Offenlegung bevorzugt

### False-Positive melden

- **GitHub Issues**: Issue mit dem Label `false-positive` erstellen
- **Microsoft**: Direkt an das Windows Defender Team melden
- **Bitte mitschicken**: Vollständige Fehlermeldung und Kontext

---

## Sicherheitsmaßnahmen

### Für Benutzer

1. Nur von offiziellen Quellen herunterladen — [GitHub](https://github.com/JonKazama-Hellion/hellion-power-tool) oder [hellion-media.de](https://hellion-media.de/hellion-power-tool)
2. Bei Zweifeln den Quellcode vor der Ausführung prüfen
3. Das Tool regelmäßig aktualisieren

### Laufende Maßnahmen

- PSScriptAnalyzer auf allen Commits
- Defender-Kompatibilitätsprüfung in CI/CD
- Transparenter Entwicklungsprozess auf GitHub
- Regelmäßige Code-Reviews

---

## Kontakt

Bei sicherheitsbezogenen Fragen:

- **Website**: [hellion-media.de](https://hellion-media.de)
- **GitHub**: [Repository Issues](https://github.com/JonKazama-Hellion/hellion-power-tool/issues)
- **E-Mail**: [kontakt@hellion-media.de](mailto:kontakt@hellion-media.de)

Letzte Aktualisierung: 2026-03-20 — Hellion Power Tool v8.0.0.0 "Jörmungandr"
