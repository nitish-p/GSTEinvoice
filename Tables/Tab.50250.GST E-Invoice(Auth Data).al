Table 50250 "GST E-Invoice(Auth Data)"
{

    fields
    {
        field(1; PK; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Auth Token"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(3; SEK; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(4; "Insertion DateTime"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Expiry Date Time"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(6; PlainAppKey; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(7; DecryptedSEK; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(8; DocumentNum; Code[30])
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Token Duration"; Time)
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Expiry Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(11; ClientId; Text[1000])
        {
            DataClassification = ToBeClassified;
        }
        field(12; secretId; Text[1000])
        {
            DataClassification = ToBeClassified;
        }
        field(13; "Public Key"; text[1000])
        {
            DataClassification = ToBeClassified;
        }
        field(14; "EWB Public Key"; Text[1000])
        {
            DataClassification = ToBeClassified;
        }
        field(15; "UserName"; Text[100])
        {

        }
        field(16; Password; Text[100])
        {
            ExtendedDatatype = Masked;
        }
        field(17; "Auth Token Url"; text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(18; IRNUrl; text[250])
        {

        }
        field(19; CancelIRN; text[250])
        {

        }
        field(20; GetEinvIRNURL; text[250])
        {

        }
        field(21; GetEWayIRNURL; text[250])
        {

        }
        field(22; EWBUrl; text[250])
        {

        }
        field(23; CancelEWB; text[250])
        {

        }
        field(24; EWBWO; text[250])
        {

        }
        field(25; VerifyGSTIN; text[250])
        {

        }
        field(100; GSTIN; code[20])
        {

        }
        field(101; "Enable Log"; Boolean)
        {
            DataClassification = ToBeClassified;
        }

    }

    keys
    {
        key(Key1; "PK")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

