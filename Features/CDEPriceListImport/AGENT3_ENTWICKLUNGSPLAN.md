# Entwicklungsplan Agent 3 — CDEPriceListImport
## JSON-Import Debitorenverkaufspreisliste
**Erstellt von:** Agent 2 (dev-preparation)
**Datum:** 2026-03-20
**Ziel-Agent:** Agent 3 (al-engineer)
**Review-Agents:** Agent 4 (guidelines-reviewer), Agent 5 (logic-tester)

---

## 0. Scan-Ergebnis ID-Range 60100–60200

**Ergebnis: ALLE IDs frei. Keine Konflikte.**

Es wurden keine .al-Dateien im Projekt gefunden. Der gesamte Range 60100–60200 ist unbelegt und steht vollständig zur Verfügung.

---

## 1. Projekt-Rahmenbedingungen

### app.json-Fakten (verbindlich)
- **Runtime:** 16.0
- **Platform/Application:** 27.0.0.0
- **ID-Range:** 60000–60999 (in app.json definiert)
- **Features:** `NoImplicitWith`, `TranslationFile`
- **Publisher:** Cemil Demirezen

### Wording-Konflikt aufgelöst
CLAUDE.md schreibt Captions in Englisch + XLIFF-Übersetzung.
Die Spezifikation fordert Deutsch als Primärsprache ("User soll BC-Standard-Feeling haben").

**Entscheidung für Agent 3:**
- `Caption`-Attribute immer in **Englisch** schreiben (CLAUDE.md-Pflicht, AppSource-Pflicht)
- Deutsche Übersetzung via XLIFF-Datei `Features/CDEPriceListImport/Translations/CDEPriceListImport.de-DE.xlf`
- `Comment`-Attribut auf Labels für Übersetzer-Kontext: `Comment = 'CDE Price List Import'`
- **ToolTip** immer in Englisch, Übersetzung via XLIFF

---

## 2. Ordnerstruktur (Agent 3 muss exakt so anlegen)

```
Features/
└── CDEPriceListImport/
    ├── src/
    │   ├── Interface/
    │   │   ├── ICDEImportOrchestrator.Interface.al
    │   │   ├── ICDEJsonPriceImporter.Interface.al
    │   │   ├── ICDEPriceListValidator.Interface.al
    │   │   ├── ICDEPriceListWriter.Interface.al
    │   │   ├── ICDECompanySelector.Interface.al
    │   │   └── ICDEImportLogger.Interface.al
    │   ├── Codeunit/
    │   │   ├── CDEImportOrchestrator.Codeunit.al     (60100)
    │   │   ├── CDEJsonPriceImporter.Codeunit.al      (60101)
    │   │   ├── CDEPriceListValidator.Codeunit.al     (60102)
    │   │   ├── CDEPriceListWriter.Codeunit.al        (60103)
    │   │   ├── CDECompanySelector.Codeunit.al        (60104)
    │   │   └── CDEImportLogger.Codeunit.al           (60105)
    │   ├── Table/
    │   │   ├── CDEPriceImportLog.Table.al            (60100)
    │   │   ├── CDEPriceHeaderBuffer.Table.al         (60106, temporary)
    │   │   └── CDEPriceLineBuffer.Table.al           (60107, temporary)
    │   ├── Page/
    │   │   ├── CDEPriceListJsonImport.Page.al        (60101)
    │   │   ├── CDEPriceImportLogList.Page.al         (60102)
    │   │   └── CDECompanySelectorPage.Page.al        (60108, modal)
    │   ├── PageExtension/
    │   │   └── CDESalesPriceListsExt.PageExt.al      (60103)
    │   └── PermissionSet/
    │       └── CDEPriceListImport.PermissionSet.al   (60100)
    └── Translations/
        └── CDEPriceListImport.de-DE.xlf              (XLIFF, nach Code-Fertigstellung)
```

**Hinweis zu Buffer-Tabellen:** CDEPriceHeaderBuffer (60106) und CDEPriceLineBuffer (60107) sind in der ursprünglichen ID-Tabelle nicht aufgeführt, da sie als technische Implementierungsdetails im Interface-Vertrag als `Record ... temporary` referenziert werden. Sie belegen IDs aus dem reservierten Bereich. IDs 60110–60200 bleiben weiterhin für spätere Erweiterungen frei.

---

## 3. Build-Reihenfolge (ZWINGEND einhalten)

AL-Compiler-Abhängigkeiten erzwingen diese Reihenfolge. Jede Schicht darf nur Typen aus tieferen Schichten referenzieren.

```
SCHICHT 1 — Buffer-Tabellen (keine Abhängigkeiten)
  └── CDEPriceHeaderBuffer.Table.al    (60106)
  └── CDEPriceLineBuffer.Table.al      (60107)

SCHICHT 2 — Log-Tabelle (keine Abhängigkeiten)
  └── CDEPriceImportLog.Table.al       (60100)

SCHICHT 3 — Interfaces (referenzieren Buffer-Tabellen aus Schicht 1)
  └── ICDEJsonPriceImporter.Interface.al
  └── ICDEPriceListValidator.Interface.al
  └── ICDEPriceListWriter.Interface.al
  └── ICDECompanySelector.Interface.al
  └── ICDEImportLogger.Interface.al
  └── ICDEImportOrchestrator.Interface.al   (referenziert alle anderen Interfaces)

SCHICHT 4 — Codeunit-Implementierungen (implementieren Interfaces aus Schicht 3)
  └── CDEJsonPriceImporter.Codeunit.al     (60101)
  └── CDEPriceListValidator.Codeunit.al    (60102)
  └── CDEPriceListWriter.Codeunit.al       (60103)
  └── CDECompanySelector.Codeunit.al       (60104)
  └── CDEImportLogger.Codeunit.al          (60105)
  └── CDEImportOrchestrator.Codeunit.al    (60100)  ← zuletzt, kennt alle anderen

SCHICHT 5 — Pages (referenzieren Codeunits + Buffer-Tabellen)
  └── CDEPriceImportLogList.Page.al        (60102)  ← nur Log-Tabelle, keine Codeunit-Dep.
  └── CDECompanySelectorPage.Page.al       (60108)  ← Company-Tabelle + CompanySelector
  └── CDEPriceListJsonImport.Page.al       (60101)  ← Haupt-Page, alle Dependencies

SCHICHT 6 — PageExtension
  └── CDESalesPriceListsExt.PageExt.al     (60103)  ← öffnet Page 60101

SCHICHT 7 — PermissionSet (referenziert alle Objekte)
  └── CDEPriceListImport.PermissionSet.al  (60100)
```

