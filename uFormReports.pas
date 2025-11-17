unit uFormReports;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBaseForm, Data.DB, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.Grids, Vcl.DBGrids,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  // REQUIRED FOR EXPORT
  FireDAC.Stan.StorageJSON, FireDAC.Stan.StorageCSV, FireDAC.Stan.StorageBin;

type
  TfrmReports = class(TfrmBase)
    pnlSidebar: TPanel;
    pnlTop: TPanel;
    grdReport: TDBGrid;
    btnRepCustomer: TButton;
    btnRepProduct: TButton;
    btnRepMonth: TButton;
    dsReport: TDataSource;
    grpFilters: TGroupBox;
    edtFilterText: TEdit;
    lblFilter: TLabel;
    btnExportCSV: TButton;
    btnExportJSON: TButton;

    procedure FormCreate(Sender: TObject);
    procedure btnRepCustomerClick(Sender: TObject);
    procedure btnRepProductClick(Sender: TObject);
    procedure btnRepMonthClick(Sender: TObject);
    procedure edtFilterTextChange(Sender: TObject);
    procedure btnExportCSVClick(Sender: TObject);
    procedure btnExportJSONClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    qryReport: TFDQuery;
    // Storage Links (created dynamically in code)
    fdJSONLink: TFDStanStorageJSONLink;
    fdCSVLink: TFDStanStorageCSVLink;
    FCurrentReportType: Integer; // 1=Customer, 2=Product, 3=Month
    procedure ExecuteReport(const ASQL: string);
  protected
    procedure ApplyTheme; override;
    procedure ApplyLanguage; override;
  public
    constructor Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage); override;
  end;

implementation

{$R *.dfm}

constructor TfrmReports.Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage);
begin
  inherited Create(AOwner, AConn, ATheme, ALang);

  // Setup Internal Query
  qryReport := TFDQuery.Create(Self);
  qryReport.Connection := DBConnection;
  dsReport.DataSet := qryReport;
end;

procedure TfrmReports.FormCreate(Sender: TObject);
begin
  // Initialize storage links if creating dynamically
  fdJSONLink := TFDStanStorageJSONLink.Create(Self);
  fdCSVLink := TFDStanStorageCSVLink.Create(Self);
end;

procedure TfrmReports.FormDestroy(Sender: TObject);
begin
  if Assigned(qryReport) then qryReport.Free;
end;

// --- REPORT EXECUTION LOGIC ---

procedure TfrmReports.ExecuteReport(const ASQL: string);
begin
  qryReport.Close;
  qryReport.SQL.Text := ASQL;
  try
    qryReport.Open;
  except
    on E: Exception do
      ShowMessage('Error running report: ' + E.Message);
  end;
end;

procedure TfrmReports.btnRepCustomerClick(Sender: TObject);
begin
  FCurrentReportType := 1;
  ExecuteReport(
    'SELECT c.CustomerName, COUNT(s.SaleID) as OrderCount, SUM(s.TotalAmount) as TotalSpent ' +
    'FROM Sales s JOIN Customers c ON s.CustomerID = c.CustomerID ' +
    'WHERE s.Status = ''FINALIZED'' ' +
    'GROUP BY c.CustomerName ORDER BY TotalSpent DESC'
  );
end;

procedure TfrmReports.btnRepProductClick(Sender: TObject);
begin
  FCurrentReportType := 2;
  ExecuteReport(
    'SELECT p.Name as ProductName, p.SKU, SUM(i.Quantity) as UnitsSold, SUM(i.SubTotal) as TotalRevenue ' +
    'FROM SaleItems i JOIN Products p ON i.ProductID = p.ProductID ' +
    'JOIN Sales s ON i.SaleID = s.SaleID ' +
    'WHERE s.Status = ''FINALIZED'' ' +
    'GROUP BY p.Name, p.SKU ORDER BY TotalRevenue DESC'
  );
end;

procedure TfrmReports.btnRepMonthClick(Sender: TObject);
begin
  FCurrentReportType := 3;
  // SQLite syntax for Month extraction
  ExecuteReport(
    'SELECT strftime(''%Y-%m'', SaleDate) as SalesMonth, COUNT(SaleID) as Orders, SUM(TotalAmount) as Revenue ' +
    'FROM Sales ' +
    'WHERE Status = ''FINALIZED'' ' +
    'GROUP BY SalesMonth ORDER BY SalesMonth DESC'
  );
