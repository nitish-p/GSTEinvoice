codeunit 50155 E_WayBill_Transfer
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;


        jsonString: text;

        CU_SalesInvoice: Codeunit E_Invoice_SalesInvoice;

        CU_TransferEInvoice: Codeunit E_Invoice_TransferShipments;
        GlobalNull: Variant;


    procedure GenerateEwaybllWithoutIRN(TransferShipHeader: Record "Transfer Shipment Header")
    var
        recAuthData: Record "GST E-Invoice(Auth Data)";
        txtDecryptedSek: text;
        GSTInv_DLL: DotNet GSTEncr_Decr;
        finalPayload: text;
        encryptedIRNPayload: Text;
        JObject2: JsonObject;
        E_Invoice_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
    begin
        if TransferShipHeader."E-Way Bill No." <> '' then
            Error('Already Generated');
        clear(GlobalNull);
        jsonString := WriteEWayWihtoutIRNPayload(TransferShipHeader);
        Message(jsonString);
        // WriteEWayWihtoutIRNPayload(TransferShipHeader)
        E_Invoice_SalesInvoice.GenerateAuthToken();
        recAuthData.Get();
        txtDecryptedSek := recAuthData.DecryptedSEK;
        GSTInv_DLL := GSTInv_DLL.RSA_AES();
        encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);

        JObject2.Add('action', 'GENEWAYBILL');

        JObject2.Add('data', encryptedIRNPayload);
        // Message(encryptedIRNPayload);

        JObject2.WriteTo(finalPayload);
        // Message((finalPayload));

        CU_TransferEInvoice.Call_EwaybillWOIRN_API(recAuthData, finalPayload, TransferShipHeader, true, false);
    end;





    procedure GenerateEwayBill(TransferShipHeader: Record "Transfer Shipment Header")
    var
        recAuthData: Record "GST E-Invoice(Auth Data)";
        txtDecryptedSek: text;
        GSTInv_DLL: DotNet GSTEncr_Decr;
        finalPayload: text;
        encryptedIRNPayload: Text;
        JObject1: JsonObject;
        E_Invoice_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
    begin

        clear(GlobalNull);
        jsonString := writeJsonPayload(TransferShipHeader);
        Message(jsonString);

        // CU_TransferEInvoice.GenerateAuthToken(TransferShipHeader);
        E_Invoice_SalesInvoice.GenerateAuthToken();
        recAuthData.Get();

        txtDecryptedSek := recAuthData.DecryptedSEK;
        GSTInv_DLL := GSTInv_DLL.RSA_AES();
        encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);


        JObject1.Add('Data', encryptedIRNPayload);
        // Message(encryptedIRNPayload);

        JObject1.WriteTo(finalPayload);
        // Message('FinalIRNPayload %1 ', finalPayload);
        CU_TransferEInvoice.Call_IRN_API(recAuthData, finalPayload, false, TransferShipHeader, true, false);
        // end;

    end;




    procedure WriteEWayWihtoutIRNPayload(TransferShipHeader: Record "Transfer Shipment Header"): Text
    var
        intDistance: Integer;
        jsonString: text;
        recShipMethod: Record "Shipment Method";
        recCstomer: Record Customer;
        recLocation: Record Location;
        Pin: integer;
        PinCode: Integer;
        statecode: Integer;
        StateBuff: Record State;
        shipCode: code[2];
        shipmentMethod: Code[10];
        TransferShipmentLine: Record "Transfer Shipment Line";
        HSNCODE: Integer;
        recTolocation: Record Location;
        JObject: JsonObject;
        ItemObj: JsonObject;
        itemList: JsonArray;
        E_Invoice_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
        ItemObject: JsonObject;
        CGSTRate: Decimal;
        SGSTRate: Decimal;
        IGSTRate: Decimal;
        CessRate: Decimal;
        CesNonAdval: Decimal;
        StateCess: Decimal;
        GSTrate: Decimal;
        RecUom: Record "Unit of Measure";
    begin
        recLocation.get(TransferShipHeader."Transfer-from Code");
        recTolocation.get(TransferShipHeader."Transfer-to Code");
        if recLocation."State Code" <> recTolocation."State Code" then
            Error('Use EwayBill Using IRN');

        JObject.Add('supplyType', 'O');

        JObject.Add('subSupplyType', '8');

        JObject.Add('subSupplyDesc', 'Branch Transfer');

        JObject.Add('docType', 'CHL');

        JObject.Add('docNo', Format((TransferShipHeader."No.")));

        JObject.Add('docDate', format(TransferShipHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));

        //Mandatory
        recLocation.Get(TransferShipHeader."Transfer-from Code");
        JObject.Add('fromGstin', recLocation."GST Registration No.");

        //Mandatory
        JObject.Add('fromTrdName', recLocation.Name);

        JObject.Add('fromAddr1', recLocation.Address);

        JObject.Add('fromAddr2', recLocation."Address 2");

        JObject.Add('fromPlace', recLocation.City);//Naveen
        Evaluate(PinCode, recLocation."Post Code");
        JObject.Add('fromPincode', PinCode);
        StateBuff.Get(recLocation."State Code");
        Evaluate(statecode, StateBuff."State Code (GST Reg. No.)");
        JObject.Add('actFromStateCode', statecode);//Naveen
        JObject.Add('fromStateCode', statecode);
        //Mandatory
        recLocation.Get(TransferShipHeader."Transfer-to Code");
        JObject.Add('toGstin', recLocation."GST Registration No.");
        JObject.Add('toTrdName', recLocation.Name);
        JObject.Add('toAddr1', recLocation.Address);
        JObject.Add('toAddr2', recLocation."Address 2");
        JObject.Add('toPlace', recLocation.City);
        Evaluate(PinCode, recLocation."Post Code");
        JObject.Add('toPincode', PinCode);
        StateBuff.Get(recLocation."State Code");
        Evaluate(statecode, StateBuff."State Code (GST Reg. No.)");
        JObject.Add('actToStateCode', statecode);//Naveen
        JObject.Add('toStateCode', statecode);
        JObject.Add('transactionType', 1);//1 regular 2 - Bill/Ship To  3 Bill/Dispatch From 
        JObject.Add('otherValue', 0);//Naveen--other value
        //Mandatory
        TransferShipmentLine.Reset();
        TransferShipmentLine.SETRANGE("Document No.", TransferShipHeader."No.");
        TransferShipmentLine.SETFILTER(Quantity, '<>%1', 0);
        IF TransferShipmentLine.FINDSET THEN BEGIN
            TransferShipmentLine.CalcSums(Amount);
        end;
        JObject.Add('totInvValue', TransferShipmentLine.Amount);
        JObject.Add('cgstValue', 0);
        JObject.Add('sgstValue', 0);
        JObject.Add('igstValue', 0);
        JObject.Add('cessValue', 0);
        JObject.Add('cessNonAdvolValue', 0);

        if TransferShipHeader."Transfer-from Code" <> TransferShipHeader."Transfer-to Code" then begin
            if TransferShipHeader."Distance (Km)" <> 0 then begin
                intDistance := TransferShipHeader."Distance (Km)";
                JObject.Add('transDistance', Format(intDistance));
            end else
                JObject.Add('transDistance', Format(0))//Auto calculation by GST Portal
        end
        else begin
            intDistance := TransferShipHeader."Distance (Km)";
            JObject.Add('transDistance', Format(intDistance));
        end;

        // recShipMethod.Get(TransferShipHeader."Shipment Method Code");
        shipmentMethod := LowerCase(TransferShipHeader."Shipment Method Code");


        recLocation.get(TransferShipHeader."Transfer-from Code");
        JObject.Add('transporterId', recLocation."GST Registration No.");
        JObject.Add('transporterName', TransferShipHeader."Shipping Agent Code");
        JObject.Add('transDocNo', TransferShipHeader."LR/RR No.");

        case   //standard GST Codes as per Json Schem per NIC
            shipmentMethod of
            'road':
                shipCode := '1';
            'ship':
                shipCode := '3';
            'air':
                shipCode := '4';
            'rail':
                shipCode := '2';
        end;
        JObject.Add('transMode', shipCode);
        JObject.Add('transDocDate', format(TransferShipHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JObject.Add('vehicleNo', TransferShipHeader."Vehicle No.");
        //"1","2","3","4"],"description": "Mode of transport (Road-1, Rail-2, Air-3, Ship-4) 
        if TransferShipHeader."Mode of Transport" = 'ODC'
         then
            JObject.Add('vehicleType', 'O')
        else
            JObject.Add('vehicleType', 'R');
        //transfershipment line
        //item details start
        TransferShipmentLine.Reset();
        TransferShipmentLine.SETRANGE("Document No.", TransferShipHeader."No.");
        TransferShipmentLine.SETFILTER(Quantity, '<>%1', 0);
        IF TransferShipmentLine.FINDSET THEN BEGIN
            IF TransferShipmentLine.COUNT > 100 THEN
                ERROR('E-Invoice allowes only 100 lines per Invoice. Curent transaction is having %1 lines.', TransferShipmentLine.COUNT);
            //Mandatory
            repeat
                Clear(ItemObj);
                ItemObj.Add('productName', TransferShipmentLine."Item No.");
                ItemObj.Add('productDesc', TransferShipmentLine.Description);
                Evaluate(HSNCODE, TransferShipmentLine."HSN/SAC Code");
                ItemObj.Add('hsnCode', HSNCODE);
                ItemObj.Add('quantity', TransferShipmentLine.Quantity);
                RecUom.Get(TransferShipmentLine."Unit of Measure Code");
                ItemObj.Add('qtyUnit', RecUom."E-Inv UOM");//Naveen
                CU_SalesInvoice.GetGSTComponentRate(TransferShipHeader."No.", TransferShipmentLine."Line No.", CGSTRate, SGSTRate, IGSTRate, CessRate, CesNonAdval, StateCess, GSTrate);
                ItemObj.Add('cgstRate', CGSTRate);
                ItemObj.Add('sgstRate', SGSTRate);
                ItemObj.Add('igstRate', IGSTRate);
                ItemObj.Add('cessRate', CessRate);
                ItemObj.Add('cessNonadvol', CesNonAdval);
                ItemObj.Add('taxableAmount', TransferShipmentLine.Amount);
                itemList.Add(ItemObj);
            until TransferShipmentLine.Next() = 0;
            JObject.Add('itemList', itemList);
            //item details end
            JObject.WriteTo(jsonString);
        end;
        exit(jsonString);
    end;

    procedure writeJsonPayload(TransferShipHeader: Record "Transfer Shipment Header"): text;
    var
        intDistance: Integer;
        jsonString: text;
        recShipMethod: Record "Shipment Method";
        recCstomer: Record Customer;
        recLocation: Record Location;
        Pin: integer;
        StateBuff: Record State;
        shipCode: code[2];
        shipmentMethod: Code[10];
        JObject: JsonObject;
    begin
        recLocation.get(TransferShipHeader."Transfer-from Code");


        if TransferShipHeader."IRN Hash" = '' then
            Error('E-Way Bill generation can only be done after E-Invoice ')
        else
            JObject.Add('Irn', TransferShipHeader."IRN Hash");
        // intDistance := 0;
        // if TransferShipHeader."Transfer-from Code" = TransferShipHeader."Transfer-to Code" then
        //     if intDistance = 0 then
        //         Error('Distance cannot be 0 for Transactions having same Origin and Destination PIN codes!!');
        if TransferShipHeader."Distance (Km)" > 4000 then
            Error('Max. allowed disctance is 4000 as per GST Portal!');


        if TransferShipHeader."Transfer-from Code" <> TransferShipHeader."Transfer-to Code" then
            JObject.Add('Distance', 0)//Auto calculation by GST Portal
        else begin
            intDistance := TransferShipHeader."Distance (Km)";
            JObject.Add('Distance', intDistance);
        end;
        // recShipMethod.Get(TransferShipHeader."Shipment Method Code");
        shipmentMethod := LowerCase(TransferShipHeader."Shipment Method Code");

        case   //standard GST Codes as per Json Schem per NIC
            shipmentMethod of
            'road':
                shipCode := '1';
            'ship':
                shipCode := '3';
            'air':
                shipCode := '4';
            'rail':
                shipCode := '2';
        end;
        JObject.Add('TransMode', shipCode);
        // JsonWriter.WriteValue(recShipMethod."GST Trans Mode");
        // JsonWriter.WriteValue(TransferShipHeader."Mode of Transport");


        JObject.Add('TransId', recLocation."GST Registration No.");


        JObject.Add('TransName', TransferShipHeader."Shipping Agent Code");

        JObject.Add('TransDocDt', format(TransferShipHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));

        JObject.Add('TransDocNo', TransferShipHeader."LR/RR No.");

        JObject.Add('VehNo', TransferShipHeader."Vehicle No.");


        if TransferShipHeader."Mode of Transport" = 'ODC'
        then
            JObject.Add('VehType', 'O')
        else
            JObject.Add('VehType', 'R');

        recLocation.get(TransferShipHeader."Transfer-from Code");

        /*JsonWriter.WritePropertyName('ExpShipDtls');
        JsonWriter.WriteStartObject();

        JsonWriter.WritePropertyName('Addr1');
        JsonWriter.WriteValue(copystr(recLocation.Address, 1, 50));

        JsonWriter.WritePropertyName('Addr2');
        JsonWriter.WriteValue(copystr(recLocation."Address 2", 1, 50));

        JsonWriter.WritePropertyName('Loc');
        JsonWriter.WriteValue(recLocation.City);

        EVALUATE(Pin, COPYSTR(recLocation."Post Code", 1, 6));
        StateBuff.GET(recLocation."State Code");

        JsonWriter.WritePropertyName('Pin');
        JsonWriter.WriteValue(Pin);

        JsonWriter.WritePropertyName('Stcd');
        JsonWriter.WriteValue(StateBuff."State Code (GST Reg. No.)");

        JsonWriter.WriteEndObject();
        */

        JObject.WriteTo(jsonString);
        exit(jsonString);

    end;

    procedure UpdateHeaderIRN(EwayBillDt: Text; EwayBillNum: text; EwayBillValid: Text; TransferShipHeader: Record "Transfer Shipment Header")
    var
        FieldRef1: FieldRef;
        RecRef1: RecordRef;
        dtText: text;
        inStr: InStream;
        ValidDate: DateTime;
        BillDate: DateTime;
        blobCU: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
    begin
        RecRef1.OPEN(5744);
        FieldRef1 := RecRef1.FIELD(1);
        FieldRef1.SETRANGE(TransferShipHeader."No.");//Parameter
        IF RecRef1.FINDFIRST THEN BEGIN

            dtText := CU_SalesInvoice.ConvertAckDt(EwayBillDt);
            Evaluate(BillDate, dtText);

            FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill Date"));
            FieldRef1.VALUE := BillDate;
            // FieldRef1 := RecRef1.FIELD(50001);//AckNum

            FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill No."));
            FieldRef1.VALUE := EwayBillNum;
            if EwayBillValid <> 'null' then begin
                dtText := CU_SalesInvoice.ConvertAckDt(EwayBillValid);
                EVALUATE(ValidDate, dtText);
            end
            else begin
                ValidDate := BillDate;
            end;
            FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill Valid Upto"));
            FieldRef1.VALUE := ValidDate;
            RecRef1.MODIFY;
        END;
        // Erase the temporary file.
    end;

    procedure UpdateHeaderWOIRN(EwayBillDt: Text; EwayBillNum: text; EwayBillValid: Text; TransferShipHeader: Record "Transfer Shipment Header")
    var
        FieldRef1: FieldRef;
        RecRef1: RecordRef;
        dtText: text;
        inStr: InStream;
        ValidDate: DateTime;
        BillDate: DateTime;
        blobCU: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
    begin
        RecRef1.OPEN(5744);
        FieldRef1 := RecRef1.FIELD(1);
        FieldRef1.SETRANGE(TransferShipHeader."No.");//Parameter
        IF RecRef1.FINDFIRST THEN BEGIN

            //dtText := CU_SalesInvoice.ConvertAckDt(EwayBillDt);
            //Evaluate(BillDate, ConvertStr(EwayBillDt, '', 'T'), 9);
            Evaluate(BillDate, EwayBillDt);

            FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill Date"));
            FieldRef1.VALUE := BillDate;
            // FieldRef1 := RecRef1.FIELD(50001);//AckNum

            FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill No."));
            FieldRef1.VALUE := EwayBillNum;
            if EwayBillValid <> '' then begin
                //dtText := CU_SalesInvoice.ConvertAckDt(EwayBillValid);
                Evaluate(ValidDate, EwayBillDt);

            end
            else begin
                ValidDate := BillDate;
            end;
            FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill Valid Upto"));
            FieldRef1.VALUE := ValidDate;
            RecRef1.MODIFY;
        END;
        // Erase the temporary file.
    end;

    procedure CancelEWayBill(recTransShipHeader: Record "Transfer Shipment Header")
    var
        jsonString: text;
        CU_SalesE_Invoice: Codeunit E_Invoice_SalesInvoice;
        GSTInv_DLL: DotNet GSTEncr_Decr;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        encryptedIRNPayload: text;
        txtDecryptedSek: text;
        finalPayload: text;
        CU_TransferEInvoice: Codeunit E_Invoice_TransferShipments;
        codeReason: code[2];
        JObject: JsonObject;
        JObject2: JsonObject;
        E_Invoice_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
    begin


        if recTransShipHeader."E-Way Bill No." = '' then
            Error('E-Way bill not generated yet. Cancellation can''t be done')
        else
            JObject.Add('ewbNo', recTransShipHeader."E-Way Bill No.");



        Case recTransShipHeader."E-Way Cancel Reason" of
            recTransShipHeader."E-Way Cancel Reason"::"Duplicate Order":
                codeReason := '1';
            recTransShipHeader."E-Way Cancel Reason"::"Data Entry Mistake":
                codeReason := '2';
            recTransShipHeader."E-Way Cancel Reason"::"Order Cancelled":
                codeReason := '3';
            recTransShipHeader."E-Way Cancel Reason"::Other:
                codeReason := '4';
        end;
        JObject.Add('cancelRsnCode', codeReason);

        JObject.Add('cancelRmrk', recTransShipHeader."E-Way Bill Cancel Remarks");

        JObject.WriteTo(jsonString);

        //CU_TransferEInvoice.GenerateAuthToken(recTransShipHeader);//Auth Token ans Sek stored in Auth Table //IRN Encrypted with decrypted Sek that was decrypted by Appkey(Random 32-bit)

        // recAuthData.Reset();
        // recAuthData.SetRange(DocumentNum, recTransShipHeader."No.");//Document number is universal for all documents and both E-Invoice and E-Way Bill 250922
        // if recAuthData.Findlast() then begin
        E_Invoice_SalesInvoice.GenerateAuthToken();
        recAuthData.Get();
        txtDecryptedSek := recAuthData.DecryptedSEK;

        Message(jsonString);

        GSTInv_DLL := GSTInv_DLL.RSA_AES();
        // base64IRN := CU_Base64.ToBase64(JsonText);
        encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);

        JObject2.Add('action', 'CANEWB');

        JObject2.Add('Data', encryptedIRNPayload);

        JObject.WriteTo(finalPayload);
        // Message('FinalIRNPayload %1 ', finalPayload);
        CU_TransferEInvoice.Call_IRN_API(recAuthData, finalPayload, false, recTransShipHeader, false, true);
    end;



    procedure UpdateEWayCancelHeader(txtEwayNum: text; txtEWayCancelDt: Text; recTrShipHeader: Record "Transfer Shipment Header")
    var
        recTrShHeader: Record "Transfer Shipment Header";
        CUSIEINvoice: Codeunit E_Invoice_SalesInvoice;
        txtCancelDT: text;

    begin
        recTrShHeader.get(recTrShipHeader."No.");
        recTrShHeader."E-Way Bill No." := txtEwayNum;
        // txtCancelDT := CUSIEINvoice.ConvertAckDt(txtEWayCancelDt);
        recTrShHeader."E-Way Bill Cancel Date" := txtEWayCancelDt;
        recTrShHeader.Modify();
    end;

    procedure ParseResponse()
    var
    begin
    end;
}

