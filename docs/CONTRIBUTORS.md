# Contributors - Hellion Power Tool

Ein herzliches **DANKE** an alle, die mir bei der Entwicklung des Hellion Power Tools geholfen haben!

Ehrlich gesagt - ohne diese Leute wäre das Tool nie so gut geworden. Jeder hat auf seine Art dazu beigetragen, dass aus meiner Idee was Brauchbares wurde.

---

## 🚀 Entwicklung

### **JonKazama** - *Der Typ der das alles angefangen hat*

- **Das bin ich** - lerne noch programmieren und das Tool ist mein erstes größeres Projekt
- **Was ich gemacht hab**:
  - Das Tool von der ersten Idee bis v7.1.5.3 "Baldur" entwickelt
  - Viel gegoogelt, YouTube geschaut und Fehler gemacht
  - Langsam gelernt wie PowerShell und Batch-Scripting funktioniert
- **Expertise**: **Quasi keine** - bin Anfänger und lerne noch, aber das Tool läuft trotzdem xD

---

## 🧪 Testing & Die Leute die meine Bugs finden

### **LomaChalit** - *Ungewollter Alpha Tester*

LomaChalit ist der Grund warum das Tool überhaupt stabil läuft. Ernsthaft.

Er ist eher ungewollter Alpha-Tester - hat sich das Tool mal runtergeladen und gibt mir seitdem Bescheid wenn bei seinen Tests was nicht funktioniert.

- **Was er macht**: Findet alle Bugs die ich übersehe (und das sind viele xD)
- **Was er gefunden hat**:
  - 6+ kritische Bugs in den frühen Versionen
  - NetTCPIP Module Loading Error bevor es zum Problem wurde
  - Winget Update Placeholder Problem (Update0, Update1, Update2)
  - 24h Restore Point Limitation auf seinem System
  - **Seine Ideen**: Treiber-Analyse und DLL-Analyzer waren ursprünglich seine Vorschläge
  - Testet die ENE.SYS Probleme die sonst keiner hat
- **Warum er wichtig ist**: Ohne ihn wären Alpha und Beta Versionen kompletter Schrott gewesen
- **Dank**: Für das Testen von Features die speziell für ihn entwickelt wurden und die ganzen Feature-Ideen!

### **Carl Beleandis** - *Ungewollter Beta Tester*

Carl merkt an wenn was bei der Ausführung komisch aussieht und macht auf Schreibfehler aufmerksam.

- **Was er macht**: Testet Beta-Versionen und sagt mir wenn was scheiße aussieht oder nicht funktioniert
- **Seine Beiträge**:
  - 4+ Bug-Reports aus der Zeit als ich noch nicht getrackt hab
  - Feedback zu UI/UX - er hat mir gesagt dass meine Menüs unübersichtlich waren xD
  - **SFC/DISM/CheckDisk Integration**: Basiert auf seinen Anforderungen für sichere System-Reparatur-Tools - seine Rückmeldungen führten zur Entwicklung benutzerfreundlicher Automatisierung für komplexe Windows-Befehle
  - **Bluescreen-Analyzer**: Kam aus einem Geistesblitz von ihm als er's grad gebrauchen konnte
  - Testet Crash-Analyzer und Hardware-Features
- **Expertise**: Findet raus ob normale User das Tool verstehen würden (hat ja selbst keine Coding-Ahnung)
- **Dank**: Für das Testen von Features die auf seine Bedürfnisse zugeschnitten sind und dafür dass er der Grund ist warum das Tool öffentlich wurde!

### **Jingliu** - *Motivation & Encouragement*

- **Was sie macht**: Gibt mir Zuspruch und Mut wenn ich mal wieder an meinen Coding-Fähigkeiten zweifle
- **Warum wichtig**: Manchmal sitze ich stundenlang vor Bugs und will aufgeben - dann motiviert sie mich weiterzumachen
- **Dank**: Für die mentale Unterstützung beim Lernen und dafür dass sie an mich glaubt auch wenn ich selbst nicht daran glaube xD

### **Jacky** - *Moralischer Beistand*

- **Wer das ist**: Mein Hund xD
- **Seine Rolle**: Moralischer Beistand bei komplexen Windows-Problemen
- **Was er macht**: Liegt neben mir wenn ich debugge und hört zu ohne zu urteilen
- **Expertise**: Emotional support bei frustrierenden PowerShell-Fehlern
- **Dank**: Für die bedingungslose Unterstützung auch bei den dümmsten Coding-Fehlern

