table 60106 "CDE Price Header Buffer"
{
    Caption = 'CDE Price Header Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
        }
        field(2; "Description"; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(3; "Source Type"; Enum "Price Source Type")
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
        }
        field(4; "Source No."; Code[20])
        {
            Caption = 'Source No.';
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
        // Currency Code intentionally NOT included — always use company currency
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
