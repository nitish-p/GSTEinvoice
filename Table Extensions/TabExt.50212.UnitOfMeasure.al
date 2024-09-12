tableextension 50212 AddGSTUOM_EInv extends "Unit of Measure"
{
    fields
    {
        field(50111; "E-Inv UOM"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        //         // field(50111; "GST UOM_N"; Code[10]) { DataClassification = ToBeClassified; }
        // Add changes to table fields here
    }

    var
        myInt: Integer;
}