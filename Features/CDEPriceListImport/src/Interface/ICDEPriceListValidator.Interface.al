interface "ICDEPriceListValidator"
{
    procedure Validate(var LineBuffer: Record "CDE Price Line Buffer" temporary; CompanyName: Text): Boolean;
    procedure GetErrorCount(): Integer;
    procedure GetWarningCount(): Integer;
}
