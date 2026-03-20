page 60103 "CDE Price Line Buffer List"
{
    Caption = 'Price Line Preview';
    PageType = ListPart;
    SourceTable = "CDE Price Line Buffer";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sequential line number in the JSON import buffer.';
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item number for this price line.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item variant code for this price line.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date from which this price line is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last date on which this price line is valid.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit price for the item on this line.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the minimum quantity required for this price to apply.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure for which this price applies.';
                }
                field("Validation Status"; Rec."Validation Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the result of the last validation run for this line: blank, Error, or Warning.';
                    StyleExpr = ValidationStatusStyle;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the validation error or warning message for this line.';
                }
                field("Skip Import"; Rec."Skip Import")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this line should be skipped during import even if it has errors.';
                    Editable = true;
                }
            }
        }
    }

    var
        ValidationStatusStyle: Text;

    procedure SetLineBuffer(var NewLineBuffer: Record "CDE Price Line Buffer" temporary)
    begin
        Rec.Copy(NewLineBuffer, true);
        CurrPage.Update(false);
    end;

    trigger OnAfterGetRecord()
    begin
        case Rec."Validation Status" of
            Rec."Validation Status"::Error:
                ValidationStatusStyle := 'Unfavorable';
            Rec."Validation Status"::Warning:
                ValidationStatusStyle := 'Ambiguous';
            else
                ValidationStatusStyle := 'Standard';
        end;
    end;
}
