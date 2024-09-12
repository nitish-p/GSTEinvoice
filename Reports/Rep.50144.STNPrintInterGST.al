report 50144 "STN Print-Inter-GST1"
{
    DefaultLayout = RDLC;
    RDLCLayout = 'New_Transfer Shipment.rdl';
    PreviewMode = PrintLayout;
    ProcessingOnly = false;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = all;

    dataset
    {
        dataitem("Transfer Shipment Header"; "Transfer Shipment Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);
            RequestFilterFields = "No.";
            column(RefenrceNo; RefenrceNo)
            {
            }
            column(Posting_Date; "Posting Date") { }
            column(No_; "No.") { }
            column(CompInfopic; CompInfo.Picture) { }
            column(compinfoCountryName; compinfoCountryName) { }
            column(CompInfoName; CompInfo.Name) { }
            column(CompInfoName2; CompInfo."Name 2") { }
            column(CompInfoAddress; CompInfo.Address) { }
            column(CompInfoAddress2; CompInfo."Address 2") { }
            column(CompInfoCountry; CompInfo."Country/Region Code") { }
            column(CompInfoCity; CompInfo.City) { }
            column(CompInfoPostcode; CompInfo."Post Code") { }
            column(CompInfostatecode; CompInfo."State Code") { }
            column(CompinfoStateName; CompinfoStateName) { }
            column(CompInfoCINNo; CompInfo."CIN No.") { }
            column(PostingDate_TransferShipmentHeader; Format("Transfer Shipment Header"."Posting Date"))
            {
            }
            // column(No_TransferShipmentHeader; "Transfer Shipment Header"."GST Shipment No."){}
            column(TransferfromName_TransferShipmentHeader; Location.Name)
            {
            }
            column(TSH_Doc_NO; "Transfer Shipment Header"."No.")
            {
            }
            column(TSH_TO_NO; "Transfer Shipment Header"."Transfer Order No.")
            {
            }
            column(TransferfromAddress_TransferShipmentHeader; Location.Address)
            {
            }
            column(TransferfromAddress2_TransferShipmentHeader; Location."Address 2")
            {
            }
            column(TransferfromPostCode_TransferShipmentHeader; Location."Post Code")
            {
            }
            column(TransferfromCity_TransferShipmentHeader; Location.City)
            {
            }
            column(TransferFromStateCode; Location."State Code")
            {
            }
            column(TransferFromGSTN; Location."GST Registration No.")
            {
            }
            column(TransfertoName_TransferShipmentHeader; Location1.Name)
            {
            }
            column(TransfertoAddress_TransferShipmentHeader; Location1.Address)
            {
            }
            column(TransfertoAddress2_TransferShipmentHeader; Location1."Address 2")
            {
            }
            column(TransfertoPostCode_TransferShipmentHeader; Location1."Post Code")
            {
            }
            column(TransfertoCity_TransferShipmentHeader; Location1.City)
            {
            }
            column(TransferToStateCode; Location1."State Code")
            {
            }
            column(TransferToGSTN; Location1."GST Registration No.")
            {
            }
            column(TotalInvoiceAmount; TotalInvoiceAmount)
            {
            }
            column(NoText; NoText[1])
            {
            }
            column(TotalIGSTAmount; TotalIGSTAmount)
            {
            }
            column(LocatGstRegNo; LocatGstRegNo) { }
            column(LocatName; LocatName) { }
            column(LocatAddress; LocatAddress) { }
            column(LocatAddress2; LocatAddress2) { }
            column(LocatPostCode; LocatPostCode) { }
            column(LocatCity; LocatCity) { }
            column(Locatstaecode; Locatstaecode) { }
            column(Irn_No_; "Transfer Shipment Header"."IRN Hash") { }
            column(QR_Code; "QR Code") { }


            dataitem("Transfer Shipment Line"; "Transfer Shipment Line")
            {
                DataItemLink = "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document No.", "Line No.") ORDER(Ascending);
                column(cnt; cnt)
                {
                }
                column(Description; recItem.Description)
                {
                }

                column(ItemNo_TransferShipmentLine; "Transfer Shipment Line"."Item No.")
                {
                }
                column(Amount_TransferShipmentLine; "Transfer Shipment Line".Amount)
                {
                }
                column(Quantity_TransferShipmentLine; "Transfer Shipment Line".Quantity)
                {
                }
                //column(MRPPrice_TransferShipmentLine; "Transfer Shipment Line"."MRP Price")
                //{
                //}
                column(HSNCode; "Transfer Shipment Line"."HSN/SAC Code")
                {
                }
                column(SlNo; SlNo) { }
                column(Unit_of_Measure; "Unit of Measure") { }
                column(Unit_Price; "Unit Price") { }
                //column(SalesLineIGST; TotalGST)//tk
                column(SalesLineIGST; SalesLineIGST)//tk new
                {
                }
                column(IGSTRate; IGSTRate) { }
                column(Amount; Amount) { }
                column(Price; OroginalPrice)
                {
                }
                column(ItemCategoryCode_TransferShipmentLine; CatCode)
                {
                }
                column(UnitCost; recItem."Unit Cost")
                {
                }
                column(Amt; ("Transfer Shipment Line"."Unit Price" * "Transfer Shipment Line".Quantity))
                {
                }
                column(MHVAT; MHVAT)
                {
                }
                column(totAmt; TotAmt)
                {
                }
                column(GST_TransferShipmentLine; Round(GSTPrcnt, 1))
                {
                }
                column(UnitCost_TransferShipmentLine; "Transfer Shipment Line"."Unit Price")
                {
                }
                trigger OnPreDataItem();
                begin
                    //NoOfRecords := "Sales Invoice Line".COUNT;
                    SlNo := 0;
                end;

                trigger OnAfterGetRecord()
                begin
                    SlNo += 1;
                    cnt += 1;
                    CatCode := '';
                    if recItem.Get("Item No.") then begin
                        CatCode := recItem."Item Category Code";
                    end;
                    OroginalPrice := 0;
                    SalesPrice.Reset;
                    SalesPrice.SetRange(SalesPrice."Item No.", "Transfer Shipment Line"."Item No.");
                    if SalesPrice.FindLast then begin
                        // OroginalPrice := SalesPrice."Original Sales Price";
                    end;

                    Clear(SalesLineCGST);
                    Clear(SalesLineIGST);
                    Clear(SalesLineSGST);

                    DetailedGSTEntryBuffer.RESET;
                    DetailedGSTEntryBuffer.SETRANGE(DetailedGSTEntryBuffer."Entry Type", DetailedGSTEntryBuffer."Entry Type"::"Initial Entry");
                    DetailedGSTEntryBuffer.SETRANGE(DetailedGSTEntryBuffer."Transaction Type", DetailedGSTEntryBuffer."Transaction Type"::Sales);
                    // DetailedGSTEntryBuffer.SETRANGE(DetailedGSTEntryBuffer."Entry Type", DetailedGSTEntryBuffer."Entry Type");
                    DetailedGSTEntryBuffer.SETRANGE("Document No.", "Transfer Shipment Line"."Document No.");
                    DetailedGSTEntryBuffer.SETRANGE(DetailedGSTEntryBuffer."Document Line No.", "Transfer Shipment Line"."Line No.");
                    DetailedGSTEntryBuffer.SETRANGE(DetailedGSTEntryBuffer."No.", "Transfer Shipment Line"."Item No.");
                    if DetailedGSTEntryBuffer.FINDFIRST then begin
                        if DetailedGSTEntryBuffer."GST Component Code" = 'IGST' then
                            SalesLineIGST := ABS(DetailedGSTEntryBuffer."GST Amount");
                        IGSTRate := DetailedGSTEntryBuffer."GST %";
                    end;
                    //++MBIPL-TK 
                    Gstamount1 := 0;
                    GSTLedgerEntry.Reset();
                    GSTLedgerEntry.SetRange("Document Type", GSTLedgerEntry."Document Type"::Invoice);
                    GSTLedgerEntry.SetRange("Transaction Type", GSTLedgerEntry."Transaction Type"::Sales);
                    GSTLedgerEntry.SetRange("Source Type", GSTLedgerEntry."Source Type"::Transfer);
                    GSTLedgerEntry.SetRange("Document No.", "Transfer Shipment Header"."No.");
                    If GSTLedgerEntry.Find('-') then
                        repeat
                            Gstamount1 += ABS(GSTLedgerEntry."GST Amount");
                            IGSTRate := DetailedGSTEntryBuffer."GST %";
                        until GSTLedgerEntry.Next = 0;
                    //_-MBIPL-TK

                    GSTPrcnt := 0;
                    TotalGST := 0;
                    TotalIGSTAmount := 0;//tk

                    CalculateGST("Transfer Shipment Line");
                    RepCheck.InitTextVariable;//MBIPL-TK
                                              //RepCheck.FormatNoText(NoText, Round(TotalInvoiceAmount), '');//MBIPL-TK
                    RepCheck.FormatNoText(NoText, Round(TotAmt + Gstamount1), '');//MBIPL-TK
                    //RepCheck.FormatNoText(NoText, Round(TotAmt + TotalIGSTAmount), '');//MBIPL-TK
                end;
            }

            trigger OnAfterGetRecord()
            begin
                //LFS-AY+
                if Location.Get("Transfer Shipment Header"."Transfer-from Code") then;
                if Location1.Get("Transfer Shipment Header"."Transfer-to Code") then;

                //TotalLineAmount := 0;
                TransferShipLine.Reset;
                TransferShipLine.SetRange("Document No.", "Transfer Shipment Header"."No.");
                if TransferShipLine.FindFirst then
                    repeat
                        recItem.Get(TransferShipLine."Item No.");
                        TotalLineAmount += TransferShipLine.Amount;
                    until TransferShipLine.Next = 0;
                /*
                TotalIGSTAmount1 := 0;

                DetailedGSTEntry.RESET;
                DetailedGSTEntry.SETRANGE("Transaction Type", DetailedGSTEntry."Transaction Type"::Purchase);
                DetailedGSTEntry.SETRANGE("Entry Type", DetailedGSTEntry."Entry Type"::"Initial Entry");
                DetailedGSTEntry.SETRANGE("Document No.", "Transfer Shipment Header"."No.");
                IF DetailedGSTEntry.FINDFIRST THEN
                    REPEAT
                        //IF DetailedGSTEntry."GST Component Code" = 'IGST' THEN
                        TotalIGSTAmount1 += DetailedGSTEntry."GST Amount";
                    UNTIL DetailedGSTEntry.NEXT = 0;
             */

                //TotalInvoiceAmount := 0;

                TotalInvoiceAmount := TotalIGSTAmount + TotalIGSTAmount;
                //TotAmt := 0;
                TransferShipLine.Reset;
                TransferShipLine.SetRange("Document No.", "No.");
                if TransferShipLine.FindFirst then
                    repeat
                        recItem.Get(TransferShipLine."Item No.");
                        TotAmt += (TransferShipLine."Unit Price" * TransferShipLine.Quantity);
                    //TotalIGSTAmount += TotalGST;
                    until TransferShipLine.Next = 0;
                TotalIGSTAmount += TotalGST;
                // Message('totalgst', TotalIGSTAmount);
                //RepCheck.InitTextVariable;
                //RepCheck.FormatNoText(NoText, Round(TotalInvoiceAmount), '');//MBIPL-TK
                //RepCheck.FormatNoText(NoText, Round(TotAmt + TotalIGSTAmount1), '');
                RecLocation.Reset();
                RecLocation.SetRange(Code, "Transfer Shipment Header"."Transfer-from Code");
                if RecLocation.FindFirst() then begin
                    LocatGstRegNo := RecLocation."GST Registration No.";
                    LocatName := RecLocation.Name;
                    LocatAddress := RecLocation.Address;
                    LocatAddress2 := RecLocation."Address 2";
                    LocatPostCode := RecLocation."Post Code";
                    LocatCity := RecLocation.City;
                    Locatstaecode := RecLocation."State Code";
                    //LocatestateName := RecLocation.
                end;

                if Recstate.Get(CompInfo."State Code") then begin
                    StateDescription := Recstate.Description;
                    stategstreg := Recstate."State Code (GST Reg. No.)";
                    CompinfoStateName := Recstate.Description;

                end;
                Reccountry.Reset();
                Reccountry.SetRange(Code, CompInfo."Country/Region Code");
                if Reccountry.FindFirst() then begin
                    compinfoCountryName := Reccountry.Name;
                end;


            end;

            trigger OnPreDataItem()
            begin
                //RefenrceNo := "Transfer Shipment Header".GetFilter("Transfer Shipment Header"."No.");
                if DocNo1 <> '' then begin
                    SetRange("No.", DocNo1);
                    RefenrceNo := DocNo1;
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompInfo.Get;
        CompInfo.CalcFields(Picture);

    end;

    procedure CalculateGST(TSL: Record "Transfer Shipment Line")
    var
        PurchaseLine: Record "Purchase Line";
        TaxRecordID: RecordId;
        TaxTransactionValue: Record "Tax Transaction Value";
        TaxTypeObjHelper: Codeunit "Tax Type Object Helper";
        ComponentAmt: Decimal;
        GSTPrcntL: Decimal;
    begin
        //if PurchaseLine.Get(PL."Document Type", PL."Document No.", PL."Line No.") then
        //  TaxRecordID := PurchaseLine.RecordId();

        ComponentAmt := 0;
        GSTPrcntL := 0;
        TaxTransactionValue.Reset();
        TaxTransactionValue.SetFilter("Tax Record ID", '%1', tsl.RecordId);
        TaxTransactionValue.SetFilter("Value Type", '%1', TaxTransactionValue."Value Type"::Component);
        TaxTransactionValue.SetRange("Visible on Interface", true);
        TaxTransactionValue.SetFilter("Value ID", '%1', 3);
        if TaxTransactionValue.FindSet() then
            repeat
                GSTPrcntL += TaxTransactionValue.Percent;
                ComponentAmt += TaxTypeObjHelper.GetComponentAmountFrmTransValue(TaxTransactionValue);
            until TaxTransactionValue.Next() = 0;
        if GSTPrcntL > 0 then
            GSTPrcnt := GSTPrcntL;
        if ComponentAmt > 0 then
            TotalGST := ComponentAmt;
        TotalIGSTAmount += TotalGST;
    end;

    procedure SetDocFilter(DocNo: Code[20])
    var
        myInt: Integer;
    begin
        DocNo1 := DocNo;
    end;

    var
        tmpExcelBuffer: Record "Excel Buffer" temporary;
        SlNo: Integer;
        intCount: Integer;
        ExportToExcel: Boolean;
        recItem: Record Item;
        cnt: Integer;
        CompInfo: Record "Company Information";
        CompanyInformation: Record "Company Information";
        SalesPrice: Record "Sales Price";
        OroginalPrice: Decimal;
        MHVAT: Boolean;
        Location: Record Location;
        Name: Text;
        Add1: Text;
        Add2: Text;
        City: Text;
        PostCodes: Code[10];
        Location1: Record Location;
        Name1: Text;
        Add11: Text;
        Add22: Text;
        City1: Text;
        PostCodes1: Code[10];
        RefenrceNo: Code[500];
        Item: Record Item;
        CatCode: Code[20];
        DetailedGSTEntry: Record "Detailed GST Ledger Entry";

        GSTLedgerEntry: Record "GST Ledger Entry";
        Gstamount1: Decimal;
        GstbaseAmount: Decimal;

        //DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
        DetailedGSTEntryBuffer: Record "Detailed GST Ledger Entry";

        SalesLineCGST: Decimal;
        SalesLineSGST: Decimal;
        SalesLineIGST: Decimal;
        RepCheck: Report "Posted Voucher";
        NoText: array[2] of Text;
        TransferShipLine: Record "Transfer Shipment Line";
        TotalIGSTAmount: Decimal;
        TotalIGSTAmount1: Decimal;
        TotalLineAmount: Decimal;
        TotalInvoiceAmount: Decimal;
        TotAmt: Decimal;
        GSTPrcnt: Decimal;
        TotalGST: Decimal;
        DocNo1: Code[20];
        RecLocation: Record Location;
        LocatGstRegNo: Code[30];
        LocatName: Text;
        LocatAddress: Text;
        LocatAddress2: Text;
        LocatPostCode: Code[20];
        LocatCity: Text;
        Locatstaecode: Code[20];
        LocatestateName: Text;
        Recstate: Record State;
        StateDescription: text;
        stategstreg: Code[20];
        Reccountry: Record "Country/Region";
        compinfoCountryName: text;
        CompinfoStateName: Text;
        IGSTRate: Decimal;


}

