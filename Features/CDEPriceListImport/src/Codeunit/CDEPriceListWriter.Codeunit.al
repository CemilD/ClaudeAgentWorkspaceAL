// SECURITY: NEVER DELETE from "Price List Header" (Table 7002)
// SECURITY: NEVER DELETE from "Price List Line" (Table 7003)
// SECURITY: NEVER MODIFY "Price List Line"
// SECURITY: New Price List Header Status ALWAYS = Draft
codeunit 60103 "CDE Price List Writer" implements "ICDEPriceListWriter"
{

    procedure CreatePriceListHeader(var HeaderBuffer: Record "CDE Price Header Buffer" temporary; NoSeriesCode: Code[20]; SourcePriceListCode: Code[20]): Code[20]
    var
        PriceListHeader: Record "Price List Header";
        NoSeries: Codeunit "No. Series";
        NewCode: Code[20];
        DescriptionText: Text[100];
        RefSuffixLbl: Label ' (Ref: %1)', Comment = '%1 = source price list code, CDE Price List Import';
    begin
        NewCode := NoSeries.GetNextNo(NoSeriesCode, WorkDate(), true);

        PriceListHeader.Init();
        PriceListHeader.Code := NewCode;
        PriceListHeader."Price Type" := "Price Type"::Sale;
        PriceListHeader.Status := "Price Status"::Draft;
        PriceListHeader."Source Type" := HeaderBuffer."Source Type";
        PriceListHeader."Source No." := HeaderBuffer."Source No.";
        PriceListHeader."Starting Date" := HeaderBuffer."Starting Date";
        PriceListHeader."Ending Date" := HeaderBuffer."Ending Date";

        if SourcePriceListCode <> '' then
            DescriptionText := CopyStr(HeaderBuffer."Description" + StrSubstNo(RefSuffixLbl, SourcePriceListCode), 1, 100)
        else
            DescriptionText := HeaderBuffer."Description";

        PriceListHeader.Description := DescriptionText;

        PriceListHeader.Insert(true);
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
        PriceListLine."Asset No." := LineBuffer."Asset No.";
        PriceListLine."Variant Code" := LineBuffer."Variant Code";
        PriceListLine."Starting Date" := LineBuffer."Starting Date";
        PriceListLine."Ending Date" := LineBuffer."Ending Date";
        PriceListLine."Unit Price" := LineBuffer."Unit Price";
        PriceListLine."Minimum Quantity" := LineBuffer."Minimum Quantity";
        PriceListLine."Unit of Measure Code" := LineBuffer."Unit of Measure Code";
        PriceListLine.Insert(true);
        exit(true);
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
