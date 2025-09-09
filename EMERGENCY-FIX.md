# 🚨 NOTFALL-FIX für Auto-Update Crash (v7.1.0/7.1.1)

## Problem

Auto-Update crasht beim Versions-Vergleich für Benutzer von v7.1.0 und v7.1.1

## Schnelle Lösung (5 Minuten)

### Option 1: Emergency-Updater (Empfohlen)

1. **Lade herunter**: [emergency-update.bat](https://raw.githubusercontent.com/JonKazama-Hellion/hellion-power-tool/main/Launcher/emergency-update.bat)
2. **Kopiere** die Datei in deinen `hellion-power-tool/Launcher/` Ordner  
3. **Doppelklick** auf die Datei (NICHT als Administrator!)
4. **Fertig!** Auto-Update funktioniert wieder

### Option 2: Manueller Fix

1. **Lade herunter**: [update-check.bat](https://raw.githubusercontent.com/JonKazama-Hellion/hellion-power-tool/main/Launcher/update-check.bat)
2. **Ersetze** deine alte `hellion-power-tool/Launcher/update-check.bat`
3. **Fertig!** Auto-Update funktioniert wieder

### Option 3: Komplett neu herunterladen

1. **Lade herunter**: [Vollständige v7.1.3](https://github.com/JonKazama-Hellion/hellion-power-tool/archive/refs/heads/main.zip)
2. **Ersetze** deine komplette Installation
3. **Fertig!** Neueste Version mit allen Fixes

## Was war das Problem?

- Ältere Versionen hatten ungültige Datum-Formate in der `version.txt`
- Der Auto-Updater crashte beim numerischen Vergleich
- Jetzt: Robuste Validierung + Fallback-Mechanismus

## Kontakt

Bei weiteren Problemen: GitHub Issues oder Discord
