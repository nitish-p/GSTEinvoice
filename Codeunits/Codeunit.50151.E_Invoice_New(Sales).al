//Creating New Codeunit for E-Invoice and E-Way bill  **CITS_RS

dotnet
{

    assembly(GST_Invoice_Encrypt)
    {
        type(GST_Invoice_Encrypt.RSA_AES; GSTEncr_Decr) { }
    }
    assembly(mscorlib)
    {
        type(System.Array; Array) { }
        type(System.Byte; Byte) { }
        type(System.Text.Encoding; Encoding) { }
    }

    // assembly(ClassLibrary1)
    // {
    //     type(ConsoleApp1.EncryptUserCreds; GST_Bouncy) { }
    // }

    // assembly(GST_Invoice103)
    // {
    //     type(GST_Invoice103.EInvoice; GST103) { }
    // }


}
codeunit 50151 E_Invoice_SalesInvoice
{
    trigger OnRun()
    begin

    end;

    procedure GenerateIRN_01(SalesHead: Record "Sales Invoice Header")
    var
        txtDecryptedSek: text;
        GSTInv_DLL: DotNet GSTEncr_Decr;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        FinalJson: JsonObject;
        eInvoiceJsonHandler: Codeunit "e-Invoice Json Handler";
        encryptedIRNPayload: text;
        finalPayload: text;
        JObject: JsonObject;
        GSTManagement: Codeunit "e-Invoice Management";
        CU_Base64: Codeunit "Base64 Convert";
        base64IRN: text;
        CurrExRate: Integer;
        // GSTBouncyDLL: DotNet GST_Bouncy;
        // GST103: DotNet GST103;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        clear(GlobalNULL);

        DocumentNo := SalesHead."No.";

        IF GSTManagement.IsGSTApplicable(SalesHead."No.", 36) THEN BEGIN
            IF SalesHead."GST Customer Type" IN
                [SalesHead."GST Customer Type"::Unregistered,
                SalesHead."GST Customer Type"::" "] THEN
                ERROR('E-Invoicing is not applicable for Unregistered, Export and Deemed Export Customers.');

        end;
        IF SalesHead."Currency Factor" <> 0 THEN
            CurrExRate := 1 / SalesHead."Currency Factor"
        ELSE
            CurrExRate := 1;

        JObject.Add('Version', '1.1');
        WriteTransDtls(JObject, SalesHead);
        WriteDocDtls(JObject, SalesHead);
        WriteSellerDtls(JObject, SalesHead);
        WriteBuyerDtls(JObject, SalesHead, gl_BillToPh, gl_BillToEm);
        WriteItemDtls(JObject, SalesHead, CurrExRate);
        WriteValDtls(JObject, SalesHead);
        WriteExpDtls(JObject, SalesHead);
        JObject.WriteTo(JsonText);


        GenerateAuthToken();

        recAuthData.Get();
        // recAuthData.Reset();
        // // recAuthData.SetRange(DocumentNum, SalesHead."No.");//Document number is universal for all documents and both E-Invoice and E-Way Bill 250922
        // if recAuthData.Findlast() then begin
        // Message('DecryptedSEK %1', recAuthData.DecryptedSEK);
        txtDecryptedSek := recAuthData.DecryptedSEK;

        Message(JsonText);
        GSTInv_DLL := GSTInv_DLL.RSA_AES();
        encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(JsonText, txtDecryptedSek);
        FinalJson.Add('Data', encryptedIRNPayload);
        FinalJson.WriteTo(finalPayload);
        // Message('FinalIRNPayload %1 ', finalPayload);
        Call_IRN_API(recAuthData, finalPayload, false, SalesHead, false, false);

        if DocumentNo = '' then
            Error(DocumentNoBlankErr);
    end;



    procedure GenerateAuthToken(): text;
    var
        plainAppkey: text;
        jsonString: text;
        //Myfile: File;
        encryptedPayload: text;
        Instream1: InStream;
        encoding: DotNet Encoding;

        keyTxt: text;
        finPayload: text;
        GSTEncr_Decr: DotNet GSTEncr_Decr;
        encryptedPass: text;
        base64Payload: text;
        rec_GSTRegNos: Record "GST Registration Nos.";
        pass: label 'Barbeque@123';
        encryptedAppKey: text;
        bytearr: DotNet Array;
        recCustomer: Record Customer;
        //GSTRegNos: Record "GST Registration Nos.";
        CU_base64: Codeunit "Base64 Convert";
        recLocation: Record Location;
        JObject: JsonObject;
        FinalJson: JsonObject;
        base64: Codeunit "Base64 Convert";
        tokenkey: Text;
        EinvoiceSetup: Record "GST E-Invoice(Auth Data)";
        base64PlainKey: Text;
    begin

        EinvoiceSetup.Get();
        // recLocation.Get(LocCode);
        // GSTRegNos.Reset();
        // GSTRegNos.SetRange(Code, recLocation."GST Registration No.");
        // if GSTRegNos.FindFirst() then;
        if EinvoiceSetup."Expiry Date Time" < CurrentDateTime then begin
            GSTEncr_Decr := GSTEncr_Decr.RSA_AES();
            encryptedPass := GSTEncr_Decr.EncryptAsymmetric(pass, EinvoiceSetup."Public Key");
            plainAppkey := GSTEncr_Decr.RandomString(32, FALSE);
            base64PlainKey := base64.ToBase64(plainAppkey);
            //bytearr := encoding.UTF8.GetBytes(plainAppkey);
            JObject.Add('userName', EinvoiceSetup.UserName);
            JObject.Add('password', EinvoiceSetup.Password);
            JObject.Add('AppKey', base64PlainKey);
            JObject.Add('ForceRefreshAuthToken', 'true');
            JObject.WriteTo(jsonString);
            //Convert to base 64 string first and then encrypt with the GST Public Key then populate the Final Json payload
            base64Payload := CU_base64.ToBase64(jsonString);
            // Message(base64Payload);
            keyTxt := EinvoiceSetup."Public Key";
            // Message('Key text %1', keyTxt);
            //GSTEncr_Decr := GSTEncr_Decr;
            encryptedPayload := GSTEncr_Decr.EncryptAsymmetric(base64Payload, keyTxt);

            FinalJson.Add('Data', encryptedPayload);
            FinalJson.WriteTo(finPayload);
            tokenkey := getAuthfromNIC(finPayload, plainAppkey);
            // Message(finPayload);
            exit(tokenkey);
        end
        Else begin
            exit(EinvoiceSetup."Auth Token");
        end;
    end;

    procedure getAuthfromNIC(JsonString: text; PlainKey: Text): Text
    var
        responsetxt: text;
        httpClient: HttpClient;
        httpresponse: HttpResponseMessage;
        httprequest: HttpRequestMessage;
        httpHdr: HttpHeaders;
        httpContent: HttpContent;
        recGSTREgNos: Record "GST Registration Nos.";
        recLocation: Record Location;
        PostUrl: Text;
        EinvoiceSetup: Record "GST E-Invoice(Auth Data)";
        tokenkey: text;
    begin
        EinvoiceSetup.Get();

        //servicepointmanager.SecurityProtocol := securityprotocol.Tls12;

        PostUrl := EinvoiceSetup."Auth Token Url";
        HttpContent.WriteFrom(JsonString);
        HttpContent.GetHeaders(HttpHdr);
        HttpHdr.Add('client_id', EinvoiceSetup.ClientId);
        HttpHdr.Add('client_secret', EinvoiceSetup.secretId);
        HttpHdr.Add('GSTIN', EinvoiceSetup.GSTIN);//NP ccit-070224
        HttpHdr.Remove('Content-Type');
        HttpHdr.Add('Content-Type', 'application/json');


        if Httpclient.Post(PostUrl, HttpContent, httpresponse) then begin
            httpresponse.Content.ReadAs(responsetxt);
            tokenkey := ParseAuthResponse(responsetxt, PlainKey);
        END;
        exit(tokenkey);
    END;

    procedure ParseAuthResponse(TextResponse: text; PlainKey: text): text;
    var

        PlainSEK: text;
        GSTIn_DLL: DotNet GSTEncr_Decr;
        txtStatus: text;
        txtAuthT: text;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        l: Integer;
        txtError: text;
        txtEncSEK: text;
        errPOS: Integer;
        txtExpiry: text;
        bytearr: DotNet Array;
        encoding: DotNet Encoding;
        txtExpireTime: text;
        JObject: JsonObject;
        DataObject: JsonObject;
        Jtoken: JsonToken;
        DataToken: JsonToken;
    begin
        // Message(TextResponse);
        JObject.ReadFrom(TextResponse);
        JObject.Get('Status', jtoken);
        if Jtoken.AsValue().AsText() = '1' then begin
            if JObject.Get('Data', Jtoken) then begin
                DataObject := Jtoken.AsObject();
                if DataObject.Get('AuthToken', Jtoken) then begin
                    txtAuthT := Jtoken.AsValue().AsText();

                end;
                if DataObject.Get('Sek', Jtoken) then begin
                    txtEncSEK := Jtoken.AsValue().AsText();
                    //einvoice."Decrypted Sek" := Encrypt.DecryptBySymmetricKeyByte(einvoice.sek, Keytext);
                end;
                if DataObject.Get('TokenExpiry', Jtoken) then begin
                    txtExpiry := Jtoken.AsValue().AsText();
                end;
            end;
        end
        else begin
            if JObject.Get('ErrorDetails', Jtoken) then
                Error(Format(Jtoken.AsArray()));
        end;


        recAuthData.Get();
        recAuthData."Auth Token" := txtAuthT;
        recAuthData.SEK := txtEncSEK;
        recAuthData."Insertion DateTime" := CurrentDateTime;
        Evaluate(recAuthData."Expiry Date Time", txtExpiry);
        txtExpireTime := copystr(txtExpiry, strpos(txtExpiry, ' '));
        txtExpireTime := DelChr(txtExpireTime, '=', ' ');
        evaluate(recAuthData."Token Duration", txtExpireTime);
        recAuthData.PlainAppKey := PlainKey;
        evaluate(recAuthData."Expiry Date", copystr(txtExpiry, 1, StrPos(txtExpiry, ' ') - 1));
        // recAuthData.DocumentNum := SIHeader."No.";//token is universal for every document and both E-Invoice and E-Way Bill 250922

        GSTIn_DLL := GSTIn_DLL.RSA_AES();
        bytearr := encoding.UTF8.GetBytes(recAuthData.PlainAppKey);
        PlainSEK := GSTIn_DLL.DecryptBySymmetricKey(recAuthData.SEK, bytearr);
        // message('SEK 1 %1,', PlainSEK);
        recAuthData.DecryptedSEK := PlainSEK;
        recAuthData.Modify();

        EXIT(txtAuthT);
    end;

    procedure Call_IRN_API(recAuthData: Record "GST E-Invoice(Auth Data)"; JsonString: text; IsIRNCancel: Boolean; SalesHead: record "Sales Invoice Header"; IsEWayBill: Boolean; IsEWayCancel: Boolean)
    var

        httpClient: HttpClient;
        httpresponse: HttpResponseMessage;
        httprequest: HttpRequestMessage;
        httpHdr: HttpHeaders;
        httpContent: HttpContent;
        GSTEncrypt: DotNet GSTEncr_Decr;
        decryptedIRNResponse: text;
        recLocation: Record Location;
        recGSTRegNos: Record "GST Registration Nos.";
        PostUrl: Text;
        responsetxt: Text;
        EinvoiceSetup: Record "GST E-Invoice(Auth Data)";
        LogEinvoice: Record "E-Invoice Log";
        RecRef: RecordRef;
        oStrm: OutStream;
        tempblob: Codeunit "Temp Blob";
    begin
        EinvoiceSetup.GET;
        recLocation.get(SalesHead."Location Code");
        recGSTRegNos.Reset();
        recGSTRegNos.SetRange(Code, recLocation."GST Registration No.");
        if recGSTRegNos.FindFirst() then;

        //servicepointmanager.SecurityProtocol := securityprotocol.Tls12;
        if IsEWayBill then
            PostUrl := EinvoiceSetup.EWBUrl
        else
            if IsIRNCancel then
                PostUrl := (EinvoiceSetup.CancelIRN)
            else
                if IsEWayCancel then
                    PostUrl := (EinvoiceSetup.CancelEWB)
                else
                    PostUrl := (EinvoiceSetup.IRNUrl);

        HttpContent.WriteFrom(JsonString);
        HttpContent.GetHeaders(HttpHdr);
        HttpHdr.Add('client_id', recGSTRegNos."E-Invoice Client ID");
        HttpHdr.Add('client_secret', recGSTRegNos."E-Invoice Client Secret");
        HttpHdr.Add('gstin', recGSTRegNos.Code);//NP ccit-070224
        if not IsEWayCancel then
            HttpHdr.Add('user_name', recGSTRegNos."E-Invoice UserName");
        HttpHdr.Remove('Content-Type');
        HttpHdr.Add('Content-Type', 'application/json');

        Httpclient.DefaultRequestHeaders.Add('AuthToken', recAuthData."Auth Token");
        if Httpclient.Post(PostUrl, HttpContent, httpresponse) then begin
            httpresponse.Content.ReadAs(responsetxt);

            signedData := ParseResponse_IRN_ENCRYPT(responsetxt, IsEWayBill, IsEWayCancel, IsIRNCancel, SalesHead);

            GSTEncrypt := GSTEncrypt.RSA_AES();
            decryptedIRNResponse := GSTEncrypt.DecryptBySymmetricKey(signedData, recAuthData.DecryptedSEK);
            Message(decryptedIRNResponse);
            ParseResponse_IRN_DECRYPT(decryptedIRNResponse, IsEWayBill, IsEWayCancel, IsIRNCancel, SalesHead);
        END
        else begin
            httpresponse.Content.ReadAs(responsetxt);
            Message(responsetxt);
            if EinvoiceSetup."Enable Log" then begin
                LogEinvoice.Reset();
                LogEinvoice.SetRange("Document Type", LogEinvoice."Document Type"::Invoice);
                LogEinvoice.SetRange("Document No.", SalesHead."No.");
                if LogEinvoice.FindFirst() then begin
                    LogEinvoice.Status := LogEinvoice.Status::Error;
                    LogEinvoice."Error Message" := CopyStr(responsetxt, 1, 1023);
                    LogEinvoice.Modify();
                end
                else begin
                    LogEinvoice.Init();
                    LogEinvoice."Document Type" := LogEinvoice."Document Type"::Invoice;
                    LogEinvoice."Document No." := SalesHead."No.";
                    // LogEinvoice."Response JSON".Import(responsetxt);
                    LogEinvoice.Status := LogEinvoice.Status::Error;
                    LogEinvoice."Error Message" := CopyStr(responsetxt, 1, 1023);
                    LogEinvoice.Insert();
                    RecRef.Get(LogEinvoice.RecordId);
                    tempblob.CreateOutStream(oStrm);
                    oStrm.WriteText(responsetxt);
                    tempblob.ToRecordRef(RecRef, LogEinvoice.FieldNo("Response JSON"));
                    RecRef.MODIFY;
                end;
            end;
        end;


    end;

    procedure ParseResponse_IRN_ENCRYPT(TextResponse: text; IsEwayBill: boolean; IsEwayCancel: Boolean; ISIRNCancel: Boolean; saleInvHdr: Record "Sales Invoice Header"): Text;
    var
        message1: Text;
        CurrentObject: Text;
        ResponseJson: JsonObject;
        p: Integer;
        l: Integer;
        errPOS: Integer;
        x: Integer;
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
        EinvoiceSetup: Record "GST E-Invoice(Auth Data)";
    begin
        //Get value from Json Response >>
        /*{
            "Status": 0,
            "ErrorDetails": [
                {
                    "ErrorCode": "2150",
                    "ErrorMessage": "Duplicate IRN"
                }
            ],
            "Data": null,
            "InfoDtls": [
                {
                    "InfCd": "DUPIRN",
                    "Desc": {
                        "AckNo": 112410193157267,
                        "AckDt": "2024-09-02 18:35:00",
                        "Irn": "51fccf1047cf806eb7ad51d1e9cb163e05b2c5f9f492f1d882dd930a3f747709"
                    }
                }
            ]
        }*/
        EinvoiceSetup.Get();
        ResponseJson.ReadFrom(TextResponse);
        if ResponseJson.Get('Status', Jtoken) then
            if Jtoken.AsValue().AsText() = '0' then begin
                if EinvoiceSetup."Enable Log" then begin
                    LogEinvoice.Reset();
                    LogEinvoice.SetRange("Document Type", LogEinvoice."Document Type"::Invoice);
                    LogEinvoice.SetRange("Document No.", saleInvHdr."No.");
                    if LogEinvoice.FindFirst() then begin
                        LogEinvoice.Status := LogEinvoice.Status::Error;
                        LogEinvoice."Error Message" := CopyStr(TextResponse, 1, 1023);
                        LogEinvoice.Modify();
                    end
                    else begin
                        LogEinvoice.Init();
                        LogEinvoice."Document Type" := LogEinvoice."Document Type"::Invoice;
                        LogEinvoice."Document No." := saleInvHdr."No.";

                        LogEinvoice.Status := LogEinvoice.Status::Error;
                        LogEinvoice."Error Message" := CopyStr(TextResponse, 1, 1023);
                        LogEinvoice.Insert();
                    end;
                    RecRef.Get(LogEinvoice.RecordId);
                    tempblob.CreateOutStream(oStrm);
                    oStrm.WriteText(TextResponse);
                    tempblob.ToRecordRef(RecRef, LogEinvoice.FieldNo("Response JSON"));
                    RecRef.MODIFY;
                    Commit();
                end;
                if IsEwayBill then
                    Error('Error in E-Way Bill generation : %1', TextResponse)
                else
                    if IsEwayCancel then
                        Error('Error in E-Way Bill cancellation : %1', TextResponse)
                    else
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

    procedure ParseResponse_IRN_DECRYPT(TextResponse: text; IsEWayBill: Boolean; IsEwayCancel: Boolean; ISIRNCancel: Boolean; SalesHead: Record "Sales Invoice Header"): Text;
    var
        message1: Text;
        CurrentObject: Text;
        DataJson: JsonObject;
        CurrentElement: Text;
        ValuePair: Text;
        txtEWBNum: Text;
        CurrentValue: Text;
        txtAckNum: Text;
        txtIRN: Text;
        txtAckDate: Text;
        txtSignedInvoice: Text;
        txtCancelIRNDate: text;
        txtSignedQR: Text;
        txtEWBDt: text;
        recSIHead: Record "Sales Invoice Header";
        txtEWBValid: Text;
        txtRemarks: Text;
        txtCancelEwayNum: Text;
        txtCancelEWayDt: text;
        CU_EWaybill: Codeunit Generate_EWayBill_SalesInvoice;
        jtoken: JsonToken;
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

        recSIHead.RESET;
        recSIHead.SETFILTER("No.", '=%1', SalesHead."No.");
        IF recSIHead.FINDFIRST THEN BEGIN
            if IsEWayBill then
                CU_EWaybill.UpdateHeaderIRN(txtEWBDt, txtEWBNum, txtEWBValid, SalesHead)//230622
            else
                if ISIRNCancel then
                    UpdateCancelDetails(txtIRN, txtCancelIRNDate, SalesHead)//150722
                else
                    if IsEwayCancel then
                        CU_EWaybill.UpdateEWayCancelHeader(txtCancelEwayNum, txtCancelEWayDt, SalesHead)//160722
                    else
                        UpdateHeaderIRN(txtSignedQR, txtIRN, txtAckDate, txtAckNum, SalesHead);//23102020


        END;

        EXIT(txtIRN);

    end;


    procedure UpdateHeaderIRN(QRCodeInput: Text; IRNTxt: Text; AckDt: text; AckNum: Text; SalesHead: Record "Sales Invoice Header")
    var
        FieldRef1: FieldRef;
        QRCodeFileName: Text;
        // TempBlob1: Record TempBlob;
        QRGenerator: Codeunit "QR Generator";
        RecRef1: RecordRef;
        dtText: text;
        inStr: InStream;
        acknwoledgeDate: DateTime;
        cu_jsonhandler: Codeunit "e-Invoice Json Handler";
        LogEinvoice: Record "E-Invoice Log";
        blobCU: Codeunit "Temp Blob";
        recref: RecordRef;
        EinvoiceSetup: Record "GST E-Invoice(Auth Data)";
    //FileManagement: Codeunit "File Management";
    begin

        //GET SI HEADER REC AND SAVE QR INTO BLOB FIELD
        RecRef1.OPEN(112);
        FieldRef1 := RecRef1.FIELD(3);
        FieldRef1.SETRANGE(SalesHead."No.");//Parameter
        IF RecRef1.FINDFIRST THEN BEGIN

            QRGenerator.GenerateQRCodeImage(QRCodeInput, blobCU);
            // FieldRef1 := RecRef1.FIELD(SalesHead.FieldNo("QR Code"));//QR
            FieldRef1 := RecRef1.FIELD(SalesHead.FieldNo("QR Code"));//QR
            blobCU.ToRecordRef(RecRef1, SalesHead.FieldNo("QR Code"));
            FieldRef1 := RecRef1.Field(SalesHead.FieldNo("IRN Hash"));
            FieldRef1.VALUE := IRNTxt;
            // FieldRef1 := RecRef1.FIELD(18171);//AckNum
            FieldRef1 := RecRef1.Field(SalesHead.FieldNo("Acknowledgement No."));
            FieldRef1.VALUE := ACkNum;
            // FieldRef1 := RecRef1.FIELD(18174);//AckDate
            dtText := ConvertAckDt(AckDt);
            FieldRef1 := RecRef1.Field(SalesHead.FieldNo("Acknowledgement Date"));
            EVALUATE(acknwoledgeDate, dtText);
            FieldRef1.VALUE := acknwoledgeDate;
            RecRef1.MODIFY;

            Commit();
            EinvoiceSetup.Get();
            if EinvoiceSetup."Enable Log" then begin

                LogEinvoice.Reset();
                LogEinvoice.SetRange("Document Type", LogEinvoice."Document Type"::Invoice);
                LogEinvoice.SetRange("Document No.", SalesHead."No.");
                if Not LogEinvoice.FindFirst() then begin
                    LogEinvoice.Init();
                    LogEinvoice."Document Type" := LogEinvoice."Document Type"::Invoice;
                    LogEinvoice."Document No." := SalesHead."No.";
                    LogEinvoice."Invoice Reference Number" := SalesHead."IRN Hash";
                    LogEinvoice."Acknowledgment Date" := format(SalesHead."Acknowledgement Date");
                    LogEinvoice.Acknowledgment_number := SalesHead."Acknowledgement No.";
                    LogEinvoice."QR Code" := QRCodeInput;
                    LogEinvoice.Status := LogEinvoice.Status::Generated;

                    LogEinvoice.Insert();

                end
                else begin
                    LogEinvoice."Invoice Reference Number" := SalesHead."IRN Hash";
                    LogEinvoice."Acknowledgment Date" := format(SalesHead."Acknowledgement Date");
                    LogEinvoice.Acknowledgment_number := SalesHead."Acknowledgement No.";
                    LogEinvoice."QR Code" := QRCodeInput;
                    LogEinvoice.Status := LogEinvoice.Status::Generated;
                    LogEinvoice.Modify();
                end;
                recref.Get(LogEinvoice.RecordId);
                blobCU.ToRecordRef(recref, LogEinvoice.FieldNo("Signed QR Code"));
                recref.Modify();
            END;

        end;


    end;

    procedure ConvertAckDt(DtText: text): text;
    var
        DateTime_Fin: text;
        YYYY: text;
        DD: text;
        MM: text;
    begin
        YYYY := COPYSTR(DtText, 1, 4);
        MM := COPYSTR(DtText, 6, 2);
        DD := COPYSTR(DtText, 9, 2);

        // TIME := COPYSTR(AckDt2,12,8);

        DateTime_Fin := DD + '/' + MM + '/' + YYYY + ' ' + COPYSTR(DtText, 12, 8);
        // DateTime_Fin := MM + '/' + DD + '/' + YYYY + ' ' + COPYSTR(DtText, 12, 8);
        exit(DateTime_Fin);
    end;

    procedure WriteTransDtls(VAR JsonObj: JsonObject; SalesInHeader: Record "Sales Invoice Header")
    var
        category: Code[10];
        E_InvoiceHandler: Codeunit "e-Invoice Management";
        E_InvoiceHandler1: codeunit "e-Invoice Json Handler";
        TransDtls: JsonObject;
    begin
        //***Trans Detail Start
        TransDtls.Add('TaxSch', 'GST');


        IF (SalesInHeader."GST Customer Type" = SalesInHeader."GST Customer Type"::Registered)
        OR (SalesInHeader."GST Customer Type" = SalesInHeader."GST Customer Type"::Exempted) THEN BEGIN
            category := 'B2B';

        END ELSE
            IF (SalesInHeader."GST Customer Type" = SalesInHeader."GST Customer Type"::Export) THEN BEGIN
                IF SalesInHeader."GST Without Payment of Duty" THEN
                    category := 'EXPWOP'
                ELSE
                    category := 'EXPWP'
            END ELSE
                IF (SalesInHeader."GST Customer Type" = SalesInHeader."GST Customer Type"::"Deemed Export") THEN
                    category := 'DEXP';

        TransDtls.Add('SupTyp', category);//Where to pick this from
        TransDtls.Add('RegRev', 'N');
        // JsonWriter.WritePropertyName('EcmGstin');
        // JsonWriter.WriteValue(BBQ_GSTIN);
        TransDtls.Add('IgstOnIntra', 'N');
        //***Trans Detail End--
        JsonObj.Add('TranDtls', TransDtls)

    end;

    procedure WriteDocDtls(VAR JsonObj: JsonObject; SalesInHeader: Record "Sales Invoice Header")
    var
        txtDocDate: Text[20];
        Typ: Code[20];
        DocDtls: JsonObject;
    begin
        IF SalesInHeader."Invoice Type" = SalesInHeader."Invoice Type"::Taxable THEN
            Typ := 'INV'
        ELSE
            IF (SalesInHeader."Invoice Type" = SalesInHeader."Invoice Type"::"Debit Note") OR
            (SalesInHeader."Invoice Type" = SalesInHeader."Invoice Type"::Supplementary)
            THEN
                Typ := 'DBN'
            ELSE
                Typ := 'INV';
        txtDocDate := FORMAT(SalesInHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');

        //***Doc Details Start


        //DocType
        DocDtls.Add('Typ', Typ);
        //Doc Num
        DocDtls.Add('No', COPYSTR(SalesInHeader."No.", 1, 16));
        /*dtDay := FORMAT(DATE2DMY(TODAY,1));
        dtMonth := FORMAT(DATE2DMY(TODAY,2));
        dtYear := FORMAT(DATE2DMY(TODAY,3));
        txtDocDate := dtDay+'/'+dtMonth+'/'+dtYear;
        MESSAGE(txtDocDate);*/
        DocDtls.Add('Dt', txtDocDate);
        JsonObj.Add('DocDtls', DocDtls);
        //***Doc Details End--


    end;

    procedure WriteSellerDtls(VAR JsonObj: JsonObject; SalesInHeader: Record "Sales Invoice Header")
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
        WITH SalesInHeader DO BEGIN
            Location.GET(SalesInHeader."Location Code");
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
        SellerDtls.Add('Gstin', SalesInHeader."Location GST Reg. No.");

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

    procedure WriteBuyerDtls(VAR JsonObj: JsonObject; SalesInvoiceHeader: Record "Sales Invoice Header"; BilltoPh: Code[20]; BillToEm: Text[100])
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
        SalesInvoiceLine: Record "Sales Invoice Line";
        StateBuff: Record State;
        Contact: Record Contact;
        recCustomer: Record Customer;
        BuyerDtls: JsonObject;
    begin

        WITH SalesInvoiceHeader DO BEGIN
            IF "GST Customer Type" = "GST Customer Type"::Export THEN
                Gstin := 'URP'
            ELSE BEGIN
                customerrec.GET(SalesInvoiceHeader."Sell-to Customer No.");
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

            SalesInvoiceLine.SETRANGE("Document No.", "No.");
            SalesInvoiceLine.SETFILTER("GST Place of Supply", '<>%1', SalesInvoiceLine."GST Place of Supply"::" ");
            IF SalesInvoiceLine.FINDFIRST THEN
                IF SalesInvoiceLine."GST Place of Supply" = SalesInvoiceLine."GST Place of Supply"::"Bill-to Address" THEN BEGIN
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
                    IF SalesInvoiceLine."GST Place of Supply" = SalesInvoiceLine."GST Place of Supply"::"Ship-to Address" THEN BEGIN
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
            BuyerDtls.Add('Ph', Ph);
        //Email
        IF Em <> '' THEN
            BuyerDtls.Add('Em', Em);
        JsonObj.Add('BuyerDtls', BuyerDtls);
        //**Buyer Details End--
    end;

    procedure WriteItemDtls(VAR JsonObj: JsonObject; VAR SalesInHeader: Record "Sales Invoice Header"; CurrExchRt: Decimal)
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
        SalesInvoiceLine: Record "Sales Invoice Line";
        ItemList: JsonArray;
        ItemJobject: JsonObject;
    begin
        CLEAR(SlNo);
        SalesInvoiceLine.SETRANGE("Document No.", SalesInHeader."No.");
        SalesInvoiceLine.SetFilter(Amount, '>%1', 0.5);//excluding rounding lines 240922
        //  SalesInvoiceLine.SETRANGE("Non-GST Line",FALSE);
        SalesInvoiceLine.SETFILTER(Type, '<>%1', SalesInvoiceLine.Type::" ");
        IF SalesInvoiceLine.FINDSET THEN BEGIN
            IF SalesInvoiceLine.COUNT > 100 THEN
                ERROR(SalesLineErr, SalesInvoiceLine.COUNT);
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
                if SalesInvoiceLine."GST Assessable Value (LCY)" <> 0 then
                    AssAmt := SalesInvoiceLine."GST Assessable Value (LCY)"
                else
                    AssAmt := SalesInvoiceLine.Amount;



                // AssAmt := SalesInvoiceLine."GST Assessable Value (LCY)";

                //   IF SalesInvoiceLine."Free Supply" THEN
                //     FreeQty := SalesInvoiceLine.Quantity
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
                GetGSTComponentRate(
                    SalesInvoiceLine."Document No.",
                    SalesInvoiceLine."Line No.",
                    CGSTRate,
                    SGSTRate,
                    IGSTRate,
                    CessRate,
                    CesNonAdval,
                    StateCess, GSTRt
                );
                CLEAR(UOM);
                IF SalesInvoiceLine."Unit of Measure Code" <> '' THEN
                    UOM := COPYSTR(SalesInvoiceLine."Unit of Measure Code", 1, 8)
                ELSE
                    UOM := OTHTxt;
                IF SalesInvoiceLine."GST Group Type" = SalesInvoiceLine."GST Group Type"::Service THEN
                    IsServc := 'Y'
                ELSE
                    IsServc := 'N';
                /*WriteItem(
                  SalesInvoiceLine.Description + SalesInvoiceLine."Description 2",
                  SalesInvoiceLine."HSN/SAC Code",
                  SalesInvoiceLine.Quantity,
                  FreeQty,
                  UOM,
                  SalesInvoiceLine."Unit Price",
                  SalesInvoiceLine."Line Amount" + SalesInvoiceLine."Line Discount Amount",
                  SalesInvoiceLine."Line Discount Amount",
                  SalesInvoiceLine."Line Amount",
                  AssAmt,
                  CGSTRate,
                  IGSTRate,
                  IgstAmt,
                  StateCesRt,
                  CesAmt,
                  CesNonAdval,
                  StateCesRt,
                  StateCesAmt,
                  StateCesNonAdvlAmt,
                  0,
                  SalesInvoiceLine."Amount Including Tax" + SalesInvoiceLine."Total GST Amount",
                  SalesInvoiceLine."Line No.",
                  SlNo,
                  IsServc, JsonWriter, CurrExchRt, GSTRt);*/

                GetGSTValueForLine(SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No.", CGSTValue, SGSTValue, IGSTValue);
                Clear(ItemJobject);
                ItemJobject := WriteItem(
                        SalesInvoiceLine.Description + SalesInvoiceLine."Description 2", '',
                        SalesInvoiceLine."HSN/SAC Code", '',
                        SalesInvoiceLine.Quantity, FreeQty,
                        CopyStr(SalesInvoiceLine."Unit of Measure Code", 1, 10),
                        SalesInvoiceLine."Unit Price",
                        SalesInvoiceLine."Line Amount" + SalesInvoiceLine."Line Discount Amount",
                        SalesInvoiceLine."Line Discount Amount", 0,
                        AssAmt, CGSTRate, SGSTRate, IGSTRate, CessRate, CesNonAdval, StateCess,
                        (AssAmt + CGSTValue + SGSTValue + IGSTValue),
                        SlNo,
                        IsServc,
                        CurrExchRt,
                        GSTRt, CGSTValue, SGSTValue, IGSTValue);
                ItemList.Add(ItemJobject);

            UNTIL SalesInvoiceLine.NEXT = 0;
            JsonObj.Add('itemList', ItemList);
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
        if Unit <> '' then
            recUOM.Get(Unit);

        ItemObject.Add('SlNo', FORMAT(SlNo));
        IF ProductName <> '' THEN
            ItemObject.Add('PrdDesc', ProductName);
        IF IsServc <> '' THEN
            ItemObject.Add('IsServc', IsServc);
        ItemObject.Add('HsnCd', HSNCode);

        /*IF IsInvoice THEN
        InvoiceRowID := ItemTrackingManagement.ComposeRowID(DATABASE::"Sales Invoice Line",0,DocumentNo,'',0,SILineNo)
        ELSE
        InvoiceRowID := ItemTrackingManagement.ComposeRowID(DATABASE::"Sales Cr.Memo Line",0,DocumentNo,'',0,SILineNo);
        ValueEntryRelation.SETCURRENTKEY("Source RowId");
        ValueEntryRelation.SETRANGE("Source RowId",InvoiceRowID);
        IF ValueEntryRelation.FINDSET THEN BEGIN
        xLotNo := '';
        JsonTextWriter.WritePropertyName('BchDtls');
        JsonTextWriter.WriteStartObject;
        REPEAT
            ValueEntry.GET(ValueEntryRelation."Value Entry No.");
            ItemLedgerEntry.SETCURRENTKEY("Item No.",Open,"Variant Code",Positive,"Lot No.","Serial No.");
            ItemLedgerEntry.GET(ValueEntry."Item Ledger Entry No.");
            IF xLotNo <> ItemLedgerEntry."Lot No." THEN BEGIN
            WriteBchDtls(
                COPYSTR(ItemLedgerEntry."Lot No.",1,20),
                FORMAT(ItemLedgerEntry."Expiration Date",0,'<Day,2>/<Month,2>/<Year4>'),
                FORMAT(ItemLedgerEntry."Warranty Date",0,'<Day,2>/<Month,2>/<Year4>'));
            xLotNo := ItemLedgerEntry."Lot No.";
            END;
        UNTIL ValueEntryRelation.NEXT = 0;
        JsonTextWriter.WriteEndObject;
        END;
        */

        // ItemObject.Add('Barcde');
        // JsonWriter.WriteValue('null');

        ItemObject.Add('Qty', Quantity);
        ItemObject.Add('FreeQty', FreeQuantity);

        if recUOM."E-Inv UOM" = '' then
            ItemObject.Add('Unit', 'OTH')
        //Error('Please map E-Invoice UOM in UOM master !');
        else
            ItemObject.Add('Unit', recUOM."E-Inv UOM");

        // IF Unit = '' THEN
        //     JsonWriter.WriteValue(GlobalNULL);

        /*IF Unit <> '' THEN BEGIN
            IF Unit = 'KG' THEN
                Unit := 'KGS';
            JsonWriter.WriteValue(Unit)
        END ELSE*/


        ItemObject.Add('UnitPrice', UnitPrice);// * CurrExRate);

        ItemObject.Add('TotAmt', TotAmount);// * CurrExRate);

        ItemObject.Add('Discount', Discount);// * CurrExRate);

        // JsonWriter.WritePropertyName('PreTaxVal');
        // JsonWriter.WriteValue(PreTaxVal * CurrExRate);

        ItemObject.Add('AssAmt', Round(AssessableAmount, 0.01, '='));// * CurrExRate);

        ItemObject.Add('GstRt', GSTRt);
        //if GSTRt < 5 then GSTRt := GSTRt * 2;
        ItemObject.Add('IgstAmt', IGSTValue);

        ItemObject.Add('CgstAmt', CGSTValue);

        ItemObject.Add('SgstAmt', SGSTValue);

        ItemObject.Add('CesRt', CESSRate);

        // JsonWriter.WritePropertyName('CesAmt');
        // JsonWriter.WriteValue(CesAmt);

        // JsonWriter.WritePropertyName('CesNonAdvlAmt');
        // JsonWriter.WriteValue(CessNonAdvanceAmount);

        ItemObject.Add('CesNonAdvl', CessNonAdvanceAmount);

        // JsonWriter.WritePropertyName('StateCesRt');
        // JsonWriter.WriteValue(StateCes);

        ItemObject.Add('StateCes', StateCess);

        // JsonWriter.WritePropertyName('StateCesAmt');
        // JsonWriter.WriteValue(StateCesAmt);

        // JsonWriter.WritePropertyName('StateCesNonAdvlAmt');
        // JsonWriter.WriteValue(CessNonAdvanceAmount);

        ItemObject.Add('TotItemVal', TotalItemValue);// * CurrExRate);

        /*JsonTextWriter.WritePropertyName('OthChrg');
        JsonTextWriter.WriteValue(OthChrg);

        JsonTextWriter.WritePropertyName('OrdLineRef');
        JsonTextWriter.WriteValue(GlobalNULL);

        JsonTextWriter.WritePropertyName('OrgCntry');
        JsonTextWriter.WriteValue('IN');

        JsonTextWriter.Add('PrdSlNo');
        JsonTextWriter.WriteValue(GlobalNULL);*/

    end;




    procedure GetGSTComponentRate(
      DocumentNo: Code[20];
      LineNo: Integer;
      var CGSTRate: Decimal;
      var SGSTRate: Decimal;
      var IGSTRate: Decimal;
      var CessRate: Decimal;
      var CessNonAdvanceAmount: Decimal;
      var StateCess: Decimal;
      var GSTRate: Decimal)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", LineNo);

        DetailedGSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
        if DetailedGSTLedgerEntry.FindFirst() then begin
            CGSTRate := DetailedGSTLedgerEntry."GST %";
            // GSTRate := DetailedGSTLedgerEntry."GST %"
        end else
            CGSTRate := 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if DetailedGSTLedgerEntry.FindFirst() then begin
            SGSTRate := DetailedGSTLedgerEntry."GST %";
            GSTRate := 2 * (DetailedGSTLedgerEntry."GST %");
        end else
            SGSTRate := 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if DetailedGSTLedgerEntry.FindFirst() then begin
            IGSTRate := DetailedGSTLedgerEntry."GST %";
            GSTRate := DetailedGSTLedgerEntry."GST %"
        end else
            IGSTRate := 0;

        CessRate := 0;
        CessNonAdvanceAmount := 0;
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CESSLbl);
        if DetailedGSTLedgerEntry.FindFirst() then
            if DetailedGSTLedgerEntry."GST %" > 0 then
                CessRate := DetailedGSTLedgerEntry."GST %"
            else
                CessNonAdvanceAmount := Abs(DetailedGSTLedgerEntry."GST Amount");

        StateCess := 0;
        DetailedGSTLedgerEntry.SetRange("GST Component Code");
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                if not (DetailedGSTLedgerEntry."GST Component Code" in [CGSTLbl, SGSTLbl, IGSTLbl, CESSLbl])
                then
                    StateCess := DetailedGSTLedgerEntry."GST %";
            until DetailedGSTLedgerEntry.Next() = 0;
    end;

    procedure GetGSTValue(
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
       var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        GSTLedgerEntry: Record "GST Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TotGSTAmt: Decimal;
    begin
        GSTLedgerEntry.SetRange("Document No.", DocumentNo);

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

        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CESSLbl);
        if DetailedGSTLedgerEntry.FindFirst() then
            repeat
                if DetailedGSTLedgerEntry."GST %" > 0 then
                    CessAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
                else
                    CessNonAdvanceAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0;


        GSTLedgerEntry.Reset();
        GSTLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        // GSTLedgerEntry.SetFilter("GST Component Code", '<>%1|<>%2|<>%3|<>%4', 'CGST', 'SGST', 'IGST', 'CESS');
        if GSTLedgerEntry.Find('-') then
            repeat
                if (GSTLedgerEntry."GST Component Code") in ['CGST', 'SGST', 'IGST', 'CESS'] then
                    StateCessValue := 0
                else
                    StateCessValue += Abs(GSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0;

        // if IsInvoice then begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        if SalesInvoiceLine.Find('-') then
            repeat
                AssessableAmount += SalesInvoiceLine.Amount;
                DiscountAmount += SalesInvoiceLine."Inv. Discount Amount";
            until SalesInvoiceLine.Next() = 0;
        TotGSTAmt := CGSTAmount + SGSTAmount + IGSTAmount + CessAmount + CessNonAdvanceAmount + StateCessValue;

        AssessableAmount := Round(
            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
              WorkDate(), SalesInvoiceHeader."Currency Code", AssessableAmount, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
        TotGSTAmt := Round(
            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
              WorkDate(), SalesInvoiceHeader."Currency Code", TotGSTAmt, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
        DiscountAmount := Round(
            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
              WorkDate(), SalesInvoiceHeader."Currency Code", DiscountAmount, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
        // end;
        /* else begin
            SalesCrMemoLine.SetRange("Document No.", DocumentNo);
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
                    SalesCrMemoHeader."Currency Code",
                    AssessableAmount,
                    SalesCrMemoHeader."Currency Factor"),
                    0.01,
                    '=');

            TotGSTAmt := Round(
                CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                    WorkDate(),
                    SalesCrMemoHeader."Currency Code",
                    TotGSTAmt,
                    SalesCrMemoHeader."Currency Factor"),
                    0.01,
                    '=');

            DiscountAmount := Round(
                CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                    WorkDate(),
                    SalesCrMemoHeader."Currency Code",
                    DiscountAmount,
                    SalesCrMemoHeader."Currency Factor"),
                    0.01,
                    '=');
        end;*/

        CustLedgerEntry.SetCurrentKey("Document No.");
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        // if IsInvoice then begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
        if CustLedgerEntry.FindFirst() then begin
            CustLedgerEntry.CalcFields("Amount (LCY)");
            TotalInvoiceValue := Abs(CustLedgerEntry."Amount (LCY)");
        end;
        // end;
        /* else begin
            CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
            CustLedgerEntry.SetRange("Customer No.", SalesCrMemoHeader."Bill-to Customer No.");
        end;*/



        OtherCharges := 0;
    end;

    procedure GetGSTValueForLine(
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
        if DetailedGSTLedgerEntry.Find('-') then
            repeat
                CGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if DetailedGSTLedgerEntry.Find('-') then
            repeat
                SGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if DetailedGSTLedgerEntry.Find('-') then
            repeat
                IGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;
    end;

    procedure WriteValDtls(
        JsonObj1: JsonObject;
        SIHeader: Record "Sales Invoice Header"
    )
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
        GetGSTValue(AssessableAmount, CGSTAmount, SGSTAmount, IGSTAmount, CessAmount, StateCessAmount, CESSNonAvailmentAmount, DiscountAmount, OtherCharges, TotalInvoiceValue, SIHeader);

        ValDtls.Add('Assval', AssessableAmount);
        ValDtls.Add('CgstVal', CGSTAmount);
        ValDtls.Add('SgstVAl', SGSTAmount);
        ValDtls.Add('IgstVal', IGSTAmount);
        ValDtls.Add('CesVal', CessAmount);

        // JsonWriter.Add('StCesVal');
        // // JsonWriter.WriteValue(StateCessAmount);
        // JsonWriter.WriteValue(0.0);

        ValDtls.Add('CesNonAdVal', CESSNonAvailmentAmount);
        ValDtls.Add('OthChrg', OtherCharges);
        ValDtls.Add('Disc', DiscountAmount);
        ValDtls.Add('TotInvVal', TotalInvoiceValue);
        JsonObj1.Add('ValDtls', ValDtls);

    end;

    procedure WriteExpDtls(JsonObj1: JsonObject; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        ExportCategory: code[20];
        DocumentAmount: Decimal;
        SalesInvoiceLine: Record "Sales Invoice Line";
        WithPayOfDuty: Code[2];
        ShipmentBillNo: Code[20];
        ExitPort: code[10];
        ShipmentBillDate: text;
        CurrencyCode: code[3];
        CountryCode: code[2];
        ExpDtls: JsonObject;
    begin
        if not (SalesInvoiceHeader."GST Customer Type" in [
            SalesInvoiceHeader."GST Customer Type"::Export,
            SalesInvoiceHeader."GST Customer Type"::"Deemed Export",
            SalesInvoiceHeader."GST Customer Type"::"SEZ Unit",
            SalesInvoiceHeader."GST Customer Type"::"SEZ Development"])
        then
            exit;

        case SalesInvoiceHeader."GST Customer Type" of
            SalesInvoiceHeader."GST Customer Type"::Export:
                ExportCategory := 'DIR';
            SalesInvoiceHeader."GST Customer Type"::"Deemed Export":
                ExportCategory := 'DEM';
            SalesInvoiceHeader."GST Customer Type"::"SEZ Unit":
                ExportCategory := 'SEZ';
            SalesInvoiceHeader."GST Customer Type"::"SEZ Development":
                ExportCategory := 'SED';
        end;

        if SalesInvoiceHeader."GST Without Payment of Duty" then
            WithPayOfDuty := 'N'
        else
            WithPayOfDuty := 'Y';

        ShipmentBillNo := CopyStr(SalesInvoiceHeader."Bill Of Export No.", 1, 16);
        ShipmentBillDate := Format(SalesInvoiceHeader."Bill Of Export Date", 0, '<Year4>-<Month,2>-<Day,2>');
        ExitPort := SalesInvoiceHeader."Exit Point";

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                DocumentAmount := DocumentAmount + SalesInvoiceLine.Amount;
            until SalesInvoiceLine.Next() = 0;

        CurrencyCode := CopyStr(SalesInvoiceHeader."Currency Code", 1, 3);
        CountryCode := CopyStr(SalesInvoiceHeader."Bill-to Country/Region Code", 1, 2);

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

    procedure CancelSalesE_Invoice(recSalesInvoiceHeader: Record "Sales Invoice Header")
    var
        JsonObj1: JsonObject;
        jsonString: text;
        jsonObjectlinq: JsonObject;
        GSTInv_DLL: DotNet GSTEncr_Decr;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        encryptedIRNPayload: text;
        txtDecryptedSek: text;
        finalPayload: text;
        codeReason: Code[2];
        intReasonCOde: Integer;
        JsonObj2: JsonObject;
    begin

        JsonObj1.Add('Irn', recSalesInvoiceHeader."IRN Hash");

        Case recSalesInvoiceHeader."E-Invoice Cancel Reason" of
            recSalesInvoiceHeader."E-Invoice Cancel Reason"::"Duplicate Order":
                codeReason := '1';
            recSalesInvoiceHeader."E-Invoice Cancel Reason"::"Data Entry Mistake":
                codeReason := '2';
            recSalesInvoiceHeader."E-Invoice Cancel Reason"::"Order Cancelled":
                codeReason := '3';
            recSalesInvoiceHeader."E-Invoice Cancel Reason"::Other:
                codeReason := '4';
        end;
        // codeReason:
        JsonObj1.Add('CnlRsn', codeReason);

        JsonObj1.Add('CnlRem', recSalesInvoiceHeader."E-Invoice Cancel Remarks");

        JsonObj1.WriteTo(jsonString);
        // GenerateAuthToken(recSalesInvoiceHeader);//Auth Token ans Sek stored in Auth Table //IRN Encrypted with decrypted Sek that was decrypted by Appkey(Random 32-bit)

        // recAuthData.Reset();
        // // recAuthData.SetRange(DocumentNum, recSalesInvoiceHeader."No.");//Document number is universal for all documents and both E-Invoice and E-Way Bill 250922
        // if recAuthData.Findlast() then begin
        GenerateAuthToken();
        recAuthData.Get();

        txtDecryptedSek := recAuthData.DecryptedSEK;

        Message(jsonString);

        GSTInv_DLL := GSTInv_DLL.RSA_AES();
        // base64IRN := CU_Base64.ToBase64(JsonText);
        encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);
        JsonObj2.Add('Data', encryptedIRNPayload);
        JsonObj2.WriteTo(finalPayload);
        // Message('FinalIRNPayload %1 ', finalPayload);
        Call_IRN_API(recAuthData, finalPayload, true, recSalesInvoiceHeader, false, false);
    end;

    procedure UpdateCancelDetails(txtIRN: Text; CancelDate: Text; recSIHeader: Record "Sales Invoice Header")
    var
        SIHeader: Record "Sales Invoice Header";
        txtCancelDate: text;
    begin
        SIHeader.get(recSIHeader."No.");
        SIHeader."IRN Hash" := txtIRN;
        txtCancelDate := ConvertAckDt(CancelDate);
        evaluate(SIHeader."E-Inv. Cancelled Date", txtCancelDate);
        SIHeader.Modify();

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    procedure Create_EInvoiceOnSalesOrderPost(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean; var CustLedgerEntry: Record "Cust. Ledger Entry"; WhseShip: Boolean; WhseReceiv: Boolean)
    var
        recSIHeader: Record "Sales Invoice Header";
        recSalesCrmemHeader: Record "Sales Cr.Memo Header";
        CU_SalesCrEInvoice: Codeunit GST_Einvoice_CrMemo;
    begin
        if GuiAllowed then
            if confirm('Do you want to create E-Invoice ?', true) then begin
                if SalesInvHdrNo <> '' then begin
                    recSIHeader.get(SalesInvHdrNo);
                    GenerateIRN_01(recSIHeader);
                end else
                    if SalesCrMemoHdrNo <> '' then begin
                        recSalesCrmemHeader.get(SalesCrMemoHdrNo);
                        CU_SalesCrEInvoice.GenerateIRN_01(recSalesCrmemHeader);
                    end
            end

    end;

    procedure GetIRNDetails_SalesInvoice(SalesHead: Record "Sales Invoice Header")
    var
        PostUrl: Text;
        responsetxt: text;
        httpClient: HttpClient;
        httpresponse: HttpResponseMessage;
        httprequest: HttpRequestMessage;
        httpHdr: HttpHeaders;
        httpContent: HttpContent;
        GSTEncrypt: DotNet GSTEncr_Decr;
        jsonObjectlinq: JsonObject;
        //genledSetup: Record 98;
        recLocation: Record 14;
        txtResponse: Text;
        recGSTRegNos: Record "GST Registration Nos.";
        decryptedIRNResponse: Text;
        recAuthData: Record "GST E-Invoice(Auth Data)";
    begin
        if SalesHead."IRN Hash" = '' then
            Error('Operation cannot be performed as IRN does not exist for Invoice %1', SalesHead."No.");

        // recAuthData.Reset();
        // // recAuthData.SetRange(DocumentNum, SalesHead."No.");//Document number is universal for all documents and both E-Invoice and E-Way Bill 250922
        // if recAuthData.Findlast() then begin
        //     if recAuthData."Auth Token" <> '' then
        GenerateAuthToken();

        recAuthData.Get();
        recLocation.get(SalesHead."Location Code");
        recGSTRegNos.Reset();
        recGSTRegNos.SetRange(Code, recLocation."GST Registration No.");
        if recGSTRegNos.FindFirst() then;

        PostUrl := (recAuthData.GetEinvIRNURL);
        PostUrl := PostUrl + SalesHead."IRN Hash";
        //HttpContent.WriteFrom(JsonString);
        Httpclient.DefaultRequestHeaders.Add('client_id', recGSTRegNos."E-Invoice Client ID");
        Httpclient.DefaultRequestHeaders.Add('client_secret', recGSTRegNos."E-Invoice Client Secret");
        Httpclient.DefaultRequestHeaders.Add('gstin', recGSTRegNos.Code);
        Httpclient.DefaultRequestHeaders.Add('user_name', recAuthData.UserName);
        //HttpHdr.Add('AuthToken', recAuthData."Auth Token");
        // HttpHdr.Remove('Content-Type');
        // HttpHdr.Add('Content-Type', 'application/json');

        Httpclient.DefaultRequestHeaders.Add('AuthToken', recAuthData."Auth Token");
        if Httpclient.Get(PostUrl, httpresponse) then begin
            httpresponse.Content.ReadAs(responsetxt);
            txtResponse := responsetxt;//Response Length exceeds the max. allowed text length in Navision 19092019

            signedData := ParseResponse_IRN_ENCRYPT(txtResponse, false, false, false, SalesHead);

            GSTEncrypt := GSTEncrypt.RSA_AES();
            decryptedIRNResponse := GSTEncrypt.DecryptBySymmetricKey(signedData, recAuthData.DecryptedSEK);
            //Message(decryptedIRNResponse);//230922
            /*path := 'E:\GST_invoice\file_'+DELCHR(FORMAT(TODAY),'=',char)+'_'+DELCHR(FORMAT(TIME),'=',char)+'.txt';//+FORMAT(TODAY)+FORMAT(TIME)+'.txt';
            File.CREATE(path);
            File.CREATEOUTSTREAM(Outstr);
            Outstr.WRITETEXT(decryptedIRNResponse);*/
            ParseResponse_IRN_DECRYPT(decryptedIRNResponse, false, false, false, SalesHead);

        end
        ELSE BEGIN
            httpresponse.Content.ReadAs(responsetxt);
            Message(responsetxt);
        END;
    end;


    procedure GetGSTINDetails(SalesHead: Record "Sales Invoice Header")
    var
        PostUrl: Text;
        responsetxt: text;
        httpClient: HttpClient;
        httpresponse: HttpResponseMessage;
        httprequest: HttpRequestMessage;
        httpHdr: HttpHeaders;
        httpContent: HttpContent;
        encryptedIRNPayload: text;
        JsonString: Text;
        //GetGSTURL: Label 'https://einv-apisandbox.nic.in/eivital/v1.04/Master/gstin/';
        GSTInv_DLL: DotNet GSTEncr_Decr;
        genledSetup: Record 98;
        recLocation: Record 14;
        recGSTRegNos: Record "GST Registration Nos.";
        decryptedIRNResponse: Text;
        finalPayload: text;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        txtDecryptedSek: text;
    begin
        recAuthData.Get();


        // genledSetup.GET;
        recLocation.get(SalesHead."Location Code");
        recGSTRegNos.Reset();
        recGSTRegNos.SetRange(Code, recLocation."GST Registration No.");
        PostUrl := recAuthData.VerifyGSTIN + recLocation."GST Registration No.";
        //HttpContent.WriteFrom(JsonString);

        Httpclient.DefaultRequestHeaders.Add('client_id', recAuthData.ClientId);
        Httpclient.DefaultRequestHeaders.Add('client_secret', recAuthData.secretId);
        Httpclient.DefaultRequestHeaders.Add('gstin', recAuthData.GSTIN);
        Httpclient.DefaultRequestHeaders.Add('user_name', recAuthData.UserName);
        Httpclient.DefaultRequestHeaders.Add('AuthToken', recAuthData."Auth Token");
        if Httpclient.Get(PostUrl, httpresponse) then begin
            httpresponse.Content.ReadAs(responsetxt);
            //  txtResponse := glreader.ReadToEnd;//Response Length exceeds the max. allowed text length in Navision 19092019
            //  txtResponse := glreader.ReadToEnd;//Response Length exceeds the max. allowed text length in Navision 19092019

            signedData := ParseResponse_IRN_ENCRYPT(responsetxt, false, false, false, SalesHead);

            GSTInv_DLL := GSTInv_DLL.RSA_AES();
            decryptedIRNResponse := GSTInv_DLL.DecryptBySymmetricKey(signedData, recAuthData.DecryptedSEK);
            Message('GSTIN Details are %1', decryptedIRNResponse);//240922

            /*path := 'E:\GST_invoice\file_'+DELCHR(FORMAT(TODAY),'=',char)+'_'+DELCHR(FORMAT(TIME),'=',char)+'.txt';//+FORMAT(TODAY)+FORMAT(TIME)+'.txt';
        /*path := 'E:\GST_invoice\file_'+DELCHR(FORMAT(TODAY),'=',char)+'_'+DELCHR(FORMAT(TIME),'=',char)+'.txt';//+FORMAT(TODAY)+FORMAT(TIME)+'.txt';
        File.CREATE(path);
        File.CREATEOUTSTREAM(Outstr);
        Outstr.WRITETEXT(decryptedIRNResponse);*/
            // ParseResponse_GETGSTINDetails_Decrypt(decryptedIRNResponse, SalesHead);


        END
        ELSE BEGIN
            httpresponse.Content.ReadAs(responsetxt);
            Message(responsetxt);
        END;

    end;

    var
        myInt: Integer;
        JsonText: Text;
        IsInvoice: Boolean;
        DocumentNo: Text[20];
        SalesLineErr: Label 'E-Invoice allowes only 100 lines per Invoice. Curent transaction is having %1 lines.', Locked = true;
        //JsonWriter: DotNet JsonTextWriter;
        GlobalNULL: Variant;
        CGSTLbl: Label 'CGST', Locked = true;
        SGSTLbl: label 'SGST', Locked = true;
        IGSTLbl: Label 'IGST', Locked = true;
        CESSLbl: Label 'CESS', Locked = true;
        //BBQ_GSTIN: Label '29AAKCS3053N1ZS', Locked = true;
        gl_BillToPh: Code[20];
        OTHTxt: Label 'OTH';

        //GSTIN: Label '29AAKCS3053N1ZS', locked = true;
        signedData: text;
        //clientID: Label 'AAKCS29TXP3G937', Locked = true;
        //clientSecret: Label 'xDdRrf6L0Zzn42HhVvAP', locked = true;
        //userName: Label 'BBQBLR', Locked = true;
        gl_BillToEm: Text[100];
        // JsonLObj:JsonObject;
        //JsonLObj: JsonObject;
        // DocumentNoBlankErr: Label 'Document No. Blank';
        DocumentNoBlankErr: Label 'Document No. Blank';
}