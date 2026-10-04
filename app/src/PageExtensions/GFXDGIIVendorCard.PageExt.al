pageextension 70113 "GFX DGII Vendor Card" extends "Vendor Card"
{
    layout
    {
        addlast(Invoicing)
        {
            field("GFX DGII Status"; Rec."GFX DGII Status")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the taxpayer status returned by DGII on the last lookup.';
            }
            field("GFX DGII Checked At"; Rec."GFX DGII Checked At")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies when the vendor was last looked up in DGII.';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(GFXLookUpDGII)
            {
                ApplicationArea = All;
                Caption = 'Look Up in DGII';
                ToolTip = 'Look up the RNC/Cédula of this vendor in the DGII taxpayer registry.';
                Image = Find;

                trigger OnAction()
                var
                    DGIITaxIdMgt: Codeunit "GFX DGII Tax ID Mgt.";
                begin
                    DGIITaxIdMgt.LookUpVendor(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(GFXLookUpDGII_Promoted; GFXLookUpDGII)
            {
            }
        }
    }
}
