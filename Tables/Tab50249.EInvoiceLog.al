table 50249 "E-Invoice Log"
{
    fields
    {
        field(1; "Document Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = 'Invoice,Credit Memo,Transfer,Transfer Cancel';
            OptionMembers = Invoice,"Credit Memo",Transfer,"Transfer Cancel";
        }
        field(2; "Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Sales Invoice Header"."No.";
            trigger OnLookup()
            var
                SalesInvHed: Record "Sales Invoice Header";
                PostedSalesInvPage: page "Posted Sales Invoice";
            begin
                SalesInvHed.Reset();
                SalesInvHed.SetRange("No.", "Document No.");
                PostedSalesInvPage.LookupMode := true;
                PostedSalesInvPage.SetTableView(SalesInvHed);
                PostedSalesInvPage.Run();
            end;
        }
        field(3; "QR Code Image"; BLOB)
        {
            DataClassification = ToBeClassified;
            SubType = Bitmap;
        }
        field(4; "Invoice Reference Number"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Signed Invoice Txt"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(6; Acknowledgment_number; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Acknowledgment Date"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(8; "Created Date Time"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Cancel DateTime"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Cancel Reason"; Enum "e-Invoice Cancel Reason")
        {
            DataClassification = ToBeClassified;
            // OptionCaption = ' ,Duplicate,Data Entry Mistake';
            // OptionMembers = " ",Duplicate,"Data Entry Mistake";

            trigger OnValidate()
            begin
                TESTFIELD("Cancel DateTime", 0DT);
            end;
        }
        field(11; "Cancel Remarks"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(12; "E-Way Bill Status"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = 'Not-Generated,Generated,Cancelled';
            OptionMembers = "Not-Generated",Generated,Cancelled;
        }
        field(13; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(14; "Transaction Identifier"; Text[150])
        {
            DataClassification = ToBeClassified;
        }
        field(15; Status; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = ' ,Error,Generated,Fail,Cancelled';
            OptionMembers = " ",Error,Generated,Fail,Cancelled;
        }
        field(16; "Error Message"; Text[1024])
        {
            DataClassification = ToBeClassified;
        }
        field(17; "Signed Invoice"; BLOB)
        {
            DataClassification = ToBeClassified;
        }
        field(18; "Signed QR Code"; BLOB)
        {
            DataClassification = ToBeClassified;
        }
        field(60; "SignedQRCode"; Code[1024])
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Created By"; Code[50])
        {
            DataClassification = ToBeClassified;
        }
        field(22; "Response JSON"; BLOB)
        {
            DataClassification = ToBeClassified;
        }
        field(23; "Request JSON"; BLOB)
        {
            DataClassification = ToBeClassified;
        }
        field(24; "QR Code"; text[1024])
        {
            DataClassification = ToBeClassified;
        }
        field(26; "IRN Status"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(27; "Cancel Date"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(28; "Cancellation Error Message"; Text[1024])
        {
            DataClassification = ToBeClassified;
        }
        field(29; "Cancelled By"; Code[50])
        {
            DataClassification = ToBeClassified;
            TableRelation = "User Setup";
        }
        field(30; "E-Waybill Status"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = ' ,Error,Generated,Fail,Cancelled';
            OptionMembers = " ",Error,Generated,Fail,Cancelled;
        }
        field(31; "E-Waybill No."; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(32; "E-Waybill Date"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(33; "E-Waybill Valid Till"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(34; "E-Waybill Remarks"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(35; "E-Waybill Generated By"; Code[50])
        {
            DataClassification = ToBeClassified;
        }
        field(36; "E-Waybill Genrated DateTime"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(37; "E-Waybill Cancelled By"; Code[50])
        {
            DataClassification = ToBeClassified;
        }
        field(38; "E-Waybill Cancelled DateTime"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(39; "E-Waybill Error Message"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(50; "CT Owner ID"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(51; "GST No."; Text[15])
        {
            DataClassification = ToBeClassified;
        }
        field(52; "EWB API Source"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = ' ,EInvoice,EWayBill';
            OptionMembers = " ",EInvoice,EWayBill;
        }
        field(53; "EWB Doc ID"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(54; "Supplier UPI Id"; Code[60])
        {
            DataClassification = ToBeClassified;
            Description = 'instead of storing in sales invoice header due to tab contraint-SRN-B2CQR-T18918';
        }
        field(56; QRstringConversion; Text[200])
        {
            DataClassification = ToBeClassified;
            Description = 'SN-T18918';
        }
        field(57; "B2C QR_Code"; BLOB)
        {
            DataClassification = ToBeClassified;
            Description = 'SN-TEC-T21952';
        }
        field(58; "B2C QR_Code Image"; BLOB)
        {
            DataClassification = ToBeClassified;
            Description = 'SN-TEC-T21952';
            SubType = Bitmap;
        }
        field(59; "E-Invoice IRN"; Code[100])
        {
            DataClassification = ToBeClassified;
        }
        field(61; GetIRN; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(62; "EWBWoIRN"; Boolean)
        {
            Caption = 'EWB Without IRN';
            DataClassification = ToBeClassified;
        }
        field(63; "E-way Success Response"; Text[1024])
        {
            DataClassification = ToBeClassified;
        }
        Field(64; "E-way Status"; Text[20])
        {
            DataClassification = ToBeClassified;
        }


    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Document No.")
        {

        }
    }
}