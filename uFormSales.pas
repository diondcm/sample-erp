unit uFormSales;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBaseForm, FireDAC.Comp.Client, Data.DB,
  FireDAC.Stan.Param, Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids, Vcl.ExtCtrls, Vcl.ComCtrls,
  FireDAC.DApt, System.DateUtils;

type
  TfrmSales = class(TfrmBase) // Inherits from our Architecture Base
    pnlHeader: TPanel;
    pnlFooter: TPanel;
    pnlMiddle: TPanel;
    grdItems: TDBGrid;
    lblCustomer: TLabel;
    cmbCustomer: TComboBox;
    lblDate: TLabel;
    dtpSaleDate: TDateTimePicker;
    lblStatus: TLabel;
    lblStatusValue: TLabel;
    lblGrandTotal: TLabel;
    lblGrandTotalValue: TLabel;
    btnFinalize: TButton;
    btnCancel: TButton;
    pnlAddItem: TPanel;
    lblProduct: TLabel;
    cmbProduct: TComboBox;
    lblQuantity: TLabel;
    edtQuantity: TEdit;
    btnAddItem: TButton;
    dsItems: TDataSource;
    btnDeleteItem: TButton;
    btnNewSale: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNewSaleClick(Sender: TObject);
    procedure btnAddItemClick(Sender: TObject);
    procedure btnDeleteItemClick(Sender: TObject);
    procedure btnFinalizeClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure grdItemsCellClick(Column: TColumn);
    procedure cmbProductChange(Sender: TObject);
  private
    FQuery: TFDQuery;
    FCurrentSaleID: Integer;
    FItemsQuery: TFDQuery;
    procedure LoadCustomers;
    procedure LoadProducts;
    procedure StartNewSale;
    procedure LoadSaleItems;
    procedure CalculateTotal;
    procedure ClearInputs;
    procedure UpdateUIState;
  protected
    procedure ApplyTheme; override;
    procedure ApplyLanguage; override;
  public
    constructor Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage); override;
  end;

implementation

{$R *.dfm}

constructor TfrmSales.Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage);
begin
  // 1. Call the Magic Constructor of the Base
  inherited Create(AOwner, AConn, ATheme, ALang);

  // 2. Setup internal Query using the INJECTED connection
  FQuery := TFDQuery.Create(Self);
  FQuery.Connection := DBConnection;

  FItemsQuery := TFDQuery.Create(Self);
  FItemsQuery.Connection := DBConnection;
  dsItems.DataSet := FItemsQuery;

  FCurrentSaleID := -1;

  // Load reference data
  LoadCustomers;
  LoadProducts;

  // Start with a new sale
  StartNewSale;
end;

procedure TfrmSales.FormCreate(Sender: TObject);
begin
  // VCL Init if needed
  dtpSaleDate.Date := Now;
  edtQuantity.Text := '1';

  // Grid setup
  grdItems.Options := grdItems.Options + [dgRowSelect];
end;

procedure TfrmSales.FormDestroy(Sender: TObject);
begin
  if Assigned(FQuery) then
    FQuery.Free;
  if Assigned(FItemsQuery) then
    FItemsQuery.Free;
end;

// --- DATA LOADING METHODS ---

procedure TfrmSales.LoadCustomers;
var
  qryCustomers: TFDQuery;
begin
  qryCustomers := TFDQuery.Create(nil);
  try
    qryCustomers.Connection := DBConnection;
    qryCustomers.SQL.Text := 'SELECT CustomerID, CustomerName FROM Customers WHERE IsActive = 1 ORDER BY CustomerName';
    qryCustomers.Open;

    cmbCustomer.Items.Clear;
    while not qryCustomers.Eof do
    begin
      cmbCustomer.Items.AddObject(
        qryCustomers.FieldByName('CustomerName').AsString,
        TObject(qryCustomers.FieldByName('CustomerID').AsInteger)
      );
      qryCustomers.Next;
    end;

    if cmbCustomer.Items.Count > 0 then
      cmbCustomer.ItemIndex := 0;

  finally
    qryCustomers.Free;
  end;