---

## 🤖 Development Support

### **Claude Code** - *AI Development Assistant*

- **Was das ist**: AI-Tool das mir hilft wenn ich komplett stuck bin
- **Wann ich es benutze**:
  - Bei Bugs die ich einfach nicht hinkriege (wie der Update-Checker der sich selbst gelöscht hat)
  - Wenn meine Logik keinen Sinn macht
  - Code aufräumen und verständlicher machen
  - Erklären warum mein Zeug nicht funktioniert
- **Gut für**: PowerShell-Debugging, Batch-Scripting, UI/UX-Verbesserungen

---

## 📊 Wer hat was gemacht (Statistiken)

| Contributor          | Was sie machen       | Bugs gefunden | QOL Fixes | Was sie gebracht haben               |
|----------------------|---------------------|---------------|-----------|--------------------------------------|
| **LomaChalit**       | Alpha Testing       | 6             | 4+        | Stabilität & Feature-Ideen           |
| **Carl Beleandis**   | Beta Testing        | 4+            | 5+        | User Experience & Core Features      |
| **Jingliu**          | Motivation          | 0             | ∞         | Mentale Unterstützung                |
| **Jacky**            | Moralischer Support | 0             | ∞         | Emotionale Unterstützung             |
| **Claude Code**      | AI Debugging        | 0             | 10+       | Technische Lösungen                  |

---

## 🎯 Hall of Fame - Die Helden

### 🔥 **Kritische Bug-Entdeckungen die mich gerettet haben**

1. **NetTCPIP Module Error** *(LomaChalit)* - Hätte das ganze Tool zerstört ohne Fallback  
2. **24h Restore Point Limit** *(LomaChalit)* - Sein System hatte diese Einschränkung, Registry-Hack entwickelt
3. **Winget Update Placeholders** *(LomaChalit)* - Update0/Update1/Update2 hätten User verwirrt

### 🎨 **Feature-Ideen die das Tool erst richtig gut gemacht haben**

1. **SFC/DISM/CheckDisk Integration** *(Carl Beleandis)* - Basiert auf seinen Anforderungen für sichere System-Reparatur-Automatisierung
2. **Bluescreen-Analyzer** *(Carl Beleandis)* - Geistesblitz als er's grad brauchte, super nützlich
3. **Treiber-Diagnose** *(LomaChalit)* - Wegen seinem ENE.SYS Problem entwickelt
4. **DLL-Analyzer** *(LomaChalit)* - Sein Vorschlag für System-Integrität

---

## 🤝 Willst du auch helfen?

Das Tool wird nur durch Community-Feedback besser! Falls du Lust hast:

### 🐛 **Bug-Hunting**

- Teste das Tool auf deinem System
- Melde wenn was nicht funktioniert (gerne mit Screenshots)
- Sag mir welche Schritte zum Problem führen

### 💡 **Ideen für neue Features**

- Vorschläge für Funktionen die fehlen
- UI/UX Verbesserungen (besonders wenn was verwirrend ist)
- Performance-Ideen

### 🧪 **Alpha/Beta Testing**

- Teste neue Versionen bevor sie live gehen
- Feedback zur Benutzerfreundlichkeit
- Hardware-Kompatibilitätstests

### 📝 **Dokumentation**

- Hilf bei der Doku (bin nicht so gut im Erklären)
- Übersetzungen wären cool
- Tutorials oder Anwendungsbeispiele

---

## 📞 Wo du mich findest

**Bugs gefunden? Ideen? Willst Alpha-Tester werden?**

- **GitHub**: [https://github.com/JonKazama-Hellion/hellion-power-tool](https://github.com/JonKazama-Hellion/hellion-power-tool)
- **Issues**: Für Bug-Reports und Feature-Requests
- **Discussions**: Für Feedback und Ideen

---

## 🌟 Danke an alle

Ehrlich - ohne diese Leute hier wäre das Tool kompletter Müll geworden. Jeder Bug-Report, jede Idee und jedes "das funktioniert nicht" hat geholfen, das Tool besser zu machen.

**Ich suche immer Leute die Lust haben zu testen**  
**Egal ob du Anfänger oder Profi bist - jedes Feedback hilft**

---

*Erstellt: 2025-09-09*  
*Letzte Aktualisierung: v7.1.5.3 "Baldur" Release*

## 🚀 Zusammen machen wir das Tool noch geiler
