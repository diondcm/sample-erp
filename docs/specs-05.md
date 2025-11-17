Based on the existing architecture defined in `uBaseForm` and `uDataModule` , here is the Product Specification for the new Reporting Module.



-----



\# Product Specification: Analytical Reporting Module (v1.0)



\## 1\\. Overview



The \*\*Reports Screen\*\* is a specialized view designed to provide high-level insights into the business data. Unlike the CRUD screens (Products/Customers), this screen is \*\*read-only\*\* and focuses on aggregation, in-memory filtering, and data extraction.



It must strictly adhere to the \*\*Apex ERP Architecture\*\*:



&nbsp; \* Inherit from `TfrmBase`.

&nbsp; \* Receive Connection, Theme, and Language via injection.

&nbsp; \* Use FireDAC's native capabilities for filtering and exporting.



-----



\## 2\\. Database Schema Expansion (Prerequisite)



To generate "Sales" reports, we must expand the `uDataModule` to include transaction history. The \*\*Code-First\*\* routine in `uDataModule` must be updated to include these tables if they do not exist.



\*\*New Tables:\*\*



1\.  \*\*`Orders`\*\*: Tracks the header (Date, Customer, Total).

2\.  \*\*`OrderItems`\*\*: Tracks the lines (Product, Quantity, Price).



\*\*SQL Definition (SQLite):\*\*



```sql

CREATE TABLE IF NOT EXISTS Orders (

&nbsp; OrderID INTEGER PRIMARY KEY AUTOINCREMENT,

&nbsp; CustomerID INTEGER,

&nbsp; OrderDate DATETIME DEFAULT CURRENT\_TIMESTAMP,

&nbsp; TotalAmount REAL,

&nbsp; FOREIGN KEY(CustomerID) REFERENCES Customers(CustomerID)

);



CREATE TABLE IF NOT EXISTS OrderItems (

&nbsp; OrderItemID INTEGER PRIMARY KEY AUTOINCREMENT,

&nbsp; OrderID INTEGER,

&nbsp; ProductID INTEGER,

&nbsp; Quantity INTEGER,

&nbsp; UnitPrice REAL,

&nbsp; SubTotal REAL,

&nbsp; FOREIGN KEY(OrderID) REFERENCES Orders(OrderID),

&nbsp; FOREIGN KEY(ProductID) REFERENCES Products(ProductID)

);

```



-----



\## 3\\. User Interface Specification



\### 3.1. Layout Structure



The form will consist of three distinct distinct panels:



1\.  \*\*Sidebar / Control Panel (Left or Top):\*\* Contains the "Report Selector" buttons.

2\.  \*\*Filter Ribbon (Top):\*\* Contains "In-Memory" filters (Date Range, Text Search) and "Export" buttons.

3\.  \*\*Data Grid (Center):\*\* A `TDBGrid` displaying the results.



\### 3.2. Report Selectors (Buttons)



Three buttons that, when clicked, close the current query, inject new SQL, and open the dataset.



1\.  \*\*Btn: Sales per Customer\*\*



&nbsp;     \* \*\*Logic:\*\* Aggregates total spend by Customer.

&nbsp;     \* \*\*SQL:\*\*

&nbsp;       ```sql

&nbsp;       SELECT c.CustomerName, COUNT(o.OrderID) as OrderCount, SUM(o.TotalAmount) as TotalSpent

&nbsp;       FROM Orders o

&nbsp;       JOIN Customers c ON o.CustomerID = c.CustomerID

&nbsp;       GROUP BY c.CustomerName

&nbsp;       ORDER BY TotalSpent DESC

&nbsp;       ```



2\.  \*\*Btn: Sales per Product\*\*



&nbsp;     \* \*\*Logic:\*\* Aggregates total quantity and revenue by Product.

&nbsp;     \* \*\*SQL:\*\*

&nbsp;       ```sql

&nbsp;       SELECT p.Name as ProductName, p.SKU, SUM(i.Quantity) as UnitsSold, SUM(i.SubTotal) as TotalRevenue

&nbsp;       FROM OrderItems i

&nbsp;       JOIN Products p ON i.ProductID = p.ProductID

&nbsp;       GROUP BY p.Name

&nbsp;       ORDER BY TotalRevenue DESC

&nbsp;       ```



