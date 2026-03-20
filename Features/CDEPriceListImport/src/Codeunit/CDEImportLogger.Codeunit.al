codeunit 60105 "CDE Import Logger" implements "ICDEImportLogger"
{

    procedure LogSuccess(CompanyName: Text; PriceListCode: Code[20]; SourcePriceListCode: Code[20]; LinesImported: Integer; LinesSkipped: Integer)
    var
        ImportLog: Record "CDE Price Import Log";
    begin
        ImportLog.Init();
        ImportLog."Import Date Time" := CurrentDateTime();
        ImportLog."User ID" := CopyStr(UserId(), 1, 50);
        ImportLog."Company Name" := CopyStr(CompanyName, 1, 30);
        ImportLog."Price List Code" := PriceListCode;
        ImportLog."Source Price List Code" := SourcePriceListCode;
        ImportLog."Lines Imported" := LinesImported;
        ImportLog."Lines Skipped" := LinesSkipped;
        ImportLog."Status" := ImportLog."Status"::Successful;
        ImportLog.Insert(true);
    end;

    procedure LogError(CompanyName: Text; PriceListCode: Code[20]; ErrorLocation: Text; ErrorMessage: Text)
    var
        ImportLog: Record "CDE Price Import Log";
        FormattedMsg: Text;
        FormatLbl: Label 'Company: %1 | Price List: %2 | Location: %3 | Error: %4', Comment = '%1 = company name, %2 = price list code, %3 = error location, %4 = error message';
    begin
        FormattedMsg := StrSubstNo(FormatLbl, CompanyName, PriceListCode, ErrorLocation, ErrorMessage);

        ImportLog.Init();
        ImportLog."Import Date Time" := CurrentDateTime();
        ImportLog."User ID" := CopyStr(UserId(), 1, 50);
        ImportLog."Company Name" := CopyStr(CompanyName, 1, 30);
        ImportLog."Price List Code" := PriceListCode;
        ImportLog."Lines Imported" := 0;
        ImportLog."Lines Skipped" := 0;
        ImportLog."Status" := ImportLog."Status"::Error;
        ImportLog."Error Location" := CopyStr(ErrorLocation, 1, 250);
        ImportLog."Error Message" := CopyStr(FormattedMsg, 1, 500);
        ImportLog.Insert(true);
    end;
}
