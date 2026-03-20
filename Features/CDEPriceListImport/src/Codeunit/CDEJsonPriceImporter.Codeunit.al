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
        ErrParseRootLbl: Label 'Failed to parse JSON root object: %1', Comment = '%1 = error details';
        ErrParseHeaderLbl: Label 'Failed to parse JSON header object: %1', Comment = '%1 = error details';
        ErrHeaderCodeLbl: Label 'JSON header is missing required field "code".', Comment = 'Validation error for missing code field';
        ErrHeaderDescLbl: Label 'JSON header is missing required field "description".', Comment = 'Validation error for missing description field';
        ErrHeaderSourceTypeLbl: Label 'JSON header is missing required field "sourceType".', Comment = 'Validation error for missing sourceType field';
        MissingHeaderNodeLbl: Label 'missing "header" node', Locked = true;
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
        HeaderBuffer."Starting Date" := ParseDate(GetJsonTextValue(HeaderObject, 'startingDate'));
        HeaderBuffer."Ending Date" := ParseDate(GetJsonTextValue(HeaderObject, 'endingDate'));
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
                LineBuffer."Starting Date" := ParseDate(GetJsonTextValue(LineObject, 'startingDate'));
                LineBuffer."Ending Date" := ParseDate(GetJsonTextValue(LineObject, 'endingDate'));
                LineBuffer."Unit Price" := GetJsonDecimalValue(LineObject, 'unitPrice');
                LineBuffer."Minimum Quantity" := GetJsonDecimalValue(LineObject, 'minimumQuantity');
                LineBuffer."Unit of Measure Code" := CopyStr(GetJsonTextValue(LineObject, 'unitOfMeasureCode'), 1, 10);
                LineBuffer."Validation Status" := LineBuffer."Validation Status"::" ";

                // Mark error if mandatory line fields missing
                if (LineBuffer."Asset No." = '') or (LineBuffer."Starting Date" = 0D) or (LineBuffer."Unit Price" <= 0) then begin
                    LineBuffer."Validation Status" := LineBuffer."Validation Status"::Error;
                    LineBuffer."Error Message" := BuildLineMissingFieldError(LineBuffer);
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

    local procedure GetJsonDecimalValue(JsonObj: JsonObject; FieldName: Text): Decimal
    var
        Token: JsonToken;
    begin
        if not JsonObj.Get(FieldName, Token) then
            exit(0);
        if not Token.IsValue() then
            exit(0);
        if Token.AsValue().IsNull() then
            exit(0);
        exit(Token.AsValue().AsDecimal());
    end;

    local procedure ParseDate(DateText: Text): Date
    var
        ParsedDate: Date;
    begin
        if DateText = '' then
            exit(0D);
        if Evaluate(ParsedDate, DateText) then
            exit(ParsedDate);
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

    local procedure BuildLineMissingFieldError(LineBuffer: Record "CDE Price Line Buffer" temporary): Text[500]
    var
        MissingFields: Text;
        ErrMissingFieldsLbl: Label 'Missing required fields: %1', Comment = '%1 = comma-separated list of missing field names';
        AssetNoFieldLbl: Label 'assetNo', Locked = true;
        StartingDateFieldLbl: Label 'startingDate', Locked = true;
        UnitPriceFieldLbl: Label 'unitPrice (must be > 0)', Locked = true;
    begin
        MissingFields := '';
        if LineBuffer."Asset No." = '' then
            MissingFields += AssetNoFieldLbl + ', ';
        if LineBuffer."Starting Date" = 0D then
            MissingFields += StartingDateFieldLbl + ', ';
        if LineBuffer."Unit Price" <= 0 then
            MissingFields += UnitPriceFieldLbl + ', ';
        MissingFields := DelChr(MissingFields, '>', ', ');
        exit(CopyStr(StrSubstNo(ErrMissingFieldsLbl, MissingFields), 1, 500));
    end;
}