---

## 4. Objekt-Spezifikationen

### 4.1 CDEPriceHeaderBuffer (Table 60106) — TEMPORÄR

**Zweck:** In-Memory-Puffer für geparste JSON-Kopfdaten. Niemals persistent.

```al
table 60106 "CDE Price Header Buffer"
{
    Caption = 'CDE Price Header Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;
```

**Felder:**
| Feldname | Typ | Hinweis |
|----------|-----|---------|
| Code | Code[20] | PK, aus JSON Header.Code |
| Description | Text[100] | aus JSON Header.Description |
| Source Type | Enum "Price Source Type" | aus JSON |
| Source No. | Code[20] | aus JSON |
| Starting Date | Date | aus JSON |
| Ending Date | Date | aus JSON, optional |
| Currency Code | Code[10] | IMMER leer lassen (Mandantenwährung) |

**Akzeptanzkriterium:**
- `TableType = Temporary` gesetzt
- Kein `DataPerCompany`, kein `LookupPageId`, kein `DrillDownPageId`
- Alle Felder haben `DataClassification`
- `ObsoleteState` nicht gesetzt (neue Tabelle)

---

### 4.2 CDEPriceLineBuffer (Table 60107) — TEMPORÄR

**Zweck:** In-Memory-Puffer für geparste JSON-Zeilen inkl. Validierungsstatus.

```al
table 60107 "CDE Price Line Buffer"
{
    Caption = 'CDE Price Line Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;
```

**Felder:**
| Feldname | Typ | Hinweis |
|----------|-----|---------|
| Entry No. | Integer | PK (laufende Nummer beim Parsen, 1,2,3...) |
| Price List Code | Code[20] | aus JSON |
| Asset No. | Code[20] | Artikel-Nr., Pflichtfeld |
| Variant Code | Code[10] | optional |
| Starting Date | Date | aus JSON |
| Ending Date | Date | optional |
| Unit Price | Decimal | Pflichtfeld |
| Minimum Quantity | Decimal | optional |
| Unit of Measure Code | Code[10] | optional |
| Validation Status | Option | Options: ' ',Error,Warning |
| Error Message | Text[500] | Fehlermeldungstext |
| Skip Import | Boolean | User-Checkbox "Trotzdem importieren" |

**Wichtig für Validation Status Option-Reihenfolge:**
`OptionMembers = ' ',Error,Warning` — Leerzeichen als "OK" (erster Wert = Initialwert)

**Akzeptanzkriterium:**
- `TableType = Temporary` gesetzt
- `Skip Import` Boolean für User-Override in Vorschau-Page
- `Validation Status` als Option-Typ (nicht Enum, kein separates Objekt nötig)

---

### 4.3 CDEPriceImportLog (Table 60100) — PERSISTENT

**Zweck:** Permanentes Protokoll aller Import-Vorgänge.

**Felder:**
| Nr. | Feldname | Typ | DataClassification | Hinweis |
|-----|----------|-----|-------------------|---------|
| 1 | Entry No. | Integer | SystemMetadata | PK, AutoIncrement |
| 2 | Timestamp | DateTime | SystemMetadata | CREATEDATETIME beim Insert |
| 3 | User ID | Code[50] | EndUserIdentifiableInformation | UserId() |
| 4 | Company Name | Text[30] | OrganizationIdentifiableInformation | |
| 5 | Price List Code | Code[20] | OrganizationIdentifiableInformation | neu angelegte Liste |
| 6 | Source Price List Code | Code[20] | OrganizationIdentifiableInformation | Ursprungsliste bei Änderung |
| 7 | Lines Imported | Integer | SystemMetadata | |
| 8 | Lines Skipped | Integer | SystemMetadata | |
| 9 | Status | Option | SystemMetadata | `OptionMembers = Successful,Partial,Error` |
| 10 | Error Location | Text[250] | SystemMetadata | |
| 11 | Error Message | Text[500] | SystemMetadata | |

**Schlüssel:** `Entry No.` (PK, AutoIncrement = true)

**Kein AutoDelete, keine Retention Policy** — fortlaufend unbegrenzt.

**Akzeptanzkriterium:**
- AutoIncrement auf Entry No.
- User ID hat `DataClassification = EndUserIdentifiableInformation`
- Company Name hat `DataClassification = OrganizationIdentifiableInformation`
- Kein `TableType = Temporary`
- LookupPageId = Page 60102

---

### 4.4 ICDEJsonPriceImporter (Interface)

```al
interface "ICDEJsonPriceImporter"
{
    procedure ParseJson(
        JsonStream: InStream;
        var HeaderBuffer: Record "CDE Price Header Buffer" temporary;
        var LineBuffer: Record "CDE Price Line Buffer" temporary): Boolean;

    procedure GetLastError(): Text;
}
```

**Akzeptanzkriterium:**
- Keine Implementierung, nur Signatur
- Parameter-Typen stimmen mit Buffer-Tabellen-Namen exakt überein
- `temporary` Keyword auf var-Record-Parametern gesetzt (BC 28 Pflicht)

---

