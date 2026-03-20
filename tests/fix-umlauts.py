#!/usr/bin/env python3
# ===================================================================
# HELLION POWER TOOL — UMLAUT-FIX
# Ersetzt ASCII-Umlaute durch echte Umlaute in allen Projektdateien
# ===================================================================

import re, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Wort-basierte Ersetzungen (nur ganze Woerter/Wortanfaenge)
# Format: (regex_pattern, replacement_callback_or_string)
REPLACEMENTS = [
    # --- pruef/Pruef ---
    (r"\bPruef",        "Prüf"),
    (r"\bpruef",        "prüf"),
    (r"\bueberpruef",   "überprüf"),
    (r"\bUeberpruef",   "Überprüf"),
    # --- fuer/Fuer ---
    (r"\bfuer\b",       "für"),
    (r"\bFuer\b",       "Für"),
    # --- ueber/Ueber ---
    (r"\bUeber(?=[a-zä])", "Über"),
    (r"\bueber(?=[a-zä])", "über"),
    # --- zurueck ---
    (r"\bZurueck",      "Zurück"),
    (r"\bzurueck",      "zurück"),
    # --- loeschen ---
    (r"\bLoeschen",     "Löschen"),
    (r"\bloeschen",     "löschen"),
    # --- waehlen ---
    (r"\bWaehlen",      "Wählen"),
    (r"\bwaehlen",      "wählen"),
    # --- vollstaendig ---
    (r"\bVollstaendig", "Vollständig"),
    (r"\bvollstaendig", "vollständig"),
    # --- verfuegbar ---
    (r"\bVerfuegbar",   "Verfügbar"),
    (r"\bverfuegbar",   "verfügbar"),
    # --- ungueltig ---
    (r"\bungueltig",    "ungültig"),
    # --- aeusser ---
    (r"\bAeusser",      "Äußer"),
    (r"\baeusser",      "äußer"),
    # --- bootfaehig ---
    (r"\bbootfaehig",   "bootfähig"),
    # --- gefaehrlich ---
    (r"\bGefaehrlich",  "Gefährlich"),
    (r"\bgefaehrlich",  "gefährlich"),
    # --- ausgefuehrt ---
    (r"\bausgefuehrt",  "ausgeführt"),
    (r"\bAusgefuehrt",  "Ausgeführt"),
    (r"\bdurchfuehr",   "durchführ"),
    (r"\bDurchfuehr",   "Durchführ"),
    (r"\bausfuehr",     "ausführ"),
    (r"\bAusfuehr",     "Ausführ"),
    # --- hoeher ---
    (r"\bhoeher",       "höher"),
    # --- aendern ---
    (r"\bAendern",      "Ändern"),
    (r"\baendern",      "ändern"),
    (r"\bAender",       "Änder"),
    (r"\baender",       "änder"),
    # --- veraendert ---
    (r"\bVeraender",    "Veränder"),
    (r"\bveraender",    "veränder"),
    # --- oeffentlich ---
    (r"\bOeffentlich",  "Öffentlich"),
    (r"\boeffentlich",  "öffentlich"),
    # --- oeffnet ---
    (r"\bOeffnet",      "Öffnet"),
    (r"\boeffnet",      "öffnet"),
    (r"\bOeffne\b",     "Öffne"),
    (r"\boeffne\b",     "öffne"),
    # --- Groesse ---
    (r"\bGroesse",      "Größe"),
    (r"\bgroesse",      "größe"),
    # --- Gruen ---
    (r"\bGruen\b",      "Grün"),
    (r"\bgruen\b",      "grün"),
    # --- koennen ---
    (r"\bKoennen",      "Können"),
    (r"\bkoennen",      "können"),
    # --- moechte ---
    (r"\bMoechte",      "Möchte"),
    (r"\bmoechte",      "möchte"),
    # --- wuerde ---
    (r"\bWuerde",       "Würde"),
    (r"\bwuerde",       "würde"),
    # --- muessen ---
    (r"\bMuessen",      "Müssen"),
    (r"\bmuessen",      "müssen"),
    # --- noetig ---
    (r"\bNoetig",       "Nötig"),
    (r"\bnoetig",       "nötig"),
    (r"\bbenoetig",     "benötig"),
    (r"\bBenoetigt",    "Benötigt"),
    # --- schuetz ---
    (r"\bSchuetz",      "Schütz"),
    (r"\bschuetz",      "schütz"),
    # --- nuetzlich ---
    (r"\bNuetzlich",    "Nützlich"),
    (r"\bnuetzlich",    "nützlich"),
    # --- zuverlaessig ---
    (r"\bzuverlaessig", "zuverlässig"),
    (r"\bZuverlaessig", "Zuverlässig"),
    # --- voellig ---
    (r"\bvoellig",      "völlig"),
    (r"\bVoellig",      "Völlig"),
    # --- kuerzel ---
    (r"\bkuerzel",      "kürzel"),
    (r"\bKuerzel",      "Kürzel"),
    # --- Verknuepfung ---
    (r"\bVerknuepfung", "Verknüpfung"),
    (r"\bverknuepfung", "verknüpfung"),
    # --- Ausfuehrung ---
    (r"\bAusfuehrung",  "Ausführung"),
    (r"\bausfuehrung",  "ausführung"),
    # --- geprueft ---
    (r"\bgeprueft",     "geprüft"),
    (r"\bGeprueft",     "Geprüft"),
    # --- Saeubern ---
    (r"\bsaeubern",     "säubern"),
    (r"\bSaeubern",     "Säubern"),
    # --- geloescht ---
    (r"\bgeloescht",    "gelöscht"),
    (r"\bGeloescht",    "Gelöscht"),
    # --- erzaehlen ---
    (r"\berzaehl",      "erzähl"),
    # --- Rueckgabe ---
    (r"\bRueck",        "Rück"),
    (r"\brueck",        "rück"),
    # --- stueck ---
    (r"\bStueck",       "Stück"),
    (r"\bstueck",       "stück"),
    # --- ausfuellen ---
    (r"\bausfuell",     "ausfüll"),
    # --- Fehlermoeglich ---
    (r"\bmoeglich",     "möglich"),
    (r"\bMoeglich",     "Möglich"),
    # --- zusaetzlich ---
    (r"\bzusaetzlich",  "zusätzlich"),
    (r"\bZusaetzlich",  "Zusätzlich"),
    # --- spaeter ---
    (r"\bspaeter",      "später"),
    (r"\bSpaeter",      "Später"),
    # --- waehrend ---
    (r"\bwaehrend",     "während"),
    (r"\bWaehrend",     "Während"),
    # --- Aufraeumen ---
    (r"\baufraeumen",   "aufräumen"),
    (r"\bAufraeumen",   "Aufräumen"),
    # --- naechst ---
    (r"\bnaechst",      "nächst"),
    (r"\bNaechst",      "Nächst"),
    # --- Uebersicht ---
    (r"\bUebersicht",   "Übersicht"),
    (r"\buebersicht",   "übersicht"),
    # --- Einfuegen ---
    (r"\beinfueg",      "einfüg"),
    (r"\bEinfueg",      "Einfüg"),
    # --- ausgefuellt ---
    (r"\bausgefuellt",  "ausgefüllt"),
    # --- Auswaehl ---
    (r"\bAuswaehl",     "Auswähl"),
    (r"\bauswaehl",     "auswähl"),
    # --- Abkuerzung ---
    (r"\bAbkuerzung",   "Abkürzung"),
    # --- Sicherheitsluecke ---
    (r"\blueck",        "lück"),
    # --- Erhoehung ---
    (r"\berhoeh",       "erhöh"),
    (r"\bErhoeh",       "Erhöh"),
]

