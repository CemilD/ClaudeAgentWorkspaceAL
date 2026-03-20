// SECURITY: NEVER DELETE from "Price List Header" (Table 7002)
// SECURITY: NEVER DELETE from "Price List Line" (Table 7003)
// SECURITY: NEVER MODIFY "Price List Line"
// SECURITY: New Price List Header Status ALWAYS = Draft
codeunit 60103 "CDE Price List Writer" implements "ICDEPriceListWriter"
{

    var
        LastCreatedCode: Code[20];

    procedure CreatePriceListHeader(var HeaderBuffer: Record "CDE Price Header Buffer" temporary; NoSeriesCode: Code[20]; ManualCode: Code[20]): Code[20]
    var
        PriceListHeader: Record "Price List Header";
        NoSeries: Codeunit "No. Series";
        NewCode: Code[20];
    begin
        // Determine code: manual entry or number series
        if ManualCode <> '' then
            NewCode := ManualCode
        else
            NewCode := NoSeries.GetNextNo(NoSeriesCode, WorkDate(), true);

        PriceListHeader.Init();
        PriceListHeader.Code := NewCode;
        PriceListHeader.Validate("Price Type", "Price Type"::Sale);
        PriceListHeader.Status := "Price Status"::Draft;
        PriceListHeader.Validate("Source Type", HeaderBuffer."Source Type");
        if HeaderBuffer."Source No." <> '' then
            PriceListHeader.Validate("Source No.", HeaderBuffer."Source No.");
        PriceListHeader."Starting Date" := HeaderBuffer."Starting Date";
        PriceListHeader."Ending Date" := HeaderBuffer."Ending Date";
        PriceListHeader.Description := HeaderBuffer."Description";

        PriceListHeader.Insert(true);
        LastCreatedCode := NewCode;
        exit(NewCode);
    end;

    procedure InsertPriceLine(PriceListCode: Code[20]; var LineBuffer: Record "CDE Price Line Buffer" temporary): Boolean
    var
        PriceListLine: Record "Price List Line";
    begin
        // Error lines are ALWAYS blocked - never import invalid data
        if LineBuffer."Validation Status" = LineBuffer."Validation Status"::Error then
            exit(false);

        // Lines explicitly marked to skip are omitted
        if LineBuffer."Skip Import" then
            exit(false);

        PriceListLine.Init();
        PriceListLine."Price List Code" := PriceListCode;
        PriceListLine."Line No." := GetNextLineNo(PriceListCode);
        PriceListLine."Price Type" := "Price Type"::Sale;
        PriceListLine."Asset Type" := "Price Asset Type"::Item;
        PriceListLine.Validate("Asset No.", LineBuffer."Asset No.");
        if LineBuffer."Variant Code" <> '' then
            PriceListLine.Validate("Variant Code", LineBuffer."Variant Code");
        PriceListLine."Starting Date" := LineBuffer."Starting Date";
        PriceListLine."Ending Date" := LineBuffer."Ending Date";
        PriceListLine.Validate("Unit Price", LineBuffer."Unit Price");
        PriceListLine."Minimum Quantity" := LineBuffer."Minimum Quantity";
        if LineBuffer."Unit of Measure Code" <> '' then
            PriceListLine.Validate("Unit of Measure Code", LineBuffer."Unit of Measure Code");
        PriceListLine."Allow Invoice Disc." := LineBuffer."CDE Allow Invoice Disc.";
        PriceListLine."Allow Line Disc." := LineBuffer."CDE Allow Line Disc.";
        PriceListLine."Price Includes VAT" := LineBuffer."CDE Price Includes VAT";
        if LineBuffer."CDE VAT Bus. Post. Gr." <> '' then
            PriceListLine.Validate("VAT Bus. Posting Gr. (Price)", LineBuffer."CDE VAT Bus. Post. Gr.");
        PriceListLine.Insert(true);
        exit(true);
    end;

    procedure GetLastCreatedPriceListCode(): Code[20]
    begin
        exit(LastCreatedCode);
    end;

    local procedure GetNextLineNo(PriceListCode: Code[20]): Integer
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Price List Code", PriceListCode);
        if PriceListLine.FindLast() then
            exit(PriceListLine."Line No." + 10000);
        exit(10000);
    end;
}
