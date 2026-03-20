# Windows Defender — Warum das Tool erkannt wird und was du tun kannst

## Was passiert hier?

Windows Defender kann dieses Tool in seltenen Fällen als Bedrohung einstufen. Das ist ein sogenanntes **False Positive** — eine Fehleinschätzung, keine echte Bedrohung.

Das betrifft nicht nur das Hellion Power Tool. Praktisch jedes PowerShell-basierte Systemtool mit Admin-Rechten kann diese Reaktion auslösen — auch Tools von Microsoft selbst.

---

## Warum passiert das?

Windows Defender nutzt heuristische Analyse. Das bedeutet: Er erkennt nicht nur bekannte Schadsoftware, sondern bewertet auch Verhaltensmuster. Bestimmte Muster, die dieses Tool zwangsläufig nutzt, kommen auch in echter Malware vor:

| Was das Tool tut | Warum Defender reagiert |
| --- | --- |
| PowerShell mit Admin-Rechten ausführen | Malware nutzt PowerShell häufig für Systemzugriff |
| Systeminformationen auslesen (CIM/WMI) | Spyware sammelt ähnliche Daten |
| Netzwerk-Konnektivität testen | Malware prüft, ob sie "nach Hause telefonieren" kann |
| Registry-Werte lesen | Trojaner suchen in der Registry nach Konfigurationen |
| Dateien im Temp-Ordner löschen | Ransomware löscht ebenfalls Dateien |

Der Unterschied: Dieses Tool tut all das für **legitime Systemwartung** — und zeigt jeden einzelnen Schritt im Live-Log an.

---

## Warum du dem Tool vertrauen kannst

- **Vollständig Open Source** — Der komplette Quellcode liegt offen auf [GitHub](https://github.com/JonKazama-Hellion/hellion-power-tool)
- **Keine Verschleierung** — Klarer, lesbarer PowerShell-Code ohne Base64-Kodierung oder Obfuskierung
- **Keine Datenübertragung** — Netzwerkzugriff ausschließlich für Konnektivitätstests und den GitHub-Update-Check
- **Keine versteckten Prozesse** — Alles was ausgeführt wird, erscheint im Log
- **Nur Windows-Bordmittel** — Das Tool ruft SFC, DISM, CheckDisk und winget auf, keine eigene Systemlogik

Im Zweifel: Den Quellcode lesen. Alles ist einsehbar, nichts ist versteckt.

---

## Lösung: Tool als Ausnahme hinzufügen

### Methode 1: Über Windows Security (empfohlen)

1. Windows-Taste drücken, **"Windows Security"** eingeben, Enter
2. **Viren- & Bedrohungsschutz** anklicken
3. Unter "Einstellungen für Viren- & Bedrohungsschutz" auf **Einstellungen verwalten** klicken
4. Nach unten scrollen zu **Ausnahmen** und "Ausnahme hinzufügen" wählen
5. **Ordner** wählen und den Ordner auswählen, in dem das Hellion Power Tool liegt

### Methode 2: Über PowerShell (schnell)

Als Administrator ausführen:

```powershell
Add-MpPreference -ExclusionPath "C:\Users\$env:USERNAME\Desktop\hellion-power-tool\"
```

Den Pfad entsprechend anpassen, falls das Tool woanders liegt.

### Methode 3: Über Gruppenrichtlinien (für IT-Admins)

1. `gpedit.msc` öffnen
2. Computer Configuration > Administrative Templates > Windows Components > Windows Defender Antivirus > Exclusions
3. "Path Exclusions" aktivieren und den Hellion-Pfad hinzufügen

---

## Was wurde bereits gegen False Positives getan?

Das Tool wird aktiv so entwickelt, dass heuristische Erkennung minimiert wird:

### Code-Anpassungen

- **Netzwerk:** `Invoke-WebRequest` durch `Test-NetConnection` ersetzt — weniger verdächtig für Heuristik
- **Downloads:** `Invoke-WebRequest` durch `.NET WebClient` ersetzt
- **Prozesse:** `Start-Process -Verb RunAs` durch `ProcessStartInfo.Verb` ersetzt
- **Registry:** Gezielte Abfragen statt Wildcard-Scans (`Get-ChildItem` statt `Get-ItemProperty *`)
- **Delays:** `Start-Sleep` durch `[Threading.Thread]::Sleep` ersetzt

### Qualitätssicherung

- Anti-Heuristic Headers und Legitimate-Software-Markierungen in allen Modulen
- Detaillierte `.SYNOPSIS`-Dokumentation für statische Analyse durch AV-Scanner
- Keine Base64-Kodierung oder Verschlüsselung im gesamten Projekt
- PSScriptAnalyzer-Prüfung in der CI/CD-Pipeline (GitHub Actions)

---

## Nur von vertrauenswürdigen Quellen herunterladen

- **GitHub:** [github.com/JonKazama-Hellion/hellion-power-tool](https://github.com/JonKazama-Hellion/hellion-power-tool)
- **Website:** [hellion-media.de/hellion-power-tool](https://hellion-media.de/hellion-power-tool)

Bei Zweifeln den Quellcode prüfen, bevor das Tool ausgeführt wird. Das ist der Vorteil von Open Source.

---

## Probleme melden

Falls Defender das Tool trotz Ausnahme blockiert oder ein anderer AV-Scanner reagiert:

- **GitHub Issues:** [Bug-Report erstellen](https://github.com/JonKazama-Hellion/hellion-power-tool/issues)
- **Kontakt:** [hellion-media.de/kontakt](https://hellion-media.de/kontakt)

---

Hellion Power Tool v8.0.0.0 "Jörmungandr" — Entwickelt von [Hellion Online Media](https://hellion-media.de)
