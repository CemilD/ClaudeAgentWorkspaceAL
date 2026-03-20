permissionset 60100 "CDE PriceList Import"
{
    Assignable = true;
    Caption = 'CDE Price List Import';
    Permissions =
        tabledata "Price List Header" = RIM,
        tabledata "Price List Line" = RIM,
        tabledata Item = R,
        tabledata "Item Variant" = R,
        tabledata "No. Series" = R,
        tabledata "No. Series Line" = RM,
        tabledata Company = R,
        tabledata "CDE Price Import Log" = RIMD,
        tabledata "CDE Price Header Buffer" = RIMD,
        tabledata "CDE Price Line Buffer" = RIMD,
        tabledata "CDE Import Params" = RIMD,
        tabledata "CDE Company Selection Buffer" = RIMD;
}