### 4.5 ICDEPriceListValidator (Interface)

```al
interface "ICDEPriceListValidator"
{
    procedure Validate(
        var LineBuffer: Record "CDE Price Line Buffer" temporary;
        CompanyName: Text): Boolean;

    procedure GetErrorCount(): Integer;
    procedure GetWarningCount(): Integer;
}
```

---

### 4.6 ICDEPriceListWriter (Interface)

```al
interface "ICDEPriceListWriter"
{
    procedure CreatePriceListHeader(
        var HeaderBuffer: Record "CDE Price Header Buffer" temporary;
        NoSeriesCode: Code[20]): Code[20];

    procedure InsertPriceLine(
        PriceListCode: Code[20];
        var LineBuffer: Record "CDE Price Line Buffer" temporary): Boolean;
}
```

---

### 4.7 ICDECompanySelector (Interface)

```al
interface "ICDECompanySelector"
{
    procedure GetSelectedCompanies(): List of [Text];
    procedure ShowSelectorPage();
}
```

---

### 4.8 ICDEImportLogger (Interface)

```al
interface "ICDEImportLogger"
{
    procedure LogSuccess(
        CompanyName: Text;
        PriceListCode: Code[20];
        LinesImported: Integer;
        LinesSkipped: Integer);

    procedure LogError(
        CompanyName: Text;
        PriceListCode: Code[20];
        ErrorLocation: Text;
        ErrorMessage: Text);
}
```

---

### 4.9 ICDEImportOrchestrator (Interface)

**Hinweis:** Der Interface-Vertrag referenziert `Record CDEImportParams temporary`. Diese temporäre Tabelle muss ebenfalls erstellt werden (ID 60109) oder als separate Record-Struktur gelöst werden.

**Empfehlung für Agent 3 — CDEImportParams als temporäre Tabelle (60109):**

```al
table 60109 "CDE Import Params"
{
    Caption = 'CDE Import Params';
    TableType = Temporary;
    DataClassification = SystemMetadata;
    // Felder:
    // Primary Key: Entry No. Integer
    // Mode: Option (NewList, ModifyExisting)
    // No. Series Code: Code[20]
    // Existing Price List Code: Code[20]
    // Source Type: Enum "Price Source Type"
    // Source No.: Code[20]
    // Starting Date: Date
    // Ending Date: Date
    // Description: Text[100]
    // All Companies: Boolean
}
```

```al
interface "ICDEImportOrchestrator"
{
    procedure Run(var ImportParams: Record "CDE Import Params" temporary): Boolean;
}
```

---

### 4.10 CDEJsonPriceImporter (Codeunit 60101)

**Implementiert:** `ICDEJsonPriceImporter`

**Kernlogik ParseJson:**
```
1. JsonObject.ReadFrom(JsonStream)
2. Header-Objekt lesen → HeaderBuffer füllen (ein Datensatz)
   - Pflichtfelder prüfen: Code, Description, Source Type, Starting Date
   - Bei fehlendem Pflichtfeld → LastError setzen → return FALSE
3. Lines-Array iterieren → pro Element einen LineBuffer-Datensatz INSERT
   - Entry No. = laufende Nummer (1,2,3...)
   - Fehlende Pflichtfelder in Line → LineBuffer.ValidationStatus = Error
   - Currency Code IMMER ignorieren (auch wenn in JSON vorhanden)
4. Return TRUE wenn Header vollständig, auch wenn Lines Fehler haben
```

**JSON-Erwartungsstruktur:**
```json
{
  "header": {
    "code": "PL-2024-001",
    "description": "Preisliste 2024",
    "sourceType": "Customer",
    "sourceNo": "C001",
    "startingDate": "2024-01-01"
  },
  "lines": [
    {
      "assetNo": "1000",
      "variantCode": "",
      "startingDate": "2024-01-01",
      "endingDate": "2024-12-31",
      "unitPrice": 99.50,
      "minimumQuantity": 0,
      "unitOfMeasureCode": "STK"
    }
  ]
}
```

**Datums-Parsing:** `Evaluate(DateVar, JsonValue)` — BC parst ISO 8601 (YYYY-MM-DD) nativ.

**Akzeptanzkriterium:**
- `implements ICDEJsonPriceImporter` in Codeunit-Header
- Kein direktes Schreiben in Tabelle 7002/7003
- Nur Buffer-Tabellen beschreiben
- LastError-Variable als globale Codeunit-Variable (Text)
- Currency Code aus JSON explizit ignorieren (Kommentar im Code)

---

### 4.11 CDEPriceListValidator (Codeunit 60102)

**Implementiert:** `ICDEPriceListValidator`

**Validierungslogik (Reihenfolge pro Zeile):**

```
1. Pflichtfelder (Asset No., Starting Date, Unit Price > 0)
   → Fehler wenn nicht gesetzt

2. Artikel-Existenz-Check
   IF NOT Item.Get(LineBuffer."Asset No.") THEN
   → ValidationStatus = Error, ErrorMessage = 'Item X does not exist'

3. Varianten-Check
   IF LineBuffer."Variant Code" <> '' THEN
     IF NOT ItemVariant.Get(LineBuffer."Asset No.", LineBuffer."Variant Code") THEN
     → ValidationStatus = Error

4. Datums-Logik
   IF (LineBuffer."Ending Date" <> 0D) AND
      (LineBuffer."Ending Date" <= LineBuffer."Starting Date") THEN
   → ValidationStatus = Error, ErrorMessage = 'Ending Date must be after Starting Date'

5. Enddatum leer → Warnung (nicht Fehler)
   IF LineBuffer."Ending Date" = 0D THEN
   → ValidationStatus = Warning (nur wenn noch kein Error)

6. Datums-Konflikt-Query (nur wenn kein Fehler aus 1-4)
   PriceListLine.SETRANGE("Asset Type", "Price Asset Type"::Item)
   PriceListLine.SETRANGE("Asset No.", LineBuffer."Asset No.")
   PriceListLine.SETRANGE("Variant Code", LineBuffer."Variant Code")
   // dann über PriceListHeader JOIN Status = Active prüfen
   // Datumsüberlappung gemäß Spezifikation
   → ValidationStatus = Error, ErrorMessage = 'Date conflict with active price line'

7. Duplikat-Check innerhalb JSON (Asset No. + Variant Code + Starting Date + Ending Date)
   → ValidationStatus = Error, ErrorMessage = 'Duplicate key in JSON'
```

