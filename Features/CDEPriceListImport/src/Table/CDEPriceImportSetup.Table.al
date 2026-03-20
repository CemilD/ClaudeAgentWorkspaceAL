table 60111 "CDE Price Import Setup"
{
    Caption = 'CDE Price Import Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "No. Series Code"; Code[20])
        {
            Caption = 'No. Series Code';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(3; "Allow Manual Code"; Boolean)
        {
            Caption = 'Allow Manual Code';
            DataClassification = CustomerContent;
        }
        field(4; "Default Source Type"; Enum "Price Source Type")
        {
            Caption = 'Default Source Type';
            DataClassification = CustomerContent;
        }
        field(5; "Default Allow Invoice Disc."; Boolean)
        {
            Caption = 'Default Allow Invoice Disc.';
            DataClassification = CustomerContent;
        }
        field(6; "Default Allow Line Disc."; Boolean)
        {
            Caption = 'Default Allow Line Disc.';
            DataClassification = CustomerContent;
        }
        field(7; "Default Price Includes VAT"; Boolean)
        {
            Caption = 'Default Price Includes VAT';
            DataClassification = CustomerContent;
        }
        field(8; "Default VAT Bus. Post. Gr."; Code[20])
        {
            Caption = 'Default VAT Bus. Posting Gr. (Price)';
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group";
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;
}
