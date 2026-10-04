tableextension 70102 "GFX DGII Customer" extends Customer
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