**ChangeCompany für Validator:**
Validator wird mit `CompanyName: Text` aufgerufen. Für cross-company Zugriff auf Tabelle 27 und 7003:
```al
Item.ChangeCompany(CompanyName);
PriceListLine.ChangeCompany(CompanyName);
```

**Akzeptanzkriterium:**
- GetErrorCount() zählt Records mit `ValidationStatus = Error`
- GetWarningCount() zählt Records mit `ValidationStatus = Warning`
- ValidationStatus wird NUR gesetzt, wenn noch kein Error vorhanden (Warnings nicht Error überschreiben)
- Duplikat-Detection über temporäres Dictionary / vorheriges Durchlaufen der Buffer-Tabelle

---

### 4.12 CDEPriceListWriter (Codeunit 60103)

**Implementiert:** `ICDEPriceListWriter`

**DATENSCHUTZREGELN (ABSOLUT — Agent 3 muss diese als Kommentare im Code vermerken):**
```
// SECURITY: NEVER DELETE from "Price List Header" (Table 7002)
// SECURITY: NEVER DELETE from "Price List Line" (Table 7003)
// SECURITY: NEVER MODIFY "Price List Line" where Status = Active
// SECURITY: New Price List Header Status ALWAYS = Draft (0)
```

**CreatePriceListHeader:**
```
1. NoSeries.GetNextNo(NoSeriesCode, WorkDate(), true) → neuen Code holen
   ODER bei "Bestehende ändern": neuen Header anlegen,
   Description enthält "Ref: [OriginalCode]"
2. PriceListHeader.INIT
3. PriceListHeader.Code := generierter Code
4. PriceListHeader.Status := "Price Status"::Draft  // NIEMALS Active
5. Felder aus HeaderBuffer übertragen
6. PriceListHeader."Price Type" := "Price Type"::Sale  // IMMER Sale
7. PriceListHeader.INSERT(true)
8. RETURN PriceListHeader.Code
```

**InsertPriceLine:**
```
1. IF LineBuffer."Validation Status" = Error THEN
     IF NOT LineBuffer."Skip Import" THEN EXIT(false)
2. PriceListLine.INIT
3. Alle Felder aus LineBuffer übertragen
4. PriceListLine."Price List Code" := PriceListCode
5. PriceListLine."Line No." := GetNextLineNo(PriceListCode)
6. PriceListLine."Price Type" := "Price Type"::Sale
7. PriceListLine."Asset Type" := "Price Asset Type"::Item
8. PriceListLine.INSERT(true)
9. RETURN true
```

**GetNextLineNo:** Letzte Line No. für den Code aus Tabelle 7003 abfragen + 10000.

**Akzeptanzkriterium:**
- Kein MODIFY auf Tabelle 7003 irgendwo
- Kein DELETE auf Tabelle 7002 oder 7003 irgendwo
- Status bei CreatePriceListHeader immer `"Price Status"::Draft`
- NoSeries-Nutzung via `NoSeriesManagement` Codeunit (Standard-BC-Pattern)

---

### 4.13 CDECompanySelector (Codeunit 60104)

**Implementiert:** `ICDECompanySelector`

**Interne State-Variable:**
```al
var
    SelectedCompanies: List of [Text];
```

**GetSelectedCompanies:**
Gibt `SelectedCompanies` zurück.

**ShowSelectorPage:**
```al
Page.RunModal(60108, ...);
// Nach Close: SelectedCompanies aus Page-Variable übernehmen
```

**Priorisierungslogik (wird von Page 60101 gesteuert, nicht von dieser Codeunit).**

**Akzeptanzkriterium:**
- `List of [Text]` korrekt deklariert (BC 28 Runtime 16.0 unterstützt das vollständig)
- ShowSelectorPage öffnet Page 60108 modal
- Codeunit hat globale Variable `SelectedCompanies`

---

### 4.14 CDEImportLogger (Codeunit 60105)

**Implementiert:** `ICDEImportLogger`

**LogSuccess:**
```al
CDEPriceImportLog.Init();
CDEPriceImportLog."Timestamp" := CurrentDateTime();
CDEPriceImportLog."User ID" := CopyStr(UserId(), 1, 50);
CDEPriceImportLog."Company Name" := CopyStr(CompanyName, 1, 30);
CDEPriceImportLog."Price List Code" := PriceListCode;
CDEPriceImportLog."Lines Imported" := LinesImported;
CDEPriceImportLog."Lines Skipped" := LinesSkipped;
CDEPriceImportLog."Status" := CDEPriceImportLog."Status"::Successful;
CDEPriceImportLog.Insert(true);
```

**LogError:**
Wie LogSuccess, aber `Status := Error`, `Error Location` und `Error Message` befüllen.

**Fehlermeldungs-Format (verbindlich):**
`'Company: [Name] | Price List: [Code] | Line [N] | Item: [X] | Error: [Text]'`

**Akzeptanzkriterium:**
- Insert(true) — Trigger laufen lassen
- UserId() mit CopyStr auf Code[50] kürzen
- CurrentDateTime() für Timestamp (nicht Now())

---

### 4.15 CDEImportOrchestrator (Codeunit 60100)

**Implementiert:** `ICDEImportOrchestrator`

**Vollständiger Run-Ablauf:**

