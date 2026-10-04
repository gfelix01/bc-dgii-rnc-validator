codeunit 70131 "GFX DGII Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterValidateEvent', 'VAT Registration No.', false, false)]
    local procedure CheckCustomerTaxId(var Rec: Record Customer)
    var
        DGIITaxIdMgt: Codeunit "GFX DGII Tax ID Mgt.";
    begin
        DGIITaxIdMgt.NotifyIfInvalidCheckDigit(Rec."VAT Registration No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterValidateEvent', 'VAT Registration No.', false, false)]
    local procedure CheckVendorTaxId(var Rec: Record Vendor)
    var
        DGIITaxIdMgt: Codeunit "GFX DGII Tax ID Mgt.";
    begin
        DGIITaxIdMgt.NotifyIfInvalidCheckDigit(Rec."VAT Registration No.");
    end;
}
