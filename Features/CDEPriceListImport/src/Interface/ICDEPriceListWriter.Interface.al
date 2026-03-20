interface "ICDEPriceListWriter"
{
    procedure CreatePriceListHeader(var HeaderBuffer: Record "CDE Price Header Buffer" temporary; NoSeriesCode: Code[20]; SourcePriceListCode: Code[20]): Code[20];
    procedure InsertPriceLine(PriceListCode: Code[20]; var LineBuffer: Record "CDE Price Line Buffer" temporary): Boolean;
    procedure GetLastCreatedPriceListCode(): Code[20];
}
