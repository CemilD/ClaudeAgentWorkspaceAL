page 60101 "CDE Price List JSON Import"
{
    Caption = 'JSON Price List Import';
    PageType = Card;
    SourceTable = "CDE Import Params";
    SourceTableTemporary = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(CompanySelection)
            {
                Caption = 'Company Selection';

                field(CurrentCompanyField; CompanyName())
                {
                    ApplicationArea = All;
                    Caption = 'Current Company';
                    Editable = false;
                    ToolTip = 'Specifies the name of the current company.';
                }
                field("All Companies"; Rec."All Companies")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to import into all companies. Default is current company only.';

                    trigger OnValidate()
                    begin
                        if Rec."All Companies" then
                            CompanySelectorCU.SetAllCompanies()
                        else
                            CompanySelectorCU.SetCurrentCompanyOnly();
                    end;
                }
            }
            group(ImportMode)
            {
                Caption = 'Import Settings';

                field("Import Mode"; Rec."Import Mode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to create a new price list or modify an existing one.';

                    trigger OnValidate()
                    begin
                        IsNewListMode := Rec."Import Mode" = Rec."Import Mode"::NewList;
                        IsModifyExistingMode := Rec."Import Mode" = Rec."Import Mode"::ModifyExisting;
                        CurrPage.Update();
                    end;
                }
                field("No. Series Code"; Rec."No. Series Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series used to assign a code to the new price list.';
                    Visible = IsNewListMode;
                    TableRelation = "No. Series";
                }
                field("Existing Price List Code"; Rec."Existing Price List Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of an existing price list to which imported lines will be added.';
                    Visible = IsModifyExistingMode;
                    TableRelation = "Price List Header" where("Price Type" = const(Sale));
                }
            }
            group(HeaderData)
            {
                Caption = 'Price List Header Data';

                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source type for the price list (e.g. Customer, All Customers).';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source number (e.g. customer number) for the price list.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date from which the price list is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last date on which the price list is valid.';
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the price list.';
                }
            }
            part(PreviewLines; "CDE Price Line Buffer List")
            {
                ApplicationArea = All;
                Caption = 'Preview Lines';
                Visible = JsonLoaded;
            }
            part(ImportLogPart; "CDE Price Import Log List")
            {
                ApplicationArea = All;
                Caption = 'Import Log';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LoadJson)
            {
                Caption = 'Load JSON File';
                ToolTip = 'Opens a file dialog to upload a JSON file containing the price list data.';
                ApplicationArea = All;
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    JsonStream: InStream;
                    FileName: Text;
                    ErrLoadFailedLbl: Label 'Failed to load JSON file: %1', Comment = '%1 = error message from parser';
                    UploadDialogTitleLbl: Label 'Select JSON File', Comment = 'CDE Price List Import - file upload dialog title';
                    JsonFileFilterLbl: Label 'JSON Files (*.json)|*.json', Locked = true;
                begin
                    HeaderBuffer.Reset();
                    HeaderBuffer.DeleteAll();
                    LineBuffer.Reset();
                    LineBuffer.DeleteAll();
                    JsonLoaded := false;

                    if not UploadIntoStream(UploadDialogTitleLbl, '', JsonFileFilterLbl, FileName, JsonStream) then
                        exit;

                    if not JsonImporter.ParseJson(JsonStream, HeaderBuffer, LineBuffer) then
                        Error(ErrLoadFailedLbl, JsonImporter.GetLastError());

                    // Populate page params from header buffer
                    if HeaderBuffer.FindFirst() then begin
                        Rec."Source Type" := HeaderBuffer."Source Type";
                        Rec."Source No." := HeaderBuffer."Source No.";
                        Rec."Starting Date" := HeaderBuffer."Starting Date";
                        Rec."Ending Date" := HeaderBuffer."Ending Date";
                        Rec."Description" := HeaderBuffer."Description";
                        Rec.Modify();
                    end;

                    JsonLoaded := true;
                    CurrPage.PreviewLines.Page.SetLineBuffer(LineBuffer);
                    CurrPage.Update(false);
                end;
            }
            action(RunValidation)
            {
                Caption = 'Validate';
                ToolTip = 'Validates all loaded price lines against master data and existing price lists before import.';
                ApplicationArea = All;
                Image = CheckRulesSyntax;
                Enabled = JsonLoaded;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    ValidationOk: Boolean;
                    MsgValidOkLbl: Label 'Validation completed. No errors found.', Comment = 'Success message after validation with no errors';
                    MsgValidErrLbl: Label 'Validation completed with %1 error(s) and %2 warning(s). Review the preview lines.', Comment = '%1 = error count, %2 = warning count';
                begin
                    ValidationOk := Validator.Validate(LineBuffer, CompanyName());
                    CurrPage.PreviewLines.Page.SetLineBuffer(LineBuffer);
                    CurrPage.Update(false);
                    if ValidationOk then
                        Message(MsgValidOkLbl)
                    else
                        Message(MsgValidErrLbl, Validator.GetErrorCount(), Validator.GetWarningCount());
                end;
            }
            action(ImportPrices)
            {
                Caption = 'Import';
                ToolTip = 'Runs the price list import for the selected companies using the loaded JSON data.';
                ApplicationArea = All;
                Image = Apply;
                Enabled = JsonLoaded;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    ImportOk: Boolean;
                    MsgImportOkLbl: Label 'Price list import completed successfully.', Comment = 'Success message shown after a successful import';
                    ErrImportFailedLbl: Label 'Price list import failed. Check the import log for details.', Comment = 'Error message shown when the import process encounters a failure';
                begin
                    // Determine company scope
                    ApplyCompanyScope();

                    ImportOk := Orchestrator.Run(Rec, HeaderBuffer, LineBuffer);
                    CurrPage.Update(false);

                    if ImportOk then
                        Message(MsgImportOkLbl)
                    else
                        Error(ErrImportFailedLbl);
                end;
            }
            action(SelectCompanies)
            {
                Caption = 'Select Companies...';
                ToolTip = 'Opens the company selection dialog to choose which companies the price list will be imported into.';
                ApplicationArea = All;
                Image = SelectEntries;

                trigger OnAction()
                begin
                    CompanySelectorCU.ShowSelectorPage();
                end;
            }
            action(DownloadTemplate)
            {
                Caption = 'Download JSON Template';
                ToolTip = 'Downloads an empty JSON template file with the correct structure for price list import.';
                ApplicationArea = All;
                Image = Template;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Exporter: Codeunit "CDE JSON Price Exporter";
                begin
                    Exporter.DownloadTemplateJson();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        DefaultJsonImporter: Codeunit "CDE JSON Price Importer";
        DefaultValidator: Codeunit "CDE Price List Validator";
        DefaultCompanySelector: Codeunit "CDE Company Selector";
        DefaultOrchestrator: Codeunit "CDE Import Orchestrator";
    begin
        Rec.Init();
        Rec."Entry No." := 1;
        Rec.Insert();
        JsonImporter := DefaultJsonImporter;
        Validator := DefaultValidator;
        CompanySelectorCU := DefaultCompanySelector;
        Orchestrator := DefaultOrchestrator;
        CompanySelectorCU.SetCurrentCompanyOnly();
    end;

    var
        HeaderBuffer: Record "CDE Price Header Buffer" temporary;
        LineBuffer: Record "CDE Price Line Buffer" temporary;
        JsonImporter: Interface "ICDEJsonPriceImporter";
        Validator: Interface "ICDEPriceListValidator";
        CompanySelectorCU: Interface "ICDECompanySelector";
        Orchestrator: Interface "ICDEImportOrchestrator";
        JsonLoaded: Boolean;
        IsNewListMode: Boolean;
        IsModifyExistingMode: Boolean;

    local procedure ApplyCompanyScope()
    begin
        // Priority 1: Manual selection via ShowSelectorPage (even if only 1 company selected)
        if CompanySelectorCU.IsManualSelectionDone() then
            exit;  // Use the manually selected companies as-is
        // Priority 2: All companies
        if Rec."All Companies" then begin
            CompanySelectorCU.SetAllCompanies();
            exit;
        end;
        // Priority 3: Default - current company only
        CompanySelectorCU.SetCurrentCompanyOnly();
    end;
}
