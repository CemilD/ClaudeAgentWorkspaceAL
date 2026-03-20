codeunit 60104 "CDE Company Selector" implements "ICDECompanySelector"
{

    var
        SelectedCompanies: List of [Text];
        ManualSelectionDone: Boolean;

    procedure GetSelectedCompanies(): List of [Text]
    begin
        exit(SelectedCompanies);
    end;

    procedure ShowSelectorPage()
    var
        CompanySelectorPage: Page "CDE Company Selector Page";
        PageSelectedCompanies: List of [Text];
    begin
        CompanySelectorPage.RunModal();
        PageSelectedCompanies := CompanySelectorPage.GetSelectedCompanies();
        SelectedCompanies := PageSelectedCompanies;
        ManualSelectionDone := true;

        // Fallback: if nothing selected, use current company
        if SelectedCompanies.Count = 0 then begin
            Clear(SelectedCompanies);
            SelectedCompanies.Add(CompanyName());
        end;
    end;

    procedure SetCurrentCompanyOnly()
    begin
        ManualSelectionDone := false;
        Clear(SelectedCompanies);
        SelectedCompanies.Add(CompanyName());
    end;

    procedure SetAllCompanies()
    var
        Company: Record Company;
    begin
        ManualSelectionDone := false;
        Clear(SelectedCompanies);
        Company.SetLoadFields(Name);
        if Company.FindSet() then
            repeat
                SelectedCompanies.Add(Company.Name);
            until Company.Next() = 0;
    end;

    procedure IsManualSelectionDone(): Boolean
    begin
        exit(ManualSelectionDone);
    end;

    procedure GetSelectedCompanyNames(): Text
    var
        CompanyName: Text;
        Result: Text;
    begin
        Result := '';
        foreach CompanyName in SelectedCompanies do begin
            if Result <> '' then
                Result += ', ';
            Result += CompanyName;
        end;
        exit(Result);
    end;

    procedure GetSelectedCount(): Integer
    begin
        exit(SelectedCompanies.Count);
    end;
}
