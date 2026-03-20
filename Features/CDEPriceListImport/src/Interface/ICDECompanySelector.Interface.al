interface "ICDECompanySelector"
{
    procedure GetSelectedCompanies(): List of [Text];
    procedure ShowSelectorPage();
    procedure SetCurrentCompanyOnly();
    procedure SetAllCompanies();
    procedure IsManualSelectionDone(): Boolean;
    procedure GetSelectedCompanyNames(): Text;
    procedure GetSelectedCount(): Integer;
}
