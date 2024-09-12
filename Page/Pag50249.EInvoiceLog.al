page 50249 "E-Invoice Log"
{
    ApplicationArea = All;
    Caption = 'E-Invoice Log';
    PageType = List;
    SourceTable = "E-Invoice Log";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ToolTip = 'Specifies the value of the Document Type field.', Comment = '%';
                }
                field("Document No."; Rec."Document No.")
                {
                    ToolTip = 'Specifies the value of the Document No. field.', Comment = '%';
                }
                field("QR Code Image"; Rec."QR Code Image")
                {
                    ToolTip = 'Specifies the value of the QR Code Image field.', Comment = '%';
                }
                field("Invoice Reference Number"; Rec."Invoice Reference Number")
                {
                    ToolTip = 'Specifies the value of the Invoice Reference Number field.', Comment = '%';
                }
                field("Signed Invoice Txt"; Rec."Signed Invoice Txt")
                {
                    ToolTip = 'Specifies the value of the Signed Invoice Txt field.', Comment = '%';
                }
                field(Acknowledgment_number; Rec.Acknowledgment_number)
                {
                    ToolTip = 'Specifies the value of the Acknowledgment_number field.', Comment = '%';
                }
                field("Acknowledgment Date"; Rec."Acknowledgment Date")
                {
                    ToolTip = 'Specifies the value of the Acknowledgment Date field.', Comment = '%';
                }
                field("Created Date Time"; Rec."Created Date Time")
                {
                    ToolTip = 'Specifies the value of the Created Date Time field.', Comment = '%';
                }
                field("Cancel DateTime"; Rec."Cancel DateTime")
                {
                    ToolTip = 'Specifies the value of the Cancel DateTime field.', Comment = '%';
                }
                field("Cancel Reason"; Rec."Cancel Reason")
                {
                    ToolTip = 'Specifies the value of the Cancel Reason field.', Comment = '%';
                }
                field("Cancel Remarks"; Rec."Cancel Remarks")
                {
                    ToolTip = 'Specifies the value of the Cancel Remarks field.', Comment = '%';
                }
                field("E-Way Bill Status"; Rec."E-Way Bill Status")
                {
                    ToolTip = 'Specifies the value of the E-Way Bill Status field.', Comment = '%';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the value of the Entry No. field.', Comment = '%';
                }
                field("Transaction Identifier"; Rec."Transaction Identifier")
                {
                    ToolTip = 'Specifies the value of the Transaction Identifier field.', Comment = '%';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the value of the Status field.', Comment = '%';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ToolTip = 'Specifies the value of the Error Message field.', Comment = '%';
                }
                field("Signed Invoice"; Rec."Signed Invoice")
                {
                    ToolTip = 'Specifies the value of the Signed Invoice field.', Comment = '%';
                }
                field("Signed QR Code"; Rec."Signed QR Code")
                {
                    ToolTip = 'Specifies the value of the Signed QR Code field.', Comment = '%';
                }
                field("Created By"; Rec."Created By")
                {
                    ToolTip = 'Specifies the value of the Created By field.', Comment = '%';
                }
                field("Response JSON"; Rec."Response JSON")
                {
                    ToolTip = 'Specifies the value of the Response JSON field.', Comment = '%';
                }
                field("Request JSON"; Rec."Request JSON")
                {
                    ToolTip = 'Specifies the value of the Request JSON field.', Comment = '%';
                }
                field("QR Code"; Rec."QR Code")
                {
                    ToolTip = 'Specifies the value of the QR Code field.', Comment = '%';
                }
                field("IRN Status"; Rec."IRN Status")
                {
                    ToolTip = 'Specifies the value of the IRN Status field.', Comment = '%';
                }
                field("Cancel Date"; Rec."Cancel Date")
                {
                    ToolTip = 'Specifies the value of the Cancel Date field.', Comment = '%';
                }
                field("Cancellation Error Message"; Rec."Cancellation Error Message")
                {
                    ToolTip = 'Specifies the value of the Cancellation Error Message field.', Comment = '%';
                }
                field("Cancelled By"; Rec."Cancelled By")
                {
                    ToolTip = 'Specifies the value of the Cancelled By field.', Comment = '%';
                }
                field("E-Waybill Status"; Rec."E-Waybill Status")
                {
                    ToolTip = 'Specifies the value of the E-Waybill Status field.', Comment = '%';
                }
                field("E-Waybill No."; Rec."E-Waybill No.")
                {
                    ToolTip = 'Specifies the value of the E-Waybill No. field.', Comment = '%';
                }
                field("E-Waybill Date"; Rec."E-Waybill Date")
                {
                    ToolTip = 'Specifies the value of the E-Waybill Date field.', Comment = '%';
                }
                field("E-Waybill Valid Till"; Rec."E-Waybill Valid Till")
                {
                    ToolTip = 'Specifies the value of the E-Waybill Valid Till field.', Comment = '%';
                }
                field("E-Waybill Remarks"; Rec."E-Waybill Remarks")
                {
                    ToolTip = 'Specifies the value of the E-Waybill Remarks field.', Comment = '%';
                }
                field("E-Waybill Generated By"; Rec."E-Waybill Generated By")
                {
                    ToolTip = 'Specifies the value of the E-Waybill Generated By field.', Comment = '%';
                }
                field("E-Waybill Genrated DateTime"; Rec."E-Waybill Genrated DateTime")
                {
                    ToolTip = 'Specifies the value of the E-Waybill Genrated DateTime field.', Comment = '%';
                }
                field("E-Waybill Cancelled By"; Rec."E-Waybill Cancelled By")
                {
                    ToolTip = 'Specifies the value of the E-Waybill Cancelled By field.', Comment = '%';
                }
                field("E-Waybill Cancelled DateTime"; Rec."E-Waybill Cancelled DateTime")
                {
                    ToolTip = 'Specifies the value of the E-Waybill Cancelled DateTime field.', Comment = '%';
                }
                field("E-Waybill Error Message"; Rec."E-Waybill Error Message")
                {
                    ToolTip = 'Specifies the value of the E-Waybill Error Message field.', Comment = '%';
                }
                field("CT Owner ID"; Rec."CT Owner ID")
                {
                    ToolTip = 'Specifies the value of the CT Owner ID field.', Comment = '%';
                }
                field("GST No."; Rec."GST No.")
                {
                    ToolTip = 'Specifies the value of the GST No. field.', Comment = '%';
                }
                field("EWB API Source"; Rec."EWB API Source")
                {
                    ToolTip = 'Specifies the value of the EWB API Source field.', Comment = '%';
                }
                field("EWB Doc ID"; Rec."EWB Doc ID")
                {
                    ToolTip = 'Specifies the value of the EWB Doc ID field.', Comment = '%';
                }
                field("Supplier UPI Id"; Rec."Supplier UPI Id")
                {
                    ToolTip = 'Specifies the value of the Supplier UPI Id field.', Comment = '%';
                }
                field(QRstringConversion; Rec.QRstringConversion)
                {
                    ToolTip = 'Specifies the value of the QRstringConversion field.', Comment = '%';
                }
                field("B2C QR_Code"; Rec."B2C QR_Code")
                {
                    ToolTip = 'Specifies the value of the B2C QR_Code field.', Comment = '%';
                }
                field("B2C QR_Code Image"; Rec."B2C QR_Code Image")
                {
                    ToolTip = 'Specifies the value of the B2C QR_Code Image field.', Comment = '%';
                }
                field("E-Invoice IRN"; Rec."E-Invoice IRN")
                {
                    ToolTip = 'Specifies the value of the E-Invoice IRN field.', Comment = '%';
                }
                field(SignedQRCode; Rec.SignedQRCode)
                {
                    ToolTip = 'Specifies the value of the SignedQRCode field.', Comment = '%';
                }
                field(GetIRN; Rec.GetIRN)
                {
                    ToolTip = 'Specifies the value of the GetIRN field.', Comment = '%';
                }
                field(EWBWoIRN; Rec.EWBWoIRN)
                {
                    ToolTip = 'Specifies the value of the EWB Without IRN field.', Comment = '%';
                }
                field("E-way Success Response"; Rec."E-way Success Response")
                {
                    ToolTip = 'Specifies the value of the E-way Success Response field.', Comment = '%';
                }
                field("E-way Status"; Rec."E-way Status")
                {
                    ToolTip = 'Specifies the value of the E-way Status field.', Comment = '%';
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ToolTip = 'Specifies the value of the SystemCreatedAt field.', Comment = '%';
                }
                field(SystemCreatedBy; Rec.SystemCreatedBy)
                {
                    ToolTip = 'Specifies the value of the SystemCreatedBy field.', Comment = '%';
                }
                field(SystemId; Rec.SystemId)
                {
                    ToolTip = 'Specifies the value of the SystemId field.', Comment = '%';
                }
                field(SystemModifiedAt; Rec.SystemModifiedAt)
                {
                    ToolTip = 'Specifies the value of the SystemModifiedAt field.', Comment = '%';
                }
                field(SystemModifiedBy; Rec.SystemModifiedBy)
                {
                    ToolTip = 'Specifies the value of the SystemModifiedBy field.', Comment = '%';
                }
            }
        }
    }
}
