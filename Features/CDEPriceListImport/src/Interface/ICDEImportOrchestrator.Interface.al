interface "ICDEImportOrchestrator"
{
    procedure Run(var ImportParams: Record "CDE Import Params" temporary; var HeaderBuffer: Record "CDE Price Header Buffer" temporary; var LineBuffer: Record "CDE Price Line Buffer" temporary): Boolean;
}
