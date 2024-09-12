pageextension 50255 PageExt50131 extends "Posted Sales Invoice"
{
    layout
    {

        modify("Shipping Agent Code")
        {
            Editable = true;
        }
        modify("Vehicle No.")
        {
            Editable = true;
        }
        modify("Shipment Method Code") { Editable = true; }

        modify("Transport Method") { Editable = true; }
        modify("Mode of Transport") { Editable = true; }

        addafter("IRN Hash")
        {
            field("E-Invoice Cancel Reason"; "E-Invoice Cancel Reason") { ApplicationArea = all; }
            field("E-Invoice Cancel Remarks"; "E-Invoice Cancel Remarks") { ApplicationArea = all; }


            field("E-Way Bill Date"; "E-Way Bill Date") { ApplicationArea = all; }
            // field("E-Way Bill No.";"E-Way Bill No."){ApplicationArea=all;}
            field("E-Way Bill Valid Upto"; "E-Way Bill Date") { ApplicationArea = all; }
            field("E-Way Bill Cancel Date"; "E-Way Bill Cancel Date") { ApplicationArea = all; }
            field("E-Way Bill Cancel Reason"; "E-Way Bill Cancel Reason") { ApplicationArea = all; }
            field("E-Way Bill Cancel Remarks"; "E-Way Bill Cancel Remarks") { ApplicationArea = all; }
            // field("QR Code";"QR Code")
            // field("E-Inv. Cancelled Date";"E-Inv. Cancelled Date"){ApplicationArea=all;}


        }
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter("Generate IRN")
        {
            action("Generate IRN2")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Generate E-Invoice';
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    E_Invoice_New: Codeunit E_Invoice_SalesInvoice;//CITS_RS
                    recSalesCrMemo: Record "Sales Cr.Memo Header";
                begin
                    // EInv.IntialiseAccesToken();
                    // EInv.Run();
                    // EInv.GenerateIRN_01(Rec);
                    E_Invoice_New.GenerateIRN_01(Rec);
                end;
            }

            action("Cancel IRN")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Cancel E-Invoice';
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    E_Invoice_New: Codeunit E_Invoice_SalesInvoice;//CITS_RS                   
                begin

                    E_Invoice_New.CancelSalesE_Invoice(Rec);
                end;

            }

            action("Generate E-Wy Bill")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Generate E-Way Bill';
                PromotedIsBig = true;
                Image = Invoice;
                trigger OnAction()
                var

                    E_WayBill_Sales: Codeunit Generate_EWayBill_SalesInvoice;
                begin

                    E_WayBill_Sales.GenerateEwayBill(Rec);

                end;
            }

            action("Cancel E-Way Bill")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Cancel E-Way Bill';
                PromotedIsBig = true;
                Image = Invoice;
                trigger OnAction()
                var
                    E_WayBill_Sales: Codeunit Generate_EWayBill_SalesInvoice;
                begin

                    E_WayBill_Sales.CancelEWayBill(Rec);

                end;
            }
            action("Get IRN Details")
            {

                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Get IRN Details';
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    E_Invoice_New: Codeunit E_Invoice_SalesInvoice;//CITS_RS                   
                begin

                    E_Invoice_New.GetIRNDetails_SalesInvoice(Rec);
                end;

            }
            action("Get GSTIN Details")
            {

                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Get GSTIN Details';
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    E_Invoice_New: Codeunit E_Invoice_SalesInvoice;//CITS_RS                   
                begin

                    E_Invoice_New.GetGSTINDetails(Rec);
                end;

            }
        }
        addafter(AttachAsPDF)
        {
            action("BBQ TaxInvoice1")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'tax Invoice Report';
                Ellipsis = true;
                Image = PrintReport;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Category6;


                trigger OnAction()
                var
                    SalesInvoice: Record "Sales Invoice Header";
                begin
                    SalesInvoice := Rec;
                    SalesInvoice.SetRecFilter();
                    Report.RunModal(Report::"BBQ TaxInvoice1", true, true, SalesInvoice);
                end;

            }
        }
        // Add changes to page actions here

    }

    var
        myInt: Integer;
}