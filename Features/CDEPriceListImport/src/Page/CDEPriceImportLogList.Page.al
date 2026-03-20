page 60102 "CDE Price Import Log List"
{
    Caption = 'CDE Price Import Log';
    PageType = ListPart;
    SourceTable = "CDE Price Import Log";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(LogLines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sequential entry number of the import log record.';
                }
                field("Import Date Time"; Rec."Import Date Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date and time when the import was executed.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the user who performed the import.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the company into which the price list was imported.';
                }
                field("Price List Code"; Rec."Price List Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the price list that was created or modified during import.';
                }
                field("Source Price List Code"; Rec."Source Price List Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the source price list used as a reference during import.';
                }
                field("Lines Imported"; Rec."Lines Imported")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of price lines that were successfully imported.';
                }
                field("Lines Skipped"; Rec."Lines Skipped")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of price lines that were skipped due to validation errors.';
                }
                field("Status"; Rec."Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the final status of the import operation: Successful, Partial, or Error.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message if the import encountered a problem.';
                }
            }
        }
    }
}
