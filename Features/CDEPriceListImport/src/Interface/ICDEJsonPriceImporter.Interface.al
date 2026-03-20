interface "ICDEJsonPriceImporter"
{
    procedure ParseJson(JsonStream: InStream; var HeaderBuffer: Record "CDE Price Header Buffer" temporary; var LineBuffer: Record "CDE Price Line Buffer" temporary): Boolean;
    procedure GetLastError(): Text;
}