end;

procedure TfrmSales.LoadProducts;
var
  qryProducts: TFDQuery;
  DisplayText: string;
begin
  qryProducts := TFDQuery.Create(nil);
  try
    qryProducts.Connection := DBConnection;
    qryProducts.SQL.Text := 'SELECT ProductID, SKU, Name, MSRP, WarrantyMonths FROM Products ORDER BY Name';
    qryProducts.Open;

    cmbProduct.Items.Clear;
    while not qryProducts.Eof do
    begin
      // Format: "Product Name - SKU (Warranty: X months) - $XX.XX"
      DisplayText := Format('%s - %s (Warranty: %d mo) - $%.2f',
        [
          qryProducts.FieldByName('Name').AsString,
          qryProducts.FieldByName('SKU').AsString,
          qryProducts.FieldByName('WarrantyMonths').AsInteger,
          qryProducts.FieldByName('MSRP').AsFloat
        ]);

      cmbProduct.Items.AddObject(
        DisplayText,
        TObject(qryProducts.FieldByName('ProductID').AsInteger)
      );
      qryProducts.Next;
    end;

    if cmbProduct.Items.Count > 0 then
      cmbProduct.ItemIndex := 0;

  finally
    qryProducts.Free;
  end;
end;

procedure TfrmSales.LoadSaleItems;
var
  SQL: string;
begin
  FItemsQuery.Close;
  SQL := 'SELECT si.ItemID, si.SaleID, si.ProductID, si.Quantity, si.UnitPrice, si.SubTotal, ' +
         '       p.Name AS ProductName, p.SKU, p.WarrantyMonths ' +
         'FROM SaleItems si ' +
         'INNER JOIN Products p ON si.ProductID = p.ProductID ' +
         'WHERE si.SaleID = :SaleID ' +
         'ORDER BY si.ItemID';

  FItemsQuery.SQL.Text := SQL;
  FItemsQuery.ParamByName('SaleID').AsInteger := FCurrentSaleID;
  FItemsQuery.Open;

  CalculateTotal;
end;

// --- SALE MANAGEMENT ---

procedure TfrmSales.StartNewSale;
var
  SQL: string;
  qryNewSale: TFDQuery;
begin
  // Create a new DRAFT sale record
  if cmbCustomer.ItemIndex < 0 then
  begin
    ShowMessage('Please select a customer first!');
    Exit;
  end;

  qryNewSale := TFDQuery.Create(nil);
  try
    qryNewSale.Connection := DBConnection;

    SQL := 'INSERT INTO Sales (CustomerID, SaleDate, Status, TotalAmount) ' +
           'VALUES (:CustomerID, :SaleDate, ''DRAFT'', 0)';

    DBConnection.ExecSQL(SQL, [
      Integer(cmbCustomer.Items.Objects[cmbCustomer.ItemIndex]),
      FormatDateTime('yyyy-mm-dd hh:nn:ss', dtpSaleDate.DateTime)
    ]);

    // Get the new SaleID
    qryNewSale.SQL.Text := 'SELECT last_insert_rowid() AS NewID';
    qryNewSale.Open;
    FCurrentSaleID := qryNewSale.FieldByName('NewID').AsInteger;
    qryNewSale.Close;

    // Update UI
    lblStatusValue.Caption := 'DRAFT';
    LoadSaleItems;
    UpdateUIState;

  finally
    qryNewSale.Free;
  end;
end;

procedure TfrmSales.btnNewSaleClick(Sender: TObject);
begin
  if FCurrentSaleID > 0 then
  begin
    if MessageDlg('Start a new sale? Current sale will remain as DRAFT.', mtConfirmation, [mbYes, mbNo], 0) = mrNo then
      Exit;
  end;

  StartNewSale;
  ClearInputs;
end;

