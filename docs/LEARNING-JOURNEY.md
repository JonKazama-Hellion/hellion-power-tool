# Entwicklungsgeschichte und Lernprozess

## Hintergrund

Ich bin Autodidakt. Das Hellion Power Tool ist mein erstes größeres Softwareprojekt — PowerShell, Batch-Scripting und WPF habe ich mir im Laufe der Entwicklung selbst beigebracht. Mein beruflicher Hintergrund ist Webentwicklung (Next.js, React, TypeScript), aber Desktop-GUI-Entwicklung mit WPF aus PowerShell heraus war komplettes Neuland. Die meiste Zeit arbeite ich alleine, lese Dokumentation und löse Probleme durch Recherche.

Wenn ich an einem Bug oder einer technischen Frage nicht weiterkomme, setze ich AI-Tools wie Claude Code als Hilfsmittel ein. Ich dokumentiere das hier, weil mir Transparenz wichtig ist.

---

## Warum erst ab Version 7 auf GitHub?

Das Hellion Power Tool war nie als öffentliches Projekt geplant. Es hat als Sammlung persönlicher Skripte angefangen — und ist durch reale Probleme gewachsen.

### Der Anfang: Eigene Faulheit

Ich hatte keine Lust, bei jedem Windows-Problem erneut zu googlen wie der Befehl nochmal hieß. SFC, DISM, CheckDisk — ich wusste dass es die gibt, aber die Syntax? Jedes Mal nachschlagen. Also habe ich angefangen, die wichtigsten Befehle als PowerShell-Skripte zu speichern, die ich einfach ausführen kann. Kein Tool, keine Struktur — nur einzelne `.ps1` Dateien für den Eigenbedarf.

### Erste Erweiterung: Ein Freund mit Problemen

Dann hatte ein Freund Probleme mit seinem System. Statt ihm Befehle zu diktieren, habe ich das Skript erweitert, um bei seinen Problemen aus der Ferne helfen zu können — einfach erfahren was los ist, ohne sich durch zehn Menüs zu klicken. Dabei kam auch die Suche nach der berüchtigten `ENE.sys` dazu. Das hat sich als komplizierter herausgestellt als erwartet: Meine ersten Versuche haben ständig False-Positives oder False-Negatives geliefert. Mittlerweile läuft die Erkennung so zuverlässig wie ich es mit meinen Mitteln hinbekomme.

Veröffentlichen? Fand ich damals unnötig. Ich habe mein Tool als nichts Besonderes empfunden — jeder mit etwas Coding-Wissen könnte das.

### Nächster Freund, nächstes Problem: Bluescreens

Unregelmäßig, aber ständig. Also musste eine Treiber-Analyse her, und der Crash-Analyzer wurde ausgebaut. Die Idee: Crash-Reports so aufbereiten, dass man sie auch ohne tiefes Systemwissen auswerten kann. Oder besser: Das Tool sagt einem direkt, was wahrscheinlich los war. Ob die Analyse immer stimmt, da bin ich mir ehrlich gesagt selbst nicht hundertprozentig sicher. Aber sie funktioniert und hilft bei der Eingrenzung auf jeden Fall.

### Das Launcher-Problem

Irgendwann hatte ich keine Lust mehr, einzelne `.ps1` Dateien per Chat zu verschicken. Also musste ein Launcher her — eine einzelne Datei die alles startet. Gemacht, getan. Technisch nicht hübsch, aber es hat funktioniert.

### Der Punkt, an dem es weiterging

Durch Carl Beleandis (siehe [CONTRIBUTORS.md](CONTRIBUTORS.md)) habe ich weitergemacht. Launcher verbessert, Struktur aufgebaut, versucht das Ganze übersichtlich zu machen. Irgendwann folgte das Auto-Update-System, was seine eigene Hölle war — und um ehrlich zu sein wahrscheinlich immer noch irgendwo Probleme hat. Aber das ist aktuell nebensächlich.

Ab Version 7 war das Tool strukturiert genug, um es auf GitHub zu stellen. Alles davor war ein organisch gewachsenes Durcheinander aus Skripten, das nie für fremde Augen gedacht war.

---

## Entwicklungsumgebung

Mein Setup:

