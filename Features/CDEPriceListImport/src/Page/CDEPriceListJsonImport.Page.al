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
                        UpdateSelectedCompaniesDisplay();
                    end;
                }
                field(SelectedCompaniesField; SelectedCompaniesText)
                {
                    ApplicationArea = All;
                    Caption = 'Selected Companies';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Shows which companies are currently selected for the import.';
                    Style = Strong;
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
                        UpdateModeFlags();
                    end;
                }
            }
            group(NewListSettings)
            {
                Caption = 'New Price List';
                Visible = IsNewListMode;

                field("No. Series Code"; Rec."No. Series Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series used to assign a code to the new price list.';
                    TableRelation = "No. Series";
                    Visible = not AllowManualCode;
                }
                field(ManualCodeField; ManualPriceListCode)
                {
                    ApplicationArea = All;
                    Caption = 'Price List Code';
                    ToolTip = 'Enter a custom code for the new price list. Enable "Allow Manual Code" in the Price Import Setup to use this field.';
                    Visible = AllowManualCode;
                }
            }
            group(ModifyExistingSettings)
            {
                Caption = 'Existing Price List';
                Visible = IsModifyExistingMode;

                field("Existing Price List Code"; Rec."Existing Price List Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of an existing price list to which imported lines will be added.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PriceListHeader: Record "Price List Header";
                    begin
                        PriceListHeader.SetRange("Price Type", "Price Type"::Sale);
                        if Page.RunModal(Page::"Sales Price Lists", PriceListHeader) = Action::LookupOK then begin
                            Text := PriceListHeader.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    var
                        PriceListHeader: Record "Price List Header";
                        ErrPriceListNotFoundLbl: Label 'Price list "%1" was not found.', Comment = '%1 = price list code';
                    begin
                        if Rec."Existing Price List Code" <> '' then
                            if not PriceListHeader.Get(Rec."Existing Price List Code") then
                                Error(ErrPriceListNotFoundLbl, Rec."Existing Price List Code");
                    end;
                }
            }
            group(HeaderData)
            {
                Caption = 'Price List Header Data';
                Visible = not IsModifyExistingMode;

                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source type for the price list (e.g. Customer, All Customers).';
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
                    ErrLoadFailedLbl: Label 'The JSON file could not be loaded.\\ \\Reason: %1', Comment = '%1 = error message from parser';
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
                    MsgValidOkLbl: Label 'Validation successful. All lines are valid and ready for import.', Comment = 'Success message after validation with no errors';
                    MsgValidErrLbl: Label 'Validation completed: %1 error(s) and %2 warning(s) found.\Please check the "Error Message" column in the preview lines for details.', Comment = '%1 = error count, %2 = warning count';
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
                    DefaultJsonImporterForImport: Codeunit "CDE JSON Price Importer";
                    DefaultValidatorForImport: Codeunit "CDE Price List Validator";
                    DefaultWriterForImport: Codeunit "CDE Price List Writer";
                    DefaultLoggerForImport: Codeunit "CDE Import Logger";
                    OrchestratorCU: Codeunit "CDE Import Orchestrator";
                    MsgImportNewOkLbl: Label 'The price list "%1" was created successfully (Status: Draft).', Comment = '%1 = price list code';
                    MsgImportModifyOkLbl: Label 'Lines were added to price list "%1" successfully.', Comment = '%1 = price list code';
                    ErrImportFailedLbl: Label 'The import failed:\%1\\Please check the Import Log section for more details.', Comment = '%1 = actual error details';
                    ErrNoExistingPriceListLbl: Label 'Please select an existing price list in the "Existing Price List Code" field.';
                    ErrNoManualCodeLbl: Label 'Please enter a price list code in the "Price List Code" field.';
                    ErrValidationFailedLbl: Label 'Validation failed: %1 error(s) found. Please fix the errors before importing.', Comment = '%1 = error count';
                    ValidationOk: Boolean;
                begin
                    // Validate required fields
                    if Rec."Import Mode" = Rec."Import Mode"::ModifyExisting then begin
                        if Rec."Existing Price List Code" = '' then
                            Error(ErrNoExistingPriceListLbl);
                    end else
                        if AllowManualCode then begin
                            if ManualPriceListCode = '' then
                                Error(ErrNoManualCodeLbl);
                            Rec."Manual Price List Code" := ManualPriceListCode;
                            Rec.Modify();
                        end;

                    // Always run validation before import
                    if Rec."Import Mode" = Rec."Import Mode"::ModifyExisting then
                        Validator.SetTargetPriceListCode(Rec."Existing Price List Code")
                    else
                        Validator.SetTargetPriceListCode('');
                    ValidationOk := Validator.Validate(LineBuffer, CompanyName());
                    CurrPage.PreviewLines.Page.SetLineBuffer(LineBuffer);
                    CurrPage.Update(false);
                    if not ValidationOk then
                        Error(ErrValidationFailedLbl, Validator.GetErrorCount());

                    // Determine company scope
                    ApplyCompanyScope();

                    // Pass page's CompanySelector to Orchestrator so it uses the same selected companies
                    OrchestratorCU.SetDependencies(DefaultJsonImporterForImport, DefaultValidatorForImport, DefaultWriterForImport, CompanySelectorCU, DefaultLoggerForImport);
                    Orchestrator := OrchestratorCU;

                    ImportOk := Orchestrator.Run(Rec, HeaderBuffer, LineBuffer);
                    CurrPage.Update(false);

                    if ImportOk then begin
                        if Rec."Import Mode" = Rec."Import Mode"::ModifyExisting then
                            Message(MsgImportModifyOkLbl, Orchestrator.GetLastPriceListCode())
                        else
                            Message(MsgImportNewOkLbl, Orchestrator.GetLastPriceListCode());
                    end else
                        Error(ErrImportFailedLbl, Orchestrator.GetLastRunError());
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
                    UpdateSelectedCompaniesDisplay();
                    CurrPage.Update(false);
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
            action(OpenSetup)
            {
                Caption = 'Setup';
                ToolTip = 'Opens the Price Import Setup page to configure number series, manual codes and default values.';
                ApplicationArea = All;
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "CDE Price Import Setup";
            }
        }
    }

    trigger OnOpenPage()
    var
        DefaultJsonImporter: Codeunit "CDE JSON Price Importer";
        DefaultValidator: Codeunit "CDE Price List Validator";
        DefaultCompanySelector: Codeunit "CDE Company Selector";
        DefaultOrchestrator: Codeunit "CDE Import Orchestrator";
        ImportSetup: Record "CDE Price Import Setup";
    begin
        Rec.Init();
        Rec."Entry No." := 1;
        Rec."No. Series Code" := GetDefaultPriceListNoSeries();
        Rec.Insert();
        JsonImporter := DefaultJsonImporter;
        Validator := DefaultValidator;
        CompanySelectorCU := DefaultCompanySelector;
        Orchestrator := DefaultOrchestrator;
        CompanySelectorCU.SetCurrentCompanyOnly();
        UpdateSelectedCompaniesDisplay();
        IsNewListMode := true;
        IsModifyExistingMode := false;
        ImportSetup.GetSetup();
        AllowManualCode := ImportSetup."Allow Manual Code";
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
        AllowManualCode: Boolean;
        ManualPriceListCode: Code[20];
        SelectedCompaniesText: Text;

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

    local procedure UpdateModeFlags()
    begin
        IsNewListMode := Rec."Import Mode" = Rec."Import Mode"::NewList;
        IsModifyExistingMode := Rec."Import Mode" = Rec."Import Mode"::ModifyExisting;
        CurrPage.Update(false);
    end;

    local procedure GetDefaultPriceListNoSeries(): Code[20]
    var
        ImportSetup: Record "CDE Price Import Setup";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        ImportSetup.GetSetup();
        if ImportSetup."No. Series Code" <> '' then
            exit(ImportSetup."No. Series Code");
        SalesSetup.Get();
        exit(SalesSetup."Price List Nos.");
    end;

    local procedure UpdateSelectedCompaniesDisplay()
    var
        CountLbl: Label '%1 company(ies): %2', Comment = '%1 = count, %2 = company names';
    begin
        SelectedCompaniesText := StrSubstNo(CountLbl, CompanySelectorCU.GetSelectedCount(), CompanySelectorCU.GetSelectedCompanyNames());
    end;
}
