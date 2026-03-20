codeunit 60102 "CDE Price List Validator" implements "ICDEPriceListValidator"
{

    var
        ErrorCount: Integer;
        WarningCount: Integer;
        TargetPriceListCode: Code[20];

    procedure SetTargetPriceListCode(PriceListCode: Code[20])
    begin
        TargetPriceListCode := PriceListCode;
    end;

    procedure Validate(var LineBuffer: Record "CDE Price Line Buffer" temporary; CompanyName: Text): Boolean
    begin
        ErrorCount := 0;
        WarningCount := 0;

        LineBuffer.Reset();
        if not LineBuffer.FindSet() then
            exit(true);

        repeat
            ValidateLine(LineBuffer, CompanyName);
            LineBuffer.Modify();
        until LineBuffer.Next() = 0;

        exit(ErrorCount = 0);
    end;

    procedure GetErrorCount(): Integer
    begin
        exit(ErrorCount);
    end;

    procedure GetWarningCount(): Integer
    begin
        exit(WarningCount);
    end;

    local procedure ValidateLine(var LineBuffer: Record "CDE Price Line Buffer" temporary; CompanyName: Text)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        VATBusPostingGrp: Record "VAT Business Posting Group";
        LineHasError: Boolean;
        ErrAssetNoEmptyLbl: Label 'Item No. is empty. Each price line must have an item number.', Comment = 'Validation error: asset no is empty';
        ErrStartDateEmptyLbl: Label 'Starting Date is empty. Each price line must have a starting date.', Comment = 'Validation error: starting date is zero';
        ErrUnitPriceZeroLbl: Label 'Unit Price is 0 or negative. The price must be greater than 0.', Comment = 'Validation error: unit price is zero or negative';
        ErrItemNotFoundLbl: Label 'Item "%1" was not found in company "%2". Please check the item number.', Comment = '%1 = item no., %2 = company name';
        ErrVariantNotFoundLbl: Label 'Variant "%1" does not exist for item "%2" in company "%3". Please check the variant code.', Comment = '%1 = variant code, %2 = item no., %3 = company name';
        ErrEndBeforeStartLbl: Label 'Ending Date (%1) is before or equal to Starting Date (%2). The ending date must be after the starting date.', Comment = '%1 = ending date, %2 = starting date';
        ErrDateConflictLbl: Label 'There is already an active price line for item "%1" in this date range. Please deactivate the existing price list first or choose a different date range.', Comment = '%1 = item no.';
        ErrDuplicateInJsonLbl: Label 'This line is a duplicate: Item "%1", Variant "%2", from %3 to %4 appears more than once in the JSON file. Please remove the duplicate entry.', Comment = '%1 = item no., %2 = variant code, %3 = starting date, %4 = ending date';
        ErrDuplicateInPriceListLbl: Label 'Item "%1", Variant "%2", Ending Date %3 already exists in price list "%4". Duplicate lines are not allowed.', Comment = '%1 = item no., %2 = variant code, %3 = ending date, %4 = price list code';
        WarnNoEndDateLbl: Label 'No ending date specified. This price line will remain valid indefinitely (open-ended).', Comment = 'Warning: ending date is zero';
        ErrVATBusPostGrpNotFoundLbl: Label 'VAT Bus. Posting Group "%1" does not exist. Please check the value.', Comment = '%1 = VAT bus posting group code';
    begin
        LineHasError := false;

        // 1. Mandatory field checks
        if LineBuffer."Asset No." = '' then begin
            SetLineError(LineBuffer, ErrAssetNoEmptyLbl);
            LineHasError := true;
        end;
        if LineBuffer."Starting Date" = 0D then begin
            SetLineError(LineBuffer, ErrStartDateEmptyLbl);
            LineHasError := true;
        end;
        if LineBuffer."Unit Price" <= 0 then begin
            SetLineError(LineBuffer, ErrUnitPriceZeroLbl);
            LineHasError := true;
        end;

        if LineHasError then begin
            ErrorCount += 1;
            exit;
        end;

        // 2. Item existence check (ChangeCompany)
        Item.ChangeCompany(CompanyName);
        if not Item.Get(LineBuffer."Asset No.") then begin
            SetLineError(LineBuffer, StrSubstNo(ErrItemNotFoundLbl, LineBuffer."Asset No.", CompanyName));
            ErrorCount += 1;
            exit;
        end;

        // 3. Variant check
        if LineBuffer."Variant Code" <> '' then begin
            ItemVariant.ChangeCompany(CompanyName);
            if not ItemVariant.Get(LineBuffer."Asset No.", LineBuffer."Variant Code") then begin
                SetLineError(LineBuffer, StrSubstNo(ErrVariantNotFoundLbl, LineBuffer."Variant Code", LineBuffer."Asset No.", CompanyName));
                ErrorCount += 1;
                exit;
            end;
        end;

        // 4. VAT Bus. Posting Group check
        if LineBuffer."CDE VAT Bus. Post. Gr." <> '' then begin
            VATBusPostingGrp.ChangeCompany(CompanyName);
            if not VATBusPostingGrp.Get(LineBuffer."CDE VAT Bus. Post. Gr.") then begin
                SetLineError(LineBuffer, StrSubstNo(ErrVATBusPostGrpNotFoundLbl, LineBuffer."CDE VAT Bus. Post. Gr."));
                ErrorCount += 1;
                exit;
            end;
        end;

        // 5. Ending Date > Starting Date when set
        if (LineBuffer."Ending Date" <> 0D) and (LineBuffer."Ending Date" <= LineBuffer."Starting Date") then begin
            SetLineError(LineBuffer, StrSubstNo(ErrEndBeforeStartLbl, LineBuffer."Ending Date", LineBuffer."Starting Date"));
            ErrorCount += 1;
            exit;
        end;

        // 6. Date conflict against active price lines
        if CheckDateConflict(LineBuffer, CompanyName) then begin
            SetLineError(LineBuffer, StrSubstNo(ErrDateConflictLbl, LineBuffer."Asset No."));
            ErrorCount += 1;
            exit;
        end;

        // 7. Duplicate in JSON (same Asset No. + Variant Code + Starting Date + Ending Date)
        if CheckDuplicateInBuffer(LineBuffer) then begin
            SetLineError(LineBuffer, StrSubstNo(ErrDuplicateInJsonLbl, LineBuffer."Asset No.", LineBuffer."Variant Code", LineBuffer."Starting Date", LineBuffer."Ending Date"));
            ErrorCount += 1;
            exit;
        end;

        // 8. Duplicate check against existing price list lines (same Asset No. + Variant Code + Ending Date)
        if CheckDuplicateInPriceList(LineBuffer, CompanyName) then begin
            SetLineError(LineBuffer, StrSubstNo(ErrDuplicateInPriceListLbl,
                LineBuffer."Asset No.", LineBuffer."Variant Code", LineBuffer."Ending Date", LineBuffer."Price List Code"));
            ErrorCount += 1;
            exit;
        end;

        // 9. Warning when Ending Date is empty (only if no error)
        if LineBuffer."Ending Date" = 0D then begin
            SetLineWarning(LineBuffer, WarnNoEndDateLbl);
            WarningCount += 1;
        end;
    end;

    local procedure SetLineError(var LineBuffer: Record "CDE Price Line Buffer" temporary; ErrorMsg: Text)
    begin
        if LineBuffer."Validation Status" <> LineBuffer."Validation Status"::Error then begin
            LineBuffer."Validation Status" := LineBuffer."Validation Status"::Error;
            LineBuffer."Error Message" := CopyStr(ErrorMsg, 1, 500);
        end;
    end;

    local procedure SetLineWarning(var LineBuffer: Record "CDE Price Line Buffer" temporary; WarningMsg: Text)
    begin
        if LineBuffer."Validation Status" = LineBuffer."Validation Status"::" " then begin
            LineBuffer."Validation Status" := LineBuffer."Validation Status"::Warning;
            LineBuffer."Error Message" := CopyStr(WarningMsg, 1, 500);
        end;
    end;

    local procedure CheckDateConflict(var LineBuffer: Record "CDE Price Line Buffer" temporary; CompanyName: Text): Boolean
    var
        PriceListLine: Record "Price List Line";
        PriceListHeader: Record "Price List Header";
    begin
        PriceListLine.ChangeCompany(CompanyName);
        PriceListLine.SetLoadFields("Price List Code", "Asset No.", "Variant Code", "Starting Date", "Ending Date");
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", LineBuffer."Asset No.");
        PriceListLine.SetRange("Variant Code", LineBuffer."Variant Code");
        if PriceListLine.FindSet() then
            repeat
                PriceListHeader.ChangeCompany(CompanyName);
                if PriceListHeader.Get(PriceListLine."Price List Code") then
                    if PriceListHeader.Status = "Price Status"::Active then begin
                        // Overlap check:
                        if ((LineBuffer."Starting Date" <= PriceListLine."Ending Date") or (PriceListLine."Ending Date" = 0D)) and
                           ((LineBuffer."Ending Date" >= PriceListLine."Starting Date") or (LineBuffer."Ending Date" = 0D)) then
                            exit(true);
                    end;
            until PriceListLine.Next() = 0;
        exit(false);
    end;

    local procedure CheckDuplicateInBuffer(var LineBuffer: Record "CDE Price Line Buffer" temporary): Boolean
    var
        CheckBuffer: Record "CDE Price Line Buffer" temporary;
    begin
        CheckBuffer.Copy(LineBuffer, true);
        CheckBuffer.Reset();
        CheckBuffer.SetRange("Asset No.", LineBuffer."Asset No.");
        CheckBuffer.SetRange("Variant Code", LineBuffer."Variant Code");
        CheckBuffer.SetRange("Starting Date", LineBuffer."Starting Date");
        CheckBuffer.SetRange("Ending Date", LineBuffer."Ending Date");
        CheckBuffer.SetFilter("Entry No.", '<>%1', LineBuffer."Entry No.");
        exit(not CheckBuffer.IsEmpty());
    end;

    local procedure CheckDuplicateInPriceList(var LineBuffer: Record "CDE Price Line Buffer" temporary; CompanyName: Text): Boolean
    var
        PriceListLine: Record "Price List Line";
    begin
        // Only check when modifying an existing price list
        if TargetPriceListCode = '' then
            exit(false);

        PriceListLine.ChangeCompany(CompanyName);
        PriceListLine.SetRange("Price List Code", TargetPriceListCode);
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", LineBuffer."Asset No.");
        PriceListLine.SetRange("Variant Code", LineBuffer."Variant Code");
        PriceListLine.SetRange("Ending Date", LineBuffer."Ending Date");
        exit(not PriceListLine.IsEmpty());
    end;
}