- **Editor**: VS Code mit Extensions (Error Lens, GitLens, Better Comments, indent-rainbow, Code Spell Checker, Batch Language Support, Markdownlint, PSScriptAnalyzer)
- **Sprachen**: PowerShell 5.1/7.x, Batch (CMD), XAML (WPF)
- **Versionskontrolle**: Git + GitHub
- **AI-Unterstützung**: Claude Code (bei Bedarf)
- **OS**: Windows 11 Pro

---

## Lernquellen

- **Microsoft Docs** — insbesondere die PowerShell-Referenz
- **Stack Overflow** — für spezifische Fehlermeldungen und Lösungsansätze
- **YouTube** — Tutorials zu PowerShell, Batch-Scripting und allgemeiner Softwareentwicklung
- **Reddit** — r/PowerShell für Fragen und Inspiration
- **GitHub** — andere Open-Source-Projekte als Referenz

---

## Der Weg zur WPF-GUI

Ab Version 8.0.0.0 hat das Tool eine vollwertige WPF-Oberfläche. Das klingt im Ergebnis selbstverständlich — der Weg dahin war es nicht. Ich komme aus der Webentwicklung (Next.js, React, TypeScript), aber WPF aus PowerShell heraus ist eine völlig andere Welt. Kein Hot-Reload, keine DevTools im Browser, keine Stack-Overflow-Antwort für "PowerShell WPF Runspace UI-Update".

### Warum ist alles so langsam?

Die erste Version der GUI hat funktioniert — technisch. Aber jeder Klick auf eine Modul-Karte hat die gesamte Oberfläche eingefroren. Der Grund: Alle Module liefen im UI-Thread. In der Webentwicklung denkt man nicht über Threads nach, weil der Browser das regelt. In WPF muss man das selbst lösen. Die Lösung waren Runspaces — separate PowerShell-Threads die im Hintergrund laufen, während die GUI responsiv bleibt. Das Konzept zu verstehen und korrekt umzusetzen (Dispatcher.Invoke für UI-Updates, Stream-Weiterleitung, Fehlerbehandlung) hat mehrere Tage gedauert.

### Karten, Closures und der letzte Wert

Die Modul-Karten werden in einer Schleife generiert. Das Problem: Jeder Klick-Handler hat immer das letzte Modul gestartet, egal welche Karte man angeklickt hat. Ein klassischer Closure-Bug — die Schleifenvariable wird nicht kopiert, sondern referenziert. In JavaScript kennt man das, in PowerShell funktioniert die Lösung anders: `$capturedId = $modId` plus `.GetNewClosure()`. Dazu kam, dass `$script:`-Scope in Event-Closures nicht zuverlässig funktioniert und alles auf `$global:` umgestellt werden musste.

### Laufwerk H statt C, D, E

Einer der frustrierendsten Bugs: CheckDisk sollte das vom Nutzer gewählte Laufwerk prüfen — hat aber konsequent nur Laufwerk H genommen. Die Ursache war eine Kombination aus falschem Parameter-Passing in den Runspace und einer Variable die im falschen Scope lag. Das hat länger gedauert als es hätte müssen, weil die Fehlermeldung kein Laufwerk-Problem anzeigte, sondern einfach "erfolgreich" meldete — nur eben für das falsche Laufwerk.

### Live-Log und winget: "Ist das Programm abgestürzt?"

Winget gibt bei manchen Operationen (besonders bei grossen Updates) minutenlang keinen Output. Für den Nutzer sieht das aus, als wäre das Programm eingefroren. Die Lösung war mehrstufig: Ein pulsierender Live-Dot zeigt an, dass ein Modul noch läuft. Dazu kommen Loading-States mit Animation und ein System-Health-Bar der weiter aktualisiert wird. So sieht der Nutzer: Die GUI lebt, es passiert etwas im Hintergrund — auch wenn winget gerade schweigt.

### Umlaute: Wo geht was?

