pageextension 50251 AddGST_UOM extends "Units of Measure"
{
    layout
    {
        addafter("International Standard Code")
        {
            field("E-Inv UOM"; "E-Inv UOM") { ApplicationArea = all; }
        }
        // Add changes to page laout here
    }


    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}