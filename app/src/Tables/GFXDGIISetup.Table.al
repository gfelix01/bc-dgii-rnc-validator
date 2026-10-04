/// <summary>
/// Single-record setup. The lookup endpoint is configurable because DGII does not publish
/// an official REST API; the default points to a free public mirror of the registry.
/// </summary>
table 70100 "GFX DGII Setup"
{
    Caption = 'DGII Validator Setup';
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "API Base URL"; Text[250])
        {
            Caption = 'API Base URL';
            InitValue = 'https://rnc.megaplus.com.do/api/consulta';
            ExtendedDatatype = URL;
        }
        field(3; "Timeout (ms)"; Integer)
        {
            Caption = 'Timeout (ms)';
            InitValue = 10000;
            MinValue = 1000;
        }
        field(4; "Check Digit Warning"; Boolean)
        {
            Caption = 'Warn on Invalid Check Digit';
            InitValue = true;
        }
        field(5; "Ask to Update Name"; Boolean)
        {
            Caption = 'Ask to Update Name';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        RecordHasBeenRead: Boolean;

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        RecordHasBeenRead := true;
    end;
}
