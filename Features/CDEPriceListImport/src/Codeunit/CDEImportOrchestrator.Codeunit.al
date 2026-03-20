codeunit 60100 "CDE Import Orchestrator" implements "ICDEImportOrchestrator"
{

    var
        JsonImporter: Interface "ICDEJsonPriceImporter";
        Validator: Interface "ICDEPriceListValidator";
        Writer: Interface "ICDEPriceListWriter";
        CompanySelector: Interface "ICDECompanySelector";
        Logger: Interface "ICDEImportLogger";
        DependenciesSet: Boolean;
        LastRunError: Text;
        LastPriceListCode: Code[20];
        OrchestratorRunLocationLbl: Label 'CDEImportOrchestrator.Run', Locked = true;

    procedure Run(var ImportParams: Record "CDE Import Params" temporary; var HeaderBuffer: Record "CDE Price Header Buffer" temporary; var LineBuffer: Record "CDE Price Line Buffer" temporary): Boolean
    var
        CompanyList: List of [Text];
        CurrentCompany: Text;
        PriceListCode: Code[20];
        LinesImported: Integer;
        LinesSkipped: Integer;
        ProcessOk: Boolean;
        ActualError: Text;
        ErrProcessCompanyLbl: Label 'The import failed for company "%1".', Comment = '%1 = company name';
        ErrNoCompanyLbl: Label 'No company selected. Please select at least one company for the import.';
    begin
        EnsureDefaultDependencies();
        LastRunError := '';
        LastPriceListCode := '';

        CompanyList := CompanySelector.GetSelectedCompanies();
        if CompanyList.Count = 0 then begin
            LastRunError := ErrNoCompanyLbl;
            exit(false);
        end;

        foreach CurrentCompany in CompanyList do begin
            LinesImported := 0;
            LinesSkipped := 0;
            PriceListCode := '';

            ProcessOk := TryProcessCompany(ImportParams, HeaderBuffer, LineBuffer, CurrentCompany, PriceListCode, LinesImported, LinesSkipped);
            if not ProcessOk then begin
                ActualError := GetLastErrorText();
                LastRunError := StrSubstNo(ErrProcessCompanyLbl, CurrentCompany) + ' ' + ActualError;
                Logger.LogError(CurrentCompany, PriceListCode, OrchestratorRunLocationLbl,
                    StrSubstNo(ErrProcessCompanyLbl, CurrentCompany) + ' ' + ActualError);
                exit(false);
            end;

            LastPriceListCode := PriceListCode;
            Logger.LogSuccess(CurrentCompany, PriceListCode, ImportParams."Existing Price List Code", LinesImported, LinesSkipped);
            Commit();
        end;

        exit(true);
    end;

    procedure GetLastRunError(): Text
    begin
        exit(LastRunError);
    end;

    procedure GetLastPriceListCode(): Code[20]
    begin
        exit(LastPriceListCode);
    end;

    procedure SetDependencies(
        NewJsonImporter: Interface "ICDEJsonPriceImporter";
        NewValidator: Interface "ICDEPriceListValidator";
        NewWriter: Interface "ICDEPriceListWriter";
        NewCompanySelector: Interface "ICDECompanySelector";
        NewLogger: Interface "ICDEImportLogger")
    begin
        JsonImporter := NewJsonImporter;
        Validator := NewValidator;
        Writer := NewWriter;
        CompanySelector := NewCompanySelector;
        Logger := NewLogger;
        DependenciesSet := true;
    end;

    [TryFunction]
    local procedure TryProcessCompany(var ImportParams: Record "CDE Import Params" temporary; var HeaderBuffer: Record "CDE Price Header Buffer" temporary; var LineBuffer: Record "CDE Price Line Buffer" temporary; CompanyName: Text; var PriceListCode: Code[20]; var LinesImported: Integer; var LinesSkipped: Integer)
    begin
        // Determine price list code based on import mode
        if ImportParams."Import Mode" = ImportParams."Import Mode"::ModifyExisting then
            // Use existing price list - just add lines
            PriceListCode := ImportParams."Existing Price List Code"
        else
            // New price list - create header (manual code or number series)
            PriceListCode := Writer.CreatePriceListHeader(HeaderBuffer, ImportParams."No. Series Code", ImportParams."Manual Price List Code");

        // Process all lines
        LineBuffer.Reset();
        if LineBuffer.FindSet() then
            repeat
                if Writer.InsertPriceLine(PriceListCode, LineBuffer) then
                    LinesImported += 1
                else
                    LinesSkipped += 1;
            until LineBuffer.Next() = 0;
    end;

    local procedure EnsureDefaultDependencies()
    var
        DefaultJsonImporter: Codeunit "CDE JSON Price Importer";
        DefaultValidator: Codeunit "CDE Price List Validator";
        DefaultWriter: Codeunit "CDE Price List Writer";
        DefaultCompanySelector: Codeunit "CDE Company Selector";
        DefaultLogger: Codeunit "CDE Import Logger";
    begin
        if DependenciesSet then
            exit;
        JsonImporter := DefaultJsonImporter;
        Validator := DefaultValidator;
        Writer := DefaultWriter;
        CompanySelector := DefaultCompanySelector;
        Logger := DefaultLogger;
        DependenciesSet := true;
    end;
}
