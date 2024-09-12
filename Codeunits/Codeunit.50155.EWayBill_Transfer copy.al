// codeunit 50159 E_WayBill_Transfer1
// {
//     trigger OnRun()
//     begin

//     end;

//     var
//         myInt: Integer;


//         jsonString: text;

//         CU_SalesInvoice: Codeunit E_Invoice_SalesInvoice;

//         CU_TransferEInvoice: Codeunit E_Invoice_TransferShipments;
//         GlobalNull: Variant;


//     procedure GenerateEwaybllWithoutIRN(TransferShipHeader: Record "Transfer Shipment Header")
//     var
//         recAuthData: Record "GST E-Invoice(Auth Data)";
//         txtDecryptedSek: text;
//         GSTInv_DLL: DotNet GSTEncr_Decr;
//         finalPayload: text;
//         encryptedIRNPayload: Text;
//     begin
//         clear(GlobalNull);
//         jsonString := WriteEWayWihtoutIRNPayload(TransferShipHeader);
//         Message(jsonString);
//     end;

//     procedure GenerateEwayBill(TransferShipHeader: Record "Transfer Shipment Header")
//     var
//         recAuthData: Record "GST E-Invoice(Auth Data)";
//         txtDecryptedSek: text;
//         GSTInv_DLL: DotNet GSTEncr_Decr;
//         finalPayload: text;
//         encryptedIRNPayload: Text;
//         JObject1: JsonObject;
//         E_Invoice_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
//     begin

//         clear(GlobalNull);
//         jsonString := writeJsonPayload(TransferShipHeader);
//         Message(jsonString);

//         // CU_TransferEInvoice.GenerateAuthToken(TransferShipHeader);

//         recAuthData.Get();

//         txtDecryptedSek := recAuthData.DecryptedSEK;
//         GSTInv_DLL := GSTInv_DLL.RSA_AES();
//         encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);


//         JObject1.Add('Data', encryptedIRNPayload);
//         // Message(encryptedIRNPayload);

//         JObject1.WriteTo(finalPayload);
//         // Message('FinalIRNPayload %1 ', finalPayload);
//         CU_TransferEInvoice.Call_IRN_API(recAuthData, finalPayload, false, TransferShipHeader, true, false);
//         // end;

//     end;



//     procedure WriteEWayWihtoutIRNPayload(TransferShipHeader: Record "Transfer Shipment Header"): Text
//     var
//         intDistance: Integer;
//         jsonString: text;
//         recShipMethod: Record "Shipment Method";
//         recCstomer: Record Customer;
//         recLocation: Record Location;
//         Pin: integer;
//         StateBuff: Record State;
//         shipCode: code[2];
//         shipmentMethod: Code[10];
//         TransferShipmentLine: Record "Transfer Shipment Line";
//         recTolocation: Record Location;
//         JObject: JsonObject;
//         itemList: JsonArray;
//         E_Invoice_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
//         ItemObject: JsonObject;
//         CGSTRate: Decimal;
//         SGSTRate: Decimal;
//         IGSTRate: Decimal;
//         CessRate: Decimal;
//         CesNonAdval: Decimal;
//         StateCess: Decimal;
//         GSTrate: Decimal;
//     begin
//         recLocation.get(TransferShipHeader."Transfer-from Code");
//         recTolocation.get(TransferShipHeader."Transfer-to Code");
//         if recLocation."State Code" <> recTolocation."State Code" then
//             Error('Use EwayBill Using IRN');

//         JObject.Add('supplyType', 'O');

//         JObject.Add('subSupplyType', '1');

//         JObject.Add('subSupplyDesc', 'Branch Transfer');

//         JObject.Add('docType', 'CHL');

//         JObject.Add('docNo', Format((TransferShipHeader."No.")));

//         JObject.Add('docDate', format(TransferShipHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));

//         //Mandatory
//         recLocation.Get(TransferShipHeader."Transfer-from Code");
//         JObject.Add('fromGstin', recLocation."GST Registration No.");

//         //Mandatory
//         JObject.Add('fromTrdName', recLocation.Name);

//         JObject.Add('fromAddr1', recLocation.Address);

//         JObject.Add('fromAddr2', recLocation."Address 2");

//         JObject.Add('fromPlace', recLocation.City);//Naveen

