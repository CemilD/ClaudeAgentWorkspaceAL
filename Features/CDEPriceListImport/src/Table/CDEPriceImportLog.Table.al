table 60100 "CDE Price Import Log"
{
    Caption = 'CDE Price Import Log';
    DataClassification = SystemMetadata;
    LookupPageId = "CDE Price Import Log List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Import Date Time"; DateTime)
        {
            Caption = 'Timestamp';
            DataClassification = SystemMetadata;
        }
        field(3; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(5; "Price List Code"; Code[20])
        {
            Caption = 'Price List Code';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(6; "Source Price List Code"; Code[20])
        {
            Caption = 'Source Price List Code';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(7; "Lines Imported"; Integer)
        {
            Caption = 'Lines Imported';
            DataClassification = SystemMetadata;
        }
        field(8; "Lines Skipped"; Integer)
        {
            Caption = 'Lines Skipped';
            DataClassification = SystemMetadata;
        }
        field(9; "Status"; Option)
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
            OptionMembers = Successful,Partial,Error;
            OptionCaption = 'Successful,Partial,Error';
        }
        field(10; "Error Location"; Text[250])
        {
            Caption = 'Error Location';
            DataClassification = SystemMetadata;
        }
        field(11; "Error Message"; Text[500])
        {
            Caption = 'Error Message';
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
