#!/usr/bin/env python3
# ===================================================================
# HELLION POWER TOOL — PROJEKT-AUDIT
# Prueft alle Dateien auf Umlaute, Encoding, PS-Bugs, XAML-Fehler
# ===================================================================

import json, re, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

errors = []
warnings = []
stats = {"files": 0, "lines": 0}

# === DATEIEN SAMMELN ===
scan_files = []
for dirpath, dirs, files in os.walk(ROOT):
    dirs[:] = [d for d in dirs if d not in (".git", "node_modules", "logs", ".claude")]
    for f in files:
        ext = os.path.splitext(f)[1].lower()
        if ext in (".ps1", ".psm1", ".json", ".xaml", ".bat", ".cmd"):
            scan_files.append(os.path.join(dirpath, f))

# === UMLAUT-PATTERNS (ASCII statt echte Umlaute) ===
umlaut_words = [
    (r"\bpruef",        "pruef -> prüf"),
    (r"\bPruef",        "Pruef -> Prüf"),
    (r"\bfuer\b",       "fuer -> für"),
    (r"\bFuer\b",       "Fuer -> Für"),
    (r"\bueber(?=[a-z])", "ueber -> über"),
    (r"\bUeber(?=[a-z])", "Ueber -> Über"),
    (r"\bzurueck",      "zurueck -> zurück"),
    (r"\bZurueck",      "Zurueck -> Zurück"),
    (r"\bloeschen\b",   "loeschen -> löschen"),
    (r"\bLoeschen\b",   "Loeschen -> Löschen"),
    (r"\bwaehlen\b",    "waehlen -> wählen"),
    (r"\bWaehlen\b",    "Waehlen -> Wählen"),
    (r"\bvollstaendig", "vollstaendig -> vollständig"),
    (r"\bVollstaendig", "Vollstaendig -> Vollständig"),
    (r"\bverfuegbar",   "verfuegbar -> verfügbar"),
    (r"\bungueltig",    "ungueltig -> ungültig"),
    (r"\baeusser",      "aeusser -> äußer"),
    (r"\bAeusser",      "Aeusser -> Äußer"),
    (r"\bbootfaehig",   "bootfaehig -> bootfähig"),
    (r"\bGefaehrlich",  "Gefaehrlich -> Gefährlich"),
    (r"\bgefaehrlich",  "gefaehrlich -> gefährlich"),
    (r"\bausgefuehrt",  "ausgefuehrt -> ausgeführt"),
    (r"\bhoeher",       "hoeher -> höher"),
    (r"\baendern",      "aendern -> ändern"),
    (r"\bveraendert",   "veraendert -> verändert"),
    (r"\boeffentlich",  "oeffentlich -> öffentlich"),
    (r"\boeffnet",      "oeffnet -> öffnet"),
    (r"\bOeffnet",      "Oeffnet -> Öffnet"),
    (r"\bGroesse",      "Groesse -> Größe"),
    (r"\bgroesse",      "groesse -> größe"),
    (r"\bGruen\b",      "Gruen -> Grün"),
    (r"\bgruen\b",      "gruen -> grün"),
    (r"\bkoennen",      "koennen -> können"),
    (r"\bmoechte",      "moechte -> möchte"),
    (r"\bwuerde",       "wuerde -> würde"),
    (r"\bmuessen",      "muessen -> müssen"),
    (r"\bnoetig\b",     "noetig -> nötig"),
    (r"\bueberpruef",   "ueberpruef -> überprüf"),
    (r"\bschuetz",      "schuetz -> schütz"),
    (r"\bnuetzlich",    "nuetzlich -> nützlich"),
    (r"\bNuetzlich",    "Nuetzlich -> Nützlich"),
    (r"\bzuverlaessig", "zuverlaessig -> zuverlässig"),
    (r"\bvoellig",      "voellig -> völlig"),
    (r"\bkuerzel",      "kuerzel -> kürzel"),
    (r"\bzuruecksetzen","zuruecksetzen -> zurücksetzen"),
    (r"\bVeraender",    "Veraender -> Veränder"),
]

