page 60108 "CDE Company Selector Page"
{
    Caption = 'Select Companies';
    PageType = List;
    SourceTable = "CDE Company Selection Buffer";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(CompanyLines)
            {
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the name of the company available for import.';
                }
                field("Selected"; Rec."Selected")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this company is selected for import.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectAll)
            {
                Caption = 'Select All';
                ToolTip = 'Selects all companies in the list.';
                ApplicationArea = All;
                Image = SelectEntries;

                trigger OnAction()
                begin
                    SetAllSelected(true);
                end;
            }
            action(DeselectAll)
            {
                Caption = 'Deselect All';
                ToolTip = 'Clears the selection for all companies in the list.';
                ApplicationArea = All;
                Image = ClearFilter;

                trigger OnAction()
                begin
                    SetAllSelected(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadCompanies();
    end;

    procedure GetSelectedCompanies(): List of [Text]
    var
        Result: List of [Text];
    begin
        Rec.Reset();
        Rec.SetRange("Selected", true);
        if Rec.FindSet() then
            repeat
                Result.Add(Rec."Company Name");
            until Rec.Next() = 0;
        Rec.Reset();
        exit(Result);
    end;

    local procedure LoadCompanies()
    var
        Company: Record Company;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        Company.SetLoadFields(Name);
        if Company.FindSet() then
            repeat
                Rec.Init();
                Rec."Company Name" := CopyStr(Company.Name, 1, 30);
                Rec."Selected" := false;
                Rec.Insert();
            until Company.Next() = 0;
    end;

    local procedure SetAllSelected(IsSelected: Boolean)
    begin
        Rec.Reset();
        if Rec.FindSet() then
            repeat
                Rec."Selected" := IsSelected;
                Rec.Modify();
            until Rec.Next() = 0;
        CurrPage.Update(false);
    end;
}