3\.  \*\*Btn: Sales per Month\*\*



&nbsp;     \* \*\*Logic:\*\* Time-series grouping.

&nbsp;     \* \*\*SQL (SQLite Syntax):\*\*

&nbsp;       ```sql

&nbsp;       SELECT strftime('%Y-%m', OrderDate) as SalesMonth, COUNT(OrderID) as Orders, SUM(TotalAmount) as Revenue

&nbsp;       FROM Orders

&nbsp;       GROUP BY SalesMonth

&nbsp;       ORDER BY SalesMonth DESC

&nbsp;       ```



\### 3.3. In-Memory Filters (The "Filter" Requirement)



These controls \*\*do not\*\* change the SQL. They apply a filter to the `TFDQuery` which is already in memory (using `LocalSQL` or standard `Filter` property).



&nbsp; \* \*\*Date Range (From/To):\*\* Filters the dataset records based on the implied date field of the report.

&nbsp; \* \*\*Text Filter:\*\* A `TEdit`. On `Change`, applies a `LIKE` filter to the primary text column (Customer Name, Product Name, or Month).



\### 3.4. Export Functionality



Two buttons using FireDAC's native `SaveToFile` capability.



&nbsp; \* \*\*Export CSV:\*\* Saves grid data to Comma Separated Values.

&nbsp; \* \*\*Export JSON:\*\* Saves grid data to JSON format.



-----



\## 4\\. Technical Implementation Guide



\### 4.1. Required Components



&nbsp; \* \*\*`TFDQuery`\*\*: Named `qryReport`.

&nbsp; \* \*\*`TFDStanStorageBinLink`\*\*: Required for saving generic data.

&nbsp; \* \*\*`TFDStanStorageJSONLink`\*\*: Required for `.SaveToFile(..., sfJSON)`.

&nbsp; \* \*\*`TFDStanStorageCSVLink`\*\*: Required for `.SaveToFile(..., sfCSV)`.



\### 4.2. Delphi Unit: `uFormReports`