# === POWERSHELL / XAML BUGS ===
ps_bugs = [
    (r"New-Object\s+System\.Windows\.Controls\.Ellipse",
     "PS-BUG: Ellipse ueber Controls statt Shapes"),
    (r"LetterSpacing",
     "XAML-BUG: LetterSpacing existiert nicht in WPF"),
    (r"CharacterSpacing",
     "XAML-BUG: CharacterSpacing existiert nicht in WPF"),
    (r"\[System\.Windows\.Thickness\]::new\(\s*\d+\s*,\s*\d+\s*\)",
     "PS-BUG: Thickness mit 2 Parametern (nur 1 oder 4 erlaubt)"),
]

# === WIR-ANREDE ===
wir_words = re.compile(r"\b(wir|unsere?[mnrs]?)\b", re.IGNORECASE)

# === JSON-VALIDIERUNG ===
def check_json(filepath, relpath):
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            json.load(f)
    except json.JSONDecodeError as e:
        errors.append(f"JSON-FEHLER [{relpath}]: {e}")
    except UnicodeDecodeError as e:
        errors.append(f"ENCODING [{relpath}]: {e}")

# === XAML-CHECK ===
def check_xaml(filepath, relpath):
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
        # Basic XML-Balance
        opens = len(re.findall(r"<(?!/)", content))
        closes = len(re.findall(r"</", content))
        self_closing = len(re.findall(r"/>", content))
        # Grobe Prüfung: opens sollte ungefaehr closes + self_closing sein
        diff = abs(opens - closes - self_closing)
        if diff > 5:
            warnings.append(f"XAML [{relpath}]: Tag-Balance auffaellig (Open:{opens} Close:{closes} Self:{self_closing})")
    except Exception as e:
        errors.append(f"XAML [{relpath}]: Lesefehler: {e}")


# === HAUPTPRUEFUNG ===
for filepath in scan_files:
    relpath = os.path.relpath(filepath, ROOT)
    ext = os.path.splitext(filepath)[1].lower()

    # Datei lesen
    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except Exception:
        try:
            with open(filepath, "r", encoding="latin-1") as f:
                lines = f.readlines()
            warnings.append(f"ENCODING [{relpath}]: Nicht UTF-8, Latin-1 Fallback")
        except Exception:
            errors.append(f"LESEN [{relpath}]: Datei kann nicht gelesen werden")
            continue

    stats["files"] += 1
    stats["lines"] += len(lines)

    # JSON validieren
    if ext == ".json":
        check_json(filepath, relpath)

    # XAML pruefen
    if ext == ".xaml":
        check_xaml(filepath, relpath)

    for line_num, line in enumerate(lines, 1):
        # --- Umlaut-Check (nicht in .md) ---
        for pattern, hint in umlaut_words:
            if re.search(pattern, line):
                # Regex in PS1 erlaubt ASCII-Umlaute (fuer Module-Output-Matching)
                if "-match" in line or "-replace" in line or "Regex" in line:
                    warnings.append(f"UMLAUT-REGEX [{relpath}:{line_num}]: {hint} (in Regex-Pattern, evtl. gewollt)")
                else:
                    errors.append(f"UMLAUT [{relpath}:{line_num}]: {hint}")

        # --- PS-Bugs (nur .ps1 und .xaml) ---
        if ext in (".ps1", ".xaml"):
            for pattern, hint in ps_bugs:
                if re.search(pattern, line):
                    if "Read-Host" not in hint:
                        errors.append(f"{hint} [{relpath}:{line_num}]")

        # --- Read-Host in GUI (nicht in Modulen) ---
        if ext == ".ps1" and "modules" not in relpath.lower():
            if re.search(r"\bRead-Host\b", line):
                # Kommentare ignorieren
                stripped = line.lstrip()
                if not stripped.startswith("#"):
                    errors.append(f"READ-HOST [{relpath}:{line_num}]: Read-Host in GUI-Code (blockiert Runspace)")

        # --- Wir-Anrede in GUI-Dateien ---
        if ext in (".ps1", ".json", ".xaml", ".bat") and "modules" not in relpath.lower():
            # Nur in Strings pruefen
            strings = re.findall(r'"([^"]{10,})"', line)
            for s in strings:
                found = wir_words.findall(s)
                if found:
                    # Filter: "Hellion Online Media" ist kein "wir"
                    real_wir = [w for w in found if w.lower() in ("wir", "unser", "unsere", "unseren", "unserem", "unserer", "unseres")]
                    if real_wir:
                        warnings.append(f"WIR-ANREDE [{relpath}:{line_num}]: '{', '.join(real_wir)}' in \"{s[:60]}\"")


