codeunit 60106 "CDE JSON Price Exporter" implements "ICDEJsonPriceExporter"
{

    procedure ExportPriceListToJson(PriceListCode: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        RootObject: JsonObject;
        HeaderObject: JsonObject;
        LinesArray: JsonArray;
        LineObject: JsonObject;
        JsonText: Text;
        OutStream: OutStream;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        FileName: Text;
        ErrNotFoundLbl: Label 'Price List %1 does not exist.', Comment = '%1 = price list code';
        FileNameLbl: Label '%1.json', Locked = true;
    begin
        if not PriceListHeader.Get(PriceListCode) then
            Error(ErrNotFoundLbl, PriceListCode);

        // Build header JSON
        HeaderObject.Add('code', PriceListHeader.Code);
        HeaderObject.Add('description', PriceListHeader.Description);
        HeaderObject.Add('sourceType', MapSourceTypeToText(PriceListHeader."Source Type"));
        HeaderObject.Add('sourceNo', Format(PriceListHeader."Source No."));
        HeaderObject.Add('startingDate', FormatDate(PriceListHeader."Starting Date"));
        HeaderObject.Add('endingDate', FormatDate(PriceListHeader."Ending Date"));

        // Build lines JSON
        PriceListLine.SetRange("Price List Code", PriceListCode);
        if PriceListLine.FindSet() then
            repeat
                Clear(LineObject);
                LineObject.Add('assetNo', Format(PriceListLine."Asset No."));
                LineObject.Add('variantCode', Format(PriceListLine."Variant Code"));
                LineObject.Add('startingDate', FormatDate(PriceListLine."Starting Date"));
                LineObject.Add('endingDate', FormatDate(PriceListLine."Ending Date"));
                LineObject.Add('unitPrice', PriceListLine."Unit Price");
                LineObject.Add('minimumQuantity', PriceListLine."Minimum Quantity");
                LineObject.Add('unitOfMeasureCode', Format(PriceListLine."Unit of Measure Code"));
                LineObject.Add('allowInvoiceDisc', PriceListLine."Allow Invoice Disc.");
                LineObject.Add('allowLineDisc', PriceListLine."Allow Line Disc.");
                LineObject.Add('priceIncludesVAT', PriceListLine."Price Includes VAT");
                LineObject.Add('vatBusPostingGr', Format(PriceListLine."VAT Bus. Posting Gr. (Price)"));
                LinesArray.Add(LineObject);
            until PriceListLine.Next() = 0;

        // Assemble root
        RootObject.Add('header', HeaderObject);
        RootObject.Add('lines', LinesArray);
        RootObject.WriteTo(JsonText);

        // Download
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(JsonText);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        FileName := StrSubstNo(FileNameLbl, PriceListCode);
        DownloadFromStream(InStream, '', '', '', FileName);
    end;

    procedure DownloadTemplateJson()
    var
        RootObject: JsonObject;
        HeaderObject: JsonObject;
        LinesArray: JsonArray;
        LineObject: JsonObject;
        JsonText: Text;
        OutStream: OutStream;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        FileName: Text;
        TemplateFileNameLbl: Label 'PriceList_Template.json', Locked = true;
    begin
        // Build template header
        HeaderObject.Add('code', '');
        HeaderObject.Add('description', '');
        HeaderObject.Add('sourceType', 'Customer');
        HeaderObject.Add('sourceNo', '');
        HeaderObject.Add('startingDate', FormatDate(WorkDate()));
        HeaderObject.Add('endingDate', '');

        // Build template line (one example)
        LineObject.Add('assetNo', '');
        LineObject.Add('variantCode', '');
        LineObject.Add('startingDate', FormatDate(WorkDate()));
        LineObject.Add('endingDate', '');
        LineObject.Add('unitPrice', 0);
        LineObject.Add('minimumQuantity', 0);
        LineObject.Add('unitOfMeasureCode', '');
        LineObject.Add('allowInvoiceDisc', false);
        LineObject.Add('allowLineDisc', false);
        LineObject.Add('priceIncludesVAT', false);
        LineObject.Add('vatBusPostingGr', '');
        LinesArray.Add(LineObject);

        // Assemble root
        RootObject.Add('header', HeaderObject);
        RootObject.Add('lines', LinesArray);
        RootObject.WriteTo(JsonText);

        // Download
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(JsonText);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        FileName := TemplateFileNameLbl;
        DownloadFromStream(InStream, '', '', '', FileName);
    end;

    local procedure MapSourceTypeToText(SourceType: Enum "Price Source Type"): Text
    begin
        case SourceType of
            "Price Source Type"::Customer:
                exit('Customer');
            "Price Source Type"::"All Customers":
                exit('AllCustomers');
            "Price Source Type"::Campaign:
                exit('Campaign');
            "Price Source Type"::Contact:
                exit('Contact');
            "Price Source Type"::"Customer Disc. Group":
                exit('CustomerDiscGrp');
            "Price Source Type"::"Customer Price Group":
                exit('CustomerPriceGrp');
            else
                exit('AllCustomers');
        end;
    end;

    local procedure FormatDate(DateValue: Date): Text
    begin
        if DateValue = 0D then
            exit('');
        exit(Format(DateValue, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;
}
