# CDE AL Workspace — Business Central 28

## Projekt-Kontext
- App-Prefix: CDE
- BC-Version: 28 (Runtime 14.0)
- Object-ID-Range: 50000–50999
- Deployment: AppSource + Per-Tenant
- Projektstruktur: Pro Feature ein eigener Ordner
- Sprache: Captions und ToolTips in Englisch, Übersetzung via XLIFF
- app.json Feature: "TranslationFile" muss aktiv sein

## Ordnerstruktur
```
Workspace/
├── CLAUDE.md
├── .claude/agents/          ← Die 5 Agents (Details dort)
├── SourceAgent1/            ← Business-Logik PDFs für Agent 1
│   ├── voll/                ← Original-Dokumente
│   └── zusammenfassung/     ← Kurz-Zusammenfassungen
└── Features/
    └── FeatureName/
        ├── src/
        │   ├── Table/
        │   ├── TableExtension/
        │   ├── Page/
        │   ├── PageExtension/
        │   ├── Codeunit/
        │   ├── Enum/
        │   ├── EnumExtension/
        │   ├── Report/
        │   ├── XMLport/
        │   └── PermissionSet/
        └── README.md
```

## Die 5-Agenten-Pipeline

Agent 1 → 2 → 3 → 4 + 5 → Fertig

| Agent | Name | Aufgabe | Schreibt Code? |
|-------|------|---------|----------------|
| 1 | business-knowledge | Liest PDFs, versteht Anforderung, fragt nach, erstellt fachliche Spezifikation | Nein |
| 2 | dev-preparation | Fragt nach ID Range, erstellt technischen Plan, gibt Prüfpunkte an 4+5 | Nein |
| 3 | al-engineer | Schreibt AL-Code nach Plan von Agent 2 | Ja |
| 4 | guidelines-reviewer | Prüft Form: Patterns, Guidelines, Lesbarkeit, AppSource | Nein |
| 5 | logic-tester | Prüft Inhalt: Logik, Datenschutz, Sinnhaftigkeit, Praxis-Szenarien | Nein |

Agent 4 und 5 prüfen unterschiedliche Dinge und können parallel laufen.
Bei NEEDS CHANGES von 4 oder 5 → Agent 3 korrigiert.

## Coding-Regeln

Die vollständigen Regeln stehen in den jeweiligen Agent-Dateien.
Hier nur die wichtigsten als Kurzreferenz:

- Prefix "CDE" überall
- Labels mit Comment, keine hardcoded Strings
- DataClassification auf jedem Feld (nie ToBeClassified)
- ApplicationArea + ToolTip auf jedem Page-Feld
- PermissionSet pro Feature, nie SUPER benötigen
- Event Subscribers statt direkte Modifikation
- Bestehende Objekte nie löschen → ObsoleteState = Pending
- Kein WITH, kein CaptionML
- Captions in Englisch, Übersetzung via XLIFF
