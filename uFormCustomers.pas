unit uFormCustomers;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, Vcl.Grids, Vcl.DBGrids, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.DBCtrls, uBaseForm, uDataModule;

type
  TfrmCustomers = class(TfrmBase) // Inherits from Base
    pnlTop: TPanel;
    pnlGrid: TPanel;
    gridCustomers: TDBGrid;
    splitterGrid: TSplitter;
    pcDetails: TPageControl;
    tsGeneral: TTabSheet;
    tsAddress: TTabSheet;
    tsFinancial: TTabSheet;

    // CRUD Controls
    pnlActions: TPanel;
    btnNew: TButton;
    btnSave: TButton;
    btnDelete: TButton;

    // Data Components (Owned by this form)
    dsCustomers: TDataSource;

    // General Fields
    lblCustName: TLabel;
    edtCustName: TEdit;
    lblLegalName: TLabel;
    edtLegalName: TEdit;
    lblTaxID: TLabel;
    edtTaxID: TEdit;
    lblEmail: TLabel;
    edtEmail: TEdit;
    lblPhone: TLabel;
    edtPhone: TEdit;
    lblWebsite: TLabel;
    edtWebsite: TEdit;
    chkActive: TCheckBox;

    // Address Fields
    lblAddress: TLabel;
    memAddress: TMemo;
    lblCity: TLabel;
    edtCity: TEdit;
    lblState: TLabel;
    edtState: TEdit;
    lblZip: TLabel;
    edtZip: TEdit;
    lblCountry: TLabel;
    edtCountry: TEdit;

    // Financial Fields
    lblCreditLimit: TLabel;
    edtCreditLimit: TEdit;
    lblNotes: TLabel;
    memNotes: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure gridCustomersCellClick(Column: TColumn);
  protected
    procedure ApplyTheme; override;
    procedure ApplyLanguage; override;
  private
    FQuery: TFDQuery;
    FCurrentCustomerID: Integer;
    procedure RefreshGrid;
    procedure ClearInputs;
    procedure LoadCustomerData;
    function ValidateInput: Boolean;
  public
    constructor Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage); override;
  end;

implementation

{$R *.dfm}

constructor TfrmCustomers.Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage);
begin
  // Call the base constructor with injected dependencies
  inherited Create(AOwner, AConn, ATheme, ALang);

  // Setup internal Query using the injected connection
  FQuery := TFDQuery.Create(Self);
  FQuery.Connection := DBConnection;

  dsCustomers.DataSet := FQuery;
  FCurrentCustomerID := -1;

  RefreshGrid;
end;

procedure TfrmCustomers.FormCreate(Sender: TObject);
begin
  // VCL initialization if needed
end;

procedure TfrmCustomers.FormDestroy(Sender: TObject);
begin
  if Assigned(FQuery) then
    FQuery.Free;
end;

// --- CRUD OPERATIONS ---

procedure TfrmCustomers.RefreshGrid;
begin
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT CustomerID, CustomerName, Email, Phone, BillingCity, IsActive FROM Customers ORDER BY CustomerName';
  FQuery.Open;
end;

procedure TfrmCustomers.btnNewClick(Sender: TObject);
begin
  ClearInputs;
  FCurrentCustomerID := -1;
  chkActive.Checked := True;
  edtCustName.SetFocus;
end;

procedure TfrmCustomers.btnSaveClick(Sender: TObject);
var
  SQL: string;
  NewCustomerID: Integer;
  qryCheck: TFDQuery;
begin
  // Validation
  if not ValidateInput then
    Exit;

  qryCheck := TFDQuery.Create(nil);
  try
    qryCheck.Connection := DBConnection;

    // Check if this is an update or insert
    if FCurrentCustomerID > 0 then
    begin
      // UPDATE existing customer
      SQL := 'UPDATE Customers SET ' +
             'CustomerName = :custname, LegalName = :legal, TaxID = :taxid, ' +
             'Email = :email, Phone = :phone, Website = :website, ' +
             'BillingAddress = :addr, BillingCity = :city, BillingState = :state, ' +
             'BillingZip = :zip, BillingCountry = :country, ' +
             'CreditLimit = :credit, IsActive = :active, Notes = :notes ' +
             'WHERE CustomerID = :id';

      DBConnection.ExecSQL(SQL, [
        edtCustName.Text,
        edtLegalName.Text,
        edtTaxID.Text,
        edtEmail.Text,
        edtPhone.Text,
        edtWebsite.Text,
        memAddress.Text,
        edtCity.Text,
        edtState.Text,
        edtZip.Text,
        edtCountry.Text,
        StrToFloatDef(edtCreditLimit.Text, 0),
        Integer(chkActive.Checked),
        memNotes.Text,
        FCurrentCustomerID
      ]);

      ShowMessage('Customer updated successfully!');
    end
    else
    begin
      // INSERT new customer
      SQL := 'INSERT INTO Customers (CustomerName, LegalName, TaxID, Email, Phone, Website, ' +
             'BillingAddress, BillingCity, BillingState, BillingZip, BillingCountry, ' +
             'CreditLimit, IsActive, Notes) ' +
             'VALUES (:custname, :legal, :taxid, :email, :phone, :website, ' +
             ':addr, :city, :state, :zip, :country, :credit, :active, :notes)';

      DBConnection.ExecSQL(SQL, [
        edtCustName.Text,
        edtLegalName.Text,
        edtTaxID.Text,
        edtEmail.Text,
        edtPhone.Text,
        edtWebsite.Text,
        memAddress.Text,
        edtCity.Text,
        edtState.Text,
        edtZip.Text,
        edtCountry.Text,
        StrToFloatDef(edtCreditLimit.Text, 0),
        Integer(chkActive.Checked),
        memNotes.Text
      ]);

      ShowMessage('Customer created successfully!');
    end;

    RefreshGrid;
    ClearInputs;

  finally
    qryCheck.Free;
  end;