# Dateien die NICHT gefixt werden sollen
SKIP_PATTERNS = [".git", "node_modules", "logs"]

# Regex-Zeilen in PS1 ueberspringen (dort sind ASCII-Umlaute gewollt)
def is_regex_line(line):
    return bool(re.search(r"-match|-replace|-notmatch|Regex|\[regex\]", line))

def fix_file(filepath):
    relpath = os.path.relpath(filepath, ROOT)

    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            original = f.read()
    except Exception:
        return 0, []

    lines = original.split("\n")
    changes = []
    new_lines = []

    for line_num, line in enumerate(lines, 1):
        new_line = line

        # Regex-Zeilen ueberspringen
        if is_regex_line(line):
            new_lines.append(line)
            continue

        for pattern, replacement in REPLACEMENTS:
            new_line = re.sub(pattern, replacement, new_line)

        if new_line != line:
            changes.append((line_num, line.strip(), new_line.strip()))

        new_lines.append(new_line)

    if changes:
        new_content = "\n".join(new_lines)
        with open(filepath, "w", encoding="utf-8", newline="") as f:
            f.write(new_content)

    return len(changes), changes


# === MAIN ===
print("=" * 60)
print("  HELLION POWER TOOL — UMLAUT-FIX")
print("=" * 60)
print()

total_fixes = 0
fixed_files = 0

scan_files = []
for dirpath, dirs, files in os.walk(ROOT):
    dirs[:] = [d for d in dirs if d not in (".git", "node_modules", "logs", ".claude")]
    for f in files:
        ext = os.path.splitext(f)[1].lower()
        if ext in (".ps1", ".psm1", ".json", ".xaml", ".bat", ".cmd"):
            scan_files.append(os.path.join(dirpath, f))

for filepath in sorted(scan_files):
    relpath = os.path.relpath(filepath, ROOT)
    count, changes = fix_file(filepath)
    if count > 0:
        fixed_files += 1
        total_fixes += count
        print(f"  {relpath}: {count} Ersetzungen")
        for line_num, old, new in changes[:5]:
            print(f"    L{line_num}: {old[:70]}")
            print(f"      -> {new[:70]}")
        if len(changes) > 5:
            print(f"    ... und {len(changes)-5} weitere")
        print()

print(f"  {'='*50}")
print(f"  ERGEBNIS: {total_fixes} Ersetzungen in {fixed_files} Dateien")
print(f"  {'='*50}")