// --- ITEM MANAGEMENT ---

procedure TfrmSales.btnAddItemClick(Sender: TObject);
var
  SQL: string;
  ProductID: Integer;
  Quantity: Integer;
  UnitPrice: Real;
  qryProduct: TFDQuery;
begin
  // Validation
  if FCurrentSaleID <= 0 then
  begin
    ShowMessage('Please start a new sale first!');
    Exit;
  end;

  if cmbProduct.ItemIndex < 0 then
  begin
    ShowMessage('Please select a product!');
    Exit;
  end;

  Quantity := StrToIntDef(edtQuantity.Text, 0);
  if Quantity <= 0 then
  begin
    ShowMessage('Please enter a valid quantity!');
    edtQuantity.SetFocus;
    Exit;
  end;

  ProductID := Integer(cmbProduct.Items.Objects[cmbProduct.ItemIndex]);

  // Get the current MSRP for this product (snapshot at time of sale)
  qryProduct := TFDQuery.Create(nil);
  try
    qryProduct.Connection := DBConnection;
    qryProduct.SQL.Text := 'SELECT MSRP FROM Products WHERE ProductID = :id';
    qryProduct.ParamByName('id').AsInteger := ProductID;
    qryProduct.Open;

    if qryProduct.IsEmpty then
    begin
      ShowMessage('Product not found!');
      Exit;
    end;

    UnitPrice := qryProduct.FieldByName('MSRP').AsFloat;

    // Insert the item
    SQL := 'INSERT INTO SaleItems (SaleID, ProductID, Quantity, UnitPrice, SubTotal) ' +
           'VALUES (:SaleID, :ProductID, :Quantity, :UnitPrice, :SubTotal)';

    DBConnection.ExecSQL(SQL, [
      FCurrentSaleID,
      ProductID,
      Quantity,
      UnitPrice,
      Quantity * UnitPrice  // SubTotal
    ]);

    // Refresh the grid
    LoadSaleItems;
    edtQuantity.Text := '1';

  finally
    qryProduct.Free;
  end;
end;

procedure TfrmSales.btnDeleteItemClick(Sender: TObject);
var
  ItemID: Integer;
