interface "ICDEImportLogger"
{
    procedure LogSuccess(CompanyName: Text; PriceListCode: Code[20]; SourcePriceListCode: Code[20]; LinesImported: Integer; LinesSkipped: Integer);
    procedure LogError(CompanyName: Text; PriceListCode: Code[20]; ErrorLocation: Text; ErrorMessage: Text);
}