//         JObject.Add('fromPincode', recLocation."Post Code");
//         JObject.Add('actFromStateCode', recLocation."State Code");//Naveen
//         JObject.Add('fromStateCode', recLocation."State Code");
//         //Mandatory
//         recLocation.Get(TransferShipHeader."Transfer-to Code");
//         JObject.Add('toGstin', recLocation."GST Registration No.");
//         JObject.Add('toTrdName', recLocation.Name);
//         JObject.Add('toAddr1', recLocation.Address);
//         JObject.Add('toAddr2', recLocation."Address 2");
//         JObject.Add('toPlace', recLocation.City);
//         JObject.Add('toPincode', recLocation."Post Code");
//         JObject.Add('actToStateCode', recLocation."State Code");//Naveen
//         JObject.Add('toStateCode', recLocation."State Code");
//         JObject.Add('transactionType', '1');//1 regular 2 - Bill/Ship To  3 Bill/Dispatch From 
//         JObject.Add('otherValue', '0');//Naveen--other value
//                                        //Mandatory
//         TransferShipmentLine.Reset();
//         TransferShipmentLine.SETRANGE("Document No.", TransferShipHeader."No.");
//         TransferShipmentLine.SETFILTER(Quantity, '<>%1', 0);
//         IF TransferShipmentLine.FINDSET THEN BEGIN
//             TransferShipmentLine.CalcSums(Amount);
//         end;
//         JObject.Add('totalValue', TransferShipmentLine.Amount);
//         JObject.Add('cgstValue', 0);
//         JObject.Add('sgstValue', 0);
//         JObject.Add('igstValue', 0);
//         JObject.Add('cessValue', 0);
//         JObject.Add('cessNonAdvolValue', 0);

//         if TransferShipHeader."Transfer-from Code" <> TransferShipHeader."Transfer-to Code" then
//             JObject.Add('Distance', 0)//Auto calculation by GST Portal
//         else begin
//             intDistance := TransferShipHeader."Distance (Km)";
//             JObject.Add('Distance', intDistance);
//         end;

//         // recShipMethod.Get(TransferShipHeader."Shipment Method Code");
//         shipmentMethod := LowerCase(TransferShipHeader."Shipment Method Code");


//         recLocation.get(TransferShipHeader."Transfer-from Code");
//         JObject.Add('transporterId', recLocation."GST Registration No.");
//         JObject.Add('transporterName', TransferShipHeader."Shipping Agent Code");
//         JObject.Add('transDocNo', TransferShipHeader."LR/RR No.");

//         case   //standard GST Codes as per Json Schem per NIC
//             shipmentMethod of
//             'road':
//                 shipCode := '1';
//             'ship':
//                 shipCode := '3';
//             'air':
//                 shipCode := '4';
//             'rail':
//                 shipCode := '2';
//         end;
//         JObject.Add('transMode', shipCode);
//         JObject.Add('transDocDate', format(TransferShipHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
//         JObject.Add('vehicleNo', TransferShipHeader."Vehicle No.");
//         //"1","2","3","4"],"description": "Mode of transport (Road-1, Rail-2, Air-3, Ship-4) 
//         if TransferShipHeader."Mode of Transport" = 'ODC'
//          then
//             JObject.Add('vehicleType', 'O')
//         else
//             JObject.Add('vehicleType', 'R');
//         //transfershipment line
//         //item details start
//         TransferShipmentLine.Reset();
//         TransferShipmentLine.SETRANGE("Document No.", TransferShipHeader."No.");
//         TransferShipmentLine.SETFILTER(Quantity, '<>%1', 0);
//         IF TransferShipmentLine.FINDSET THEN BEGIN
//             IF TransferShipmentLine.COUNT > 100 THEN
//                 ERROR('E-Invoice allowes only 100 lines per Invoice. Curent transaction is having %1 lines.', TransferShipmentLine.COUNT);
//             //Mandatory
//             repeat
//                 JObject.Add('productName', TransferShipmentLine."Item No.");
//                 JObject.Add('productDesc', TransferShipmentLine.Description);
//                 JObject.Add('hsnCode', TransferShipmentLine."HSN/SAC Code");
//                 JObject.Add('quantity', TransferShipmentLine.Quantity);
//                 JObject.Add('qtyUnit', TransferShipmentLine.Quantity);//Naveen
//                 CU_SalesInvoice.GetGSTComponentRate(TransferShipHeader."No.", TransferShipmentLine."Line No.", CGSTRate, SGSTRate, IGSTRate, CessRate, CesNonAdval, StateCess, GSTrate);
//                 JObject.Add('cgstRate', CGSTRate);
//                 JObject.Add('sgstRate', SGSTRate);
//                 JObject.Add('igstRate', IGSTRate);
//                 JObject.Add('cessRate', CessRate);
//                 JObject.Add('cessNonadvol', CesNonAdval);
//                 JObject.Add('taxableAmount', TransferShipmentLine.Amount);
//             until TransferShipmentLine.Next() = 0;
//             JObject.Add('itemList', itemList);
//             //item details end
//             JObject.WriteTo(jsonString);
//         end;
//     end;


