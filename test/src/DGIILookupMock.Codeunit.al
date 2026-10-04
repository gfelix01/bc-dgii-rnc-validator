/// <summary>
/// Replaces the HTTP lookup during tests, so they are fast and do not depend on the internet.
/// </summary>
codeunit 70151 "GFX DGII Lookup Mock"
{
    EventSubscriberInstance = Manual;

    var
        ReturnFound: Boolean;

    procedure SetFound(NewReturnFound: Boolean)
    begin
        ReturnFound := NewReturnFound;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GFX DGII Tax ID Mgt.", 'OnBeforeLookupTaxpayer', '', false, false)]
    local procedure MockLookup(TaxId: Text[11]; var TempTaxpayer: Record "GFX DGII Taxpayer" temporary; var Found: Boolean; var IsHandled: Boolean)
    begin
        IsHandled := true;
        Found := ReturnFound;
        if not ReturnFound then
            exit;

        TempTaxpayer.Init();
        TempTaxpayer."Tax ID" := TaxId;
        TempTaxpayer."Tax ID Formatted" := '1-31-24679-6';
        TempTaxpayer.Name := 'EMPRESA DEMO SRL';
        TempTaxpayer.Status := 'ACTIVO';
        TempTaxpayer.Insert();
    end;
}