end;

// --- IN-MEMORY FILTERING ---

procedure TfrmReports.edtFilterTextChange(Sender: TObject);
var
  FilterField: string;
begin
  if not qryReport.Active then Exit;

  if Trim(edtFilterText.Text) = '' then
  begin
    qryReport.Filtered := False;
    Exit;
  end;

  // Determine which field to filter based on current report
  case FCurrentReportType of
    1: FilterField := 'CustomerName';
    2: FilterField := 'ProductName';
    3: FilterField := 'SalesMonth';
  else
    Exit;
  end;

  // Apply FireDAC In-Memory Filter
  qryReport.Filter := Format('%s LIKE ''%%%s%%''', [FilterField, edtFilterText.Text]);
  qryReport.Filtered := True;
end;

// --- EXPORT LOGIC ---

procedure TfrmReports.btnExportCSVClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  if not qryReport.Active then Exit;

  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Filter := 'CSV File|*.csv';
    SaveDlg.DefaultExt := 'csv';
    if SaveDlg.Execute then
    begin
      // FireDAC built-in export
      qryReport.SaveToFile(SaveDlg.FileName, sfCSV);
      ShowMessage('Exported to CSV successfully.');
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmReports.btnExportJSONClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  if not qryReport.Active then Exit;

  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Filter := 'JSON File|*.json';
    SaveDlg.DefaultExt := 'json';
    if SaveDlg.Execute then
    begin
      // FireDAC built-in export
      qryReport.SaveToFile(SaveDlg.FileName, sfJSON);
      ShowMessage('Exported to JSON successfully.');
    end;
  finally
    SaveDlg.Free;
  end;
end;

// --- THEME & LANGUAGE ---

procedure TfrmReports.ApplyTheme;
begin
  inherited;
  if AppTheme = atDark then
  begin
    pnlSidebar.Color := $00151C28;
    pnlTop.Color := $002B1E16;
    grdReport.Color := $00382E26;
    grdReport.Font.Color := clWhite;
    grdReport.TitleFont.Color := clWhite;
    edtFilterText.Color := $00382E26;
    edtFilterText.Font.Color := clWhite;
  end
  else
  begin
    pnlSidebar.Color := $00F4F6F8;
    pnlTop.Color := clWhite;
    grdReport.Color := clWhite;
    grdReport.Font.Color := clBlack;
    grdReport.TitleFont.Color := clBlack;
    edtFilterText.Color := clWhite;
    edtFilterText.Font.Color := clBlack;
  end;
end;

procedure TfrmReports.ApplyLanguage;
begin
  inherited;
  case AppLanguage of
    alEnglish:
      begin
        Caption := 'Business Intelligence';
        btnRepCustomer.Caption := 'Sales by Customer';
        btnRepProduct.Caption := 'Sales by Product';
        btnRepMonth.Caption := 'Sales by Month';
        lblFilter.Caption := 'Filter Results:';
        btnExportCSV.Caption := 'Export CSV';
        btnExportJSON.Caption := 'Export JSON';
      end;
    alPortuguese:
      begin
        Caption := 'Inteligência de Negócios';
        btnRepCustomer.Caption := 'Vendas por Cliente';
        btnRepProduct.Caption := 'Vendas por Produto';
        btnRepMonth.Caption := 'Vendas por Mês';
        lblFilter.Caption := 'Filtrar Resultados:';
        btnExportCSV.Caption := 'Exportar CSV';
        btnExportJSON.Caption := 'Exportar JSON';
      end;
    alSpanish:
      begin
        Caption := 'Inteligencia de Negocios';
        btnRepCustomer.Caption := 'Ventas por Cliente';
        btnRepProduct.Caption := 'Ventas por Producto';
        btnRepMonth.Caption := 'Ventas por Mes';
        lblFilter.Caption := 'Filtrar Resultados:';
        btnExportCSV.Caption := 'Exportar CSV';
        btnExportJSON.Caption := 'Exportar JSON';
      end;
  end;
end;

end.
