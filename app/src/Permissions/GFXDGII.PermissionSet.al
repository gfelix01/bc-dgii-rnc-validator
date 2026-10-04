permissionset 70140 "GFX DGII"
{
    Caption = 'DGII RNC Validator';
    Assignable = true;

    Permissions =
        table "GFX DGII Setup" = X,
        tabledata "GFX DGII Setup" = RIM,
        table "GFX DGII Taxpayer" = X,
        tabledata "GFX DGII Taxpayer" = RIMD,
        codeunit "GFX DGII Tax ID Mgt." = X,
        codeunit "GFX DGII Subscribers" = X,
        page "GFX DGII Setup" = X,
        page "GFX DGII Taxpayer Info" = X;
}
