program ApexERP;

uses
  Vcl.Forms,
  Form.Main in 'Form.Main.pas' {frmMain},
  uDataModule in 'uDataModule.pas' {dmCore: TDataModule},
  uBaseForm in 'uBaseForm.pas' {frmBase},
  uFormProducts in 'uFormProducts.pas' {frmProducts},
  uFormCustomers in 'uFormCustomers.pas' {frmCustomers};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