end;

procedure TfrmCustomers.btnDeleteClick(Sender: TObject);
begin
  if not FQuery.IsEmpty then
  begin
    if MessageDlg('Are you sure you want to delete this customer?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      DBConnection.ExecSQL('DELETE FROM Customers WHERE CustomerID = :id', [FQuery.FieldByName('CustomerID').AsInteger]);
      RefreshGrid;
      ClearInputs;
      ShowMessage('Customer deleted successfully!');
    end;
  end
  else
    ShowMessage('No customer selected!');
end;

procedure TfrmCustomers.gridCustomersCellClick(Column: TColumn);
begin
  if not FQuery.IsEmpty then
  begin
    FCurrentCustomerID := FQuery.FieldByName('CustomerID').AsInteger;
    LoadCustomerData;
  end;
end;

procedure TfrmCustomers.LoadCustomerData;
var
  qryLoad: TFDQuery;
begin
  qryLoad := TFDQuery.Create(nil);
  try
    qryLoad.Connection := DBConnection;
    qryLoad.SQL.Text := 'SELECT * FROM Customers WHERE CustomerID = :id';
    qryLoad.ParamByName('id').AsInteger := FCurrentCustomerID;
    qryLoad.Open;

    if not qryLoad.IsEmpty then
    begin
      edtCustName.Text := qryLoad.FieldByName('CustomerName').AsString;
      edtLegalName.Text := qryLoad.FieldByName('LegalName').AsString;
      edtTaxID.Text := qryLoad.FieldByName('TaxID').AsString;
      edtEmail.Text := qryLoad.FieldByName('Email').AsString;
      edtPhone.Text := qryLoad.FieldByName('Phone').AsString;
      edtWebsite.Text := qryLoad.FieldByName('Website').AsString;
      memAddress.Text := qryLoad.FieldByName('BillingAddress').AsString;
      edtCity.Text := qryLoad.FieldByName('BillingCity').AsString;
      edtState.Text := qryLoad.FieldByName('BillingState').AsString;
      edtZip.Text := qryLoad.FieldByName('BillingZip').AsString;
      edtCountry.Text := qryLoad.FieldByName('BillingCountry').AsString;
      edtCreditLimit.Text := qryLoad.FieldByName('CreditLimit').AsString;
      chkActive.Checked := qryLoad.FieldByName('IsActive').AsInteger = 1;
      memNotes.Text := qryLoad.FieldByName('Notes').AsString;
    end;

  finally
    qryLoad.Free;
  end;
end;

procedure TfrmCustomers.ClearInputs;
begin
  edtCustName.Clear;
  edtLegalName.Clear;
  edtTaxID.Clear;
  edtEmail.Clear;
  edtPhone.Clear;
  edtWebsite.Clear;
  memAddress.Clear;
  edtCity.Clear;
  edtState.Clear;
  edtZip.Clear;
  edtCountry.Clear;
  edtCreditLimit.Text := '0';
  chkActive.Checked := True;
  memNotes.Clear;

  FCurrentCustomerID := -1;
end;

function TfrmCustomers.ValidateInput: Boolean;
var
  qryCheck: TFDQuery;
begin
  Result := False;

  // 1. Mandatory Name
  if Trim(edtCustName.Text) = '' then
  begin
    ShowMessage('Customer Name is required!');
    edtCustName.SetFocus;
    Exit;
  end;

  // 2. Unique Tax ID (if provided)
  if Trim(edtTaxID.Text) <> '' then
  begin
    qryCheck := TFDQuery.Create(nil);
    try
      qryCheck.Connection := DBConnection;
      qryCheck.SQL.Text := 'SELECT COUNT(*) AS Cnt FROM Customers WHERE TaxID = :taxid AND CustomerID <> :id';
      qryCheck.ParamByName('taxid').AsString := edtTaxID.Text;
      qryCheck.ParamByName('id').AsInteger := FCurrentCustomerID;
      qryCheck.Open;

      if qryCheck.FieldByName('Cnt').AsInteger > 0 then
      begin
        ShowMessage('Tax ID already exists for another customer!');
        edtTaxID.SetFocus;
        Exit;
      end;
    finally
      qryCheck.Free;
    end;
  end;

  // 3. Credit Limit must be >= 0
  if StrToFloatDef(edtCreditLimit.Text, 0) < 0 then
  begin
    ShowMessage('Credit Limit must be greater than or equal to 0!');
    edtCreditLimit.SetFocus;
    Exit;
  end;

  Result := True;
end;

// --- THEMING IMPLEMENTATION ---
procedure TfrmCustomers.ApplyTheme;
begin
  inherited; // Sets the form background color

  if AppTheme = atDark then
  begin
    // Panels
    pnlTop.Color := $00151C28; // Dark Navy
    pnlGrid.Color := $002B1E16;
    pnlActions.Color := $00151C28;

    // PageControl
    pcDetails.Color := $002B1E16;
    tsGeneral.Color := $002B1E16;
    tsAddress.Color := $002B1E16;
    tsFinancial.Color := $002B1E16;

    // Grid Customization for Dark Mode
    gridCustomers.Color := $00382E26;
    gridCustomers.Font.Color := clWhite;
    gridCustomers.TitleFont.Color := clWhite;

    // Labels
    lblCustName.Font.Color := clSilver;
    lblLegalName.Font.Color := clSilver;
    lblTaxID.Font.Color := clSilver;
    lblEmail.Font.Color := clSilver;
    lblPhone.Font.Color := clSilver;
    lblWebsite.Font.Color := clSilver;
    lblAddress.Font.Color := clSilver;
    lblCity.Font.Color := clSilver;
    lblState.Font.Color := clSilver;
    lblZip.Font.Color := clSilver;
    lblCountry.Font.Color := clSilver;
    lblCreditLimit.Font.Color := clSilver;
    lblNotes.Font.Color := clSilver;

    // Edit Controls
    edtCustName.Color := $00382E26;
    edtLegalName.Color := $00382E26;
    edtTaxID.Color := $00382E26;
    edtEmail.Color := $00382E26;
    edtPhone.Color := $00382E26;
    edtWebsite.Color := $00382E26;
    edtCity.Color := $00382E26;
    edtState.Color := $00382E26;
    edtZip.Color := $00382E26;
    edtCountry.Color := $00382E26;
    edtCreditLimit.Color := $00382E26;
    memAddress.Color := $00382E26;
    memNotes.Color := $00382E26;

    edtCustName.Font.Color := clWhite;
    edtLegalName.Font.Color := clWhite;
    edtTaxID.Font.Color := clWhite;
    edtEmail.Font.Color := clWhite;
    edtPhone.Font.Color := clWhite;
    edtWebsite.Font.Color := clWhite;
    edtCity.Font.Color := clWhite;
    edtState.Font.Color := clWhite;
    edtZip.Font.Color := clWhite;
    edtCountry.Font.Color := clWhite;
    edtCreditLimit.Font.Color := clWhite;
    memAddress.Font.Color := clWhite;
    memNotes.Font.Color := clWhite;
  end
  else
  begin
    // Light Mode
    pnlTop.Color := $00F4F6F8;
    pnlGrid.Color := clWhite;
    pnlActions.Color := $00F4F6F8;

    // PageControl
    pcDetails.Color := clWhite;
    tsGeneral.Color := clWhite;
    tsAddress.Color := clWhite;
    tsFinancial.Color := clWhite;

    gridCustomers.Color := clWhite;
    gridCustomers.Font.Color := clBlack;
    gridCustomers.TitleFont.Color := clBlack;

    lblCustName.Font.Color := clBlack;
    lblLegalName.Font.Color := clBlack;
    lblTaxID.Font.Color := clBlack;
    lblEmail.Font.Color := clBlack;
    lblPhone.Font.Color := clBlack;
    lblWebsite.Font.Color := clBlack;
    lblAddress.Font.Color := clBlack;
    lblCity.Font.Color := clBlack;
    lblState.Font.Color := clBlack;
    lblZip.Font.Color := clBlack;
    lblCountry.Font.Color := clBlack;
    lblCreditLimit.Font.Color := clBlack;
    lblNotes.Font.Color := clBlack;

    edtCustName.Color := clWhite;
    edtLegalName.Color := clWhite;
    edtTaxID.Color := clWhite;
    edtEmail.Color := clWhite;
    edtPhone.Color := clWhite;
    edtWebsite.Color := clWhite;
    edtCity.Color := clWhite;
    edtState.Color := clWhite;
    edtZip.Color := clWhite;
    edtCountry.Color := clWhite;
    edtCreditLimit.Color := clWhite;
    memAddress.Color := clWhite;
    memNotes.Color := clWhite;

    edtCustName.Font.Color := clBlack;
    edtLegalName.Font.Color := clBlack;
    edtTaxID.Font.Color := clBlack;
    edtEmail.Font.Color := clBlack;
    edtPhone.Font.Color := clBlack;
    edtWebsite.Font.Color := clBlack;
    edtCity.Font.Color := clBlack;
    edtState.Font.Color := clBlack;
    edtZip.Font.Color := clBlack;
    edtCountry.Font.Color := clBlack;
    edtCreditLimit.Font.Color := clBlack;
    memAddress.Font.Color := clBlack;
    memNotes.Font.Color := clBlack;
  end;
end;

// --- LOCALIZATION IMPLEMENTATION ---
procedure TfrmCustomers.ApplyLanguage;
begin
  inherited;

  case AppLanguage of
    alEnglish:
      begin
        Caption := 'Customer Management';
        tsGeneral.Caption := 'General';
        tsAddress.Caption := 'Address';
        tsFinancial.Caption := 'Financial';
        btnNew.Caption := 'New';
        btnSave.Caption := 'Save';
        btnDelete.Caption := 'Delete';
        lblCustName.Caption := 'Customer Name:';
        lblLegalName.Caption := 'Legal Name:';
        lblTaxID.Caption := 'Tax ID (VAT/EIN/CNPJ):';
        lblEmail.Caption := 'Email:';
        lblPhone.Caption := 'Phone:';
        lblWebsite.Caption := 'Website:';
        lblAddress.Caption := 'Billing Address:';
        lblCity.Caption := 'City:';
        lblState.Caption := 'State/Province:';
        lblZip.Caption := 'Zip/Postal Code:';
        lblCountry.Caption := 'Country:';
        lblCreditLimit.Caption := 'Credit Limit:';
        lblNotes.Caption := 'Internal Notes:';
        chkActive.Caption := 'Active Account';
      end;
    alPortuguese:
      begin
        Caption := 'Gerenciar Clientes';
        tsGeneral.Caption := 'Geral';
        tsAddress.Caption := 'Endereço';
        tsFinancial.Caption := 'Financeiro';
        btnNew.Caption := 'Novo';
        btnSave.Caption := 'Salvar';
        btnDelete.Caption := 'Excluir';
        lblCustName.Caption := 'Nome do Cliente:';
        lblLegalName.Caption := 'Razão Social:';
        lblTaxID.Caption := 'CNPJ/CPF:';
        lblEmail.Caption := 'Email:';
        lblPhone.Caption := 'Telefone:';
        lblWebsite.Caption := 'Site:';
        lblAddress.Caption := 'Endereço de Cobrança:';
        lblCity.Caption := 'Cidade:';
        lblState.Caption := 'Estado:';
        lblZip.Caption := 'CEP:';
        lblCountry.Caption := 'País:';
        lblCreditLimit.Caption := 'Limite de Crédito:';
        lblNotes.Caption := 'Observações Internas:';
        chkActive.Caption := 'Conta Ativa';
      end;
    alSpanish:
      begin
        Caption := 'Gestión de Clientes';
        tsGeneral.Caption := 'General';
        tsAddress.Caption := 'Dirección';
        tsFinancial.Caption := 'Financiero';
        btnNew.Caption := 'Nuevo';
        btnSave.Caption := 'Guardar';
        btnDelete.Caption := 'Eliminar';
        lblCustName.Caption := 'Nombre del Cliente:';
        lblLegalName.Caption := 'Nombre Legal:';
        lblTaxID.Caption := 'Identificación Fiscal:';
        lblEmail.Caption := 'Correo Electrónico:';
        lblPhone.Caption := 'Teléfono:';
        lblWebsite.Caption := 'Sitio Web:';
        lblAddress.Caption := 'Dirección de Facturación:';
        lblCity.Caption := 'Ciudad:';
        lblState.Caption := 'Estado/Provincia:';
        lblZip.Caption := 'Código Postal:';
        lblCountry.Caption := 'País:';
        lblCreditLimit.Caption := 'Límite de Crédito:';
        lblNotes.Caption := 'Notas Internas:';
        chkActive.Caption := 'Cuenta Activa';
      end;
  end;
end;

end.
