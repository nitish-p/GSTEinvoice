pageextension 50254 PageExt50162 extends "Posted Transfer Shipment"
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

        modify("Transport Method") { Editable = true; }
        modify("Mode of Transport") { Editable = true; }
        modify("Shipment Method Code") { Editable = true; }

        // Add changes to page layout here
        addafter("Foreign Trade")
        {
            field("E-Invoice Cancel Date"; "E-Invoice Cancel Date") { ApplicationArea = all; }
            field("E-Invoice Cancel Reason"; "E-Invoice Cancel Reason") { ApplicationArea = all; }
            field("E-Invoice Cancel Remarks"; "E-Invoice Cancel Remarks") { ApplicationArea = all; }


            group("E-Way Bill")
            {

                field("E-Way Bill Date"; "E-Way Bill Date")
                {
                    ApplicationArea = all;
                }
                field("E-Way Bill Valid Upto"; "E-Way Bill Valid Upto")
                {
                    ApplicationArea = all;
                }
                field("E-Way Bill Remarks"; "E-Way Bill Remarks")
                {
                    ApplicationArea = all;
                }

                field("E-Way Bill Cancel Date"; "E-Way Bill Cancel Date") { ApplicationArea = all; }
                // field("E-Way Bill Cancel Reason"; "E-Way Bill Cancel Reason") { Enabled = false; HideValue = true; ApplicationArea = all; }
                field("E-Way Bill Cancel Remarks"; "E-Way Bill Cancel Remarks") { ApplicationArea = all; }
                field("E-Way Cancel Reason"; "E-Way Cancel Reason") { ApplicationArea = all; }
            }


        }
    }


    actions
    {
        modify("Generate IRN")
        {
            Visible = false;
        }
        // Add changes to page actions here
        addafter("Attached Gate Entry")
        {

            action("Generate-IRN")
            {
                ApplicationArea = All;

                Caption = 'Generate E Invoice';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    CU_EInvoice: Codeunit GST_Einvoice_CrMemo;
                    CU_EInvoiceTransfer: Codeunit E_Invoice_TransferShipments;
                    recSalesInvoice: Record "Sales Invoice Header";
                begin
                    CU_EInvoiceTransfer.GenerateIRN(Rec);
                end;
            }




            action("Cancel IRN")
            {
                ApplicationArea = All;

                Caption = 'Cancel E Invoice';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    CU_EINvoiceTransfer: Codeunit E_Invoice_TransferShipments;
                begin
                    CU_EINvoiceTransfer.CancelIRN_Transfer(Rec);

                end;
            }
            // action("Update IRN")
            // {
            //     ApplicationArea = All;

            //     trigger OnAction()
            //     begin
            //         a := b;
            //     end;
            // }
            action("Generate E-Way Bill")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    E_WayBill_Transfer: Codeunit E_WayBill_Transfer;
                begin
                    E_WayBill_Transfer.GenerateEwayBill(Rec);
                end;
            }
            action("Cancel E-Way Bill")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    E_WayBill_Transfer: Codeunit E_WayBill_Transfer;
                begin
                    E_WayBill_Transfer.CancelEWayBill(Rec);
                end;


            }
            action("Generate E-Way Bill Without IRN")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    E_WayBill_Transfer: Codeunit E_WayBill_Transfer;
                begin
                    E_WayBill_Transfer.GenerateEwaybllWithoutIRN(Rec);
                end;
            }
        }
        addafter("&Shipment")
        {
            action("STN Print-Inter-GST1")
            {

                ApplicationArea = Basic, Suite;
                Caption = 'Inte GST Report';
                Ellipsis = true;
                Image = PrintReport;
                Promoted = true;
                PromotedCategory = Category10;
                PromotedIsBig = true;
                trigger OnAction()
                var
                    PurchaHeader: Record "Purchase Header";
                    PostedTrShipment: record "Transfer Shipment Header";
                begin
                    PostedTrShipment := Rec;
                    PostedTrShipment.SetRecFilter();
                    Report.RunModal(Report::"STN Print-Inter-GST1", true, true, PostedTrShipment);
                end;

            }
        }
    }

    var
        myInt: Integer;
        a: Integer;
        b: Integer;
}