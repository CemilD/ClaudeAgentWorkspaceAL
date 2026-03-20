pageextension 60103 "CDE Sales Price Lists Ext" extends "Sales Price Lists"
{
    actions
    {
        addlast(processing)
        {
            action(CDEImportFromJson)
            {
                Caption = 'Import Prices from JSON';
                ToolTip = 'Opens the JSON price list import page to import external prices from a JSON file.';
                ApplicationArea = All;
                Image = Import;
                RunObject = page "CDE Price List JSON Import";
            }
            action(CDEExportToJson)
            {
                Caption = 'Export Price List to JSON';
                ToolTip = 'Exports the selected price list including all lines as a JSON file.';
                ApplicationArea = All;
                Image = Export;

                trigger OnAction()
                var
                    Exporter: Codeunit "CDE JSON Price Exporter";
                    ErrNoSelectionLbl: Label 'Please select a price list to export.', Comment = 'Error when no price list is selected for export';
                begin
                    if Rec.Code = '' then
                        Error(ErrNoSelectionLbl);
                    Exporter.ExportPriceListToJson(Rec.Code);
                end;
            }
            action(CDEDownloadTemplate)
            {
                Caption = 'Download JSON Template';
                ToolTip = 'Downloads an empty JSON template file with the correct structure for price list import.';
                ApplicationArea = All;
                Image = Template;

                trigger OnAction()
                var
                    Exporter: Codeunit "CDE JSON Price Exporter";
                begin
                    Exporter.DownloadTemplateJson();
                end;
            }
        }
    }
}
