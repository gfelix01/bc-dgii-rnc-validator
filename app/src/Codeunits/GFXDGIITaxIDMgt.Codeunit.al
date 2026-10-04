/// <summary>
/// Dominican tax ID (RNC / Cédula) logic: normalization, local check-digit validation,
/// registry lookup and the customer/vendor flows that use them.
/// </summary>
codeunit 70130 "GFX DGII Tax ID Mgt."
{
    var
        NoTaxIdErr: Label 'Fill in the VAT Registration No. (RNC or Cédula) before looking it up in DGII.';
        InvalidLengthErr: Label '%1 is not a valid RNC (9 digits) or Cédula (11 digits).', Comment = '%1 = Tax ID';
        ConnectionErr: Label 'Could not connect to the DGII lookup service. Check that "Allow HttpClient Requests" is enabled for this extension.\\Details: %1', Comment = '%1 = Error text';
        HttpErr: Label 'The DGII lookup service returned an error: %1 %2.', Comment = '%1 = HTTP status code, %2 = Reason phrase';
        InvalidResponseErr: Label 'The DGII lookup service returned a response that could not be read.';
        NotRegisteredMsg: Label '%1 is not registered in DGII.', Comment = '%1 = Tax ID';
        NotRegisteredTxt: Label 'NOT REGISTERED';
        UpdateNameQst: Label 'The legal name in DGII is:\\%1\\Do you want to use it as the name?', Comment = '%1 = Legal name';
        InvalidCheckDigitMsg: Label '%1 does not have a valid RNC/Cédula check digit. Please verify it.', Comment = '%1 = Tax ID';
        CheckDigitNotificationIdTok: Label '7819665d-3614-48d8-a4d4-f370f63b6783', Locked = true;
        DigitsTok: Label '0123456789', Locked = true;
        RncWeightsTok: Label '79865432', Locked = true;

    procedure LookUpCustomer(var Customer: Record Customer)
    var
        TempTaxpayer: Record "GFX DGII Taxpayer" temporary;
        NewName: Text[100];
    begin
        if RunInteractiveLookup(Customer."VAT Registration No.", Customer.Name, TempTaxpayer, NewName) then begin
            Customer."GFX DGII Status" := TempTaxpayer.Status;
            if NewName <> Customer.Name then
                Customer.Validate(Name, NewName);
        end else
            Customer."GFX DGII Status" := NotRegisteredTxt;
        Customer."GFX DGII Checked At" := CurrentDateTime();
        Customer.Modify(true);
    end;

    procedure LookUpVendor(var Vendor: Record Vendor)
    var
        TempTaxpayer: Record "GFX DGII Taxpayer" temporary;
        NewName: Text[100];
    begin
        if RunInteractiveLookup(Vendor."VAT Registration No.", Vendor.Name, TempTaxpayer, NewName) then begin
            Vendor."GFX DGII Status" := TempTaxpayer.Status;
            if NewName <> Vendor.Name then
                Vendor.Validate(Name, NewName);
        end else
            Vendor."GFX DGII Status" := NotRegisteredTxt;
        Vendor."GFX DGII Checked At" := CurrentDateTime();
        Vendor.Modify(true);
    end;

    /// <summary>
    /// Looks up a tax ID in the registry. Returns false when the taxpayer does not exist.
    /// Technical failures (network, HTTP errors, unreadable response) raise an error.
    /// </summary>
    procedure LookupTaxpayer(TaxId: Text[11]; var TempTaxpayer: Record "GFX DGII Taxpayer" temporary): Boolean
    var
        Setup: Record "GFX DGII Setup";
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
        Found: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeLookupTaxpayer(TaxId, TempTaxpayer, Found, IsHandled);
        if IsHandled then
            exit(Found);

        Setup.GetRecordOnce();
        Setup.TestField("API Base URL");
        Client.Timeout(Setup."Timeout (ms)");

        if not Client.Get(Setup."API Base URL" + '?rnc=' + TaxId, Response) then
            Error(ConnectionErr, GetLastErrorText());

        if Response.HttpStatusCode() = 404 then
            exit(false);
        if not Response.IsSuccessStatusCode() then
            Error(HttpErr, Response.HttpStatusCode(), Response.ReasonPhrase());

        Response.Content().ReadAs(ResponseText);
        exit(ParseResponse(TaxId, ResponseText, TempTaxpayer));
    end;

    /// <summary>
    /// Keeps only the digits: "1-01-01063-2" becomes "101010632".
    /// </summary>
    procedure NormalizeTaxId(Value: Text): Text
    begin
        exit(DelChr(Value, '=', DelChr(Value, '=', DigitsTok)));
    end;

    /// <summary>
    /// Validates the check digit locally: modulus 11 for RNC (9 digits), Luhn for Cédula (11 digits).
    /// Expects a normalized tax ID.
    /// </summary>
    procedure IsValidTaxId(TaxId: Text): Boolean
    begin
        case StrLen(TaxId) of
            9:
                exit(IsValidRnc(TaxId));
            11:
                exit(IsValidCedula(TaxId));
        end;
        exit(false);
    end;

    /// <summary>
    /// RNC: X-XX-XXXXX-X. Cédula: XXX-XXXXXXX-X. Anything else is returned unchanged.
    /// </summary>
    procedure FormatTaxId(TaxId: Text): Text
    begin
        case StrLen(TaxId) of
            9:
                exit(StrSubstNo('%1-%2-%3-%4', CopyStr(TaxId, 1, 1), CopyStr(TaxId, 2, 2), CopyStr(TaxId, 4, 5), CopyStr(TaxId, 9, 1)));
            11:
                exit(StrSubstNo('%1-%2-%3', CopyStr(TaxId, 1, 3), CopyStr(TaxId, 4, 7), CopyStr(TaxId, 11, 1)));
        end;
        exit(TaxId);
    end;

    procedure NotifyIfInvalidCheckDigit(VATRegistrationNo: Text)
    var
        Setup: Record "GFX DGII Setup";
        CheckDigitNotification: Notification;
        TaxId: Text;
    begin
        if not GuiAllowed() then
            exit;
        TaxId := NormalizeTaxId(VATRegistrationNo);
        if TaxId = '' then
            exit;
        Setup.GetRecordOnce();
        if not Setup."Check Digit Warning" then
            exit;
        if IsValidTaxId(TaxId) then
            exit;

        CheckDigitNotification.Id := CheckDigitNotificationIdTok;
        CheckDigitNotification.Message := StrSubstNo(InvalidCheckDigitMsg, VATRegistrationNo);
        CheckDigitNotification.Scope := NotificationScope::LocalScope;
        CheckDigitNotification.Send();
    end;

    internal procedure ParseResponse(TaxId: Text[11]; ResponseText: Text; var TempTaxpayer: Record "GFX DGII Taxpayer" temporary): Boolean
    var
        Json: JsonObject;
    begin
        if not Json.ReadFrom(ResponseText) then
            Error(InvalidResponseErr);

        TempTaxpayer.Reset();
        TempTaxpayer.DeleteAll();
        TempTaxpayer.Init();
        TempTaxpayer."Tax ID" := TaxId;
        TempTaxpayer."Tax ID Formatted" := CopyStr(GetJsonText(Json, 'cedula_rnc'), 1, MaxStrLen(TempTaxpayer."Tax ID Formatted"));
        TempTaxpayer.Name := CopyStr(GetJsonText(Json, 'nombre_razon_social'), 1, MaxStrLen(TempTaxpayer.Name));
        TempTaxpayer."Trade Name" := CopyStr(GetJsonText(Json, 'nombre_comercial'), 1, MaxStrLen(TempTaxpayer."Trade Name"));
        TempTaxpayer.Status := CopyStr(GetJsonText(Json, 'estado'), 1, MaxStrLen(TempTaxpayer.Status));
        TempTaxpayer."Payment Regime" := CopyStr(GetJsonText(Json, 'regimen_de_pagos'), 1, MaxStrLen(TempTaxpayer."Payment Regime"));
        TempTaxpayer."Economic Activity" := CopyStr(GetJsonText(Json, 'actividad_economica'), 1, MaxStrLen(TempTaxpayer."Economic Activity"));
        TempTaxpayer."Local Administration" := CopyStr(GetJsonText(Json, 'administracion_local'), 1, MaxStrLen(TempTaxpayer."Local Administration"));
        TempTaxpayer."Electronic Invoicer" := CopyStr(GetJsonText(Json, 'facturador_electronico'), 1, MaxStrLen(TempTaxpayer."Electronic Invoicer"));

        if TempTaxpayer.Name = '' then
            exit(false);

        if TempTaxpayer."Tax ID Formatted" = '' then
            TempTaxpayer."Tax ID Formatted" := CopyStr(FormatTaxId(TaxId), 1, MaxStrLen(TempTaxpayer."Tax ID Formatted"));
        TempTaxpayer.Insert();
        exit(true);
    end;

    local procedure RunInteractiveLookup(VATRegistrationNo: Text; CurrentName: Text[100]; var TempTaxpayer: Record "GFX DGII Taxpayer" temporary; var NewName: Text[100]): Boolean
    var
        Setup: Record "GFX DGII Setup";
        TaxpayerPage: Page "GFX DGII Taxpayer Info";
        NormalizedTaxId: Text;
        TaxId: Text[11];
    begin
        NewName := CurrentName;
        NormalizedTaxId := NormalizeTaxId(VATRegistrationNo);
        if NormalizedTaxId = '' then
            Error(NoTaxIdErr);
        if not (StrLen(NormalizedTaxId) in [9, 11]) then
            Error(InvalidLengthErr, VATRegistrationNo);
        TaxId := CopyStr(NormalizedTaxId, 1, MaxStrLen(TaxId));

        if not LookupTaxpayer(TaxId, TempTaxpayer) then begin
            Message(NotRegisteredMsg, FormatTaxId(TaxId));
            exit(false);
        end;

        TaxpayerPage.SetTaxpayer(TempTaxpayer);
        TaxpayerPage.RunModal();

        Setup.GetRecordOnce();
        if Setup."Ask to Update Name" and (UpperCase(CurrentName) <> UpperCase(TempTaxpayer.Name)) then
            if Confirm(UpdateNameQst, false, TempTaxpayer.Name) then
                NewName := CopyStr(TempTaxpayer.Name, 1, MaxStrLen(NewName));
        exit(true);
    end;

    local procedure IsValidRnc(Rnc: Text): Boolean
    var
        i: Integer;
        Total: Integer;
        Remainder: Integer;
        CheckDigit: Integer;
    begin
        for i := 1 to 8 do
            Total += DigitAt(Rnc, i) * DigitAt(RncWeightsTok, i);
        Remainder := Total mod 11;
        case Remainder of
            0:
                CheckDigit := 2;
            1:
                CheckDigit := 1;
            else
                CheckDigit := 11 - Remainder;
        end;
        exit(CheckDigit = DigitAt(Rnc, 9));
    end;

    local procedure IsValidCedula(Cedula: Text): Boolean
    var
        i: Integer;
        Product: Integer;
        Total: Integer;
    begin
        // Luhn: weights 1,2,1,2... on the first 10 digits, two-digit products are reduced by 9.
        for i := 1 to 10 do begin
            Product := DigitAt(Cedula, i) * (1 + ((i - 1) mod 2));
            if Product > 9 then
                Product -= 9;
            Total += Product;
        end;
        exit((10 - (Total mod 10)) mod 10 = DigitAt(Cedula, 11));
    end;

    local procedure DigitAt(Value: Text; Position: Integer): Integer
    begin
        exit(StrPos(DigitsTok, CopyStr(Value, Position, 1)) - 1);
    end;

    local procedure GetJsonText(Json: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Json.Get(KeyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    /// <summary>
    /// Lets another extension replace the lookup provider, or lets tests run without calling the internet.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupTaxpayer(TaxId: Text[11]; var TempTaxpayer: Record "GFX DGII Taxpayer" temporary; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;
}