```al
procedure Run(var ImportParams: Record "CDE Import Params" temporary): Boolean
var
    CompanyList: List of [Text];
    CompanyName: Text;
    PriceListCode: Code[20];
    LinesImported: Integer;
    LinesSkipped: Integer;
    LineBuffer: Record "CDE Price Line Buffer" temporary;
    HeaderBuffer: Record "CDE Price Header Buffer" temporary;
begin
    CompanyList := CompanySelector.GetSelectedCompanies();

    foreach CompanyName in CompanyList do begin
        // ChangeCompany-Kontext
        LinesImported := 0;
        LinesSkipped := 0;

        // BEGIN TRANSACTION (implizit durch Commit am Ende)
        if not TryProcessCompany(
            CompanyName, ImportParams, HeaderBuffer, LineBuffer,
            PriceListCode, LinesImported, LinesSkipped)
        then begin
            Logger.LogError(CompanyName, PriceListCode,
                GetLastErrorText(), GetLastErrorCallStack());
            exit(false);  // STOP — keine weiteren Mandanten
        end;

        Logger.LogSuccess(CompanyName, PriceListCode,
            LinesImported, LinesSkipped);
        Commit();
    end;
    exit(true);
end;
```

**TryProcessCompany als `[TryFunction]`:**
```al
[TryFunction]
local procedure TryProcessCompany(...): Boolean
```
Damit wird bei Fehler automatisch ROLLBACK ausgelöst (BC-Pattern für Try-Functions).

**Akzeptanzkriterium:**
- `[TryFunction]` für Company-Verarbeitung (garantiert Rollback bei Fehler)
- Nach Fehler: STOP (kein Weitermachen mit anderen Mandanten)
- Commit() nur bei Erfolg
- Interface-Variablen deklariert (nicht direkte Codeunit-Typen)

---

### 4.16 CDEPriceListJsonImport (Page 60101)

**PageType:** Card
**SourceTable:** `CDE Import Params` (temporary, Record 60109)
**Caption:** `'JSON Price List Import'`

**Layout-Struktur:**

```
group(CompanySelection)        Caption = 'Company Selection'
  field(CurrentCompany)         ReadOnly, source: CompanyName()
  field(AllCompanies)           Boolean var auf Page
  action(SelectCompanies)       → CompanySelector.ShowSelectorPage()

group(ImportMode)               Caption = 'Import Mode'
  field(ImportMode)             Option: NewList | ModifyExisting
  field(NoSeriesCode)           Visible = ImportMode = NewList, Lookup → Table 308
  field(ExistingPriceListCode)  Visible = ImportMode = ModifyExisting,
                                Lookup → Table 7002 (Filter: Price Type = Sale)

group(HeaderData)               Caption = 'Header Data'
  field(SourceType)             Enum "Price Source Type"
  field(SourceNo)               Code[20]
  field(StartingDate)           Date
  field(EndingDate)             Date
  field(Description)            Text[100]

part(PreviewLines, CDEPriceLineBufferSubPage)   ← SubPage zeigt LineBuffer
  Visible = JsonLoaded

part(ImportLog, CDEPriceImportLogList)          ← FactBox oder SubPage
  SubPageView = ...

actions:
  action(LoadJson)    → ICDEJsonPriceImporter.ParseJson()
  action(RunValidation) → ICDEPriceListValidator.Validate()
  action(Import)      Enabled = JsonLoaded, → ICDEImportOrchestrator.Run()
```

**Page-Variablen:**
```al
var
    JsonLoaded: Boolean;
    AllCompanies: Boolean;
    ImportModeOption: Option NewList,ModifyExisting;
    CompanySelector: Codeunit "CDE Company Selector";
    Orchestrator: Codeunit "CDE Import Orchestrator";
    JsonImporter: Codeunit "CDE JSON Price Importer";
    Validator: Codeunit "CDE Price List Validator";
    HeaderBuffer: Record "CDE Price Header Buffer" temporary;
    LineBuffer: Record "CDE Price Line Buffer" temporary;
```

**Hinweis zu NoImplicitWith:** Da `NoImplicitWith` in Features aktiv ist, darf KEIN `WITH`-Statement verwendet werden. Alle Felder über vollqualifizierte Record-Referenz ansprechen.

**Akzeptanzkriterium:**
- Import-Aktion nur aktiv wenn `JsonLoaded = true`
- NoSeriesCode-Feld nur sichtbar bei NewList
- ExistingPriceListCode-Feld nur sichtbar bei ModifyExisting
- Vorschau-SubPage zeigt LineBuffer-Datensätze
- Mandanten-Priorisierungslogik korrekt implementiert (Selected > AllCompanies > Current)

---

### 4.17 CDEPriceImportLogList (Page 60102)

**PageType:** List
**SourceTable:** `CDE Price Import Log` (60100)
**Editable:** false
**Caption:** `'CDE Price Import Log'`

**Spalten:** Entry No., Timestamp, User ID, Company Name, Price List Code, Lines Imported, Lines Skipped, Status, Error Message

**Akzeptanzkriterium:**
- Nur lesend (Editable = false)
- Kann als FactBox in Page 60101 eingebunden werden
- Kein DeleteAllowed, kein InsertAllowed, kein ModifyAllowed

---

### 4.18 CDECompanySelectorPage (Page 60108)

**PageType:** List (modal)
**SourceTable:** `Company` (2000000006)
**RunModal:** true
**Caption:** `'Select Companies'`

**Felder:**
- `Name` (ReadOnly aus Tabelle Company)
- `Selected` (Boolean — Page-Variable, nicht Tabellen-Feld!)

**Pattern für Checkbox-Auswahl ohne Tabellen-Modifikation:**
```al
// Temporäre Hilfstabelle oder Dictionary-Ansatz
// Empfehlung: eigene temporäre Tabelle CDECompanySelectionBuffer (60110)
// mit Feldern: Company Name (PK), Selected (Boolean)
// Diese Tabelle füllen beim Öffnen aus Tabelle 2000000006
```

