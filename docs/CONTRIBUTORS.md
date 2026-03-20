# Contributors — Hellion Power Tool

Dieses Projekt wäre ohne die folgenden Personen nicht das, was es heute ist.
Jeder hat auf seine Weise dazu beigetragen — ob durch Bug-Reports, Feature-Ideen oder schlicht dadurch, dass er das Tool im Alltag getestet hat.

---

## Entwicklung

### JonKazama — Projektleitung und Entwicklung

Ich habe das Hellion Power Tool als persönliche Skriptsammlung gestartet, weil ich keine Lust hatte, bei jedem Windows-Problem die Befehle erneut nachzuschlagen. Was als Sammlung einzelner `.ps1` Dateien begann, ist über 7+ Monate zu einem modularen Wartungstool mit WPF-Oberfläche gewachsen.

PowerShell, Batch-Scripting und WPF habe ich mir während der Entwicklung selbst beigebracht. Mein beruflicher Hintergrund ist Webentwicklung (Next.js, React, TypeScript) — Desktop-GUI-Programmierung war komplettes Neuland. Mehr zum Lernprozess in [LEARNING-JOURNEY.md](LEARNING-JOURNEY.md).

Das Tool ist Teil von [Hellion Online Media](https://hellion-media.de) und wird über [hellion-media.de/hellion-power-tool](https://hellion-media.de/hellion-power-tool) bereitgestellt.

---

## Testing

### LomaChalit — Alpha-Tester

LomaChalit testet das Tool seit den frühen Versionen und hat maßgeblich zur Stabilität beigetragen. Er findet Probleme, bevor sie bei anderen Nutzern aufschlagen — und hat keine Scheu, auch die unbequemen Bugs zu melden.

**Bug-Reports:**

- 6+ kritische Bugs in den Alpha-Versionen
- NetTCPIP Module Loading Error — frühzeitig erkannt, bevor es produktionsrelevant wurde
- Winget Update Placeholder-Problem (Update0, Update1, Update2)
- 24h Restore Point Limitation — führte zur Entwicklung eines Registry-Workarounds
- ENE.SYS Kompatibilitätsprobleme auf seinem System
- Auto-Updater Fehler über mehrere Versionen hinweg — hat das Update-System durch konsequentes Testen stabil gemacht

**Feature-Ideen:**

- Treiber-Diagnose — entstanden aus seinem ENE.SYS-Problem
- DLL-Analyzer — sein Vorschlag für System-Integritätsprüfung

### Carl Beleandis — Beta-Tester

Carl testet das Tool aus der Perspektive eines normalen Anwenders — und genau das macht sein Feedback so wertvoll. Seine Rückmeldungen zu Bedienung und Verständlichkeit haben die Benutzerführung deutlich verbessert.

Er ist außerdem der Grund, warum das Tool überhaupt öffentlich veröffentlicht wurde. Ohne seinen Zuspruch wäre es eine private Skriptsammlung geblieben.

**Bug-Reports:**

- 4+ Fehlerberichte aus der frühen Entwicklungsphase
- UI/UX-Feedback — seine Rückmeldungen führten zur Überarbeitung der Menüstruktur

**Feature-Ideen:**

- SFC/DISM/CheckDisk Integration — basiert auf seinen Anforderungen für sichere System-Reparatur-Automatisierung
- Bluescreen-Analyzer — entstand aus konkreten Bluescreens auf seinem System, die analysiert werden mussten

### Jingliu — Motivation

Manchmal sitze ich stundenlang vor einem Problem und komme nicht weiter. In diesen Momenten gibt mir Jingliu den nötigen Zuspruch, um weiterzumachen.

### Jacky — Moralischer Beistand

Mein Hund. Liegt neben mir beim Debuggen und urteilt nicht.

---

## Development Support

### Claude Code — AI Development Assistant

AI-Tool, das ich als Hilfsmittel einsetze — nicht als Ersatz für eigene Arbeit. Architektur, Features und alle Entscheidungen sind Eigenleistung. Claude Code hilft bei:

- Debugging von komplexen PowerShell- und WPF-Problemen
- Analyse von Encoding-Problemen (Umlaute in XAML, Batch, GitHub Actions)
- Code-Optimierung und Strukturverbesserung
- Erklärungen, warum etwas nicht funktioniert

AI ist ein Werkzeug — entscheidend ist, dass man versteht, was der eigene Code tut. Mehr dazu in [LEARNING-JOURNEY.md](LEARNING-JOURNEY.md).

---

## Übersicht

| Contributor | Rolle | Bugs gefunden | Beitrag |
| --- | --- | --- | --- |
| **LomaChalit** | Alpha-Testing | 6+ | Stabilität und Feature-Ideen |
| **Carl Beleandis** | Beta-Testing | 4+ | User Experience und Core-Features |
| **Jingliu** | Motivation | — | Mentale Unterstützung |
| **Jacky** | Moralischer Support | — | Emotionale Unterstützung |
| **Claude Code** | AI-Debugging | — | Technische Lösungsunterstützung |

---

## Kritische Bug-Entdeckungen

1. **NetTCPIP Module Error** *(LomaChalit)* — hätte ohne Fallback das gesamte Tool unbrauchbar gemacht
2. **24h Restore Point Limit** *(LomaChalit)* — Registry-Workaround entwickelt
3. **Winget Update Placeholders** *(LomaChalit)* — Update0/Update1/Update2 Anzeigefehler behoben

## Feature-Ideen aus der Community

1. **SFC/DISM/CheckDisk Integration** *(Carl Beleandis)* — sichere System-Reparatur-Automatisierung
2. **Bluescreen-Analyzer** *(Carl Beleandis)* — Crash-Log-Analyse für Endanwender
3. **Treiber-Diagnose** *(LomaChalit)* — ENE.SYS und allgemeine Treiberprobleme
4. **DLL-Analyzer** *(LomaChalit)* — System-Integritätsprüfung

---

## Mitmachen

Das Tool lebt von Community-Feedback. Wer Interesse hat:

- **Bug-Reports** — Tool testen und Probleme melden (gerne mit Screenshots und Reproduktionsschritten)
- **Feature-Ideen** — Vorschläge für neue Funktionen oder Verbesserungen
- **Alpha/Beta-Testing** — Neue Versionen vor dem Release testen
- **Dokumentation** — Übersetzungen, Tutorials oder Anwendungsbeispiele

---

## Kontakt

- **GitHub**: [github.com/JonKazama-Hellion/hellion-power-tool](https://github.com/JonKazama-Hellion/hellion-power-tool)
- **Website**: [hellion-media.de](https://hellion-media.de)
- **Projekt**: [hellion-media.de/hellion-power-tool](https://hellion-media.de/hellion-power-tool)

---

*Erstellt: 2025-09-09*
*Letzte Aktualisierung: v8.0.0.0 "Jörmungandr" — 2026-03-20*
