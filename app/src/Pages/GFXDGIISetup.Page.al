page 70110 "GFX DGII Setup"
{
    Caption = 'DGII Validator Setup';
    PageType = Card;
    SourceTable = "GFX DGII Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Connection)
            {
                Caption = 'Connection';

                field("API Base URL"; Rec."API Base URL")
                {
                    ToolTip = 'Specifies the endpoint used to look up taxpayers. The RNC/Cédula is sent as the "rnc" query parameter.';
                }
                field("Timeout (ms)"; Rec."Timeout (ms)")
                {
                    ToolTip = 'Specifies how long to wait for the lookup service, in milliseconds.';
                }
            }
            group(Behavior)
            {
                Caption = 'Behavior';

                field("Check Digit Warning"; Rec."Check Digit Warning")
                {
                    ToolTip = 'Specifies whether to show a notification when a VAT Registration No. has an invalid RNC/Cédula check digit.';
                }
                field("Ask to Update Name"; Rec."Ask to Update Name")
                {
                    ToolTip = 'Specifies whether to offer replacing the customer or vendor name with the legal name registered in DGII.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetRecordOnce();
    end;
}