**Akzeptanzkriterium:**
- Tabelle 2000000006 (Company) wird NICHT modifiziert
- Auswahl über temporäre Buffer-Tabelle
- Bei OK → SelectedCompanies-Liste in CDECompanySelector befüllen

---

### 4.19 CDESalesPriceListsExt (PageExtension 60103)

**Extends:** `"Sales Price Lists"` (Page 7022)

```al
pageextension 60103 "CDE Sales Price Lists Ext" extends "Sales Price Lists"
{
    actions
    {
        addlast(processing)
        {
            action(CDEImportFromJson)
            {
                Caption = 'Import Prices from JSON';
                ToolTip = 'Opens the JSON price list import page to import prices from a JSON file.';
                ApplicationArea = All;
                Image = Import;
                RunObject = Page "CDE Price List JSON Import";
            }
        }
    }
}
```

**Akzeptanzkriterium:**
- `addlast(processing)` — Aktion am Ende der Processing-Gruppe
- `RunObject` statt Code in OnAction (einfacher, keine Codeunit-Dep.)
- ApplicationArea = All

---

### 4.20 CDEPriceListImport (PermissionSet 60100)

```al
permissionset 60100 "CDE Price List Import"
{
    Caption = 'CDE Price List Import';
    Assignable = true;
    Permissions =
        tabledata "Price List Header" = RIM,       // 7002
        tabledata "Price List Line" = RIM,         // 7003
        tabledata Item = R,                        // 27
        tabledata "Item Variant" = R,              // 5401
        tabledata "No. Series" = R,                // 308
        tabledata "No. Series Line" = RM,          // 309
        tabledata Company = R,                     // 2000000006
        tabledata "CDE Price Import Log" = RIMD,   // 60100
        tabledata "CDE Price Header Buffer" = RIMD,// 60106
        tabledata "CDE Price Line Buffer" = RIMD,  // 60107
        tabledata "CDE Import Params" = RIMD;      // 60109
}
```

**Akzeptanzkriterium:**
- `Assignable = true`
- Kein `D` auf Tabelle 7002/7003 (kein Delete erlaubt)
- Temporäre Buffer-Tabellen ebenfalls aufgeführt

---

## 5. Technische Hinweise BC 28 / Runtime 16.0

### 5.1 Temporäre Tabellen — Korrekte Implementierung

In BC 28 (Runtime 16.0) gibt es **zwei Arten** von temporären Tabellen:

**Art 1: `TableType = Temporary`** — Objekt ist immer temporär (empfohlen für Buffer)
```al
table 60107 "CDE Price Line Buffer"
{
    TableType = Temporary;
    // Kann NUR als "temporary" Record verwendet werden
    // Kein Datenbank-Eintrag möglich
}
```

**Art 2: Normales Table-Objekt mit `temporary` Keyword auf Variable**
```al
var
    LineBuffer: Record "CDE Price Line Buffer" temporary;
```

Für dieses Projekt: **Art 1 für alle Buffer** (`TableType = Temporary`), da sie konzeptionell immer temporär sind und nie persistent sein dürfen.

### 5.2 Interface-Implementierung in Codeunits

```al
codeunit 60101 "CDE JSON Price Importer" implements "ICDEJsonPriceImporter"
{
    // Alle Interface-Methoden MÜSSEN implementiert werden
    // Signatur muss exakt übereinstimmen
}
```

### 5.3 List of [Text] — Runtime 16.0 Support

`List of [Text]` ist ab Runtime 4.0 unterstützt. Keine Bedenken für Runtime 16.0.

### 5.4 ChangeCompany Pattern

```al
// Korrekt in BC 28:
Item.ChangeCompany(CompanyName);
if Item.Get(AssetNo) then ...

// NICHT empfohlen (Performance):
// Database.ChangeCompany() auf globaler Ebene
```

### 5.5 NoImplicitWith (PFLICHT)

Da `NoImplicitWith` in `app.json` aktiv ist:
```al
// FALSCH:
Rec.Validate("Asset No.", AssetNo);  // in Trigger OK
// aber in Codeunits:
LineBuffer.Validate("Asset No.", LineBuffer."Asset No.");  // immer vollständig

// RICHTIG in Codeunits:
LineBuffer."Asset No." := AssetNo;
```

### 5.6 Enum "Price Source Type" und "Price Status"

Diese Enums sind BC-Standard (App: Base Application):
- `"Price Source Type"::Customer`, `::AllCustomers`, etc.
- `"Price Status"::Draft`, `::Active`
- `"Price Type"::Sale`, `::Purchase`
- `"Price Asset Type"::Item`

Agent 3 muss keine eigenen Enums erstellen.

### 5.7 NoSeries-Nutzung (BC 28 Pattern)

In BC 28 ist `NoSeriesManagement` Codeunit deprecated zugunsten der `NoSeries` Codeunit:
```al
// BC 28 korrekt:
var
    NoSeries: Codeunit "No. Series";
begin
    PriceListCode := NoSeries.GetNextNo(NoSeriesCode, WorkDate(), true);
end;
```

### 5.8 JSON-Parsing in AL

```al
var
    JObject: JsonObject;
    JToken: JsonToken;
    JArray: JsonArray;
begin
    if not JObject.ReadFrom(JsonStream) then
        exit(false);

    // Wert lesen:
    if JObject.Get('code', JToken) then
        HeaderBuffer.Code := CopyStr(JToken.AsValue().AsText(), 1, 20);

    // Array iterieren:
    if JObject.Get('lines', JToken) then begin
        JArray := JToken.AsArray();
        foreach JToken in JArray do begin
            // JToken.AsObject()...
        end;
    end;
end;
```

### 5.9 TryFunction für Rollback