//     procedure writeJsonPayload(TransferShipHeader: Record "Transfer Shipment Header"): text;
//     var
//         intDistance: Integer;
//         jsonString: text;
//         recShipMethod: Record "Shipment Method";
//         recCstomer: Record Customer;
//         recLocation: Record Location;
//         Pin: integer;
//         StateBuff: Record State;
//         shipCode: code[2];
//         shipmentMethod: Code[10];
//         JObject: JsonObject;
//     begin
//         recLocation.get(TransferShipHeader."Transfer-from Code");


//         if TransferShipHeader."IRN Hash" = '' then
//             Error('E-Way Bill generation can only be done after E-Invoice ')
//         else
//             JObject.Add('Irn', TransferShipHeader."IRN Hash");
//         // intDistance := 0;
//         // if TransferShipHeader."Transfer-from Code" = TransferShipHeader."Transfer-to Code" then
//         //     if intDistance = 0 then
//         //         Error('Distance cannot be 0 for Transactions having same Origin and Destination PIN codes!!');
//         if TransferShipHeader."Distance (Km)" > 4000 then
//             Error('Max. allowed disctance is 4000 as per GST Portal!');


//         if TransferShipHeader."Transfer-from Code" <> TransferShipHeader."Transfer-to Code" then
//             JObject.Add('Distance', 0)//Auto calculation by GST Portal
//         else begin
//             intDistance := TransferShipHeader."Distance (Km)";
//             JObject.Add('Distance', intDistance);
//         end;
//         // recShipMethod.Get(TransferShipHeader."Shipment Method Code");
//         shipmentMethod := LowerCase(TransferShipHeader."Shipment Method Code");

//         case   //standard GST Codes as per Json Schem per NIC
//             shipmentMethod of
//             'road':
//                 shipCode := '1';
//             'ship':
//                 shipCode := '3';
//             'air':
//                 shipCode := '4';
//             'rail':
//                 shipCode := '2';
//         end;
//         JObject.Add('TransMode', shipCode);
//         // JsonWriter.WriteValue(recShipMethod."GST Trans Mode");
//         // JsonWriter.WriteValue(TransferShipHeader."Mode of Transport");


//         JObject.Add('TransId', recLocation."GST Registration No.");


//         JObject.Add('TransName', TransferShipHeader."Shipping Agent Code");

//         JObject.Add('TransDocDt', format(TransferShipHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));

//         JObject.Add('TransDocNo', TransferShipHeader."LR/RR No.");

//         JObject.Add('VehNo', TransferShipHeader."Vehicle No.");


//         if TransferShipHeader."Mode of Transport" = 'ODC'
//         then
//             JObject.Add('VehType', 'O')
//         else
//             JObject.Add('VehType', 'R');

//         recLocation.get(TransferShipHeader."Transfer-from Code");

//         /*JObject.Add('ExpShipDtls');
//         JsonWriter.WriteStartObject();

//         JObject.Add('Addr1',copystr(recLocation.Address, 1, 50));

//         JObject.Add('Addr2',copystr(recLocation."Address 2", 1, 50));

//         JObject.Add('Loc',recLocation.City);

//         EVALUATE(Pin, COPYSTR(recLocation."Post Code", 1, 6));
//         StateBuff.GET(recLocation."State Code");

//         JsonWriter.WritePropertyName('Pin',Pin);

//         JsonWriter.WritePropertyName('Stcd',StateBuff."State Code (GST Reg. No.)");

//         JsonWriter.WriteEndObject();
//         */

//         JObject.WriteTo(jsonString);
//         exit(jsonString);

//     end;

//     procedure UpdateHeaderIRN(EwayBillDt: Text; EwayBillNum: text; EwayBillValid: Text; TransferShipHeader: Record "Transfer Shipment Header")
//     var
//         FieldRef1: FieldRef;
//         RecRef1: RecordRef;
//         dtText: text;
//         inStr: InStream;
//         ValidDate: DateTime;
//         BillDate: DateTime;
//         blobCU: Codeunit "Temp Blob";
//         FileManagement: Codeunit "File Management";
//     begin
//         RecRef1.OPEN(5744);
//         FieldRef1 := RecRef1.FIELD(1);
//         FieldRef1.SETRANGE(TransferShipHeader."No.");//Parameter
//         IF RecRef1.FINDFIRST THEN BEGIN