Umlaute in einem PowerShell-Projekt das auch als Batch gestartet wird und XAML lädt — das ist ein Minenfeld. In PowerShell-Strings funktionieren Umlaute. In XAML-Here-Strings manchmal nicht (Encoding-Problem). In Batch-Dateien nur mit Codepage 65001. In GitHub Actions werden sie zu Zeichensalat wenn man nicht explizit `-Encoding UTF8` angibt. Die Lösung war eine Kombination: XAML verwendet Unicode-Escapes (`&#x26A1;`), Batch-Dateien setzen `chcp 65001`, und ein Python-Audit-Script prüft das gesamte Projekt auf Encoding-Probleme. Claude Code Opus 4.6 hat hier massiv geholfen — nicht um die Lösung zu generieren, sondern um systematisch zu analysieren, wo welches Encoding greift und warum bestimmte Zeichen in bestimmten Kontexten brechen.

### Fenster-Drag im Vollbild

Ein Detail das einfach klingt: Das Fenster soll per Drag auf der Titelleiste verschiebbar sein — auch wenn es maximiert ist. In WPF gibt es dafür kein fertiges Property. Die Lösung erfordert MouseLeftButtonDown-Events, DragMove() und eine Logik die erkennt ob das Fenster gerade maximiert ist und es vorher in den Normal-State zurücksetzt. Klingt nach drei Zeilen, war aber mit Edge-Cases (Doppelklick zum Maximieren, Multi-Monitor) deutlich mehr.

### PS2EXE und Antivirus

Das Tool als `.exe` zu kompilieren war ein eigenes Abenteuer. PS2EXE funktioniert, aber das Ergebnis wird von fast jedem Antivirus-Scanner als verdächtig eingestuft. Bitdefender hat die fertige EXE direkt in die Quarantäne gepackt — noch bevor sie einmal gestartet wurde. Der Grund: PS2EXE bettet PowerShell-Code in eine .NET-Executable ein, und das Muster (Base64-encoded Script in EXE) ist identisch mit dem, was echte Malware tut. Die Lösung: Defender-Metadata im Code, spezifische Code-Patterns die heuristische Erkennung reduzieren, und eine ausführliche Whitelist-Anleitung für Nutzer. Das Problem ist nicht vollständig lösbar — es liegt in der Natur von PowerShell-zu-EXE-Kompilierung.

---

## Einsatz von AI-Tools

Ich verwende Claude Code als Hilfsmittel — nicht als Ersatz für eigene Arbeit.

**Wofür ich AI einsetze:**

- Debugging von Problemen, bei denen ich nach längerer Eigenrecherche nicht weiterkomme
- Verständnisfragen zu komplexer Logik oder unerwarteten Fehlern
- Code-Review und Strukturverbesserung
- Erklärungen zu PowerShell-Konzepten, die mir noch nicht geläufig sind

**Was ich selbst mache:**

- Architektur und Projektstruktur
- Feature-Konzeption und -Implementierung
- Alle Designentscheidungen
- Testing und Qualitätssicherung

Die Feature-Ideen stammen von mir und meinen Testern (siehe [CONTRIBUTORS.md](CONTRIBUTORS.md)). AI hilft mir, diese Ideen sauber umzusetzen, wenn ich an technischen Grenzen stoße.

---

## Warum diese Transparenz

Wer sich den Quellcode ansieht, soll wissen:

- Ich bin kein professioneller Entwickler und lerne weiterhin dazu
- AI-Unterstützung ist ein Werkzeug, kein Ghostwriter
- Alle Ideen, Features und die Grundstruktur sind Eigenleistung
- Ich versuche, meinen Code so sauber wie möglich zu halten

Ich hoffe, dass andere Anfänger sehen: Es ist in Ordnung, sich Hilfe zu holen. Ob durch Dokumentation, Community oder AI — entscheidend ist, dass man versteht, was der eigene Code tut.

---

## Feedback und Kontakt

Ich freue mich über jede Rückmeldung — ob Bug-Report, Feature-Vorschlag oder Tipp zur Verbesserung.

- **GitHub Issues**: [Bug-Reports und Feature-Requests](https://github.com/JonKazama-Hellion/hellion-power-tool/issues)
- **Website**: [hellion-media.de](https://hellion-media.de)
- **Projekt**: [hellion-initiative.online](https://hellion-initiative.online)

---

Letzte Aktualisierung: v8.0.0.0 "Jörmungandr" — 2026-03-20
