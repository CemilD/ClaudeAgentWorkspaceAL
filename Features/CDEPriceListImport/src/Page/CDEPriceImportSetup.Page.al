page 60109 "CDE Price Import Setup"
{
    Caption = 'Price Import Setup';
    PageType = Card;
    SourceTable = "CDE Price Import Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(NumberAssignment)
            {
                Caption = 'Number Assignment';

                field("No. Series Code"; Rec."No. Series Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default number series for new price lists. If empty, the number series from Sales & Receivables Setup is used.';
                }
                field("Allow Manual Code"; Rec."Allow Manual Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the user can enter a custom price list code manually instead of using the number series.';
                }
            }
            group(Defaults)
            {
                Caption = 'Default Values for New Lines';

                field("Default Source Type"; Rec."Default Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default source type for new price lists.';
                }
                field("Default Allow Invoice Disc."; Rec."Default Allow Invoice Disc.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default value for Allow Invoice Disc. on imported price lines.';
                }
                field("Default Allow Line Disc."; Rec."Default Allow Line Disc.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default value for Allow Line Disc. on imported price lines.';
                }
                field("Default Price Includes VAT"; Rec."Default Price Includes VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default value for Price Includes VAT on imported price lines.';
                }
                field("Default VAT Bus. Post. Gr."; Rec."Default VAT Bus. Post. Gr.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default VAT Business Posting Group for imported price lines.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