```al
[TryFunction]
local procedure TryProcessCompany(CompanyName: Text; ...): Boolean
begin
    // Bei Exception → AL Runtime macht automatisch ROLLBACK
    // und gibt false zurück
    Writer.CreatePriceListHeader(...);
    // ...
end;

// Aufruf:
if not TryProcessCompany(CompanyName, ...) then begin
    Logger.LogError(...);
    exit(false);
end;
Commit();  // Nur bei Erfolg
```

### 5.10 TranslationFile Feature — XLIFF-Pflicht

Da `TranslationFile` in Features aktiv ist, generiert AL-Compiler `.g.xlf`-Dateien.
Agent 3 soll nach Code-Fertigstellung die `de-DE.xlf`-Datei im Translations-Ordner anlegen.
Alle `Label`-Definitionen müssen via `Label`-Typ deklariert werden (nicht hardcoded Strings):

```al
var
    DateConflictErr: Label 'Date conflict with active price line (from %1 to %2)', Comment = '%1=Start Date, %2=End Date, CDE Price List Import';
    ItemNotFoundErr: Label 'Item %1 does not exist.', Comment = '%1=Item No., CDE Price List Import';
```

---

## 6. Install-Logik — Bewertung

### Braucht dieses Feature Install-Codeunit?

**Antwort: NEIN — keine Install-Codeunit erforderlich, aber eine Empfehlung:**

**Begründung:**
1. Log-Tabelle (60100) ist leer bei Installation — kein Setup nötig
2. Buffer-Tabellen sind immer temporär — kein Setup nötig
3. Nummernserie wird vom User bei Import-Ausführung ausgewählt (Lookup auf Tabelle 308) — kein Default nötig

**Empfehlung für künftige Erweiterung (IDs reserviert):**
Falls eine Default-Nummernserie automatisch angelegt werden soll, kann das über eine Install-Codeunit erfolgen. Aktuell: nicht nötig.

**PermissionSet muss manuell dem User zugewiesen werden** — das ist Standard-BC-Verhalten, keine Install-Logik.

---

## 7. Vollständige ID-Tabelle (Final)

| Objekt | Typ | ID | Dateiname |
|--------|-----|----|-----------|
| CDE Price Import Log | Table | 60100 | CDEPriceImportLog.Table.al |
| CDE Price Header Buffer | Table | 60106 | CDEPriceHeaderBuffer.Table.al |
| CDE Price Line Buffer | Table | 60107 | CDEPriceLineBuffer.Table.al |
| CDE Import Params | Table | 60109 | CDEImportParams.Table.al |
| CDE Company Selection Buffer | Table | 60110 | CDECompanySelectionBuffer.Table.al |
| CDE Price List JSON Import | Page | 60101 | CDEPriceListJsonImport.Page.al |
| CDE Price Import Log List | Page | 60102 | CDEPriceImportLogList.Page.al |
| CDE Company Selector Page | Page | 60108 | CDECompanySelectorPage.Page.al |
| CDE Sales Price Lists Ext | PageExtension | 60103 | CDESalesPriceListsExt.PageExt.al |
| CDE Import Orchestrator | Codeunit | 60100 | CDEImportOrchestrator.Codeunit.al |
| CDE JSON Price Importer | Codeunit | 60101 | CDEJsonPriceImporter.Codeunit.al |
| CDE Price List Validator | Codeunit | 60102 | CDEPriceListValidator.Codeunit.al |
| CDE Price List Writer | Codeunit | 60103 | CDEPriceListWriter.Codeunit.al |
| CDE Company Selector | Codeunit | 60104 | CDECompanySelector.Codeunit.al |
| CDE Import Logger | Codeunit | 60105 | CDEImportLogger.Codeunit.al |
| ICDEImportOrchestrator | Interface | — | ICDEImportOrchestrator.Interface.al |
| ICDEJsonPriceImporter | Interface | — | ICDEJsonPriceImporter.Interface.al |
| ICDEPriceListValidator | Interface | — | ICDEPriceListValidator.Interface.al |
| ICDEPriceListWriter | Interface | — | ICDEPriceListWriter.Interface.al |
| ICDECompanySelector | Interface | — | ICDECompanySelector.Interface.al |
| ICDEImportLogger | Interface | — | ICDEImportLogger.Interface.al |
| CDE Price List Import | PermissionSet | 60100 | CDEPriceListImport.PermissionSet.al |

**IDs 60111–60200: Reserviert für spätere Erweiterungen.**

---

## 8. Akzeptanzkriterien — Gesamtcheckliste für Agent 3

### Kompilierbarkeit
- [ ] Alle Objekte kompilieren ohne Fehler und Warnings
- [ ] Keine Circular Dependencies
- [ ] Build-Reihenfolge eingehalten (Tables → Interfaces → Codeunits → Pages → PageExt → PermissionSet)

### Code-Qualität (Agent 4 prüft)
- [ ] Prefix "CDE" auf allen Custom-Objekten
- [ ] Alle Labels als `Label`-Variable (kein hardcoded String)
- [ ] Alle `Label`-Variablen haben `Comment = 'CDE ..., %1=...'`
- [ ] `DataClassification` auf JEDEM Feld (nie `ToBeClassified`)
- [ ] `ApplicationArea = All` auf JEDEM Page-Feld und JEDER Page-Aktion
- [ ] `ToolTip` auf JEDEM Page-Feld (in Englisch)
- [ ] Kein `WITH`-Statement (NoImplicitWith aktiv)
- [ ] Kein `CaptionML` (veraltet, XLIFF stattdessen)
- [ ] `ObsoleteState` nicht auf neuen Objekten gesetzt
- [ ] Captions in Englisch (Primärsprache), de-DE via XLIFF

