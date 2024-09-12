report 50145 "BBQ TaxInvoice1"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    DefaultLayout = RDLC;
    RDLCLayout = 'BBQTaxinvoice.rdl';

    dataset
    {
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Sell-to Customer No.";
            RequestFilterHeading = 'Posted Sales Invoice';

            column(Posting_Date; "Posting Date") { }
            column(salespersonName; salespersonName) { }
            column(Salesperson_Code; "Salesperson Code") { }
            column(External_Document_No_; "External Document No.") { }
            column(Pre_Assigned_No_; "Pre-Assigned No.") { }
            column(Order_No_; "Order No.") { }
            column(No_; "No.") { }
            column(Customer_Posting_Group; "Customer Posting Group") { }
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
            column(StateDescription; StateDescription) { }
            column(stategstreg; stategstreg) { }
            column(CompInfoTelephoneno; CompInfo."Telex No.") { }
            column(CompInfoFaxNo; CompInfo."Fax No.") { }
            column(CompInfoPhoneNo; CompInfo."Phone No.") { }
            column(CompInfoWebsite; CompInfo."Home Page") { }
            column(CompInfoPanNO; CompInfo."P.A.N. No.") { }
            column(CompInfoGstRegist; CompInfo."GST Registration No.") { }
            column(Ship_to_Name; "Ship-to Name") { }
            column(Ship_to_Address; "Ship-to Address") { }
            column(Ship_to_Address_2; "Ship-to Address 2") { }
            column(Ship_to_City; "Ship-to City") { }
            column(Ship_to_Post_Code; "Ship-to Post Code") { }
            column(Ship_to_County; "Ship-to County") { }
            column(Ship_to_Contact; "Ship-to Contact") { }
            column(Ship_to_Code; "Ship-to Code") { }
            column(Bill_to_Name; "Bill-to Name") { }
            column(Bill_to_Name_2; "Bill-to Name 2") { }
            column(Bill_to_Address; "Bill-to Address") { }
            column(Bill_to_Address_2; "Bill-to Address 2") { }
            column(Bill_to_City; "Bill-to City") { }
            column(Bill_to_Post_Code; "Bill-to Post Code") { }
            column(Sell_to_Contact; "Sell-to Contact") { }
            column(CustomerGSTRegistrationNo; CustomerGSTRegistrationNo) { }
            column(CustomerPanNo; CustomerPanNo) { }
            column(CustomerStateName; CustomerStateName) { }
            column(CustomerCode; CustomerCode) { }
            column(CustomerServiceZone; CustomerServiceZone) { }
            column(currency; currency) { }
            column(IRN_Hash; "IRN Hash") { }
            column(QR_Code; "QR Code") { }
            column(BrandText; BrandText) { }
            column(Brand_Caption; Brand_Caption) { }
            column(LocatGstRegNo; LocatGstRegNo) { }
            column(LocatName; LocatName) { }
            column(LocatAddress; LocatAddress) { }
            column(LocatAddress2; LocatAddress2) { }
            column(LocatPostCode; LocatPostCode) { }
            column(LocatCity; LocatCity) { }
            column(Locatstaecode; Locatstaecode) { }


            dataitem("Sales Invoice Line"; "Sales Invoice Line")
            {
                DataItemTableView = SORTING("Document No.", "Line No.");
                DataItemLinkReference = "Sales Invoice Header";
                DataItemLink = "Document No." = FIELD("No.");

                column(Description; Description) { }
                column(Sno; Sno) { }
                column(Amount; Amount) { }
                column(Quantity; Quantity) { }
                column(Unit_Cost; "Unit Cost")
                { }
                column(Unit_of_Measure; "Unit of Measure")
                { }
                column(Discount_perc___; "Sales Invoice Line"."Line Discount %")
                {
                }
                column(LineDiscount_SalesInvoiceLine; "Sales Invoice Line"."Line Discount %")
                {
                }
                column(Unit_Price; "Unit Price") { }
                column(CGSTRate; CGSTRate) { }
                column(SGSTRate; SGSTRate) { }
                column(IGSTRate; IGSTRate) { }
                column(CGSTAmt; CGSTAmt) { }
                column(SGSTAmt; SGSTAmt) { }
                column(IGSTAmt; IGSTAmt) { }

                column(HSN_SAC_Code; "HSN/SAC Code") { }
                column(AmountToVendor; AmountToVendor) { }
                column(AmountinWords1; AmountinWords[2]) { }
                // column(AmountinWords; AmountinWords[1]) { }
                column(Amtinwrds; Amtinwrds) { }
                column(Pkg; Pkg) { }
                column(BDexecutive; BDexecutive) { }
                column(LineComment; LineComment) { }
                column(DimensionName; DimensionName) { }
                column(Dimensionncode; Dimensionncode) { }
                column(UserLicenseText; UserLicenseText) { }
                column(GlNo_; "No.") { }
                column(TextAmount; TextAmount) { }
                column(GrandTotal; GrandTotal) { }
                column(AmountinWords; AmountinWords[1]) { }
                column(TaxAmountInWords; TaxNoText[1]) { }
                trigger OnAfterGetRecord()
                var
                    IGSTAMT2: Decimal;
                begin
                    Sno := Sno + 1;
                    if "Sales Invoice Header"."Currency Code" <> '' then begin
                        Currency := "Sales Invoice Header"."Currency Code";
                    end else begin
                        Currency := 'INR';
                    end;

                    /*If "Sales Invoice Header"."Currency Code" = 'USD' then begin
                        Amt := ("Sales Invoice Line".Amount / "Sales Invoice Header"."Currency Factor")
                    end
                    else begin
                        Amt := "Sales Invoice Line".Amount;
                    end;*/

                    DetailedGSTLedgerEntry.RESET;
                    DetailedGSTLedgerEntry.SETRANGE("Document No.", "Document No.");
                    DetailedGSTLedgerEntry.SETRANGE("Document Line No.", "Line No.");
                    DetailedGSTLedgerEntry.SETRANGE("GST Group Code", "GST Group Code");
                    DetailedGSTLedgerEntry.SETFILTER("Transaction Type", '%1', DetailedGSTLedgerEntry."Transaction Type"::Sales);
                    DetailedGSTLedgerEntry.SETRANGE("GST Component Code", 'CGST');
                    IF DetailedGSTLedgerEntry.FIND('-') THEN
                        REPEAT
                            CGSTAmt := Abs(DetailedGSTLedgerEntry."GST Amount");
                            CGSTRate := DetailedGSTLedgerEntry."GST %";
                        UNTIL DetailedGSTLedgerEntry.NEXT() = 0;
                    //SGST
                    DetailedGSTLedgerEntry1.RESET;
                    DetailedGSTLedgerEntry1.SETRANGE("Document No.", "Document No.");
                    DetailedGSTLedgerEntry1.SETRANGE("Document Line No.", "Line No.");
                    DetailedGSTLedgerEntry1.SETRANGE("GST Group Code", "GST Group Code");
                    DetailedGSTLedgerEntry1.SETFILTER("Transaction Type", '%1', DetailedGSTLedgerEntry1."Transaction Type"::Sales);
                    DetailedGSTLedgerEntry1.SETRANGE("GST Component Code", 'SGST');
                    IF DetailedGSTLedgerEntry1.FIND('-') THEN
                        REPEAT
                            SGSTAmt := Abs(DetailedGSTLedgerEntry1."GST Amount");
                            SGSTRate := DetailedGSTLedgerEntry1."GST %";
                        UNTIL DetailedGSTLedgerEntry1.NEXT() = 0;
                    //IGST
                    DetailedGSTLedgerEntry2.RESET;
                    DetailedGSTLedgerEntry2.SETRANGE("Document No.", "Document No.");
                    DetailedGSTLedgerEntry2.SETRANGE("Document Line No.", "Line No.");
                    DetailedGSTLedgerEntry2.SETRANGE("GST Group Code", "GST Group Code");
                    DetailedGSTLedgerEntry2.SETFILTER("Transaction Type", '%1', DetailedGSTLedgerEntry2."Transaction Type"::Sales);
                    DetailedGSTLedgerEntry2.SETRANGE("GST Component Code", 'IGST');
                    IF DetailedGSTLedgerEntry2.FindSet() THEN
                        REPEAT
                            IGSTRate := DetailedGSTLedgerEntry2."GST %";
                            IGSTAMT2 := Abs(DetailedGSTLedgerEntry2."GST Amount");

                            if DetailedGSTLedgerEntry2."Currency Code" = '' then
                                IGSTAmt := Abs(DetailedGSTLedgerEntry2."GST Amount")
                            else
                                IGSTAmt := IGSTAMT2 * "Sales Invoice Header"."Currency Factor"
                        UNTIL DetailedGSTLedgerEntry2.NEXT() = 0;
                    //Totals

                    Total := Total + "Sales Invoice Line".Amount;    // Amt;
                    TaxTotal += Abs(CGSTAmt) + AbS(SGSTAmt) + Abs(IGSTAmt);
                    GrandTotal := Total + TaxTotal; //Abs(CGSTAmt) + Abs(SGSTAmt) + Abs(IGSTAmt);

                    if "Sales Invoice Header"."Currency Code" <> '' then begin
                        PostedVoucher.InitTextVariable();
                        PostedVoucher.FormatNoText(AmountinWords, Round(GrandTotal), Currency);

                        PostedVoucher1.InitTextVariable();
                        PostedVoucher1.FormatNoText(TaxNoText, Round(TaxTotal), Currency);

                    end else begin
                        PostedVoucher.InitTextVariable;
                        PostedVoucher.FormatNoText(AmountinWords, ROUND(GrandTotal), '');

                        PostedVoucher1.InitTextVariable();
                        PostedVoucher1.FormatNoText(TaxNoText, Round(TaxTotal), '');
                    end;


                end;

                trigger OnPreDataItem();
                begin
                    Sno := 0;
                end;

            }
            trigger OnAfterGetRecord()
            var
                myInt: Integer;
            begin
                Customer.Reset();
                Customer.SetRange("No.", "Sell-to Customer No.");
                if Customer.Find('-') then begin
                    CustomerGSTRegistrationNo := Customer."GST Registration No.";
                    CustomerPanNo := Customer."P.A.N. No.";
                    CustomerServiceZone := Customer."Service Zone Code";
                    //salespersonName := salesperson.Name;
                    IF Recstate.GET(Customer."State Code") then
                        CustomerStateName := Recstate.Description;
                    CustomerCode := Recstate."State Code (GST Reg. No.)";
                    // VendorCode := Recstate."State Code (GST Reg. No.)"
                    //NAVEEN
                    AmountToVendor += "Sales Invoice Line".Amount;
                    PostedVoucher.InitTextVariable();
                    "Sales Invoice Header".CalcFields(Amount);
                    // PostedVoucher.FormatNoText(AmountinWords, Round("Purchase Header".Amount), "Purchase Header"."Currency Code");
                    PostedVoucher.FormatNoText(AmountinWords, Round(AmountToVendor), "Sales Invoice Header"."Currency Code");
                    Amtinwrds := AmountinWords[1] + AmountinWords[2];
                    //NKP
                    if "Sales Invoice Header"."Currency Code" <> '' then
                        currency := "Sales Invoice Header"."Currency Code"
                    else
                        currency := 'INR';


                end;
                RecLocation.Reset();
                RecLocation.SetRange(Code, "Sales Invoice Header"."Location Code");
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
                end;
                Reccountry.Reset();
                Reccountry.SetRange(Code, CompInfo."Country/Region Code");
                if Reccountry.FindFirst() then begin
                    compinfoCountryName := Reccountry.Name;
                end;

                Recsalesperson.Reset();
                Recsalesperson.SetRange(Code, "Salesperson Code");
                if Recsalesperson.FindFirst() then begin
                    salespersonName := Recsalesperson.Name;
                end;


                /* RecSalesLine.SetRange("Document No.", "No.");
                 if RecSalesLine.FindFirst then
                     if RecSalesLine.Subscription then
                         BrandText := 'As per Annexure'
                     else
                         BrandText := '';*/


            end;

            trigger OnPostDataItem()
            var
                myInt: Integer;
            begin

            end;

        }

    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    /* field(Name; SourceExpression)
                     {
                         ApplicationArea = All;

                     }*/
                }
            }
        }

        actions
        {
            area(processing)
            {
                action(ActionName)
                {
                    ApplicationArea = All;

                }
            }
        }
    }
    trigger OnPreReport()
    begin
        CompInfo.get();
        CompInfo.CalcFields(Picture);
    end;

    var
        myInt: Integer;
        choice: Code[30];
        SalesLine: Record "Sales Invoice Line";
        CompInfo: Record "Company Information";
        Customer: Record Customer;
        CIName: Text;
        CICode: Code[20];
        CustomerGSTRegistrationNo: Code[20];
        CustomerPanNo: Code[20];
        Recstate: Record State;
        Recsalesperson: Record "Salesperson/Purchaser";
        salespersonName: Text;
        Dimension: Record "Dimension Set Entry";
        // Dimension2: Record "Dimension Set Entry";
        DimensionName: Text;
        BDexecutive: Text;
        dim: Record Dimension;
        Dimensionncode: Text;
        RecDimension: Record "Dimension Value";
        // RecBarc: Record "Barc setup";
        Pkg: Text;
        StateDescription: text;
        stategstreg: Code[20];
        CustomerStateCode: Code[20];
        CustomerStateName: Code[20];
        CustomerCode: Code[20];
        CustomerServiceZone: Code[20];
        AmountToVendor: Decimal;
        TextAmount: Decimal;
        PostedVoucher: Report "Posted Voucher";
        Amtinwrds: Text;
        AmountinWords: array[5] of Text;
        currency: Code[20];
        Sno: Integer;


        CGSTAmt: Decimal;
        CGSTRate: Decimal;
        IGSTAmt: Decimal;
        IGSTRate: Decimal;
        SGSTAmt: Decimal;
        SGSTRate: Decimal;
        Total: Decimal;
        GrandTotal: Decimal;
        TotalGST: Decimal;
        RecSalesLine: Record "Sales Invoice Line";
        CGST: Decimal;
        SGST: Decimal;
        IGST: Decimal;
        TotalCGST: Decimal;
        TotalSGST: Decimal;
        TotalIGST: Decimal;
        AmountinWordsINR: array[5] of Text;
        ExchangeRate: Decimal;
        IGSTtxt: text[10];
        CGSTtxt: text[10];
        SGSTtxt: text[10];
        TaxTransactionValue: Record "Tax Transaction Value";
        TaxRecordID: RecordId;
        //compinfo: Record "Company Information";
        compinfoGstRegi: Code[30];
        cominfoPanNo: Code[20];
        compinfoCountryName: text;
        Reccountry: Record "Country/Region";
        salesComment: Record "Sales Comment Line";
        LineComment: Text;
        Glsetup: Record "General Ledger Setup";
        BrandText: Text;
        Brand_Caption: label 'Brand';
        UserLicenseText: text;
        RecLocation: Record Location;
        LocatGstRegNo: Code[30];
        LocatName: Text;
        LocatAddress: Text;
        LocatAddress2: Text;
        LocatPostCode: Code[20];
        LocatCity: Text;
        Locatstaecode: Code[20];
        LocatestateName: Text;
        //Naveen
        TaxTrnasactionValue: Record "Tax Transaction Value";//CCIT_TK
        TaxTrnasactionValue1: Record "Tax Transaction Value";//CCIT_TK
        GSTCompNo: Integer;
        TotGSTAmt: Decimal;

        TempPurchLine: record "Purchase Line";
        PurchLine1: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        j: Integer;
        GSTCompAmount: array[20] of Decimal;
        GSTComponentCode: array[20] of Integer;
        TDSCompAmount: array[20] of Decimal;
        TDSComponentCode: array[20] of Integer;
        GSTComponentCodeName: array[20] of Code[20];
        TotalServiceTaxAmount: Decimal;
        // TDSAmt: Decimal;

        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        DetailedGSTLedgerEntry1: Record "Detailed GST Ledger Entry";
        DetailedGSTLedgerEntry2: Record "Detailed GST Ledger Entry";
        //PostedVoucher: Report "Posted Voucher";
        PostedVoucher1: Report "Posted Voucher";

        TaxTotal: Decimal;
        TaxNoText: array[2] of Text;




    local procedure ClearData()
    Begin
        IGSTRate := 0;
        SGSTRate := 0;
        CGSTRate := 0;
        SGSTtxt := '';
        CGSTtxt := '';
        TotalCGST := 0;
        TotalSGST := 0;
        TotalIGST := 0;
        CGSTtxt := '';
        IGSTtxt := '';

        IGST := 0;
        CGST := 0;
        SGST := 0;
        Clear(AmountinWords);
        AmountToVendor := 0;

    End;

}



