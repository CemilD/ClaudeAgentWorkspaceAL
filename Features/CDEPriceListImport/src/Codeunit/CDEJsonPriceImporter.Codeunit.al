codeunit 60101 "CDE JSON Price Importer" implements "ICDEJsonPriceImporter"
{

    var
        LastError: Text;

    procedure ParseJson(JsonStream: InStream; var HeaderBuffer: Record "CDE Price Header Buffer" temporary; var LineBuffer: Record "CDE Price Line Buffer" temporary): Boolean
    var
        RootJsonObject: JsonObject;
        HeaderToken: JsonToken;
        LinesToken: JsonToken;
        HeaderObject: JsonObject;
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineObject: JsonObject;
        EntryNo: Integer;
        StartDateInvalid: Boolean;
        EndDateInvalid: Boolean;
        UnitPriceInvalid: Boolean;
        MinQtyInvalid: Boolean;
        ErrParseRootLbl: Label 'The file contains invalid JSON and could not be read. Please check the file for syntax errors (e.g. missing commas, brackets or quotation marks). Technical detail: %1', Comment = '%1 = error details';
        ErrParseHeaderLbl: Label 'The JSON file is missing the "header" section. The file must contain a "header" object with code, description and sourceType. Technical detail: %1', Comment = '%1 = error details';
        ErrHeaderCodeLbl: Label 'The price list code is missing in the header. Please fill in the field "code" in the JSON header.', Comment = 'Validation error for missing code field';
        ErrHeaderDescLbl: Label 'The description is missing in the header. Please fill in the field "description" in the JSON header.', Comment = 'Validation error for missing description field';
        ErrHeaderSourceTypeLbl: Label 'The source type is missing in the header. Please fill in the field "sourceType" in the JSON header (e.g. "Customer", "AllCustomers").', Comment = 'Validation error for missing sourceType field';
        MissingHeaderNodeLbl: Label 'missing "header" node', Locked = true;
        ErrHeaderDateInvalidLbl: Label 'The starting date "%1" in the header is not a valid date. Please use the format YYYY-MM-DD (e.g. 2024-01-15).', Comment = '%1 = the invalid date value';
        ErrHeaderEndDateInvalidLbl: Label 'The ending date "%1" in the header is not a valid date. Please use the format YYYY-MM-DD (e.g. 2024-12-31).', Comment = '%1 = the invalid date value';
    begin
        LastError := '';
        HeaderBuffer.Reset();
        HeaderBuffer.DeleteAll();
        LineBuffer.Reset();
        LineBuffer.DeleteAll();

        // Parse JSON directly from stream
        if not RootJsonObject.ReadFrom(JsonStream) then begin
            LastError := StrSubstNo(ErrParseRootLbl, GetLastErrorText());
            exit(false);
        end;

        // Parse header
        if not RootJsonObject.Get('header', HeaderToken) then begin
            LastError := StrSubstNo(ErrParseHeaderLbl, MissingHeaderNodeLbl);
            exit(false);
        end;
        HeaderObject := HeaderToken.AsObject();

        // Validate mandatory header fields (only code, description, sourceType)
        // startingDate, endingDate, sourceNo are optional in JSON — user can set them on the import page
        if not HasJsonTextValue(HeaderObject, 'code') then begin
            LastError := ErrHeaderCodeLbl;
            exit(false);
        end;
        if not HasJsonTextValue(HeaderObject, 'description') then begin
            LastError := ErrHeaderDescLbl;
            exit(false);
        end;
        if not HasJsonTextValue(HeaderObject, 'sourceType') then begin
            LastError := ErrHeaderSourceTypeLbl;
            exit(false);
        end;

        // Fill header buffer
        HeaderBuffer.Init();
        HeaderBuffer."Code" := CopyStr(GetJsonTextValue(HeaderObject, 'code'), 1, 20);
        HeaderBuffer."Description" := CopyStr(GetJsonTextValue(HeaderObject, 'description'), 1, 100);
        HeaderBuffer."Source Type" := MapSourceType(GetJsonTextValue(HeaderObject, 'sourceType'));
        HeaderBuffer."Source No." := CopyStr(GetJsonTextValue(HeaderObject, 'sourceNo'), 1, 20);
        HeaderBuffer."Starting Date" := ParseDate(GetJsonTextValue(HeaderObject, 'startingDate'), StartDateInvalid);
        if StartDateInvalid then begin
            LastError := StrSubstNo(ErrHeaderDateInvalidLbl, GetJsonTextValue(HeaderObject, 'startingDate'));
            exit(false);
        end;
        HeaderBuffer."Ending Date" := ParseDate(GetJsonTextValue(HeaderObject, 'endingDate'), EndDateInvalid);
        if EndDateInvalid then begin
            LastError := StrSubstNo(ErrHeaderEndDateInvalidLbl, GetJsonTextValue(HeaderObject, 'endingDate'));
            exit(false);
        end;
        // INTENTIONAL: Currency Code ignored, always use company currency
        HeaderBuffer.Insert();

        // Parse lines
        EntryNo := 0;
        if RootJsonObject.Get('lines', LinesToken) then begin
            LinesArray := LinesToken.AsArray();
            foreach LineToken in LinesArray do begin
                EntryNo += 1;
                LineObject := LineToken.AsObject();
                LineBuffer.Init();
                LineBuffer."Entry No." := EntryNo;
                LineBuffer."Price List Code" := HeaderBuffer."Code";
                LineBuffer."Asset No." := CopyStr(GetJsonTextValue(LineObject, 'assetNo'), 1, 20);
                LineBuffer."Variant Code" := CopyStr(GetJsonTextValue(LineObject, 'variantCode'), 1, 10);
                LineBuffer."Starting Date" := ParseDate(GetJsonTextValue(LineObject, 'startingDate'), StartDateInvalid);
                LineBuffer."Ending Date" := ParseDate(GetJsonTextValue(LineObject, 'endingDate'), EndDateInvalid);
                LineBuffer."Unit Price" := GetJsonDecimalValue(LineObject, 'unitPrice', UnitPriceInvalid);
                LineBuffer."Minimum Quantity" := GetJsonDecimalValue(LineObject, 'minimumQuantity', MinQtyInvalid);
                LineBuffer."Unit of Measure Code" := CopyStr(GetJsonTextValue(LineObject, 'unitOfMeasureCode'), 1, 10);
                LineBuffer."CDE Allow Invoice Disc." := GetJsonBoolValue(LineObject, 'allowInvoiceDisc');
                LineBuffer."CDE Allow Line Disc." := GetJsonBoolValue(LineObject, 'allowLineDisc');
                LineBuffer."CDE Price Includes VAT" := GetJsonBoolValue(LineObject, 'priceIncludesVAT');
                LineBuffer."CDE VAT Bus. Post. Gr." := CopyStr(GetJsonTextValue(LineObject, 'vatBusPostingGr'), 1, 20);
                LineBuffer."Validation Status" := LineBuffer."Validation Status"::" ";

                // Mark error with human-readable messages
                if StartDateInvalid or EndDateInvalid or UnitPriceInvalid or MinQtyInvalid or
                   (LineBuffer."Asset No." = '') or (LineBuffer."Starting Date" = 0D) or (LineBuffer."Unit Price" <= 0) then begin
                    LineBuffer."Validation Status" := LineBuffer."Validation Status"::Error;
                    LineBuffer."Error Message" := BuildLineError(EntryNo, LineBuffer,
                        StartDateInvalid, EndDateInvalid, UnitPriceInvalid, MinQtyInvalid,
                        GetJsonTextValue(LineObject, 'startingDate'),
                        GetJsonTextValue(LineObject, 'endingDate'),
                        GetJsonTextValue(LineObject, 'unitPrice'));
                end;

                LineBuffer.Insert();
            end;
        end;

        exit(true);
    end;

    procedure GetLastError(): Text
    begin
        exit(LastError);
    end;

    local procedure HasJsonTextValue(JsonObj: JsonObject; FieldName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not JsonObj.Get(FieldName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        exit(Token.AsValue().AsText() <> '');
    end;

    local procedure GetJsonTextValue(JsonObj: JsonObject; FieldName: Text): Text
    var
        Token: JsonToken;
    begin
        if not JsonObj.Get(FieldName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetJsonBoolValue(JsonObj: JsonObject; FieldName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not JsonObj.Get(FieldName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        exit(Token.AsValue().AsText() in ['true', '1', 'yes']);
    end;

    local procedure GetJsonDecimalValue(JsonObj: JsonObject; FieldName: Text; var IsInvalid: Boolean): Decimal
    var
        Token: JsonToken;
        DecValue: Decimal;
        TextValue: Text;
    begin
        IsInvalid := false;
        if not JsonObj.Get(FieldName, Token) then
            exit(0);
        if not Token.IsValue() then begin
            IsInvalid := true;
            exit(0);
        end;
        if Token.AsValue().IsNull() then
            exit(0);
        if Token.AsValue().IsUndefined() then
            exit(0);
        // Get as text, then parse to decimal (safe for any JSON value type)
        TextValue := Token.AsValue().AsText();
        if not Evaluate(DecValue, TextValue) then begin
            IsInvalid := true;
            exit(0);
        end;
        exit(DecValue);
    end;

    local procedure ParseDate(DateText: Text; var IsInvalid: Boolean): Date
    var
        ParsedDate: Date;
    begin
        IsInvalid := false;
        if DateText = '' then
            exit(0D);
        if Evaluate(ParsedDate, DateText) then
            exit(ParsedDate);
        IsInvalid := true;
        exit(0D);
    end;

    local procedure MapSourceType(SourceTypeText: Text): Enum "Price Source Type"
    begin
        case SourceTypeText of
            'Customer':
                exit("Price Source Type"::Customer);
            'AllCustomers':
                exit("Price Source Type"::"All Customers");
            'Campaign':
                exit("Price Source Type"::Campaign);
            'Contact':
                exit("Price Source Type"::Contact);
            'CustomerDiscGrp':
                exit("Price Source Type"::"Customer Disc. Group");
            'CustomerPriceGrp':
                exit("Price Source Type"::"Customer Price Group");
            else
                exit("Price Source Type"::"All Customers");
        end;
    end;

    local procedure BuildLineError(LineNo: Integer; LineBuffer: Record "CDE Price Line Buffer" temporary; StartDateInvalid: Boolean; EndDateInvalid: Boolean; UnitPriceInvalid: Boolean; MinQtyInvalid: Boolean; RawStartDate: Text; RawEndDate: Text; RawUnitPrice: Text): Text[500]
    var
        Problems: Text;
        ErrLineProblemsLbl: Label 'Line %1: %2', Comment = '%1 = line number, %2 = problem description';
        ErrAssetNoMissingLbl: Label 'Item No. (assetNo) is empty', Comment = 'Human-readable error for missing item number';
        ErrStartDateMissingLbl: Label 'Starting Date (startingDate) is empty', Comment = 'Human-readable error for missing start date';
        ErrStartDateInvalidLbl: Label 'Starting Date "%1" is not a valid date (expected format: YYYY-MM-DD)', Comment = '%1 = the invalid date value from JSON';
        ErrEndDateInvalidLbl: Label 'Ending Date "%1" is not a valid date (expected format: YYYY-MM-DD)', Comment = '%1 = the invalid date value from JSON';
        ErrUnitPriceZeroLbl: Label 'Unit Price must be greater than 0', Comment = 'Human-readable error for zero/negative price';
        ErrUnitPriceInvalidLbl: Label 'Unit Price "%1" is not a valid number (use a dot as decimal separator, e.g. 99.50)', Comment = '%1 = the invalid price value from JSON';
        ErrMinQtyInvalidLbl: Label 'Minimum Quantity is not a valid number', Comment = 'Human-readable error for invalid min qty';
    begin
        Problems := '';

        if LineBuffer."Asset No." = '' then
            Problems += ErrAssetNoMissingLbl + '; ';

        if StartDateInvalid then
            Problems += StrSubstNo(ErrStartDateInvalidLbl, RawStartDate) + '; '
        else
            if LineBuffer."Starting Date" = 0D then
                Problems += ErrStartDateMissingLbl + '; ';

        if UnitPriceInvalid then
            Problems += StrSubstNo(ErrUnitPriceInvalidLbl, RawUnitPrice) + '; '
        else
            if LineBuffer."Unit Price" <= 0 then
                Problems += ErrUnitPriceZeroLbl + '; ';

        if EndDateInvalid then
            Problems += StrSubstNo(ErrEndDateInvalidLbl, RawEndDate) + '; ';

        if MinQtyInvalid then
            Problems += ErrMinQtyInvalidLbl + '; ';

        Problems := DelChr(Problems, '>', '; ');
        exit(CopyStr(StrSubstNo(ErrLineProblemsLbl, LineNo, Problems), 1, 500));
    end;
}
