page 50250 "E-invoice Setup"
{
    ApplicationArea = All;
    Caption = 'E-invoice Setup';
    PageType = List;
    SourceTable = "GST E-Invoice(Auth Data)";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(PK; Rec.PK)
                {
                    ToolTip = 'Specifies the value of the PK field.', Comment = '%';
                }
                field("Auth Token"; Rec."Auth Token")
                {
                    ToolTip = 'Specifies the value of the Auth Token field.', Comment = '%';
                }
                field(SEK; Rec.SEK)
                {
                    ToolTip = 'Specifies the value of the SEK field.', Comment = '%';
                }
                field("Insertion DateTime"; Rec."Insertion DateTime")
                {
                    ToolTip = 'Specifies the value of the Insertion DateTime field.', Comment = '%';
                }
                field("Expiry Date Time"; Rec."Expiry Date Time")
                {
                    ToolTip = 'Specifies the value of the Expiry Date Time field.', Comment = '%';
                }
                field(PlainAppKey; Rec.PlainAppKey)
                {
                    ToolTip = 'Specifies the value of the PlainAppKey field.', Comment = '%';
                }
                field(DecryptedSEK; Rec.DecryptedSEK)
                {
                    ToolTip = 'Specifies the value of the DecryptedSEK field.', Comment = '%';
                }
                field(DocumentNum; Rec.DocumentNum)
                {
                    ToolTip = 'Specifies the value of the DocumentNum field.', Comment = '%';
                }
                field("Token Duration"; Rec."Token Duration")
                {
                    ToolTip = 'Specifies the value of the Token Duration field.', Comment = '%';
                }
                field("Expiry Date"; Rec."Expiry Date")
                {
                    ToolTip = 'Specifies the value of the Expiry Date field.', Comment = '%';
                }
                field(ClientId; Rec.ClientId)
                {
                    ToolTip = 'Specifies the value of the ClientId field.', Comment = '%';
                }
                field(secretId; Rec.secretId)
                {
                    ToolTip = 'Specifies the value of the secretId field.', Comment = '%';
                }
                field("Public Key"; Rec."Public Key")
                {
                    ToolTip = 'Specifies the value of the Public Key field.', Comment = '%';
                }
                field("EWB Public Key"; Rec."EWB Public Key")
                {
                    ToolTip = 'Specifies the value of the EWB Public Key field.', Comment = '%';
                }
                field(UserName; Rec.UserName)
                {
                    ToolTip = 'Specifies the value of the UserName field.', Comment = '%';
                }
                field(Password; Rec.Password)
                {
                    ToolTip = 'Specifies the value of the Password field.', Comment = '%';
                }
                field("Auth Token Url"; Rec."Auth Token Url")
                {
                    ToolTip = 'Specifies the value of the Auth Token Url field.', Comment = '%';
                }
                field(IRNUrl; Rec.IRNUrl)
                {
                    ToolTip = 'Specifies the value of the IRNUrl field.', Comment = '%';
                }
                field(CancelIRN; Rec.CancelIRN)
                {
                    ToolTip = 'Specifies the value of the CancelIRN field.', Comment = '%';
                }
                field(GetEinvIRNURL; Rec.GetEinvIRNURL)
                {
                    ToolTip = 'Specifies the value of the GetEinvIRNURL field.', Comment = '%';
                }
                field(GetEWayIRNURL; Rec.GetEWayIRNURL)
                {
                    ToolTip = 'Specifies the value of the GetEWayIRNURL field.', Comment = '%';
                }
                field(EWBUrl; Rec.EWBUrl)
                {
                    ToolTip = 'Specifies the value of the EWBUrl field.', Comment = '%';
                }
                field(CancelEWB; Rec.CancelEWB)
                {
                    ToolTip = 'Specifies the value of the CancelEWB field.', Comment = '%';
                }
                field(EWBWO; Rec.EWBWO)
                {
                    ToolTip = 'Specifies the value of the EWBWO field.', Comment = '%';
                }
                field(VerifyGSTIN; Rec.VerifyGSTIN)
                {
                    ToolTip = 'Specifies the value of the VerifyGSTIN field.', Comment = '%';
                }
                field(GSTIN; Rec.GSTIN)
                {
                    ToolTip = 'Specifies the value of the GSTIN field.', Comment = '%';
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
