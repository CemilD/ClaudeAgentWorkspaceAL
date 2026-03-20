table 60107 "CDE Price Line Buffer"
{
    Caption = 'CDE Price Line Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Price List Code"; Code[20])
        {
            Caption = 'Price List Code';
            DataClassification = SystemMetadata;
        }
        field(3; "Asset No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
        }
        field(5; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = SystemMetadata;
        }
        field(6; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = SystemMetadata;
        }
        field(7; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
        }
        field(8; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DataClassification = SystemMetadata;
        }
        field(9; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = SystemMetadata;
        }
        field(10; "Validation Status"; Option)
        {
            Caption = 'Validation Status';
            DataClassification = SystemMetadata;
            OptionMembers = " ",Error,Warning;
            OptionCaption = ' ,Error,Warning';
        }
        field(11; "Error Message"; Text[500])
        {
            Caption = 'Error Message';
            DataClassification = SystemMetadata;
        }
        field(12; "Skip Import"; Boolean)
        {
            Caption = 'Skip Import';
            DataClassification = SystemMetadata;
        }
        field(13; "CDE Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            DataClassification = SystemMetadata;
        }
        field(14; "CDE Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            DataClassification = SystemMetadata;
        }
        field(15; "CDE Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';
            DataClassification = SystemMetadata;
        }
        field(16; "CDE VAT Bus. Post. Gr."; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
