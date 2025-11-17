-----

# Product Definition: Apex ERP - Customer Module (v2.1)

## Part 1: Business Specifications

### 1.1. Overview

The Customer module acts as the single source of truth for client data. To meet industry standards for ERP systems, the record must support legal entity tracking, credit management, and multi-regional address handling.

### 1.2. Standard Data Requirements

A "Customer" in Apex ERP is defined by the following data points:

  * **Identity:** Internal ID, Display Name, Legal/Registered Name, Tax ID (EIN/VAT/CNPJ).
  * **Contact:** Primary Email, Phone, Mobile/Alt Phone, Website.
  * **Location:** Billing Address (Street, City, State/Province, Zip/Postal, Country).
  * **Financials:** Credit Limit (Currency), Payment Terms (Net 30, COD, etc.), Account Status (Active/Hold).
  * **Metadata:** Created Date, Last Modified Date, Internal Notes.

### 1.3. UI/UX Requirements

  * **View Mode:** A searchable grid displaying high-level info (Name, City, Phone, Status).
  * **Edit Mode:** A tabbed interface (General | Address | Financials) to prevent scrolling fatigue.
  * **Theming:** Must fully support the `atDark` (Navy/Dark Grey) and `atLight` modes defined in `uBaseForm`.

-----

## Part 2: Technical Implementation

### 2.1. Database Schema Update (`uDataModule.pas`)

We must update the `CheckAndCreateSchema` procedure in `uDataModule` to include the `Customers` table. This ensures the table is auto-generated on startup.

**Action:** Append the following SQL execution to `TdmCore.CheckAndCreateSchema`:

```delphi
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
```

### 2.2. The Customer Form (`uFormCustomers.pas`)

[cite\_start]This form inherits from `TfrmBase`[cite: 7]. It creates its own `TFDQuery` instance using the injected connection from the `Create` constructor.

**Design Pattern:**

1.  **Constructor:** Receives Connection, Theme, Language.
2.  **OnCreate:** Configures the internal `FDQuery` and `DataSource`.
3.  **CRUD Logic:** Methods `btnSaveClick`, `btnDeleteClick`, `btnNewClick`.

#### Source Code Specification

```delphi
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
    pnlControls: TPanel;
    pcDetails: TPageControl;
    tsGeneral: TTabSheet;
    tsAddress: TTabSheet;
    tsFinancial: TTabSheet;
    gridCustomers: TDBGrid;
    splitterGrid: TSplitter;
    
    // CRUD Controls
    pnlActions: TPanel;
    btnNew: TButton;
    btnSave: TButton;
    btnDelete: TButton;
    
    // Data Components (Owned by this form)
    qryCustomers: TFDQuery;
    dsCustomers: TDataSource;
    
    // General Fields
    lblCustName: TLabel;
    edtCustName: TDBEdit;
    lblTaxID: TLabel;
    edtTaxID: TDBEdit;
    chkActive: TDBCheckBox;
    
    // Address Fields
    lblAddress: TLabel;
    memAddress: TDBMemo;
    
    procedure FormCreate(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
  protected
    procedure ApplyTheme; override;
    procedure ApplyLanguage; override;
  private
    procedure SetupQuery;
  public
    // No new constructor needed, we use the inherited Reintroduce one
  end;

implementation

{$R *.dfm}

procedure TfrmCustomers.FormCreate(Sender: TObject);
begin
  // Note: Connection, Theme, and Lang are already set by TfrmBase constructor
  SetupQuery;
end;

procedure TfrmCustomers.SetupQuery;
begin
  qryCustomers.Connection := DBConnection; [cite_start]// Uses FConnection from TfrmBase [cite: 7]
  qryCustomers.SQL.Text := 'SELECT * FROM Customers ORDER BY CustomerName';
  dsCustomers.DataSet := qryCustomers;
  gridCustomers.DataSource := dsCustomers;
  
  qryCustomers.Open;
end;

procedure TfrmCustomers.btnNewClick(Sender: TObject);
begin
  qryCustomers.Insert;
  edtCustName.SetFocus;
end;

procedure TfrmCustomers.btnSaveClick(Sender: TObject);
begin
  if qryCustomers.State in [dsEdit, dsInsert] then
    qryCustomers.Post;
end;

procedure TfrmCustomers.btnDeleteClick(Sender: TObject);
begin
  if not qryCustomers.IsEmpty then
    if MessageDlg('Delete this customer?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      qryCustomers.Delete;
end;

// --- THEMING IMPLEMENTATION ---
procedure TfrmCustomers.ApplyTheme;
begin
  inherited; [cite_start]// Sets the form background color [cite: 7]

  if AppTheme = atDark then
  begin
    // Panels
    pnlControls.Color := $00151C28; // Dark Navy
    pnlActions.Color := $00151C28;
    
    // Grid Customization for Dark Mode
    gridCustomers.Color := $002B1E16;
    gridCustomers.Font.Color := clWhite;
    gridCustomers.TitleFont.Color := clWhite;
    
    // Labels
    lblCustName.Font.Color := clSilver;
    lblTaxID.Font.Color := clSilver;
    lblAddress.Font.Color := clSilver;
  end
  else
  begin
    // Light Mode
    pnlControls.Color := clWhite;
    pnlActions.Color := $00F4F6F8;
    
    gridCustomers.Color := clWhite;
    gridCustomers.Font.Color := clBlack;
    
    lblCustName.Font.Color := clBlack;
    lblTaxID.Font.Color := clBlack;
    lblAddress.Font.Color := clBlack;
  end;
end;

// --- LOCALIZATION IMPLEMENTATION ---
procedure TfrmCustomers.ApplyLanguage;
begin
  inherited;
  
  if AppLanguage = alPortuguese then
  begin
    Caption := 'Gerenciar Clientes';
    tsGeneral.Caption := 'Geral';
    tsAddress.Caption := 'Endereço';
    tsFinancial.Caption := 'Financeiro';
    btnNew.Caption := 'Novo';
    btnSave.Caption := 'Salvar';
    lblCustName.Caption := 'Nome do Cliente';
  end
  else if AppLanguage = alSpanish then
  begin
    Caption := 'Gestión de Clientes';
    tsGeneral.Caption := 'General';
    // ... implementations
  end
  else
  begin
    Caption := 'Customer Management';
    tsGeneral.Caption := 'General';
    tsAddress.Caption := 'Address';
    tsFinancial.Caption := 'Financial';
    btnNew.Caption := 'New';
    btnSave.Caption := 'Save';
    lblCustName.Caption := 'Customer Name';
  end;
end;

end.
```

## Part 3: Integration Logic

To integrate this into the system, update `Form.Main.pas` to include the new button and call.

**1. Update Uses Clause:**
Add `uFormCustomers` to the interface uses clause.

**2. Add Sidebar Button:**
Add `btnCustomers` to the sidebar panel in `Form.Main.dfm`.

**3. Event Handler:**

```delphi
procedure TfrmMain.btnCustomersClick(Sender: TObject);
begin
  // Injects the Connection, Theme, and Language automatically via TBaseForm logic
  OpenChildForm(TfrmCustomers); 
end;
```

## Part 4: Validation Rules (Business Logic)

When implementing the `BeforePost` event on the `qryCustomers` dataset, strict validations must be applied:

1.  **Mandatory Name:** `CustomerName` cannot be empty.
2.  **Unique Tax ID:** If `TaxID` is provided, check via SQL query if it already exists for a different ID.
3.  **Credit Limit:** Must be \>= 0. Negative credit limits are invalid.