begin
  if FItemsQuery.IsEmpty then
  begin
    ShowMessage('No item selected!');
    Exit;
  end;

  if MessageDlg('Delete this item from the sale?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ItemID := FItemsQuery.FieldByName('ItemID').AsInteger;
    DBConnection.ExecSQL('DELETE FROM SaleItems WHERE ItemID = :id', [ItemID]);
    LoadSaleItems;
  end;
end;

procedure TfrmSales.grdItemsCellClick(Column: TColumn);
begin
  // Grid selection handling (if needed)
end;

procedure TfrmSales.cmbProductChange(Sender: TObject);
begin
  // Update product info display (if needed)
end;

// --- FINALIZATION ---

procedure TfrmSales.btnFinalizeClick(Sender: TObject);
var
  SQL: string;
  TotalAmount: Real;
begin
  if FCurrentSaleID <= 0 then
  begin
    ShowMessage('No active sale!');
    Exit;
  end;

  if FItemsQuery.IsEmpty then
  begin
    ShowMessage('Cannot finalize an empty sale! Add at least one product.');
    Exit;
  end;

  if MessageDlg('Finalize this sale? This action cannot be undone.', mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    Exit;

  // Calculate total
  TotalAmount := 0;
  FItemsQuery.First;
  while not FItemsQuery.Eof do
  begin
    TotalAmount := TotalAmount + FItemsQuery.FieldByName('SubTotal').AsFloat;
    FItemsQuery.Next;
  end;

  // Start Transaction for ACID compliance
  DBConnection.StartTransaction;
  try
    // 1. Update Sale Header
    SQL := 'UPDATE Sales SET Status = ''FINALIZED'', TotalAmount = :Total WHERE SaleID = :ID';
    DBConnection.ExecSQL(SQL, [TotalAmount, FCurrentSaleID]);

    // 2. Update Stock Levels (Decrease inventory)
    FItemsQuery.First;
    while not FItemsQuery.Eof do
    begin
      SQL := 'UPDATE Products SET StockLevel = StockLevel - :Qty WHERE ProductID = :ID';
      DBConnection.ExecSQL(SQL, [
        FItemsQuery.FieldByName('Quantity').AsInteger,
        FItemsQuery.FieldByName('ProductID').AsInteger
      ]);
      FItemsQuery.Next;
    end;

    // Commit Transaction
    DBConnection.Commit;

    ShowMessage('Sale finalized successfully!');
    lblStatusValue.Caption := 'FINALIZED';
    UpdateUIState;

  except
    on E: Exception do
    begin
      DBConnection.Rollback;
      ShowMessage('Error finalizing sale: ' + E.Message);
    end;
  end;
end;

procedure TfrmSales.btnCancelClick(Sender: TObject);
var
  SQL: string;
begin
  if FCurrentSaleID <= 0 then
    Exit;

  if MessageDlg('Cancel this sale? All items will be removed.', mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    Exit;

  // Delete all items (CASCADE will handle this, but we can be explicit)
  SQL := 'DELETE FROM SaleItems WHERE SaleID = :ID';
  DBConnection.ExecSQL(SQL, [FCurrentSaleID]);

  // Update sale status
  SQL := 'UPDATE Sales SET Status = ''CANCELLED'' WHERE SaleID = :ID';
  DBConnection.ExecSQL(SQL, [FCurrentSaleID]);

  ShowMessage('Sale cancelled.');
  StartNewSale;
end;

// --- CALCULATION ---

procedure TfrmSales.CalculateTotal;
var
  Total: Real;
begin
  Total := 0;

  if not FItemsQuery.IsEmpty then
  begin
    FItemsQuery.First;
    while not FItemsQuery.Eof do
    begin
      Total := Total + FItemsQuery.FieldByName('SubTotal').AsFloat;
      FItemsQuery.Next;
    end;
  end;

  lblGrandTotalValue.Caption := Format('$%.2f', [Total]);
end;

procedure TfrmSales.ClearInputs;
begin
  edtQuantity.Text := '1';
  if cmbProduct.Items.Count > 0 then
    cmbProduct.ItemIndex := 0;
end;

procedure TfrmSales.UpdateUIState;
var
  IsFinalized: Boolean;
begin
  IsFinalized := lblStatusValue.Caption = 'FINALIZED';

  // Disable controls if sale is finalized
  cmbCustomer.Enabled := not IsFinalized;
  dtpSaleDate.Enabled := not IsFinalized;
  cmbProduct.Enabled := not IsFinalized;
  edtQuantity.Enabled := not IsFinalized;
  btnAddItem.Enabled := not IsFinalized;
  btnDeleteItem.Enabled := not IsFinalized;
  btnFinalize.Enabled := not IsFinalized;
  btnCancel.Enabled := not IsFinalized;
end;

// --- ARCHITECTURE OVERRIDES ---

procedure TfrmSales.ApplyTheme;
begin
  inherited; // Sets Form Color

  if AppTheme = atDark then
  begin
    // Dark Mode
    pnlHeader.Color := $002B1E16;
    pnlMiddle.Color := $002B1E16;
    pnlFooter.Color := $002B1E16;
    pnlAddItem.Color := $002B1E16;

    grdItems.Color := $00382E26; // Slightly lighter than background
    grdItems.Font.Color := clWhite;
    grdItems.TitleFont.Color := clWhite;

    lblCustomer.Font.Color := clSilver;
    lblDate.Font.Color := clSilver;
    lblStatus.Font.Color := clSilver;
    lblProduct.Font.Color := clSilver;
    lblQuantity.Font.Color := clSilver;
    lblGrandTotal.Font.Color := clAqua; // Cyan for emphasis

    lblStatusValue.Font.Color := clYellow;
    lblGrandTotalValue.Font.Color := clAqua;
    lblGrandTotalValue.Font.Size := 16;
    lblGrandTotalValue.Font.Style := [fsBold];

    cmbCustomer.Color := $00382E26;
    cmbCustomer.Font.Color := clWhite;
    cmbProduct.Color := $00382E26;
    cmbProduct.Font.Color := clWhite;
    edtQuantity.Color := $00382E26;
    edtQuantity.Font.Color := clWhite;
  end
  else
  begin
    // Light Mode
    pnlHeader.Color := clWhite;
    pnlMiddle.Color := clWhite;
    pnlFooter.Color := clWhite;
    pnlAddItem.Color := clWhite;

    grdItems.Color := clWhite;
    grdItems.Font.Color := clBlack;
    grdItems.TitleFont.Color := clBlack;

    lblCustomer.Font.Color := clBlack;
    lblDate.Font.Color := clBlack;
    lblStatus.Font.Color := clBlack;
    lblProduct.Font.Color := clBlack;
    lblQuantity.Font.Color := clBlack;
    lblGrandTotal.Font.Color := clNavy; // Dark Blue for emphasis

    lblStatusValue.Font.Color := clGreen;
    lblGrandTotalValue.Font.Color := clNavy;
    lblGrandTotalValue.Font.Size := 16;
    lblGrandTotalValue.Font.Style := [fsBold];

    cmbCustomer.Color := clWhite;
    cmbCustomer.Font.Color := clBlack;
    cmbProduct.Color := clWhite;
    cmbProduct.Font.Color := clBlack;
    edtQuantity.Color := clWhite;
    edtQuantity.Font.Color := clBlack;
  end;
end;

procedure TfrmSales.ApplyLanguage;
begin
  inherited;

  // Simple Switch based on Context
  case AppLanguage of
    alEnglish:
      begin
        Caption := 'Sales Management';
        lblCustomer.Caption := 'Customer:';
        lblDate.Caption := 'Sale Date:';
        lblStatus.Caption := 'Status:';
        lblProduct.Caption := 'Product:';
        lblQuantity.Caption := 'Quantity:';
        lblGrandTotal.Caption := 'Grand Total:';
        btnNewSale.Caption := 'New Sale';
        btnAddItem.Caption := 'Add Item';
        btnDeleteItem.Caption := 'Delete Item';
        btnFinalize.Caption := 'Finalize Sale';
        btnCancel.Caption := 'Cancel Sale';
      end;
    alPortuguese:
      begin
        Caption := 'Gestão de Vendas';
        lblCustomer.Caption := 'Cliente:';
        lblDate.Caption := 'Data da Venda:';
        lblStatus.Caption := 'Status:';
        lblProduct.Caption := 'Produto:';
        lblQuantity.Caption := 'Quantidade:';
        lblGrandTotal.Caption := 'Total Geral:';
        btnNewSale.Caption := 'Nova Venda';
        btnAddItem.Caption := 'Adicionar Item';
        btnDeleteItem.Caption := 'Excluir Item';
        btnFinalize.Caption := 'Finalizar Venda';
        btnCancel.Caption := 'Cancelar Venda';
      end;
    alSpanish:
      begin
        Caption := 'Gestión de Ventas';
        lblCustomer.Caption := 'Cliente:';
        lblDate.Caption := 'Fecha de Venta:';
        lblStatus.Caption := 'Estado:';
        lblProduct.Caption := 'Producto:';
        lblQuantity.Caption := 'Cantidad:';
        lblGrandTotal.Caption := 'Total General:';
        btnNewSale.Caption := 'Nueva Venta';
        btnAddItem.Caption := 'Agregar Artículo';
        btnDeleteItem.Caption := 'Eliminar Artículo';
        btnFinalize.Caption := 'Finalizar Venta';
        btnCancel.Caption := 'Cancelar Venta';
      end;
  end;
end;

end.
