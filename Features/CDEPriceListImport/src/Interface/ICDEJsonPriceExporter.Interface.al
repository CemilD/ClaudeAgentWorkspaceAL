interface "ICDEJsonPriceExporter"
{
    procedure ExportPriceListToJson(PriceListCode: Code[20]);
    procedure DownloadTemplateJson();
}
