tableextension 70103 "GFX DGII Vendor" extends Vendor
{
    fields
    {
        field(70100; "GFX DGII Status"; Text[50])
        {
            Caption = 'DGII Status';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70101; "GFX DGII Checked At"; DateTime)
        {
            Caption = 'DGII Checked At';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