//             dtText := CU_SalesInvoice.ConvertAckDt(EwayBillDt);
//             Evaluate(BillDate, dtText);

//             FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill Date"));
//             FieldRef1.VALUE := BillDate;
//             // FieldRef1 := RecRef1.FIELD(50001);//AckNum

//             FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill No."));
//             FieldRef1.VALUE := EwayBillNum;

//             dtText := CU_SalesInvoice.ConvertAckDt(EwayBillValid);
//             EVALUATE(ValidDate, dtText);
//             FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill Valid Upto"));
//             FieldRef1.VALUE := ValidDate;
//             RecRef1.MODIFY;
//         END;
//         // Erase the temporary file.
//     end;

//     procedure CancelEWayBill(recTransShipHeader: Record "Transfer Shipment Header")
//     var
//         jsonString: text;
//         CU_SalesE_Invoice: Codeunit E_Invoice_SalesInvoice;
//         GSTInv_DLL: DotNet GSTEncr_Decr;
//         recAuthData: Record "GST E-Invoice(Auth Data)";
//         encryptedIRNPayload: text;
//         txtDecryptedSek: text;
//         finalPayload: text;
//         CU_TransferEInvoice: Codeunit E_Invoice_TransferShipments;
//         codeReason: code[2];
//         JObject: JsonObject;
//         JObject2: JsonObject;
//         E_Invoice_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
//     begin


//         if recTransShipHeader."E-Way Bill No." = '' then
//             Error('E-Way bill not generated yet. Cancellation can''t be done')
//         else
//             JObject.Add('ewbNo', recTransShipHeader."E-Way Bill No.");



//         Case recTransShipHeader."E-Way Cancel Reason" of
//             recTransShipHeader."E-Way Cancel Reason"::"Duplicate Order":
//                 codeReason := '1';
//             recTransShipHeader."E-Way Cancel Reason"::"Data Entry Mistake":
//                 codeReason := '2';
//             recTransShipHeader."E-Way Cancel Reason"::"Order Cancelled":
//                 codeReason := '3';
//             recTransShipHeader."E-Way Cancel Reason"::Other:
//                 codeReason := '4';
//         end;
//         JObject.Add('cancelRsnCode', codeReason);

//         JObject.Add('cancelRmrk', recTransShipHeader."E-Way Bill Cancel Remarks");

//         JObject.WriteTo(jsonString);

//         //CU_TransferEInvoice.GenerateAuthToken(recTransShipHeader);//Auth Token ans Sek stored in Auth Table //IRN Encrypted with decrypted Sek that was decrypted by Appkey(Random 32-bit)

//         // recAuthData.Reset();
//         // recAuthData.SetRange(DocumentNum, recTransShipHeader."No.");//Document number is universal for all documents and both E-Invoice and E-Way Bill 250922
//         // if recAuthData.Findlast() then begin

//         E_Invoice_SalesInvoice.GenerateAuthToken();
//         recAuthData.Get();

//         txtDecryptedSek := recAuthData.DecryptedSEK;

//         Message(jsonString);

//         GSTInv_DLL := GSTInv_DLL.RSA_AES();
//         // base64IRN := CU_Base64.ToBase64(JsonText);
//         encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);

//         JObject2.Add('action', 'CANEWB');

//         JObject2.Add('Data', encryptedIRNPayload);

//         JObject.WriteTo(finalPayload);
//         // Message('FinalIRNPayload %1 ', finalPayload);
//         CU_TransferEInvoice.Call_IRN_API(recAuthData, finalPayload, false, recTransShipHeader, false, true);
//     end;



//     procedure UpdateEWayCancelHeader(txtEwayNum: text; txtEWayCancelDt: Text; recTrShipHeader: Record "Transfer Shipment Header")
//     var
//         recTrShHeader: Record "Transfer Shipment Header";
//         CUSIEINvoice: Codeunit E_Invoice_SalesInvoice;
//         txtCancelDT: text;

//     begin
//         recTrShHeader.get(recTrShipHeader."No.");
//         recTrShHeader."E-Way Bill No." := txtEwayNum;
//         // txtCancelDT := CUSIEINvoice.ConvertAckDt(txtEWayCancelDt);
//         recTrShHeader."E-Way Bill Cancel Date" := txtEWayCancelDt;
//         recTrShHeader.Modify();
//     end;

//     procedure ParseResponse()
//     var
//     begin
//     end;
// }
