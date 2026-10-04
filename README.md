# DGII RNC Validator for Business Central

[![CI/CD](https://github.com/gfelix01/bc-dgii-rnc-validator/actions/workflows/CICD.yaml/badge.svg)](https://github.com/gfelix01/bc-dgii-rnc-validator/actions/workflows/CICD.yaml)

> **ES:** Extensión para Microsoft Dynamics 365 Business Central que consulta el RNC o la Cédula de clientes y proveedores en el registro de contribuyentes de la DGII (República Dominicana), valida el dígito verificador localmente y guarda el estado DGII en la ficha.

Validate Dominican Republic tax IDs (RNC and Cédula) inside Business Central: local check-digit validation plus a lookup in the DGII taxpayer registry, from the customer and vendor cards.

## Features

- **Look Up in DGII** action on the Customer Card and Vendor Card.
  - Shows legal name, trade name, status, payment regime, economic activity, local office and whether the taxpayer is an authorized **e-CF** issuer.
  - Offers to replace the name with the legal name registered in DGII.
  - Stores the DGII status and the date of the last check on the card.
- **Local check-digit validation** when the VAT Registration No. is entered: modulus 11 for RNC, Luhn for Cédula. Invalid values show a non-blocking notification.
- **Accepts any format**: `401506254`, `4-01-50625-4` or `4 01 50625 4` are all normalized.
- **Configurable endpoint**: DGII does not publish an official REST API, so the lookup URL lives in a setup page instead of the code.
- **Replaceable provider**: the `OnBeforeLookupTaxpayer` integration event lets another extension plug in a different source (a paid service, a local copy of the DGII registry file, etc.).
- **Tested without the internet**: tests mock the lookup through that same event.

## How it works

```
Customer / Vendor Card ── Look Up in DGII
            │
            ▼
Codeunit 70130 "GFX DGII Tax ID Mgt."
  1. Normalize   "4-01-50625-4" → "401506254"
  2. Validate    9 or 11 digits
  3. Lookup      OnBeforeLookupTaxpayer (mockable) → HTTP GET → ParseResponse
  4. Show        Page 70111 "GFX DGII Taxpayer Info"
  5. Store       DGII Status + Checked At, optional name update
```

## Objects

| Type | ID | Name |
|---|---|---|
| Table | 70100 | GFX DGII Setup |
| Table (temporary) | 70101 | GFX DGII Taxpayer |
| Table Extension | 70102 | GFX DGII Customer |
| Table Extension | 70103 | GFX DGII Vendor |
| Page | 70110 | GFX DGII Setup |
| Page | 70111 | GFX DGII Taxpayer Info |
| Page Extension | 70112 | GFX DGII Customer Card |
| Page Extension | 70113 | GFX DGII Vendor Card |
| Codeunit | 70130 | GFX DGII Tax ID Mgt. |
| Codeunit | 70131 | GFX DGII Subscribers |
| Permission Set | 70140 | GFX DGII |
| Test Codeunit | 70150 | GFX DGII Tax ID Tests (test app) |
| Codeunit | 70151 | GFX DGII Lookup Mock (test app) |

## Getting started

1. Open `app/` in VS Code with the AL Language extension, set your sandbox in `.vscode/launch.json`, download symbols and publish.
2. In **Extension Management**, open the extension settings and turn on **Allow HttpClient Requests** (required for any extension that calls external services in a sandbox).
3. Search for **DGII Validator Setup** and review the endpoint. The default is a free public mirror of the DGII registry.
4. Assign the **GFX DGII** permission set.
5. Open a customer or vendor with a VAT Registration No. and choose **Look Up in DGII**.

### Tests

Open `test/`, download symbols (depends on the main app and Microsoft's *Library Assert*), publish and run codeunit 70150 from the **Test Tool** page or the AL Test Runner extension.

They cover normalization, formatting, RNC and Cédula check digits, response parsing (including nulls and invalid JSON), and the full customer lookup flow with modal page, confirm and message handlers.

## Notes

- The check digit is only a warning, never a block: a small number of old Cédulas issued before the current numbering do not follow the Luhn rule.
- The lookup service is a third-party mirror, not an official DGII API. For production use, review its terms or plug in your own provider through `OnBeforeLookupTaxpayer`.

## About me

Gabriel Félix — Business Central AL developer based in the Dominican Republic.
I build AL extensions, integrations and Dominican localization features (NCF, e-CF, ITBIS) for Microsoft partners and companies.

- Web: [gabrielfelix.tech](https://gabrielfelix.tech)
- LinkedIn: [linkedin.com/in/gabriel-felix-paez](https://www.linkedin.com/in/gabriel-felix-paez)

## License

MIT
