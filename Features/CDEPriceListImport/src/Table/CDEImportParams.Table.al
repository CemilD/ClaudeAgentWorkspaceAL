table 60109 "CDE Import Params"
{
    Caption = 'CDE Import Params';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Import Mode"; Option)
        {
            Caption = 'Import Mode';
            DataClassification = SystemMetadata;
            OptionMembers = NewList,ModifyExisting;
            OptionCaption = 'New Price List,Modify Existing';
        }
        field(3; "No. Series Code"; Code[20])
        {
            Caption = 'No. Series Code';
            DataClassification = SystemMetadata;
        }
        field(4; "Existing Price List Code"; Code[20])
        {
            Caption = 'Existing Price List Code';
            DataClassification = SystemMetadata;
        }
        field(5; "Source Type"; Enum "Price Source Type")
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            DataClassification = SystemMetadata;
        }
        field(7; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = SystemMetadata;
        }
        field(8; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = SystemMetadata;
        }
        field(9; "Description"; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(10; "All Companies"; Boolean)
        {
            Caption = 'All Companies';
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
