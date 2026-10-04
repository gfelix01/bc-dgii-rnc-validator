/// <summary>
/// In-memory result of a DGII lookup. Never stored in the database.
/// </summary>
table 70101 "GFX DGII Taxpayer"
{
    Caption = 'DGII Taxpayer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Tax ID"; Text[11])
        {
            Caption = 'RNC / Cédula';
        }
        field(2; "Tax ID Formatted"; Text[20])
        {
            Caption = 'RNC / Cédula (formatted)';
        }
        field(3; Name; Text[250])
        {
            Caption = 'Legal Name';
        }
        field(4; "Trade Name"; Text[250])
        {
            Caption = 'Trade Name';
        }
        field(5; Status; Text[50])
        {
            Caption = 'Status';
        }
        field(6; "Payment Regime"; Text[50])
        {
            Caption = 'Payment Regime';
        }
        field(7; "Economic Activity"; Text[250])
        {
            Caption = 'Economic Activity';
        }
        field(8; "Local Administration"; Text[100])
        {
            Caption = 'Local Administration';
        }
        field(9; "Electronic Invoicer"; Text[10])
        {
            Caption = 'Electronic Invoicer (e-CF)';
        }
    }

    keys
    {
        key(PK; "Tax ID")
        {
            Clustered = true;
        }
    }
}