### Datenschutz (Agent 5 prüft)
- [ ] Kein DELETE auf Tabelle 7002 (Price List Header)
- [ ] Kein DELETE auf Tabelle 7003 (Price List Line)
- [ ] Kein MODIFY auf Tabelle 7003
- [ ] Status bei neuen Price List Headers immer `"Price Status"::Draft`
- [ ] Currency Code aus JSON wird ignoriert
- [ ] Kein automatisches Aktivieren von Preislisten

### Logik-Korrektheit (Agent 5 prüft)
- [ ] Mandanten-Priorisierung korrekt: Selected > AllCompanies > CurrentCompany
- [ ] Nach Fehler bei einem Mandant: STOP (keine weiteren Mandanten)
- [ ] Rollback bei Fehler (TryFunction-Pattern)
- [ ] Commit nur bei Erfolg
- [ ] Validator setzt ValidationStatus korrekt (Error > Warning, nicht überschreiben)
- [ ] Skip Import Checkbox wird in InsertPriceLine berücksichtigt
- [ ] Duplikat-Detection innerhalb JSON funktioniert
- [ ] Datums-Konflikt-Query korrekte Überlappungslogik

### Interface-Architektur (Agent 4 und 5 prüfen)
- [ ] Alle Codeunits implementieren ihr Interface (`implements "I..."`)
- [ ] Page 60101 nutzt Interface-Variablen (nicht direkte Codeunit-Typen)
- [ ] Orchestrator kennt nur Interfaces, keine konkreten Codeunit-Typen

---

## 9. Prüfpunkte für Agent 4 (Guidelines Review)

Agent 4 soll folgende Punkte besonders prüfen:

1. **Label-Vollständigkeit:** Jede Fehlermeldung, jede Caption, jede ToolTip als `Label`-Variable?
2. **DataClassification:** Stimmt die Klassifizierung? `User ID`-Feld muss `EndUserIdentifiableInformation` haben.
3. **AppSource-Readiness:** `Assignable = true` im PermissionSet? Kein `SUPER`-Requirement?
4. **Obsolete-Pattern:** Wurden bestehende BC-Objekte nur per Extension erweitert?
5. **NoImplicitWith-Compliance:** Kein WITH-Statement, vollständige Record-Qualifizierung?
6. **Interface-Signatur-Konsistenz:** Stimmen Interface-Methoden-Signaturen exakt mit Implementierungen überein?
7. **Datei-Namens-Konventionen:** `ObjectName.ObjectType.al` (z.B. `CDEPriceImportLog.Table.al`)?
8. **Keine leeren Trigger:** OnInsert, OnModify etc. nur wenn tatsächlich Logik drin?

---

## 10. Prüfpunkte für Agent 5 (Logic Test)

Agent 5 soll folgende Szenarien testen (mental walkthrough):

### Szenario 1: Happy Path — Neue Preisliste, aktueller Mandant
1. User öffnet Page 7022, klickt "Import Prices from JSON"
2. Page 60101 öffnet, CurrentCompany vorbelegt
3. Modus = NewList, Nummernserie ausgewählt
4. JSON geladen → HeaderBuffer + LineBuffer gefüllt
5. Validierung → alle grün
6. Import → Header als Draft angelegt, Lines inserted, Log erfolgreich

### Szenario 2: Datums-Konflikt
1. JSON enthält Artikel 1000, 01.01.2024–31.12.2024
2. In BC existiert aktive Preisliste: Artikel 1000, 01.06.2024–31.12.2024
3. Validator setzt ValidationStatus = Error für diese Zeile
4. Fehlermeldung lesbar: "Date conflict with active price line"
5. User kann "Skip Import" aktivieren → Zeile wird trotzdem nicht importiert (WENN Fehler → skip)
6. Oder: User deaktiviert die Zeile und importiert Rest

### Szenario 3: Mehrmandant — Fehler bei Mandant 2
1. 3 Mandanten ausgewählt
2. Mandant 1: Erfolg, Commit
3. Mandant 2: Fehler (Artikel existiert nicht), Rollback, LogError
4. Mandant 3: WIRD NICHT VERARBEITET (STOP)
5. Log zeigt: Mandant 1 Erfolgreich, Mandant 2 Fehler

### Szenario 4: Currency Code in JSON vorhanden
1. JSON enthält `"currencyCode": "EUR"`
2. Importer ignoriert dieses Feld explizit
3. Price List Header wird ohne Currency Code angelegt (= Mandantenwährung)

### Szenario 5: Leere Nummernserie
1. Modus = NewList, aber keine Nummernserie ausgewählt
2. Import-Aktion gibt Fehlermeldung: "No Series Code must not be empty"
3. Kein Datenbankzugriff, kein Log-Eintrag

---

## 11. Abhängigkeiten auf BC-Standard-Objekte (Referenzliste für Agent 3)

| Objekt | Typ | Zweck |
|--------|-----|-------|
| "Price List Header" (7002) | Table | Writer: INSERT Header |
| "Price List Line" (7003) | Table | Writer: INSERT Line, Validator: Konflikt-Check |
| "Price Source Type" | Enum | Header Source Type |
| "Price Status" | Enum | Header Status = Draft |
| "Price Type" | Enum | Header/Line Price Type = Sale |
| "Price Asset Type" | Enum | Line Asset Type = Item |
| Item (27) | Table | Validator: Artikel-Existenz |
| "Item Variant" (5401) | Table | Validator: Varianten-Existenz |
| "No. Series" (308) | Table | Page: Lookup Nummernserie |
| "No. Series Line" (309) | Table | Writer: NoSeries.GetNextNo() |
| Company (2000000006) | Table | CompanySelectorPage: Liste aller Mandanten |
| "No. Series" Codeunit | Codeunit | Writer: GetNextNo() |
| "Sales Price Lists" (7022) | Page | PageExtension Basis |

---

*Plan-Ende. Alle IDs 60100–60110 vergeben, 60111–60200 frei.*