# === MODUL-FUNKTIONS-CHECK ===
modules_path = os.path.join(ROOT, "src", "modules")
mj_path = os.path.join(ROOT, "config", "modules.json")

if os.path.exists(modules_path) and os.path.exists(mj_path):
    # Alle Funktionen in Modulen
    module_funcs = set()
    for mf in os.listdir(modules_path):
        if mf.endswith(".ps1"):
            mp = os.path.join(modules_path, mf)
            try:
                with open(mp, "r", encoding="utf-8", errors="replace") as f:
                    mc = f.read()
                funcs = re.findall(r"function\s+([\w-]+)", mc)
                module_funcs.update(funcs)
            except Exception:
                pass

    # modules.json Funktionen pruefen
    try:
        with open(mj_path, "r", encoding="utf-8") as f:
            modules_json = json.load(f)
        for mod in modules_json:
            func = mod.get("Func", "")
            if func and func not in module_funcs:
                warnings.append(f"FUNC-MISMATCH: \"{func}\" (Modul \"{mod.get('Id','?')}\") nicht in /modules/ gefunden (evtl. in GUI definiert)")
    except Exception:
        pass


# === SOFTWARE-KATALOG SPEZIAL-CHECK ===
sc_path = os.path.join(ROOT, "config", "software-catalog.json")
if os.path.exists(sc_path):
    try:
        with open(sc_path, "r", encoding="utf-8") as f:
            catalog = json.load(f)
        pkg_ids = []
        for cat in catalog.get("categories", []):
            for pkg in cat.get("packages", []):
                pkg_ids.append(pkg.get("id", ""))
                if not pkg.get("desc"):
                    errors.append(f"KATALOG: {pkg.get('name','?')} hat keine Beschreibung")
                if len(pkg.get("desc", "")) < 20:
                    warnings.append(f"KATALOG: {pkg.get('name','?')} Beschreibung sehr kurz")
        # Duplikate
        dupes = set(x for x in pkg_ids if pkg_ids.count(x) > 1)
        if dupes:
            errors.append(f"KATALOG-DUPLIKAT: {dupes}")
    except Exception:
        pass


# === AUSGABE ===
print("=" * 60)
print("  HELLION POWER TOOL — PROJEKT-AUDIT")
print("=" * 60)
print()
print(f"  Dateien geprueft:  {stats['files']}")
print(f"  Zeilen geprueft:   {stats['lines']:,}")
print(f"  Fehler:            {len(errors)}")
print(f"  Hinweise:          {len(warnings)}")
print()

# Dateien auflisten
print("  Gepruefte Dateien:")
for fp in sorted(scan_files):
    rp = os.path.relpath(fp, ROOT)
    print(f"    {rp}")
print()

if errors:
    print(f"  {'='*50}")
    print(f"  FEHLER ({len(errors)})")
    print(f"  {'='*50}")
    by_type = {}
    for e in errors:
        typ = e.split("[")[0].strip().rstrip(":")
        if typ not in by_type:
            by_type[typ] = []
        by_type[typ].append(e)
    for typ, items in sorted(by_type.items()):
        print(f"\n  --- {typ} ({len(items)}) ---")
        for e in items[:20]:
            print(f"    [X] {e}")
        if len(items) > 20:
            print(f"    ... und {len(items)-20} weitere")
    print()

if warnings:
    print(f"  {'='*50}")
    print(f"  HINWEISE ({len(warnings)})")
    print(f"  {'='*50}")
    by_type = {}
    for w in warnings:
        typ = w.split("[")[0].strip().rstrip(":")
        if typ not in by_type:
            by_type[typ] = []
        by_type[typ].append(w)
    for typ, items in sorted(by_type.items()):
        print(f"\n  --- {typ} ({len(items)}) ---")
        for w in items[:20]:
            print(f"    [!] {w}")
        if len(items) > 20:
            print(f"    ... und {len(items)-20} weitere")
    print()

if not errors and not warnings:
    print("  ERGEBNIS: Alles sauber! Keine Fehler, keine Hinweise.")
elif not errors:
    print(f"  ERGEBNIS: Keine Fehler. {len(warnings)} Hinweis(e).")
else:
    print(f"  ERGEBNIS: {len(errors)} Fehler, {len(warnings)} Hinweis(e).")

print()
print("=" * 60)
