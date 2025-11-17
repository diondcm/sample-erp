unit uDataModule;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.VCLUI.Wait,
  FireDAC.Comp.Client, FireDAC.Comp.UI, Data.DB;

type
  TdmCore = class(TDataModule)
    fdConnection: TFDConnection;
    fdPhysSQLite: TFDPhysSQLiteDriverLink;
    fdGUIxWaitCursor: TFDGUIxWaitCursor;
    procedure DataModuleCreate(Sender: TObject);
  private
    procedure CheckAndCreateSchema;
  public
    function GetConnection: TFDConnection;
  end;

var
  dmCore: TdmCore;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmCore.DataModuleCreate(Sender: TObject);
begin
  // Configure for local SQLite
  fdConnection.DriverName := 'SQLite';
  // Ideally, path should be relative to AppData or Exe
  fdConnection.Params.Values['Database'] := ExtractFilePath(ParamStr(0)) + 'ApexData.db';
  fdConnection.Params.Values['OpenMode'] := 'CreateUTF8';

  try
    fdConnection.Connected := True;
    CheckAndCreateSchema;
  except
    on E: Exception do
      // Log error here in a real app
      raise Exception.Create('Critical DB Error: ' + E.Message);
  end;
end;

procedure TdmCore.CheckAndCreateSchema;
begin
  // Simple DDL execution to ensure tables exist
  fdConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS AppSettings (' +
    '  SettingKey TEXT PRIMARY KEY, ' +
    '  SettingValue TEXT ' +
    ');'
  );

  fdConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS AuditLogs (' +
    '  LogID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    '  LogDate DATETIME, ' +
    '  Message TEXT ' +
    ');'
  );

  // --- NEW: Products Table (Electronics Spec) ---
  fdConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS Products (' +
    '  ProductID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    '  SKU TEXT UNIQUE NOT NULL, ' +
    '  Name TEXT NOT NULL, ' +
    '  Category TEXT, ' +
    '  MSRP REAL, ' +
    '  StockLevel INTEGER DEFAULT 0, ' +
    '  FCC_ID TEXT, ' +
    '  WarrantyMonths INTEGER ' +
    ');'
  );

  // --- NEW: Product Images (Limit managed by App Logic) ---
  fdConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS ProductImages (' +
    '  ImageID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    '  ProductID INTEGER NOT NULL, ' +
    '  ImageData BLOB, ' +
    '  CONSTRAINT fk_products FOREIGN KEY (ProductID) REFERENCES Products (ProductID) ON DELETE CASCADE ' +
    ');'
  );

  // --- NEW: Customers Table (Industry Standard) ---
  fdConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS Customers (' +
    '  CustomerID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    '  CustomerName TEXT NOT NULL, ' +    // Display Name
    '  LegalName TEXT, ' +                // For Invoicing
    '  TaxID TEXT, ' +                    // VAT / EIN / CNPJ
    '  Email TEXT, ' +
    '  Phone TEXT, ' +
    '  Website TEXT, ' +
    '  BillingAddress TEXT, ' +
    '  BillingCity TEXT, ' +
    '  BillingState TEXT, ' +
    '  BillingZip TEXT, ' +
    '  BillingCountry TEXT, ' +
    '  CreditLimit REAL DEFAULT 0, ' +
    '  IsActive INTEGER DEFAULT 1, ' +    // 0 = Hold, 1 = Active
    '  Notes TEXT, ' +
    '  CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ' +
    ');'
  );

  // Optimization: Index on Name for fast searching
  fdConnection.ExecSQL(
    'CREATE INDEX IF NOT EXISTS idx_CustName ON Customers (CustomerName);'
  );
end;

function TdmCore.GetConnection: TFDConnection;
begin
  Result := fdConnection;
end;

end.
