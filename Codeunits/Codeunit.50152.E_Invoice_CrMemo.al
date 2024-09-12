

codeunit 50152 GST_Einvoice_CrMemo
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;
        gl_BillToPh: Code[12];
        //JsonLObj: JsonObject;
        gl_BillToEm: Text;

        SalesLineErr: Label 'E-Invoice allowes only 100 lines per Invoice. Curent transaction is having %1 lines.', Locked = true;
        GlobalNULL: Variant;
        CGSTLbl: Label 'CGST', Locked = true;
        SGSTLbl: label 'SGST', Locked = true;
        IGSTLbl: Label 'IGST', Locked = true;
        CESSLbl: Label 'CESS', Locked = true;

        DocumentNo: Code[50];

        OTHTxt: Label 'OTH';
        DocumentNoBlankErr: Label 'Document No. Blank';


    procedure GenerateIRN_01(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        txtDecryptedSek: text;
        GSTInv_DLL: DotNet GSTEncr_Decr;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        jsonObjectlinq: JsonObject;
        encryptedIRNPayload: text;
        finalPayload: text;
        JsonText: text;
        JObject: JsonObject;
        DocumentNo: Code[20];
        GSTManagement: Codeunit "e-Invoice Management";
        CU_Base64: Codeunit "Base64 Convert";
        base64IRN: text;
        CurrExRate: Decimal;
        JsonLObj: JsonObject;
        E_Invoice_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
    begin
        clear(GlobalNULL);

        DocumentNo := SalesCrMemoHeader."No.";

        IF GSTManagement.IsGSTApplicable(SalesCrMemoHeader."No.", 36) THEN BEGIN
            IF SalesCrMemoHeader."GST Customer Type" IN
                [SalesCrMemoHeader."GST Customer Type"::Unregistered,
                SalesCrMemoHeader."GST Customer Type"::" "] THEN
                ERROR('E-Invoicing is not applicable for Unregistered, Export and Deemed Export Customers.');

            IF SalesCrMemoHeader."Currency Factor" <> 0 THEN
                CurrExRate := 1 / SalesCrMemoHeader."Currency Factor"
            ELSE
                CurrExRate := 1;
        end;
        JObject.Add('Version', '1.1');//Later to be provided as setup.

        WriteTransDtls(JObject, SalesCrMemoHeader);
        WriteDocDtls(JObject, SalesCrMemoHeader);
        WriteSellerDtls(JObject, SalesCrMemoHeader);
        WriteBuyerDtls(JObject, SalesCrMemoHeader, gl_BillToPh, gl_BillToEm);
        WriteItemDtls(JObject, SalesCrMemoHeader, CurrExRate);
        WriteValDtls(JObject, SalesCrMemoHeader);
        WriteExpDtls(JObject, SalesCrMemoHeader);

        JObject.WriteTo(JsonText);

        E_Invoice_SalesInvoice.GenerateAuthToken();

        recAuthData.Get();


        // Message('DecryptedSEK %1', recAuthData.DecryptedSEK);
        txtDecryptedSek := recAuthData.DecryptedSEK;
        Message(JsonText);

        GSTInv_DLL := GSTInv_DLL.RSA_AES();

        encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(JsonText, txtDecryptedSek);
        // Message('EncryptedIRNPayload %1', encryptedIRNPayload);
        JsonLObj.Add('Data', encryptedIRNPayload);
        JsonLObj.WriteTo(finalPayload);
        Call_IRN_API(recAuthData, finalPayload, false, SalesCrMemoHeader);
        if DocumentNo = '' then
            Error(DocumentNoBlankErr);
    end;

    // procedure GenerateAuthToken(RecSalesCrMemo: Record "Sales Cr.Memo Header"): text;
    // var
    //     plainAppkey: text;
    //     jsonString: text;
    //     Myfile: File;
    //     encryptedPayload: text;
    //     Instream1: InStream;
    //     encoding: DotNet Encoding;
    //     GenLedSet: Record "General Ledger Setup";
    //     keyTxt: text;
    //     finPayload: text;
    //     GSTEncr_Decr: DotNet GSTEncr_Decr;
    //     encryptedPass: text;
    //     base64Payload: text;
    //     rec_GSTRegNos: Record "GST Registration Nos.";
    //     pass: label 'Barbeque@123';
    //     encryptedAppKey: text;
    //     bytearr: DotNet Array;
    //     recCustomer: Record Customer;
    //     GSTRegNos: Record "GST Registration Nos.";
    //     CU_base64: Codeunit "Base64 Convert";
    //     recLocation: Record Location;
    //     JObject: JsonObject;
    //     FinalJson: JsonObject;
    //     base64: Codeunit "Base64 Convert";
    // begin

    //     GenLedSet.Get();
    //     recLocation.Get(RecSalesCrMemo."Location Code");
    //     GSTRegNos.Reset();
    //     GSTRegNos.SetRange(Code, recLocation."GST Registration No.");
    //     if GSTRegNos.FindFirst() then;
    //     Myfile.OPEN(GenLedSet."GST Public Key Directory Path");
    //     Myfile.CREATEINSTREAM(Instream1);
    //     Instream1.READTEXT(keyTxt);

    //     GSTEncr_Decr := GSTEncr_Decr.RSA_AES();
    //     encryptedPass := GSTEncr_Decr.EncryptAsymmetric(pass, keyTxt);
    //     plainAppkey := base64.ToBase64(GSTEncr_Decr.RandomString(32, FALSE));
    //     //bytearr := encoding.UTF8.GetBytes(plainAppkey);
    //     JObject.Add('userName', GSTRegNos."E-Invoice UserName");
    //     JObject.Add('password', GSTRegNos."E-Invoice Password");
    //     JObject.Add('AppKey', plainAppkey);
    //     JObject.Add('ForceRefreshAuthToken', 'true');

    //     //Convert to base 64 string first and then encrypt with the GST Public Key then populate the Final Json payload
    //     base64Payload := CU_base64.ToBase64(jsonString);
    //     // Message(base64Payload);

    //     // Message('Key text %1', keyTxt);
    //     encryptedPayload := GSTEncr_Decr.EncryptAsymmetric(base64Payload, keyTxt);

    //     FinalJson.Add('Data', encryptedPayload);
    //     FinalJson.WriteTo(finPayload);
    //     getAuthfromNIC(finPayload, plainAppkey, RecSalesCrMemo);
    //     // Message(finPayload);
    //     exit(finPayload);
    //     // exit(jsonString);
    // end;

    // procedure getAuthfromNIC(JsonString: text; PlainKey: Text; SalesCrMemo: Record "Sales Cr.Memo Header")
    // var
    //     genledSetup: Record "General Ledger Setup";
    //     responsetxt: text;
    //     httpClient: HttpClient;
    //     httpresponse: HttpResponseMessage;
    //     httprequest: HttpRequestMessage;
    //     httpHdr: HttpHeaders;
    //     httpContent: HttpContent;
    //     recGSTREgNos: Record "GST Registration Nos.";
    //     recLocation: Record Location;
    //     PostUrl: Text;
    // begin
    //     genledSetup.GET;
    //     recLocation.Get(SalesCrMemo."Location Code");
    //     recGSTREgNos.Reset();
    //     recGSTREgNos.SetRange(Code, recLocation."GST Registration No.");
    //     if recGSTREgNos.FindFirst() then;
    //     //servicepointmanager.SecurityProtocol := securityprotocol.Tls12;

    //     PostUrl := genledSetup."GST Authorization URL";
    //     HttpContent.WriteFrom(JsonString);
    //     HttpContent.GetHeaders(HttpHdr);
    //     HttpHdr.Add('client_id', recGSTREgNos."E-Invoice Client ID");
    //     HttpHdr.Add('client_secret', recGSTREgNos."E-Invoice Client Secret");
    //     HttpHdr.Add('GSTIN', recGSTREgNos.Code);//NP ccit-070224
    //     HttpHdr.Remove('Content-Type');
    //     HttpHdr.Add('Content-Type', 'application/json');


    //     if Httpclient.Post(PostUrl, HttpContent, httpresponse) then begin
    //         httpresponse.Content.ReadAs(responsetxt);
    //         ParseAuthResponse(responsetxt, PlainKey, SalesCrMemo);
    //     END;

    // END;

    // procedure ParseAuthResponse(TextResponse: text; PlainKey: text; SalesCrMemo: Record "Sales Cr.Memo Header"): text;
    // var
    //     message1: text;
    //     CurrentObject: text;
    //     CurrentElement: text;
    //     ValuePair: text;
    //     PlainSEK: text;
    //     GSTIn_DLL: DotNet GSTEncr_Decr;
    //     FormatChar: label '{}';
    //     CurrentValue: text;
    //     txtStatus: text;
    //     p: Integer;
    //     x: Integer;
    //     txtAuthT: text;
    //     recAuthData: Record "GST E-Invoice(Auth Data)";
    //     l: Integer;
    //     txtError: text;
    //     txtEncSEK: text;
    //     errPOS: Integer;
    //     encoding: DotNet Encoding;
    //     txtExpiry: text;
    //     bytearr: DotNet Array;
    // begin
    //     // Message(TextResponse);

    //     CLEAR(message1);
    //     CLEAR(CurrentObject);
    //     p := 0;
    //     x := 1;

    //     IF STRPOS(TextResponse, '{}') > 0 THEN
    //         EXIT;

    //     TextResponse := DELCHR(TextResponse, '=', FormatChar);
    //     l := STRLEN(TextResponse);
    //     // MESSAGE(TextResponse);
    //     errPOS := STRPOS(TextResponse, '"Status":0');
    //     IF errPOS > 0 THEN
    //         ERROR('Error in Auth Token generation : %1', TextResponse);
    //     //no response

    //     // CurrentObject := COPYSTR(TextResponse,STRPOS(TextResponse,'{')+1,STRPOS(TextResponse,':'));
    //     // TextResponse := COPYSTR(TextResponse,STRLEN(CurrentObject)+1);

    //     TextResponse := DELCHR(TextResponse, '=', FormatChar);
    //     l := STRLEN(TextResponse);

    //     WHILE p < l DO BEGIN
    //         ValuePair := SELECTSTR(x, TextResponse);  // get comma separated pairs of values and element names
    //         IF STRPOS(ValuePair, ':') > 0 THEN BEGIN
    //             p := STRPOS(TextResponse, ValuePair) + STRLEN(ValuePair); // move pointer to the end of the current pair in Value
    //             CurrentElement := COPYSTR(ValuePair, 1, STRPOS(ValuePair, ':'));
    //             CurrentElement := DELCHR(CurrentElement, '=', ':');
    //             CurrentElement := DELCHR(CurrentElement, '=', '"');

    //             CurrentValue := COPYSTR(ValuePair, STRPOS(ValuePair, ':'));
    //             CurrentValue := DELCHR(CurrentValue, '=', ':');
    //             CurrentValue := DELCHR(CurrentValue, '=', '"');

    //             CASE CurrentElement OF
    //                 'Status':
    //                     BEGIN
    //                         txtStatus := CurrentValue;
    //                     END;
    //                 'ErrorDetails':
    //                     BEGIN
    //                         txtError := CurrentValue;
    //                     END;
    //                 'AuthToken':
    //                     BEGIN
    //                         txtAuthT := CurrentValue;
    //                         // Message('AuthToke %1', txtAuthT);
    //                     END;
    //                 'Sek':
    //                     BEGIN
    //                         txtEncSEK := CurrentValue;
    //                         // Message('EncryptedSEK %1', txtEncSEK);
    //                     END;
    //                 'TokenExpiry':
    //                     BEGIN
    //                         txtExpiry := CurrentValue;
    //                     END;
    //             END;
    //         END;
    //         x := x + 1;
    //     END;



    //     recAuthData.RESET;
    //     recAuthData.SETCURRENTKEY("Sr No.");
    //     IF recAuthData.FINDLAST THEN
    //         recAuthData."Sr No." += 1
    //     ELSE
    //         recAuthData."Sr No." := 1;
    //     recAuthData."Auth Token" := txtAuthT;
    //     recAuthData.SEK := txtEncSEK;
    //     recAuthData."Insertion DateTime" := CurrentDateTime;
    //     recAuthData."Expiry Date Time" := txtExpiry;
    //     recAuthData.PlainAppKey := PlainKey;
    //     // recAuthData.DocumentNum := SalesCrMemo."No.";//Document number is universal for all documents and both E-Invoice and E-Way Bill 250922
    //     recAuthData.INSERT;

    //     recAuthData.Reset();
    //     // recAuthData.SetRange(DocumentNum, SalesCrMemo."No.");//Document number is universal for all documents and both E-Invoice and E-Way Bill 250922
    //     if recAuthData.FindFirst() then begin
    //         GSTIn_DLL := GSTIn_DLL.RSA_AES();
    //         bytearr := encoding.UTF8.GetBytes(recAuthData.PlainAppKey);
    //         PlainSEK := GSTIn_DLL.DecryptBySymmetricKey(recAuthData.SEK, bytearr);
    //         // message('SEK 1 %1,', PlainSEK);
    //         recAuthData.DecryptedSEK := PlainSEK;
    //         recAuthData.Modify();
    //     end;

    //     EXIT(txtEncSEK);
    // end;

    procedure WriteTransDtls(VAR JsonObj: JsonObject; SalesCrMemo: Record "Sales Cr.Memo Header")
    var
        category: Code[10];
        E_InvoiceHandler: Codeunit "e-Invoice Management";
        E_InvoiceHandler1: codeunit "e-Invoice Json Handler";
        TranDtls: JsonObject;
    begin
        //***Trans Detail Start


        TranDtls.Add('TaxSch', 'GST');

        IF (SalesCrMemo."GST Customer Type" = SalesCrMemo."GST Customer Type"::Registered)
        OR (SalesCrMemo."GST Customer Type" = SalesCrMemo."GST Customer Type"::Exempted) THEN BEGIN
            category := 'B2B';

        END ELSE
            IF
            (SalesCrMemo."GST Customer Type" = SalesCrMemo."GST Customer Type"::Export) THEN BEGIN
                IF SalesCrMemo."GST Without Payment of Duty" THEN
                    category := 'EXPWOP'
                ELSE
                    category := 'EXPWP'
            END ELSE
                IF
           (SalesCrMemo."GST Customer Type" = SalesCrMemo."GST Customer Type"::"Deemed Export") THEN
                    category := 'DEXP';
        if SalesCrMemo."GST Customer Type" = SalesCrMemo."GST Customer Type"::Unregistered then
            category := 'B2C';

        TranDtls.Add('SupTyp', category);//Where to pick this from

        TranDtls.Add('RegRev', 'N');

        // JsonWriter.Add('EcmGstin');
        // JsonWriter.WriteValue(BBQ_GSTIN);

        TranDtls.Add('IgstOnIntra', 'N');

        JsonObj.Add('TranDtls', TranDtls);
        //***Trans Detail End--

    end;


    procedure WriteDocDtls(VAR JsonObj: JsonObject; SalesCrMemo: Record "Sales Cr.Memo Header")
    var
        txtDocDate: Text[20];
        Typ: Code[20];
        DocDtls: JsonObject;
    begin
        IF SalesCrMemo."Invoice Type" = SalesCrMemo."Invoice Type"::Taxable THEN
            Typ := 'CRN';
        /*ELSE
            IF (SalesCrMemo."Invoice Type" = SalesCrMemo."Invoice Type"::"Debit Note") OR
            (SalesCrMemo."Invoice Type" = SalesCrMemo."Invoice Type"::Supplementary)
            THEN
                Typ := 'DBN'
            ELSE
                Typ := 'INV';*/
        txtDocDate := FORMAT(SalesCrMemo."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
        // txtDocDate := FORMAT(Today - 5, 0, '<Day,2>/<Month,2>/<Year4>');

        //***Doc Details Start


        //DocType
        DocDtls.Add('Typ', Typ);

        //Doc Num
        DocDtls.Add('No', COPYSTR(SalesCrMemo."No.", 1, 16));

        DocDtls.Add('Dt', txtDocDate);

        JsonObj.Add('DocDtls', DocDtls);
        //***Doc Details End--


    end;

    procedure WriteSellerDtls(VAR JsonObj: JsonObject; SalesCrMemo: Record "Sales Cr.Memo Header")
    var
        loc: code[10];
        Pin: Integer;
        Stcd: Code[15];
        Ph: Code[20];
        LocationBuff: Record Location;
        Location: Record Location;
        Em: Text[100];
        CompanyInformationBuff: Record "Company Information";
        TrdNm: Text;
        LglNm: text;
        Addr1: text;
        Addr2: text;
        StateBuff: Record State;
        Gstin: text;
        SellerDtls: JsonObject;
    begin
        CLEAR(Loc);
        CLEAR(Pin);
        CLEAR(Stcd);
        CLEAR(Ph);
        CLEAR(Em);
        WITH SalesCrMemo DO BEGIN
            Location.GET(SalesCrMemo."Location Code");
            //    Gstin := "Location GST Reg. No.";
            Gstin := Location."GST Registration No.";
            CompanyInformationBuff.GET;
            TrdNm := CompanyInformationBuff.Name;
            LocationBuff.GET("Location Code");
            LglNm := LocationBuff.Name;
            Addr1 := LocationBuff.Address;
            Addr2 := LocationBuff."Address 2";
            IF LocationBuff.GET("Location Code") THEN BEGIN
                Loc := LocationBuff.City;
                EVALUATE(Pin, COPYSTR(LocationBuff."Post Code", 1, 6));
                StateBuff.GET(LocationBuff."State Code");
                //      Stcd := StateBuff.Description;
                Stcd := StateBuff."State Code (GST Reg. No.)";
                Ph := COPYSTR(LocationBuff."Phone No.", 1, 12);
                gl_BilltoPh := COPYSTR(LocationBuff."Phone No.", 1, 12);
                gl_BilltoEm := COPYSTR(LocationBuff."E-Mail", 1, 100);
                Em := COPYSTR(LocationBuff."E-Mail", 1, 100);
            END;
        END;

        //***Seller Details start

        SellerDtls.Add('Gstin', SalesCrMemo."Location GST Reg. No.");
        // JsonWriter.WriteValue(Gstin);
        //JsonWriter.WriteValue(BBQ_GSTIN);
        //Seller Legal Name
        SellerDtls.Add('LglNm', LglNm);
        //Seller Trading Name
        SellerDtls.Add('TrdNm', LglNm);
        SellerDtls.Add('Addr1', Addr1);
        SellerDtls.Add('Addr2', Addr2);
        //City e.g., GANDHINAGAR
        SellerDtls.Add('Loc', UPPERCASE(Loc));
        SellerDtls.Add('Pin', Pin);
        SellerDtls.Add('Stcd', Stcd);
        //Phone
        SellerDtls.Add('Ph', Ph);
        //Email
        SellerDtls.Add('Em', Em);
        JsonObj.Add('SellerDtls', SellerDtls);
        //***Seller Details End--

    end;

    procedure WriteBuyerDtls(VAR JsonObj: JsonObject; SalesCrMemo: Record "Sales Cr.Memo Header"; VAR BilltoPh: Code[20]; BillToEm: Text[100])
    var
        POS: text;
        Stcd: text;
        Ph: text;
        Em: Text;
        Gstin: text;
        customerrec: Record Customer;
        Lglnm: text;
        Trdnm: text;
        Addr1: text;
        Loc: Code[10];
        Addr2: text;
        Pin: integer;
        ShipToAddr: Record "Ship-to Address";
        // SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        StateBuff: Record State;
        Contact: Record Contact;
        recCustomer: Record Customer;
        BuyerDtls: JsonObject;
    begin

        WITH SalesCrMemo DO BEGIN
            IF "GST Customer Type" = "GST Customer Type"::Export THEN
                Gstin := 'URP'
            ELSE BEGIN
                customerrec.GET(SalesCrMemo."Sell-to Customer No.");
                //      Gstin := "Customer GST Reg. No.";
                Gstin := customerrec."GST Registration No.";
            END;
            LglNm := "Sell-to Customer Name";
            TrdNm := "Bill-to Name";
            Addr1 := "Bill-to Address";
            Addr2 := "Bill-to Address 2";
            Loc := "Bill-to City";
            IF "GST Customer Type" <> "GST Customer Type"::Export THEN begin
                if recCustomer.Get("Sell-to Customer No.") then;
                if "Bill-to Post Code" <> '' then
                    EVALUATE(Pin, COPYSTR("Bill-to Post Code", 1, 6))
                else
                    EVALUATE(Pin, COPYSTR(recCustomer."Post Code", 1, 6))
            end;

            SalesCrMemoLine.SETRANGE("Document No.", "No.");
            SalesCrMemoLine.SETFILTER("GST Place of Supply", '<>%1', SalesCrMemoLine."GST Place of Supply"::" ");
            IF SalesCrMemoLine.FINDFIRST THEN
                IF SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Bill-to Address" THEN BEGIN
                    IF "GST Customer Type" IN
                    ["GST Customer Type"::Export]//,"GST Customer Type"::"SEZ Development","GST Customer Type"::"SEZ Unit"]
                    THEN
                        POS := '96'
                    ELSE BEGIN
                        StateBuff.RESET;
                        StateBuff.GET("GST Bill-to State Code");
                        POS := FORMAT(StateBuff."State Code (GST Reg. No.)");
                        //          Stcd := StateBuff.Description;
                        Stcd := StateBuff."State Code (GST Reg. No.)";
                    END;

                    IF Contact.GET("Bill-to Contact No.") THEN BEGIN
                        Ph := COPYSTR(Contact."Phone No.", 1, 12);
                        Em := COPYSTR(Contact."E-Mail", 1, 100);
                    END;
                END ELSE
                    IF SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Ship-to Address" THEN BEGIN
                        IF "GST Customer Type" IN
                            ["GST Customer Type"::Export]//,"GST Customer Type"::"SEZ Development","GST Customer Type"::"SEZ Unit"]
                        THEN
                            POS := '96'
                        ELSE BEGIN
                            StateBuff.RESET;
                            StateBuff.GET("GST Ship-to State Code");
                            POS := FORMAT(StateBuff."State Code (GST Reg. No.)");
                            Stcd := StateBuff.Description;
                        END;

                        IF ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code") THEN BEGIN
                            Ph := COPYSTR(ShipToAddr."Phone No.", 1, 12);
                            Em := COPYSTR(ShipToAddr."E-Mail", 1, 100);
                        END;
                    END;
        END;

        //***Buyer Details start
        BuyerDtls.Add('Gstin', Gstin);
        // JsonWriter.WriteValue('29AWGPV7107B1Z1');
        // JsonWriter.WriteValue(BBQ_GSTIN);

        //Legal Name
        BuyerDtls.Add('LglNm', LglNm);

        //Trading Name
        BuyerDtls.Add('TrdNm', TrdNm);

        //What is this e.g., 12
        BuyerDtls.Add('Pos', POS);
        BuyerDtls.Add('Addr1', Addr1);
        BuyerDtls.Add('Addr2', Addr2);
        BuyerDtls.Add('Loc', Loc);
        BuyerDtls.Add('Pin', Pin);
        //What is this e.g., 29
        BuyerDtls.Add('Stcd', Stcd);
        //Phone

        IF Ph <> '' THEN
            BuyerDtls.Add('Ph', Ph)
        ELSE
            BuyerDtls.Add('Ph', '9988776654');

        //Email

        IF Em <> '' THEN
            BuyerDtls.Add('Em', Em);

        JsonObj.Add('BuyerDtls', BuyerDtls);

        //**Buyer Details End--
    end;

    procedure WriteItemDtls(VAR JsonObj: JsonObject; VAR SalesCrMemo: Record "Sales Cr.Memo Header"; VAR CurrExchRt: Decimal)
    var
        AssAmt: Decimal;
        SlNo: integer;
        CGSTRate: Decimal;
        SGSTRate: Decimal;
        IGSTRate: Decimal;
        CessRate: Decimal;
        FreeQty: Decimal;
        CesNonAdval: Decimal;
        IsServc: text;
        GSTTr: Decimal;
        StateCess: Decimal;
        UOM: Code[10];
        GSTRt: Decimal;
        CgstAmt: Decimal;
        SgstAmt: Decimal;
        IgstAmt: Decimal;
        CesRt: Decimal;
        CesAmt: Decimal;
        StateCesRt: Decimal;
        StateCesAmt: Decimal;
        StateCesNonAdvlAmt: Decimal;
        CGSTValue: Decimal;
        SGSTValue: Decimal;
        IGSTValue: Decimal;
        // SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        recUOM: Record "Unit of Measure";
        ItemList: JsonArray;
        ItemObject: JsonObject;
        E_Invoice_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
    begin

        CLEAR(SlNo);
        SalesCrMemoLine.SETRANGE("Document No.", SalesCrMemo."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        SalesCrMemoLine.SetFilter(Amount, '>%1', 0.5);
        //  SalesInvoiceLine.SETRANGE("Non-GST Line",FALSE);
        //  SalesInvoiceLine.SETFILTER(Type,'=%1',SalesInvoiceLine.Type::Item);
        IF SalesCrMemoLine.FIND('-') THEN BEGIN
            IF SalesCrMemoLine.COUNT > 100 THEN
                ERROR(SalesLineErr, SalesCrMemoLine.COUNT);
            // JsonWriter.Add('ItemList');
            // JsonWriter.WriteStartArray;
            REPEAT
                Clear(CGSTRate);
                Clear(SGSTRate);
                Clear(IGSTRate);
                Clear(CessRate);
                Clear(CesNonAdval);
                Clear(StateCesAmt);
                Clear(GSTRt);
                SlNo += 1;
                //   {IF SalesInvoiceLine."GST On Assessable Value" THEN
                //     AssAmt := SalesInvoiceLine."GST Assessable Value (LCY)"
                //   ELSE}
                if SalesCrMemoLine."GST Assessable Value (LCY)" <> 0 then
                    AssAmt := SalesCrMemoLine."GST Assessable Value (LCY)"
                else
                    AssAmt := SalesCrMemoLine.Amount;



                // AssAmt := SalesCrMemoLine."GST Assessable Value (LCY)";
                //   IF SalesCrMemoLine."Free Supply" THEN
                //     FreeQty := SalesCrMemoLine.Quantity
                //   ELSE
                //     FreeQty := 0;

                //   GetGSTCompRate(
                //     SalesInvoiceLine."Document No.",
                //     SalesInvoiceLine."Line No.",
                //     GSTRt,
                //     CgstAmt,
                //     SgstAmt,
                //     IgstAmt,
                //     CesRt,
                //     CesAmt,
                //     CesNonAdval,
                //     StateCesRt,
                //     StateCesAmt,
                //     StateCesNonAdvlAmt);
                E_Invoice_SalesInvoice.GetGSTComponentRate(
                    SalesCrMemoLine."Document No.",
                    SalesCrMemoLine."Line No.",
                    CGSTRate,
                    SGSTRate,
                    IGSTRate,
                    CessRate,
                    CesNonAdval,
                    StateCess, GSTRt
                );
                CLEAR(UOM);
                IF SalesCrMemoLine."Unit of Measure Code" <> '' THEN
                    UOM := COPYSTR(SalesCrMemoLine."Unit of Measure Code", 1, 8)
                ELSE
                    UOM := OTHTxt;
                IF SalesCrMemoLine."GST Group Type" = SalesCrMemoLine."GST Group Type"::Service THEN
                    IsServc := 'Y'
                ELSE
                    IsServc := 'N';
                // WriteItem(
                //   SalesInvoiceLine.Description + SalesInvoiceLine."Description 2",
                //   SalesInvoiceLine."HSN/SAC Code",
                //   SalesInvoiceLine.Quantity,
                //   FreeQty,
                //   UOM,
                //   SalesInvoiceLine."Unit Price",
                //   SalesInvoiceLine."Line Amount" + SalesInvoiceLine."Line Discount Amount",
                //   SalesInvoiceLine."Line Discount Amount",
                //   SalesInvoiceLine."Line Amount",
                //   AssAmt,
                //   CGSTRate,
                //   IGSTRate,
                //   IgstAmt,
                //   StateCesRt,
                //   CesAmt,
                //   CesNonAdval,
                //   StateCesRt,
                //   StateCesAmt,
                //   StateCesNonAdvlAmt,
                //   0,
                //   SalesInvoiceLine."Amount Including Tax" + SalesInvoiceLine."Total GST Amount",
                //   SalesInvoiceLine."Line No.",
                //   SlNo,
                //   IsServc, JsonWriter, CurrExchRt, GSTRt);

                GetGSTValueForLine(SalesCrMemoLine."Document No.", SalesCrMemoLine."Line No.", CGSTValue, SGSTValue, IGSTValue);
                Clear(ItemObject);
                ItemObject := WriteItem(
                        SalesCrMemoLine.Description + SalesCrMemoLine."Description 2", '',
                        SalesCrMemoLine."HSN/SAC Code", '',
                        SalesCrMemoLine.Quantity, FreeQty,
                        CopyStr(SalesCrMemoLine."Unit of Measure Code", 1, 10),
                        SalesCrMemoLine."Unit Price",
                        SalesCrMemoLine."Line Amount" + SalesCrMemoLine."Line Discount Amount",
                        SalesCrMemoLine."Line Discount Amount", 0,
                        AssAmt, CGSTRate, SGSTRate, IGSTRate, CessRate, CesNonAdval, StateCess,
                        (AssAmt + CGSTValue + SGSTValue + IGSTValue),
                        SlNo,
                        IsServc,
                        CurrExchRt,
                        GSTRt, CGSTValue, SGSTValue, IGSTValue);
                ItemList.Add(ItemObject);
            UNTIL SalesCrMemoLine.NEXT = 0;
            JsonObj.Add('ItemList', ItemList);
        END;

    end;

    // procedure WriteItem(PrdDesc: Text; HsnCd: Text; Qty: Decimal; FreeQty: Decimal; Unit: Text; UnitPrice: Decimal; TotAmt: Decimal; Discount: Decimal; PreTaxVal: Decimal; AssAmt: Decimal; CgstAmt: Decimal; SgstAmt: Decimal; IgstAmt: Decimal; CesRt: Decimal; CesAmt: Decimal; CesNonAdval: Decimal; StateCes: Decimal; StateCesAmt: Decimal; StateCesNonAdvlAmt: Decimal; OthChrg: Decimal; TotItemVal: Decimal; SILineNo: Decimal; SlNo: Integer; IsServc: Text; VAR JsonTextWriter: DotNet JsonTextWriter; CurrExRate: Decimal; GSTRt: Decimal)
    // var
    // begin

    // end;
    local procedure WriteItem(
        ProductName: Text;
        ProductDescription: Text;
        HSNCode: Text[10];
        BarCode: Text[30];
        Quantity: Decimal;
        FreeQuantity: Decimal;
        Unit: Code[10];
        UnitPrice: Decimal;
        TotAmount: Decimal;
        Discount: Decimal;
        OtherCharges: Decimal;
        AssessableAmount: Decimal;
        CGSTRate: Decimal;
        SGSTRate: Decimal;
        IGSTRate: Decimal;
        CESSRate: Decimal;
        CessNonAdvanceAmount: Decimal;
        StateCess: Decimal;
        TotalItemValue: Decimal;
        SlNo: Integer;
        IsServc: Code[2];
        CurrExRate: Decimal;
        GSTRt: Decimal;
        CGSTValue: Decimal;
        SGSTValue: Decimal;
        IGSTValue: Decimal) ItemObject: JsonObject
    var
        recUOM: Record "Unit of Measure";
    begin
        recUOM.get(Unit);

        ItemObject.Add('SlNo', FORMAT(SlNo));


        IF ProductName <> '' THEN
            ItemObject.Add('PrdDesc', ProductName)
        ;



        IF IsServc <> '' THEN
            ItemObject.Add('IsServc', IsServc);


        IF HSNCode <> '' THEN
            ItemObject.Add('HsnCd', HSNCode);


        // IF IsInvoice THEN
        // InvoiceRowID := ItemTrackingManagement.ComposeRowID(DATABASE::"Sales Invoice Line",0,DocumentNo,'',0,SILineNo)
        // ELSE
        // InvoiceRowID := ItemTrackingManagement.ComposeRowID(DATABASE::"Sales Cr.Memo Line",0,DocumentNo,'',0,SILineNo);
        // ValueEntryRelation.SETCURRENTKEY("Source RowId");
        // ValueEntryRelation.SETRANGE("Source RowId",InvoiceRowID);
        // IF ValueEntryRelation.FINDSET THEN BEGIN
        // xLotNo := '';
        // JsonTextWriter.Add('BchDtls');
        // JsonTextWriter.WriteStartObject;
        // REPEAT
        //     ValueEntry.GET(ValueEntryRelation."Value Entry No.");
        //     ItemLedgerEntry.SETCURRENTKEY("Item No.",Open,"Variant Code",Positive,"Lot No.","Serial No.");
        //     ItemLedgerEntry.GET(ValueEntry."Item Ledger Entry No.");
        //     IF xLotNo <> ItemLedgerEntry."Lot No." THEN BEGIN
        //     WriteBchDtls(
        //         COPYSTR(ItemLedgerEntry."Lot No.",1,20),
        //         FORMAT(ItemLedgerEntry."Expiration Date",0,'<Day,2>/<Month,2>/<Year4>'),
        //         FORMAT(ItemLedgerEntry."Warranty Date",0,'<Day,2>/<Month,2>/<Year4>'));
        //     xLotNo := ItemLedgerEntry."Lot No.";
        //     END;
        // UNTIL ValueEntryRelation.NEXT = 0;
        // JsonTextWriter.WriteEndObject;
        // END;


        //ItemObject.Add('Barcde','null');

        ItemObject.Add('Qty', Quantity);
        ItemObject.Add('FreeQty', FreeQuantity);


        if recUOM."E-Inv UOM" = '' then Error('Please map the E-Invoice UOM on UOM master');
        ItemObject.Add('Unit', recUOM."E-Inv UOM");

        // IF Unit = '' THEN
        //     JsonWriter.WriteValue(GlobalNULL);

        ItemObject.Add('UnitPrice', UnitPrice);

        ItemObject.Add('TotAmt', TotAmount);// * CurrExRate);

        ItemObject.Add('Discount', Discount);//* CurrExRate);

        // JsonWriter.Add('PreTaxVal');
        // JsonWriter.WriteValue(PreTaxVal * CurrExRate);

        ItemObject.Add('AssAmt', Round(AssessableAmount, 0.01, '='));
        // JsonWriter.WriteValue(AssessableAmount);// * CurrExRate);

        ItemObject.Add('GstRt', GSTRt);
        // if GSTRt < 5 then GSTRt := GSTRt * 2;
        // JsonWriter.WriteValue(GSTRt);

        ItemObject.Add('IgstAmt', IGSTValue);

        ItemObject.Add('CgstAmt', CGSTValue);

        ItemObject.Add('SgstAmt', SGSTValue);

        ItemObject.Add('CesRt', CESSRate);

        // JsonWriter.Add('CesAmt');
        // JsonWriter.WriteValue(CesAmt);

        // JsonWriter.Add('CesNonAdvlAmt');
        // JsonWriter.WriteValue(CessNonAdvanceAmount);

        ItemObject.Add('CesNonAdvl', CessNonAdvanceAmount);

        // JsonWriter.Add('StateCesRt');
        // JsonWriter.WriteValue(StateCes);

        ItemObject.Add('StateCes', StateCess);

        // JsonWriter.Add('StateCesAmt');
        // JsonWriter.WriteValue(StateCesAmt);

        // JsonWriter.Add('StateCesNonAdvlAmt');
        // JsonWriter.WriteValue(CessNonAdvanceAmount);

        ItemObject.Add('TotItemVal', TotalItemValue);// * CurrExRate);

        // JsonTextWriter.Add('OthChrg');
        // JsonTextWriter.WriteValue(OthChrg);

        // JsonTextWriter.Add('OrdLineRef');
        // JsonTextWriter.WriteValue(GlobalNULL);

        // JsonTextWriter.Add('OrgCntry');
        // JsonTextWriter.WriteValue('IN');

        // JsonTextWriter.Add('PrdSlNo');
        // JsonTextWriter.WriteValue(GlobalNULL);


    end;




    // local procedure GetGSTComponentRate(
    //     DocumentNo: Code[20];
    //     LineNo: Integer;
    //     var CGSTRate: Decimal;
    //     var SGSTRate: Decimal;
    //     var IGSTRate: Decimal;
    //     var CessRate: Decimal;
    //     var CessNonAdvanceAmount: Decimal;
    //     var StateCess: Decimal;
    //     var GSTRate: Decimal)
    // var
    //     DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    // begin
    //     DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
    //     DetailedGSTLedgerEntry.SetRange("Document Line No.", LineNo);

    //     DetailedGSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
    //     if DetailedGSTLedgerEntry.FindFirst() then begin
    //         CGSTRate := DetailedGSTLedgerEntry."GST %";
    //         GSTRate := DetailedGSTLedgerEntry."GST %"
    //     end else
    //         CGSTRate := 0;

    //     DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
    //     if DetailedGSTLedgerEntry.FindFirst() then begin
    //         SGSTRate := DetailedGSTLedgerEntry."GST %";
    //         GSTRate := DetailedGSTLedgerEntry."GST %"
    //     end else
    //         SGSTRate := 0;

    //     DetailedGSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
    //     if DetailedGSTLedgerEntry.FindFirst() then begin
    //         IGSTRate := DetailedGSTLedgerEntry."GST %";
    //         GSTRate := DetailedGSTLedgerEntry."GST %"
    //     end else
    //         IGSTRate := 0;

    //     CessRate := 0;
    //     CessNonAdvanceAmount := 0;
    //     DetailedGSTLedgerEntry.SetRange("GST Component Code", CESSLbl);
    //     if DetailedGSTLedgerEntry.FindFirst() then
    //         if DetailedGSTLedgerEntry."GST %" > 0 then
    //             CessRate := DetailedGSTLedgerEntry."GST %"
    //         else
    //             CessNonAdvanceAmount := Abs(DetailedGSTLedgerEntry."GST Amount");

    //     StateCess := 0;
    //     DetailedGSTLedgerEntry.SetRange("GST Component Code");
    //     if DetailedGSTLedgerEntry.FindSet() then
    //         repeat
    //             if not (DetailedGSTLedgerEntry."GST Component Code" in [CGSTLbl, SGSTLbl, IGSTLbl, CESSLbl])
    //             then
    //                 StateCess := DetailedGSTLedgerEntry."GST %";
    //         until DetailedGSTLedgerEntry.Next() = 0;
    // end;

    local procedure GetGSTValue(
        var AssessableAmount: Decimal;
        var CGSTAmount: Decimal;
        var SGSTAmount: Decimal;
        var IGSTAmount: Decimal;
        var CessAmount: Decimal;
        var StateCessValue: Decimal;
        var CessNonAdvanceAmount: Decimal;
        var DiscountAmount: Decimal;
        var OtherCharges: Decimal;
        var TotalInvoiceValue: Decimal;
        var SalesCrMemo: Record "Sales Cr.Memo Header"
        )
    var
        // SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        GSTLedgerEntry: Record "GST Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TotGSTAmt: Decimal;
    begin
        GSTLedgerEntry.SetRange("Document No.", SalesCrMemo."No.");

        GSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat
                CGSTAmount += Abs(GSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0
        else
            CGSTAmount := 0;

        GSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat
                SGSTAmount += Abs(GSTLedgerEntry."GST Amount")
            until GSTLedgerEntry.Next() = 0
        else
            SGSTAmount := 0;

        GSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat
                IGSTAmount += Abs(GSTLedgerEntry."GST Amount")
            until GSTLedgerEntry.Next() = 0
        else
            IGSTAmount := 0;

        CessAmount := 0;
        CessNonAdvanceAmount := 0;

        DetailedGSTLedgerEntry.SetRange("Document No.", SalesCrMemo."No.");
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CESSLbl);
        if DetailedGSTLedgerEntry.FindFirst() then
            repeat
                if DetailedGSTLedgerEntry."GST %" > 0 then
                    CessAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
                else
                    CessNonAdvanceAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0;

        GSTLedgerEntry.Reset();
        GSTLedgerEntry.SetRange("Document No.", SalesCrMemo."No.");
        // GSTLedgerEntry.SetFilter("GST Component Code", '<>%1|<>%2|<>%3|<>%4', 'CGST', 'SGST', 'IGST', 'CESS');
        if GSTLedgerEntry.Find('-') then
            repeat
                if (GSTLedgerEntry."GST Component Code") in ['CGST', 'SGST', 'IGST', 'CESS'] then
                    StateCessValue := 0
                else
                    StateCessValue += Abs(GSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0;

        // if IsInvoice then begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemo."No.");
        if SalesCrMemoLine.Find('-') then
            repeat
                AssessableAmount += SalesCrMemoLine.Amount;
                DiscountAmount += SalesCrMemoLine."Inv. Discount Amount";
            until SalesCrMemoLine.Next() = 0;
        TotGSTAmt := CGSTAmount + SGSTAmount + IGSTAmount + CessAmount + CessNonAdvanceAmount + StateCessValue;

        AssessableAmount := Round(
            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
              WorkDate(), SalesCrMemo."Currency Code", AssessableAmount, SalesCrMemo."Currency Factor"), 0.01, '=');
        TotGSTAmt := Round(
            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
              WorkDate(), SalesCrMemo."Currency Code", TotGSTAmt, SalesCrMemo."Currency Factor"), 0.01, '=');
        DiscountAmount := Round(
            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
              WorkDate(), SalesCrMemo."Currency Code", DiscountAmount, SalesCrMemo."Currency Factor"), 0.01, '=');

        CustLedgerEntry.SetCurrentKey("Document No.");
        CustLedgerEntry.SetRange("Document No.", SalesCrMemo."No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
        CustLedgerEntry.SetRange("Customer No.", SalesCrMemo."Bill-to Customer No.");
        if CustLedgerEntry.FindFirst() then begin
            CustLedgerEntry.CalcFields("Amount (LCY)");
            TotalInvoiceValue := Abs(CustLedgerEntry."Amount (LCY)");
        end;
        // end;
        /*else begin
           SalesCrMemoLine.SetRange("Document No.", SalesCrMemo."No.");
           if SalesCrMemoLine.FindSet() then begin
               repeat
                   AssessableAmount += SalesCrMemoLine.Amount;
                   DiscountAmount += SalesCrMemoLine."Inv. Discount Amount";
               until SalesCrMemoLine.Next() = 0;
               TotGSTAmt := CGSTAmount + SGSTAmount + IGSTAmount + CessAmount + CessNonAdvanceAmount + StateCessValue;
           end;

           AssessableAmount := Round(
               CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                   WorkDate(),
                   SalesCrMemo."Currency Code",
                   AssessableAmount,
                   SalesCrMemo."Currency Factor"),
                   0.01,
                   '=');

           TotGSTAmt := Round(
               CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                   WorkDate(),
                   SalesCrMemo."Currency Code",
                   TotGSTAmt,
                   SalesCrMemo."Currency Factor"),
                   0.01,
                   '=');

           DiscountAmount := Round(
               CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                   WorkDate(),
                   SalesCrMemo."Currency Code",
                   DiscountAmount,
                   SalesCrMemo."Currency Factor"),
                   0.01,
                   '=');
           //   end;

           CustLedgerEntry.SetCurrentKey("Document No.");
           CustLedgerEntry.SetRange("Document No.", SalesCrMemo."No.");
           CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
           CustLedgerEntry.SetRange("Customer No.", SalesCrMemo."Bill-to Customer No.");
           if CustLedgerEntry.FindFirst() then begin
               CustLedgerEntry.CalcFields("Amount (LCY)");
               TotalInvoiceValue := Abs(CustLedgerEntry."Amount (LCY)");
           end;
           //   if IsInvoice then begin
           //       CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
           //       CustLedgerEntry.SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
           //   end;
           //  else begin

           // end;*/



        OtherCharges := 0;
    end;

    local procedure GetGSTValueForLine(
        DocumentNo: Code[80];
        DocumentLineNo: Integer;
        var CGSTLineAmount: Decimal;
        var SGSTLineAmount: Decimal;
        var IGSTLineAmount: Decimal)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        CGSTLineAmount := 0;
        SGSTLineAmount := 0;
        IGSTLineAmount := 0;

        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", DocumentLineNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                CGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                SGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                IGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;
    end;

    procedure WriteValDtls(JsonObj1: JsonObject; SalesCrMemo: Record "Sales Cr.Memo Header")
    var
        AssessableAmount: Decimal;
        CGSTAmount: Decimal;
        SGSTAmount: Decimal;
        IGSTAmount: Decimal;
        CessAmount: Decimal;
        StateCessAmount: Decimal;
        CESSNonAvailmentAmount: Decimal;
        DiscountAmount: Decimal;
        OtherCharges: Decimal;
        TotalInvoiceValue: Decimal;
        ValDtls: JsonObject;
    begin
        GetGSTValue(AssessableAmount, CGSTAmount, SGSTAmount, IGSTAmount, CessAmount, StateCessAmount, CESSNonAvailmentAmount, DiscountAmount, OtherCharges, TotalInvoiceValue, SalesCrMemo);

        ValDtls.Add('Assval', AssessableAmount);

        ValDtls.Add('CgstVal', CGSTAmount);

        ValDtls.Add('SgstVAl', SGSTAmount);

        ValDtls.Add('IgstVal', IGSTAmount);

        ValDtls.Add('CesVal', CessAmount);

        ValDtls.Add('StCesVal', StateCessAmount);

        ValDtls.Add('CesNonAdVal', CESSNonAvailmentAmount);

        ValDtls.Add('OthChrg', OtherCharges);


        ValDtls.Add('Disc', DiscountAmount);

        ValDtls.Add('TotInvVal', TotalInvoiceValue);
        JsonObj1.Add('ValDtls', ValDtls);

    end;

    procedure WriteExpDtls(JsonObj1: JsonObject; SalesCrMemo: Record "Sales Cr.Memo Header")
    var
        ExportCategory: code[20];
        DocumentAmount: Decimal;
        // SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        WithPayOfDuty: Code[2];
        ShipmentBillNo: Code[20];
        ExitPort: code[10];
        ShipmentBillDate: text;
        CurrencyCode: code[3];
        CountryCode: code[2];
        ExpDtls: JsonObject;
    begin
        if not (SalesCrMemo."GST Customer Type" in [
            SalesCrMemo."GST Customer Type"::Export,
            SalesCrMemo."GST Customer Type"::"Deemed Export",
            SalesCrMemo."GST Customer Type"::"SEZ Unit",
            SalesCrMemo."GST Customer Type"::"SEZ Development"])
        then
            exit;

        case SalesCrMemo."GST Customer Type" of
            SalesCrMemo."GST Customer Type"::Export:
                ExportCategory := 'DIR';
            SalesCrMemo."GST Customer Type"::"Deemed Export":
                ExportCategory := 'DEM';
            SalesCrMemo."GST Customer Type"::"SEZ Unit":
                ExportCategory := 'SEZ';
            SalesCrMemo."GST Customer Type"::"SEZ Development":
                ExportCategory := 'SED';
        end;

        if SalesCrMemo."GST Without Payment of Duty" then
            WithPayOfDuty := 'N'
        else
            WithPayOfDuty := 'Y';

        ShipmentBillNo := CopyStr(SalesCrMemo."Bill Of Export No.", 1, 16);
        ShipmentBillDate := Format(SalesCrMemo."Bill Of Export Date", 0, '<Year4>-<Month,2>-<Day,2>');
        ExitPort := SalesCrMemo."Exit Point";

        SalesCrMemoLine.SetRange("Document No.", SalesCrMemo."No.");
        if SalesCrMemoLine.FindSet() then
            repeat
                DocumentAmount := DocumentAmount + SalesCrMemoLine.Amount;
            until SalesCrMemoLine.Next() = 0;

        CurrencyCode := CopyStr(SalesCrMemo."Currency Code", 1, 3);
        CountryCode := CopyStr(SalesCrMemo."Bill-to Country/Region Code", 1, 2);



        ExpDtls.Add('ExpCat', ExportCategory);

        ExpDtls.Add('WithPay', WithPayOfDuty);

        ExpDtls.Add('ShipBNo', ShipmentBillNo);

        ExpDtls.Add('ShipBDt', ShipmentBillDate);

        ExpDtls.Add('Port', ExitPort);

        ExpDtls.Add('InvForCur', DocumentAmount);

        ExpDtls.Add('ForCur', CurrencyCode);

        ExpDtls.Add('CntCode', CountryCode);
        JsonObj1.Add('ExpDtls', ExpDtls);
    end;

    procedure Call_IRN_API(recAuthData: Record "GST E-Invoice(Auth Data)"; JsonString: text; ISIRNCancel: Boolean; SalesCrMemo: record "Sales Cr.Memo Header")
    var

        PostUrl: Text;
        responsetxt: text;
        httpClient: HttpClient;
        httpresponse: HttpResponseMessage;
        httprequest: HttpRequestMessage;
        httpHdr: HttpHeaders;
        httpContent: HttpContent;
        GSTEncrypt: DotNet GSTEncr_Decr;
        signedData: text;
        decryptedIRNResponse: text;
        recLocation: Record Location;
        recGSTRegNos: Record "GST Registration Nos.";
        einvoice: Record "GST E-Invoice(Auth Data)";
        LogEinvoice: Record "E-Invoice Log";
        RecRef: RecordRef;
        oStrm: OutStream;
        tempblob: Codeunit "Temp Blob";
    begin

        recLocation.get(SalesCrMemo."Location Code");
        einvoice.Get();
        recGSTRegNos.Reset();
        recGSTRegNos.SetRange(Code, recLocation."GST Registration No.");
        if recGSTRegNos.FindFirst() then;
        //CLEAR(glHTTPRequest);
        //PostUrl := (genledSetup."GST IRN Generation URL");
        if not ISIRNCancel then
            PostUrl := (einvoice.IRNUrl)
        else
            PostUrl := (einvoice.CancelIRN);

        HttpContent.WriteFrom(JsonString);
        HttpContent.GetHeaders(HttpHdr);
        HttpHdr.Add('client_id', recGSTRegNos."E-Invoice Client ID");
        HttpHdr.Add('client_secret', recGSTRegNos."E-Invoice Client Secret");
        HttpHdr.Add('gstin', recGSTRegNos.Code);
        HttpHdr.Add('user_name', recGSTRegNos."E-Invoice UserName");
        //HttpHdr.Add('authtoken', recAuthData."Auth Token");
        HttpHdr.Remove('Content-Type');
        HttpHdr.Add('Content-Type', 'application/json');

        Httpclient.DefaultRequestHeaders.Add('AuthToken', recAuthData."Auth Token");
        if Httpclient.Post(PostUrl, HttpContent, httpresponse) then begin
            httpresponse.Content.ReadAs(responsetxt);
            //servicepointmanager.SecurityProtocol := securityprotocol.Tls12;

            signedData := ParseResponse_IRN_ENCRYPT(responsetxt, ISIRNCancel, SalesCrMemo);

            GSTEncrypt := GSTEncrypt.RSA_AES();
            decryptedIRNResponse := GSTEncrypt.DecryptBySymmetricKey(signedData, recAuthData.DecryptedSEK);

            // path := 'E:\GST_invoice\file_'+DELCHR(FORMAT(TODAY),'=',char)+'_'+DELCHR(FORMAT(TIME),'=',char)+'.txt';//+FORMAT(TODAY)+FORMAT(TIME)+'.txt';
            // File.CREATE(path);
            // File.CREATEOUTSTREAM(Outstr);
            // Outstr.WRITETEXT(decryptedIRNResponse);
            ParseResponse_IRN_DECRYPT(decryptedIRNResponse, ISIRNCancel, SalesCrMemo);

        END
        ELSE BEGIN
            httpresponse.Content.ReadAs(responsetxt);
            Message(responsetxt);
            LogEinvoice.Reset();
            LogEinvoice.SetRange("Document Type", LogEinvoice."Document Type"::Invoice);
            LogEinvoice.SetRange("Document No.", SalesCrMemo."No.");
            if LogEinvoice.FindFirst() then begin
                LogEinvoice.Status := LogEinvoice.Status::Error;
                LogEinvoice."Error Message" := CopyStr(responsetxt, 1, 1023);
                LogEinvoice.Modify();
            end
            else begin
                LogEinvoice.Init();
                LogEinvoice."Document Type" := LogEinvoice."Document Type"::Invoice;
                LogEinvoice."Document No." := SalesCrMemo."No.";
                //LogEinvoice."Response JSON".Import(responsetxt);
                LogEinvoice.Status := LogEinvoice.Status::Error;
                LogEinvoice."Error Message" := CopyStr(responsetxt, 1, 1023);
                LogEinvoice.Insert();
                RecRef.Get(LogEinvoice.RecordId);
                tempblob.CreateOutStream(oStrm);
                oStrm.WriteText(responsetxt);
                tempblob.ToRecordRef(RecRef, LogEinvoice.FieldNo("Response JSON"));
                RecRef.MODIFY;

            END;
        end;

    end;


    procedure ParseResponse_IRN_ENCRYPT(TextResponse: text; ISIrnCancel: Boolean; SalesCrMemo: Record "Sales Cr.Memo Header"): Text;
    var
        message1: Text;
        CurrentObject: Text;
        CurrentElement: Text;
        ValuePair: Text;
        txtEWBNum: Text;
        txtStatus: Text;
        CurrentValue: Text;
        txtError: text;
        txtSignedData: text;
        txtInfodDtls: text;
        Jtoken: JsonToken;
        LogEinvoice: Record "E-Invoice Log";
        oStrm: OutStream;
        tempblob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        ResponseJson: JsonObject;
        EinvoiceSetup: Record "GST E-Invoice(Auth Data)";
    begin
        //Get value from Json Response >>
        EinvoiceSetup.Get();
        ResponseJson.ReadFrom(TextResponse);
        if ResponseJson.Get('Status', Jtoken) then
            if Jtoken.AsValue().AsText() = '0' then begin
                if EinvoiceSetup."Enable Log" then begin
                    LogEinvoice.Reset();
                    LogEinvoice.SetRange("Document Type", LogEinvoice."Document Type"::Invoice);
                    LogEinvoice.SetRange("Document No.", SalesCrMemo."No.");
                    if LogEinvoice.FindFirst() then begin
                        LogEinvoice.Status := LogEinvoice.Status::Error;
                        LogEinvoice."Error Message" := CopyStr(TextResponse, 1, 1023);
                        LogEinvoice.Modify();
                    end
                    else begin
                        LogEinvoice.Init();
                        LogEinvoice."Document Type" := LogEinvoice."Document Type"::Invoice;
                        LogEinvoice."Document No." := SalesCrMemo."No.";

                        LogEinvoice.Status := LogEinvoice.Status::Error;
                        LogEinvoice."Error Message" := CopyStr(TextResponse, 1, 1023);
                        LogEinvoice.Insert();
                    end;

                    RecRef.Get(LogEinvoice.RecordId);
                    tempblob.CreateOutStream(oStrm);
                    oStrm.WriteText(TextResponse);
                    tempblob.ToRecordRef(RecRef, LogEinvoice.FieldNo("Response JSON"));
                    RecRef.MODIFY;
                end;
                Commit();

                if ISIRNCancel then
                    Error('Error in IRN cancellation : %1', TextResponse)
                else
                    Error('Error in IRN generation : %1', TextResponse);
            end
            else
                if ResponseJson.Get('Data', Jtoken) then
                    txtSignedData := Jtoken.AsValue().AsText();
        EXIT(txtSignedData);

    end;

    procedure ParseResponse_IRN_DECRYPT(TextResponse: text; IsIrnCancel: Boolean; SalesCrMemo: Record "Sales Cr.Memo Header"): Text;
    var
        message1: Text;
        CurrentObject: Text;
        CurrentElement: Text;
        ValuePair: Text;
        txtEWBNum: Text;
        CurrentValue: Text;
        txtCancelDate: text;
        txtAckNum: Text;
        txtIRN: Text;
        txtAckDate: Text;
        txtSignedInvoice: Text;
        txtSignedQR: Text;
        txtEWBDt: text;
        txtEWBValid: Text;
        recSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        txtRemarks: Text;
        DataJson: JsonObject;
        jtoken: JsonToken;
        txtCancelIRNDate: text;
        txtCancelEwayNum: Text;
        txtCancelEWayDt: text;
    begin
        //Get value from Json Response >>

        Message(TextResponse);
        DataJson.ReadFrom(TextResponse);
        if DataJson.get('AckNo', jtoken) then
            txtAckNum := jtoken.AsValue().AsText();

        if DataJson.get('AckDt', jtoken) then
            txtAckDate := jtoken.AsValue().AsText();

        if DataJson.get('Irn', jtoken) then
            txtIRN := jtoken.AsValue().AsText();

        if DataJson.get('SignedInvoice', jtoken) then
            txtSignedInvoice := jtoken.AsValue().AsText();

        if DataJson.get('SignedQRCode', jtoken) then
            txtSignedQR := jtoken.AsValue().AsText();

        if DataJson.get('EwbNo', jtoken) then
            if not jtoken.AsValue().IsNull() then
                txtEWBNum := jtoken.AsValue().AsText();

        if DataJson.get('EwbDt', jtoken) then
            if not jtoken.AsValue().IsNull() then
                txtEWBDt := jtoken.AsValue().AsText();

        if DataJson.get('EwbValidTill', jtoken) then
            if not jtoken.AsValue().IsNull() then
                txtEWBValid := jtoken.AsValue().AsText();

        if DataJson.get('Remarks', jtoken) then
            if not jtoken.AsValue().IsNull() then
                txtRemarks := jtoken.AsValue().AsText();

        if DataJson.get('CancelDate', jtoken) then
            if not jtoken.AsValue().IsNull() then begin
                txtCancelIRNDate := jtoken.AsValue().AsText();
                txtCancelEWayDt := jtoken.AsValue().AsText();
            end;
        if DataJson.get('ewayBillNo', jtoken) then
            txtCancelEwayNum := jtoken.AsValue().AsText();

        recSalesCrMemoHeader.RESET;
        recSalesCrMemoHeader.SETFILTER("No.", '=%1', SalesCrMemo."No.");
        IF recSalesCrMemoHeader.FINDFIRST THEN BEGIN
            if not IsIrnCancel then
                UpdateHeaderIRN(txtSignedQR, txtIRN, txtAckDate, txtAckNum, SalesCrMemo)//23102020
            else
                UpdateCancelSalesCrIRN(txtIRN, txtCancelIRNDate, SalesCrMemo);
        END;

        EXIT(txtIRN);

    end;

    procedure UpdateHeaderIRN(QRCodeInput: Text; IRNTxt: Text; AckDt: text; AckNum: Text; SalesCrMemo: Record "Sales Cr.Memo Header")
    var
        FieldRef1: FieldRef;
        QRCodeFileName: Text;
        // TempBlob1: Record TempBlob;
        RecRef1: RecordRef;
        QRGenerator: Codeunit "QR Generator";
        CU_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
        dtText: text;
        blobCU: Codeunit "Temp Blob";
        acknwoledgeDate: DateTime;
        LogEinvoice: Record "E-Invoice Log";
        recref: RecordRef;
        EinvoiceSetup: Record "GST E-Invoice(Auth Data)";
    begin

        //GET SI HEADER REC AND SAVE QR INTO BLOB FIELD


        RecRef1.OPEN(114);
        FieldRef1 := RecRef1.FIELD(3);
        FieldRef1.SETRANGE(SalesCrMemo."No.");//Parameter
        IF RecRef1.FINDFIRST THEN BEGIN
            // RecRef1.FieldIndex()
            // FieldRef1 := RecRef1.FIELD(18173);//QR
            // FieldRef1.VALUE := TempBlob1.Blob;
            QRGenerator.GenerateQRCodeImage(QRCodeInput, blobCU);
            // FieldRef1 := RecRef1.FIELD(SalesHead.FieldNo("QR Code"));//QR
            FieldRef1 := RecRef1.FIELD(SalesCrMemo.FieldNo("QR Code"));//QR
            blobCU.ToRecordRef(RecRef1, SalesCrMemo.FieldNo("QR Code"));


            FieldRef1 := RecRef1.FIELD(SalesCrMemo.FieldNo("IRN Hash"));//IRN Num
            FieldRef1.VALUE := IRNTxt;
            FieldRef1 := RecRef1.FIELD(SalesCrMemo.FieldNo("Acknowledgement No."));//AckNum
            FieldRef1.VALUE := ACkNum;
            dtText := CU_SalesInvoice.ConvertAckDt(AckDt);
            EVALUATE(acknwoledgeDate, dtText);
            FieldRef1 := RecRef1.FIELD(SalesCrMemo.FieldNo("Acknowledgement Date"));//AckDate
            FieldRef1.VALUE := acknwoledgeDate;
            RecRef1.MODIFY;
            Commit();
            EinvoiceSetup.get;
            if EinvoiceSetup."Enable Log" then begin

                LogEinvoice.Reset();
                LogEinvoice.SetRange("Document Type", LogEinvoice."Document Type"::Invoice);
                LogEinvoice.SetRange("Document No.", SalesCrMemo."No.");
                if Not LogEinvoice.FindFirst() then begin
                    LogEinvoice.Init();
                    LogEinvoice."Document Type" := LogEinvoice."Document Type"::Invoice;
                    LogEinvoice."Document No." := SalesCrMemo."No.";
                    LogEinvoice."Invoice Reference Number" := SalesCrMemo."IRN Hash";
                    LogEinvoice."Acknowledgment Date" := format(SalesCrMemo."Acknowledgement Date");
                    LogEinvoice.Acknowledgment_number := SalesCrMemo."Acknowledgement No.";
                    LogEinvoice."QR Code" := QRCodeInput;
                    LogEinvoice.Status := LogEinvoice.Status::Generated;

                    LogEinvoice.Insert();

                end
                else begin
                    LogEinvoice."Invoice Reference Number" := SalesCrMemo."IRN Hash";
                    LogEinvoice."Acknowledgment Date" := format(SalesCrMemo."Acknowledgement Date");
                    LogEinvoice.Acknowledgment_number := SalesCrMemo."Acknowledgement No.";
                    LogEinvoice."QR Code" := QRCodeInput;
                    LogEinvoice.Status := LogEinvoice.Status::Generated;
                    LogEinvoice.Modify();
                end;
                recref.Get(LogEinvoice.RecordId);
                blobCU.ToRecordRef(recref, LogEinvoice.FieldNo("Signed QR Code"));
                recref.Modify();

            end;
        END;
        // Erase the temporary file.
        // IF NOT ISSERVICETIER THEN
        //     IF EXISTS(QRCodeFileName) THEN
        //         ERASE(QRCodeFileName);

    end;



    procedure CancelSalesCrMemo_IRN(recSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        jObject: JsonObject;
        GSTInv_DLL: DotNet GSTEncr_Decr;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        encryptedIRNPayload: text;
        JsonPayload: Text;
        codeReason: Code[10];
        EInvoice: Codeunit GST_Einvoice_CrMemo;
        jsonString: text;
        DocumentNum: Code[10];
        txtDecryptedSek: Text;
        JsonObj1: JsonObject;
        E_Invoice: Codeunit E_Invoice_SalesInvoice;
        finalPayload: Text;

    begin


        JsonObj1.Add('Irn', recSalesCrMemoHeader."IRN Hash");


        Case recSalesCrMemoHeader."Cancel Reason" of
            recSalesCrMemoHeader."Cancel Reason"::Duplicate:
                codeReason := '1';
            recSalesCrMemoHeader."Cancel Reason"::"Data Entry Mistake":
                codeReason := '2';
            recSalesCrMemoHeader."Cancel Reason"::"Order Canceled":
                codeReason := '3';
            recSalesCrMemoHeader."Cancel Reason"::Other:
                codeReason := '4';
        end;
        // codeReason:
        JsonObj1.Add('CnlRsn', codeReason);

        JsonObj1.Add('CnlRem', recSalesCrMemoHeader."E-Invoice Cancel Remarks");

        JsonObj1.WriteTo(jsonString);

        // GenerateAuthToken(recSalesCrMemoHeader);//Auth Token ans Sek stored in Auth Table //IRN Encrypted with decrypted Sek that was decrypted by Appkey(Random 32-bit)
        E_Invoice.GenerateAuthToken();
        recAuthData.Get();
        txtDecryptedSek := recAuthData.DecryptedSEK;

        Message(jsonString);

        GSTInv_DLL := GSTInv_DLL.RSA_AES();
        // base64IRN := CU_Base64.ToBase64(JsonText);
        encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);

        jObject.Add('Data', encryptedIRNPayload);

        jObject.WriteTo(finalPayload);
        // Message('FinalIRNPayload %1 ', finalPayload);
        Call_IRN_API(recAuthData, finalPayload, true, recSalesCrMemoHeader);
    end;

    procedure UpdateCancelSalesCrIRN(txtIRN: Text; CancelDate: Text; recSalesCrHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrHeader: Record "Sales Cr.Memo Header";
        txtCancelDate: text;
        CUSalesInvoice: Codeunit E_Invoice_SalesInvoice;
    begin
        SalesCrHeader.get(recSalesCrHeader."No.");
        SalesCrHeader."IRN Hash" := txtIRN;
        txtCancelDate := CUSalesInvoice.ConvertAckDt(CancelDate);
        evaluate(SalesCrHeader."E-Inv. Cancelled Date", txtCancelDate);
        SalesCrHeader.Modify();

    end;


    // procedure MoveToMagicPath(SourceFileName: text): text;
    // var
    //     DestinationFileName: Text;
    //     FileManagement: Codeunit "File Management";
    //     FileSystemObject: Text;
    // begin


    // User Temp Path
    // DestinationFileName := COPYSTR(FileManagement.ClientTempFileName(''), 1, 1024);
    // // IF ISCLEAR(FileSystemObject) THEN
    // //   CREATE(FileSystemObject,TRUE,TRUE);
    // FileManagement.MoveFile(SourceFileName, DestinationFileName);
    // end;


}