```delphi

unit uFormReports;



interface



uses

&nbsp; Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,

&nbsp; Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBaseForm, Data.DB, FireDAC.Stan.Intf,

&nbsp; FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,

&nbsp; FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,

&nbsp; FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.Grids, Vcl.DBGrids,

&nbsp; Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,

&nbsp; // REQUIRED FOR EXPORT

&nbsp; FireDAC.Stan.StorageJSON, FireDAC.Stan.StorageCSV, FireDAC.Stan.StorageBin;



type

&nbsp; TfrmReports = class(TfrmBase)

&nbsp;   pnlSidebar: TPanel;

&nbsp;   pnlTop: TPanel;

&nbsp;   grdReport: TDBGrid;

&nbsp;   btnRepCustomer: TButton;

&nbsp;   btnRepProduct: TButton;

&nbsp;   btnRepMonth: TButton;

&nbsp;   dsReport: TDataSource;

&nbsp;   grpFilters: TGroupBox;

&nbsp;   edtFilterText: TEdit;

&nbsp;   lblFilter: TLabel;

&nbsp;   btnExportCSV: TButton;

&nbsp;   btnExportJSON: TButton;

&nbsp;   

&nbsp;   // Storage Links (Non-Visual in code or dropped on form)

&nbsp;   fdJSONLink: TFDStanStorageJSONLink;

&nbsp;   fdCSVLink: TFDStanStorageCSVLink;



&nbsp;   procedure FormCreate(Sender: TObject);

&nbsp;   procedure btnRepCustomerClick(Sender: TObject);

&nbsp;   procedure btnRepProductClick(Sender: TObject);

&nbsp;   procedure btnRepMonthClick(Sender: TObject);

&nbsp;   procedure edtFilterTextChange(Sender: TObject);

&nbsp;   procedure btnExportCSVClick(Sender: TObject);

&nbsp;   procedure btnExportJSONClick(Sender: TObject);

&nbsp;   procedure FormDestroy(Sender: TObject);

&nbsp; private

&nbsp;   qryReport: TFDQuery;

&nbsp;   FCurrentReportType: Integer; // 1=Cust, 2=Prod, 3=Month

&nbsp;   procedure ExecuteReport(const ASQL: string);

&nbsp; protected

&nbsp;   procedure ApplyTheme; override;

&nbsp;   procedure ApplyLanguage; override;

&nbsp; public

&nbsp;   constructor Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage); override;

&nbsp; end;



implementation



{$R \*.dfm}



constructor TfrmReports.Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage);

begin

&nbsp; inherited Create(AOwner, AConn, ATheme, ALang);

&nbsp; 

&nbsp; // Setup Internal Query

&nbsp; qryReport := TFDQuery.Create(Self);

&nbsp; qryReport.Connection := DBConnection;

&nbsp; dsReport.DataSet := qryReport;

end;



procedure TfrmReports.FormCreate(Sender: TObject);

begin

&nbsp; // Initialize storage links if creating dynamically

&nbsp; fdJSONLink := TFDStanStorageJSONLink.Create(Self);

&nbsp; fdCSVLink := TFDStanStorageCSVLink.Create(Self);

end;



procedure TfrmReports.FormDestroy(Sender: TObject);

begin

&nbsp; if Assigned(qryReport) then qryReport.Free;

end;



// --- REPORT EXECUTION LOGIC ---



procedure TfrmReports.ExecuteReport(const ASQL: string);

begin

&nbsp; qryReport.Close;

&nbsp; qryReport.SQL.Text := ASQL;

&nbsp; try

&nbsp;   qryReport.Open;

&nbsp; except

&nbsp;   on E: Exception do

&nbsp;     ShowMessage('Error running report: ' + E.Message);

&nbsp; end;

end;



procedure TfrmReports.btnRepCustomerClick(Sender: TObject);

begin

&nbsp; FCurrentReportType := 1;

&nbsp; ExecuteReport(

&nbsp;   'SELECT c.CustomerName, COUNT(o.OrderID) as OrderCount, SUM(o.TotalAmount) as TotalSpent ' +

&nbsp;   'FROM Orders o JOIN Customers c ON o.CustomerID = c.CustomerID ' +

&nbsp;   'GROUP BY c.CustomerName ORDER BY TotalSpent DESC'

&nbsp; );

end;



procedure TfrmReports.btnRepProductClick(Sender: TObject);

begin

&nbsp; FCurrentReportType := 2;

&nbsp; ExecuteReport(

&nbsp;   'SELECT p.Name as ProductName, p.SKU, SUM(i.Quantity) as UnitsSold, SUM(i.SubTotal) as TotalRevenue ' +

&nbsp;   'FROM OrderItems i JOIN Products p ON i.ProductID = p.ProductID ' +

&nbsp;   'GROUP BY p.Name ORDER BY TotalRevenue DESC'

&nbsp; );

end;



procedure TfrmReports.btnRepMonthClick(Sender: TObject);

begin

&nbsp; FCurrentReportType := 3;

&nbsp; // SQLite syntax for Month extraction

&nbsp; ExecuteReport(

&nbsp;   'SELECT strftime(''%Y-%m'', OrderDate) as SalesMonth, COUNT(OrderID) as Orders, SUM(TotalAmount) as Revenue ' +

&nbsp;   'FROM Orders GROUP BY SalesMonth ORDER BY SalesMonth DESC'

&nbsp; );

end;



// --- IN-MEMORY FILTERING ---



procedure TfrmReports.edtFilterTextChange(Sender: TObject);

var

&nbsp; FilterField: string;

begin

&nbsp; if not qryReport.Active then Exit;



&nbsp; if Trim(edtFilterText.Text) = '' then

&nbsp; begin

&nbsp;   qryReport.Filtered := False;

&nbsp;   Exit;

&nbsp; end;



&nbsp; // Determine which field to filter based on current report

&nbsp; case FCurrentReportType of

&nbsp;   1: FilterField := 'CustomerName';

&nbsp;   2: FilterField := 'ProductName';

&nbsp;   3: FilterField := 'SalesMonth';

&nbsp; else

&nbsp;   Exit;

&nbsp; end;



&nbsp; // Apply FireDAC In-Memory Filter

&nbsp; qryReport.Filter := Format('%s LIKE ''%%%s%%''', \[FilterField, edtFilterText.Text]);

&nbsp; qryReport.Filtered := True;

end;



// --- EXPORT LOGIC ---



procedure TfrmReports.btnExportCSVClick(Sender: TObject);

var

&nbsp; SaveDlg: TSaveDialog;

begin

&nbsp; if not qryReport.Active then Exit;



&nbsp; SaveDlg := TSaveDialog.Create(nil);

&nbsp; try

&nbsp;   SaveDlg.Filter := 'CSV File|\*.csv';

&nbsp;   SaveDlg.DefaultExt := 'csv';

&nbsp;   if SaveDlg.Execute then

&nbsp;   begin

&nbsp;     // FireDAC built-in export

&nbsp;     qryReport.SaveToFile(SaveDlg.FileName, sfCSV);

&nbsp;     ShowMessage('Exported to CSV successfully.');

&nbsp;   end;

&nbsp; finally

&nbsp;   SaveDlg.Free;

&nbsp; end;

end;



procedure TfrmReports.btnExportJSONClick(Sender: TObject);

var

&nbsp; SaveDlg: TSaveDialog;

begin

&nbsp; if not qryReport.Active then Exit;



&nbsp; SaveDlg := TSaveDialog.Create(nil);

&nbsp; try

&nbsp;   SaveDlg.Filter := 'JSON File|\*.json';

&nbsp;   SaveDlg.DefaultExt := 'json';

&nbsp;   if SaveDlg.Execute then

&nbsp;   begin

&nbsp;     // FireDAC built-in export

&nbsp;     qryReport.SaveToFile(SaveDlg.FileName, sfJSON);

&nbsp;     ShowMessage('Exported to JSON successfully.');

&nbsp;   end;

&nbsp; finally

&nbsp;   SaveDlg.Free;

&nbsp; end;

end;



// --- THEME \& LANGUAGE ---



procedure TfrmReports.ApplyTheme;

begin

&nbsp; inherited;

&nbsp; if AppTheme = atDark then

&nbsp; begin

&nbsp;   pnlSidebar.Color := $00151C28;

&nbsp;   pnlTop.Color := $002B1E16;

&nbsp;   grdReport.Color := $00382E26;

&nbsp;   grdReport.Font.Color := clWhite;

&nbsp;   grdReport.TitleFont.Color := clWhite;

&nbsp;   edtFilterText.Color := $00382E26;

&nbsp;   edtFilterText.Font.Color := clWhite;

&nbsp; end

&nbsp; else

&nbsp; begin

&nbsp;   pnlSidebar.Color := $00F4F6F8;

&nbsp;   pnlTop.Color := clWhite;

&nbsp;   grdReport.Color := clWhite;

&nbsp;   grdReport.Font.Color := clBlack;

&nbsp;   grdReport.TitleFont.Color := clBlack;

&nbsp;   edtFilterText.Color := clWhite;

&nbsp;   edtFilterText.Font.Color := clBlack;

&nbsp; end;

end;



procedure TfrmReports.ApplyLanguage;

begin

&nbsp; inherited;

&nbsp; case AppLanguage of

&nbsp;   alEnglish:

&nbsp;     begin

&nbsp;       Caption := 'Business Intelligence';

&nbsp;       btnRepCustomer.Caption := 'Sales by Customer';

&nbsp;       btnRepProduct.Caption := 'Sales by Product';

&nbsp;       btnRepMonth.Caption := 'Sales by Month';

&nbsp;       lblFilter.Caption := 'Filter Results:';

&nbsp;       btnExportCSV.Caption := 'Export CSV';

&nbsp;       btnExportJSON.Caption := 'Export JSON';

&nbsp;     end;

&nbsp;   alPortuguese:

&nbsp;     begin

&nbsp;       Caption := 'Inteligência de Negócios';

&nbsp;       btnRepCustomer.Caption := 'Vendas por Cliente';

&nbsp;       btnRepProduct.Caption := 'Vendas por Produto';

&nbsp;       btnRepMonth.Caption := 'Vendas por Mês';

&nbsp;       lblFilter.Caption := 'Filtrar Resultados:';

&nbsp;       btnExportCSV.Caption := 'Exportar CSV';

&nbsp;       btnExportJSON.Caption := 'Exportar JSON';

&nbsp;     end;

&nbsp;   // Spanish...

&nbsp; end;

end;



end.

```

