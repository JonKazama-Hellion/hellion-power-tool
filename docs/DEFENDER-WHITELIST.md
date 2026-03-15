# Windows Defender Whitelist Anleitung

## Problem: False Positive "Trojan:Script/Wacatac.B!ml"

Windows Defender erkennt PowerShell-basierte Systemtools gelegentlich als Bedrohung. Das ist ein **bekanntes Problem** bei legitimen PowerShell-Scripts und betrifft nicht nur das Hellion Power Tool.

Der heuristische Detector **Wacatac.B!ml** reagiert auf Verhaltensmuster wie PowerShell + Netzwerkzugriffe, Registry-Operationen, Systemdatei-Änderungen und administrative Rechte. Das Hellion Power Tool nutzt diese Funktionen — aber ausschließlich für **legitime Systemwartung**.

Der vollständige Quellcode ist auf [GitHub](https://github.com/JonKazama-Hellion/hellion-power-tool) und über [hellion-media.de](https://hellion-media.de/hellion-power-tool) einsehbar.

---

## Lösung: Tool zur Defender-Ausnahme hinzufügen

### Methode 1: Über Windows Security (empfohlen)

1. **Windows Security öffnen** — Windows-Taste drücken, "Windows Security" eingeben, Enter
2. **Viren- & Bedrohungsschutz** — Auf "Viren- & Bedrohungsschutz" klicken
3. **Einstellungen verwalten** — Unter "Einstellungen für Viren- & Bedrohungsschutz" auf "Einstellungen verwalten" klicken
4. **Ausnahme hinzufügen** — Nach unten scrollen, "Ausnahmen hinzufügen oder entfernen", dann "Ausnahme hinzufügen" und "Ordner" wählen
5. **Hellion-Ordner auswählen** — Den Ordner wählen, in dem das Tool liegt

### Methode 2: Über PowerShell (schnell)

Als Administrator ausführen:

```powershell
Add-MpPreference -ExclusionPath "C:\Users\$env:USERNAME\Desktop\hellion-power-tool\"
```

Den Pfad entsprechend anpassen, falls das Tool woanders liegt.

### Methode 3: Über Gruppenrichtlinien (IT-Profis)

1. `gpedit.msc` öffnen
2. Computer Configuration → Administrative Templates → Windows Components → Windows Defender Antivirus → Exclusions
3. "Path Exclusions" aktivieren und den Hellion-Pfad hinzufügen

---

## Warum das Tool sicher ist

- **Open Source** — Kompletter Quellcode jederzeit einsehbar
- **Keine Obfuskierung** — Klarer, lesbarer PowerShell-Code
- **Keine Datenexfiltration** — Netzwerkzugriff nur für Konnektivitätstests und GitHub-Updates
- **Keine Admin-Rechte-Missbrauch** — Elevation nur für legitime Systemwartung
- **Defender-optimiert** — Kritische Befehle durch sichere Alternativen ersetzt

---

## Bereits durchgeführte Optimierungen

Ich habe zahlreiche Maßnahmen umgesetzt, um False Positives zu minimieren:

### Anti-False-Positive Verbesserungen

- **Netzwerk**: `Invoke-WebRequest` durch `Test-NetConnection` ersetzt
- **Downloads**: `Invoke-WebRequest` durch `.NET WebClient` ersetzt (Defender-sicher)
- **Prozesse**: `Start-Process -Verb RunAs` durch `ProcessStartInfo.Verb` ersetzt
- **Registry**: `Get-ItemProperty *` durch `Get-ChildItem + Get-ItemProperty` ersetzt
- **Delays**: `Start-Sleep` durch `[Threading.Thread]::Sleep` ersetzt

### Code-Qualitätsmaßnahmen

- Anti-Heuristic Headers in allen Modulen
- Detaillierte `.SYNOPSIS`-Dokumentation für statische Analyse
- Explizite Legitimate-Software-Markierung
- Keine Base64-Kodierung oder Verschlüsselung
- PSScriptAnalyzer-Prüfung in CI/CD

---

## Vorsichtsmaßnahmen

- Nur von **vertrauenswürdigen Quellen** herunterladen — [GitHub](https://github.com/JonKazama-Hellion/hellion-power-tool) oder [hellion-media.de](https://hellion-media.de/hellion-power-tool)
- Bei Zweifeln den **Quellcode prüfen** vor der Ausführung
- **Regelmäßige Updates** installieren für die neuesten Sicherheitsverbesserungen

---

## Support

Bei Problemen mit Defender:

1. **GitHub Issues** — False Positive melden: [Issues](https://github.com/JonKazama-Hellion/hellion-power-tool/issues)
2. **Website** — [hellion-media.de/kontakt](https://hellion-media.de/kontakt)
3. **Microsoft** — Defender-Team über das False Positive informieren

---

Hellion Power Tool v7.2.0.0 "Heimdall" — Entwickelt von [Hellion Online Media](https://hellion-media.de)
