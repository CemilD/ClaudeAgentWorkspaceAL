codeunit 60100 "CDE Import Orchestrator" implements "ICDEImportOrchestrator"
{

    var
        JsonImporter: Interface "ICDEJsonPriceImporter";
        Validator: Interface "ICDEPriceListValidator";
        Writer: Interface "ICDEPriceListWriter";
        CompanySelector: Interface "ICDECompanySelector";
        Logger: Interface "ICDEImportLogger";
        DependenciesSet: Boolean;
        OrchestratorRunLocationLbl: Label 'CDEImportOrchestrator.Run', Locked = true;

    procedure Run(var ImportParams: Record "CDE Import Params" temporary; var HeaderBuffer: Record "CDE Price Header Buffer" temporary; var LineBuffer: Record "CDE Price Line Buffer" temporary): Boolean
    var
        CompanyList: List of [Text];
        CurrentCompany: Text;
        PriceListCode: Code[20];
        LinesImported: Integer;
        LinesSkipped: Integer;
        ProcessOk: Boolean;
        ErrProcessCompanyLbl: Label 'Import failed for company %1.', Comment = '%1 = company name';
    begin
        EnsureDefaultDependencies();

        CompanyList := CompanySelector.GetSelectedCompanies();
        if CompanyList.Count = 0 then
            exit(false);

        foreach CurrentCompany in CompanyList do begin
            LinesImported := 0;
            LinesSkipped := 0;
            PriceListCode := '';

            ProcessOk := TryProcessCompany(ImportParams, HeaderBuffer, LineBuffer, CurrentCompany, PriceListCode, LinesImported, LinesSkipped);
            if not ProcessOk then begin
                Logger.LogError(CurrentCompany, PriceListCode, OrchestratorRunLocationLbl, StrSubstNo(ErrProcessCompanyLbl, CurrentCompany));
                exit(false);
            end;

            Logger.LogSuccess(CurrentCompany, PriceListCode, ImportParams."Existing Price List Code", LinesImported, LinesSkipped);
            Commit();
        end;

        exit(true);
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
    var
        SourcePriceListCode: Code[20];
    begin
        // Determine source price list code for reference
        if ImportParams."Import Mode" = ImportParams."Import Mode"::ModifyExisting then
            SourcePriceListCode := ImportParams."Existing Price List Code"
        else
            SourcePriceListCode := '';

        // Create the price list header
        PriceListCode := Writer.CreatePriceListHeader(HeaderBuffer, ImportParams."No. Series Code", SourcePriceListCode);

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
