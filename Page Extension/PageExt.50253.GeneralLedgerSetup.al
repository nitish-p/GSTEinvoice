// //CITS_RS GST Invoice Field addition on Setup pages
// pageextension 50253 Add_EInvoice_GenLedgerSet extends "General Ledger Setup"
// {

//     layout
//     {

//         addafter(Application)
//         {
//             group(GST_E_Invoice)
//             {
//                 Caption = 'GST E Invoice';
//                 field("GST IRN Generation URL"; "GST IRN Generation URL") { ApplicationArea = all; }
//                 field("GST Authorization URL"; "GST Authorization URL") { ApplicationArea = all; }
//                 field("GST Public Key Directory Path"; "GST Public Key Directory Path") { ApplicationArea = all; }
//                 field("E_Way Bill URL"; "E_Way Bill URL") { ApplicationArea = all; }
//                 field("Cancel E-Invoice URL"; "Cancel E-Invoice URL") { ApplicationArea = all; }
//                 field("Cancel E-Way Bill"; "Cancel E-Way Bill") { ApplicationArea = all; }
//                 field("EWAYBILL w/o IRN"; "EWAYBILL w/o IRN") { ApplicationArea = all; }
//             }

//         }
//         // Add changes to page layout here
//     }

//     actions
//     {
//         // Add changes to page actions here
//     }

//     var
//         myInt: Integer;
// }