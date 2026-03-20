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
        }
    }
}
