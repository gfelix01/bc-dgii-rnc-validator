page 70111 "GFX DGII Taxpayer Info"
{
    Caption = 'DGII Taxpayer';
    PageType = Card;
    SourceTable = "GFX DGII Taxpayer";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Taxpayer';

                field("Tax ID Formatted"; Rec."Tax ID Formatted")
                {
                    ToolTip = 'Specifies the RNC or Cédula as registered in DGII.';
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the legal name (razón social) registered in DGII.';
                }
                field("Trade Name"; Rec."Trade Name")
                {
                    ToolTip = 'Specifies the trade name (nombre comercial) registered in DGII.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the taxpayer status in DGII.';
                    StyleExpr = StatusStyle;
                }
            }
            group(Tax)
            {
                Caption = 'Tax Details';

                field("Payment Regime"; Rec."Payment Regime")
                {
                    ToolTip = 'Specifies the payment regime of the taxpayer.';
                }
                field("Electronic Invoicer"; Rec."Electronic Invoicer")
                {
                    ToolTip = 'Specifies whether the taxpayer is an authorized electronic invoice (e-CF) issuer.';
                }
                field("Local Administration"; Rec."Local Administration")
                {
                    ToolTip = 'Specifies the DGII local office that manages the taxpayer.';
                }
                field("Economic Activity"; Rec."Economic Activity")
                {
                    ToolTip = 'Specifies the main economic activity of the taxpayer.';
                    MultiLine = true;
                }
            }
        }
    }

    var
        StatusStyle: Text;

    procedure SetTaxpayer(var TempTaxpayer: Record "GFX DGII Taxpayer" temporary)
    begin
        Rec.Copy(TempTaxpayer, true);
    end;

    trigger OnAfterGetRecord()
    begin
        if UpperCase(Rec.Status) = 'ACTIVO' then
            StatusStyle := Format(PageStyle::Favorable)
        else
            StatusStyle := Format(PageStyle::Unfavorable);
    end;
}
