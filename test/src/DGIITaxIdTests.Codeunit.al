codeunit 70150 "GFX DGII Tax ID Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        DGIITaxIdMgt: Codeunit "GFX DGII Tax ID Mgt.";
        LookupMock: Codeunit "GFX DGII Lookup Mock";

    // ---------- Normalization and formatting ----------

    [Test]
    procedure NormalizeRemovesDashesAndSpaces()
    begin
        Assert.AreEqual('401506254', DGIITaxIdMgt.NormalizeTaxId(' 4-01-50625-4 '), 'RNC was not normalized.');
        Assert.AreEqual('40223456787', DGIITaxIdMgt.NormalizeTaxId('402-2345678-7'), 'Cédula was not normalized.');
    end;

    [Test]
    procedure FormatTaxIdUsesDGIIMasks()
    begin
        Assert.AreEqual('4-01-50625-4', DGIITaxIdMgt.FormatTaxId('401506254'), 'Wrong RNC format.');
        Assert.AreEqual('402-2345678-7', DGIITaxIdMgt.FormatTaxId('40223456787'), 'Wrong Cédula format.');
    end;

    // ---------- Check digit ----------

    [Test]
    procedure ValidRncPassesCheckDigit()
    begin
        Assert.IsTrue(DGIITaxIdMgt.IsValidTaxId('401506254'), '401506254 should be a valid RNC.');
        Assert.IsTrue(DGIITaxIdMgt.IsValidTaxId('131246796'), '131246796 should be a valid RNC.');
    end;

    [Test]
    procedure InvalidRncFailsCheckDigit()
    begin
        Assert.IsFalse(DGIITaxIdMgt.IsValidTaxId('401506255'), '401506255 should be rejected.');
    end;

    [Test]
    procedure ValidCedulaPassesCheckDigit()
    begin
        Assert.IsTrue(DGIITaxIdMgt.IsValidTaxId('40223456787'), '40223456787 should be a valid Cédula.');
    end;

    [Test]
    procedure InvalidCedulaFailsCheckDigit()
    begin
        Assert.IsFalse(DGIITaxIdMgt.IsValidTaxId('40223456780'), '40223456780 should be rejected.');
    end;

    [Test]
    procedure WrongLengthIsInvalid()
    begin
        Assert.IsFalse(DGIITaxIdMgt.IsValidTaxId('12345'), 'A 5-digit value should be rejected.');
    end;

    // ---------- Response parsing ----------

    [Test]
    procedure ParseResponseMapsAllFields()
    var
        TempTaxpayer: Record "GFX DGII Taxpayer" temporary;
    begin
        Assert.IsTrue(DGIITaxIdMgt.ParseResponse('131246796', SampleResponse(), TempTaxpayer), 'Response should be parsed as found.');
        Assert.AreEqual('EMPRESA DEMO SRL', TempTaxpayer.Name, 'Legal name');
        Assert.AreEqual('DEMO', TempTaxpayer."Trade Name", 'Trade name');
        Assert.AreEqual('ACTIVO', TempTaxpayer.Status, 'Status');
        Assert.AreEqual('NORMAL', TempTaxpayer."Payment Regime", 'Payment regime');
        Assert.AreEqual('SI', TempTaxpayer."Electronic Invoicer", 'Electronic invoicer');
    end;

    [Test]
    procedure ParseResponseHandlesNullsAndFormatsTaxId()
    var
        TempTaxpayer: Record "GFX DGII Taxpayer" temporary;
    begin
        Assert.IsTrue(DGIITaxIdMgt.ParseResponse('131246796', '{"nombre_razon_social":"EMPRESA DEMO SRL","nombre_comercial":null,"cedula_rnc":null}', TempTaxpayer), 'Response should be parsed as found.');
        Assert.AreEqual('', TempTaxpayer."Trade Name", 'Null should become empty text.');
        Assert.AreEqual('1-31-24679-6', TempTaxpayer."Tax ID Formatted", 'Missing formatted id should be built locally.');
    end;

    [Test]
    procedure ParseResponseWithoutNameMeansNotFound()
    var
        TempTaxpayer: Record "GFX DGII Taxpayer" temporary;
    begin
        Assert.IsFalse(DGIITaxIdMgt.ParseResponse('131246796', '{"estado":null}', TempTaxpayer), 'A response without name should mean not found.');
    end;

    [Test]
    procedure ParseInvalidJsonRaisesError()
    var
        TempTaxpayer: Record "GFX DGII Taxpayer" temporary;
    begin
        asserterror DGIITaxIdMgt.ParseResponse('131246796', '<html>Service unavailable</html>', TempTaxpayer);
        Assert.ExpectedError('could not be read');
    end;

    // ---------- Customer flow (lookup mocked, no internet) ----------

    [Test]
    [HandlerFunctions('TaxpayerInfoHandler,AcceptConfirmHandler')]
    procedure LookUpCustomerStoresStatusAndUpdatesName()
    var
        Customer: Record Customer;
    begin
        // [GIVEN] A customer with a registered RNC and a different name
        CreateCustomer(Customer, '1-31-24679-6', 'Demo');
        LookupMock.SetFound(true);
        BindSubscription(LookupMock);

        // [WHEN] The user looks it up and accepts the DGII name
        DGIITaxIdMgt.LookUpCustomer(Customer);
        UnbindSubscription(LookupMock);

        // [THEN] Status, timestamp and legal name are stored
        Customer.Get(Customer."No.");
        Assert.AreEqual('ACTIVO', Customer."GFX DGII Status", 'DGII status was not stored.');
        Assert.AreNotEqual(0DT, Customer."GFX DGII Checked At", 'Checked At was not stored.');
        Assert.AreEqual('EMPRESA DEMO SRL', Customer.Name, 'Name was not updated.');
    end;

    [Test]
    [HandlerFunctions('NotRegisteredMessageHandler')]
    procedure LookUpUnknownCustomerMarksNotRegistered()
    var
        Customer: Record Customer;
    begin
        // [GIVEN] A customer whose RNC is not in DGII
        CreateCustomer(Customer, '131246796', 'Ghost Company');
        LookupMock.SetFound(false);
        BindSubscription(LookupMock);

        // [WHEN] The user looks it up
        DGIITaxIdMgt.LookUpCustomer(Customer);
        UnbindSubscription(LookupMock);

        // [THEN] The customer is flagged and the name is untouched
        Customer.Get(Customer."No.");
        Assert.AreEqual('NOT REGISTERED', Customer."GFX DGII Status", 'Customer should be flagged as not registered.');
        Assert.AreEqual('Ghost Company', Customer.Name, 'Name should not change.');
    end;

    [Test]
    procedure LookUpWithoutTaxIdFails()
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer, '', 'No Tax Id');
        asserterror DGIITaxIdMgt.LookUpCustomer(Customer);
        Assert.ExpectedError('Fill in the VAT Registration No.');
    end;

    local procedure CreateCustomer(var Customer: Record Customer; VATRegistrationNo: Text[20]; CustomerName: Text[100])
    begin
        Customer.Init();
        Customer."No." := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(Customer."No."));
        Customer.Name := CustomerName;
        Customer."VAT Registration No." := VATRegistrationNo;
        Customer.Insert(false);
    end;

    local procedure SampleResponse(): Text
    begin
        exit('{"cedula_rnc":"1-31-24679-6","nombre_razon_social":"EMPRESA DEMO SRL","nombre_comercial":"DEMO","estado":"ACTIVO",' +
             '"regimen_de_pagos":"NORMAL","actividad_economica":"SERVICIOS DE CONSULTORIA","administracion_local":"ADM LOCAL GGC","facturador_electronico":"SI"}');
    end;

    [ModalPageHandler]
    procedure TaxpayerInfoHandler(var TaxpayerInfo: TestPage "GFX DGII Taxpayer Info")
    begin
        TaxpayerInfo.Name.AssertEquals('EMPRESA DEMO SRL');
    end;

    [ConfirmHandler]
    procedure AcceptConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure NotRegisteredMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage('is not registered in DGII', Message);
    end;
}
