# Product Definition: Sales Management Module

## Part 1: Database Schema Strategy (Self-Healing)

We need to extend the `CheckAndCreateSchema` procedure in `uDataModule` to include three new entities.

### 1.1. Entity Relationships

  * **Customers:** The entity purchasing the goods.
  * **Sales (Header):** The high-level transaction record (Date, Customer, Total).
  * **SaleItems (Detail):** The specific electronics products sold in that transaction. **Crucial:** We must snapshot the `UnitPrice` at the moment of sale to ensure historical accuracy if product MSRP changes later.

### 1.2. DDL Requirements

The following SQL must be added to the `uDataModule.pas` schema generation logic:

```sql
-- 1. Customers Table
CREATE TABLE IF NOT EXISTS Customers (
  CustomerID INTEGER PRIMARY KEY AUTOINCREMENT,
  FullName TEXT NOT NULL,
  TaxID TEXT, -- CPF/CNPJ or SSN
  Email TEXT,
  Phone TEXT,
  Address TEXT
);

-- 2. Sales Header
CREATE TABLE IF NOT EXISTS Sales (
  SaleID INTEGER PRIMARY KEY AUTOINCREMENT,
  CustomerID INTEGER NOT NULL,
  SaleDate DATETIME DEFAULT CURRENT_TIMESTAMP,
  Status TEXT DEFAULT 'DRAFT', -- DRAFT, FINALIZED, CANCELLED
  TotalAmount REAL DEFAULT 0,
  CONSTRAINT fk_sales_customer FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID)
);

-- 3. Sales Items (The "Shopping Cart")
CREATE TABLE IF NOT EXISTS SaleItems (
  ItemID INTEGER PRIMARY KEY AUTOINCREMENT,
  SaleID INTEGER NOT NULL,
  ProductID INTEGER NOT NULL,
  Quantity INTEGER DEFAULT 1,
  UnitPrice REAL NOT NULL, -- Snapshotted price at time of sale
  SubTotal REAL GENERATED ALWAYS AS (Quantity * UnitPrice) VIRTUAL,
  CONSTRAINT fk_items_sale FOREIGN KEY (SaleID) REFERENCES Sales (SaleID) ON DELETE CASCADE,
  CONSTRAINT fk_items_product FOREIGN KEY (ProductID) REFERENCES Products (ProductID)
);
```

-----

## Part 2: UI/UX Specifications (The Order Screen)

The Sales Screen (`TfrmSales`) acts as a Master-Detail transactional view. [cite\_start]It must inherit from `TfrmBase` to accept Context Injection[cite: 12].

### 2.1. Visual Layout

  * **Top Panel (Header):**
      * **Customer Selector:** A ComboBox or Search Edit to link the `CustomerID`.
      * **Date Picker:** Defaults to `Now`.
      * **Status Indicator:** Label showing "Draft" or "Finalized".
  * **Middle Panel (The Grid):**
      * A `TDBGrid` or `TStringGrid` displaying `SaleItems`.
      * **Columns:** Product Name, SKU, Warranty (Months), Quantity, Unit Price, Line Total.
      * **Input Method:** A row of Edit controls above the grid to add items: `[Product Search] [Qty] [Add Button]`.
  * **Bottom Panel (Footer):**
      * **Grand Total:** Large, bold label updating in real-time.
      * **Action Buttons:** "Finalize Sale", "Cancel", "Print Invoice".

### 2.2. Theming Rules (Dynamic)

[cite\_start]Per `specs-01.md`[cite: 12], the form must override `ApplyTheme`:

  * **Light Mode:** Grid background `clWhite`, Header Panel `clBtnFace`. Total Label: Dark Blue.
  * **Dark Mode:** Grid background `$002B1E16` (Dark Brown/Grey), Text `clWhite`. Total Label: Cyan/Light Blue for contrast.

### 2.3. Localization Rules

[cite\_start]Per `uBaseForm`[cite: 12], the form must override `ApplyLanguage`:

  * **English:** "New Sale", "Customer", "Finalize".
  * **Portuguese:** "Nova Venda", "Cliente", "Finalizar".
  * **Spanish:** "Nueva Venta", "Cliente", "Finalizar".

-----

## Part 3: Technical Implementation Guide

### 3.1. The Sales Form Class (`uFormSales.pas`)

```delphi
unit uFormSales;

interface

uses
  Winapi.Windows, System.SysUtils, Vcl.Forms, Vcl.StdCtrls, Vcl.Grids, Vcl.ExtCtrls,
  FireDAC.Comp.Client, Data.DB, 
  uBaseForm; // Must inherit from Base

type
  TfrmSales = class(TfrmBase) // Inherits connection, theme, lang
    pnlHeader: TPanel;
    pnlFooter: TPanel;
    gridItems: TDBGrid; // Or StringGrid if managing manually
    lblTotal: TLabel;
    btnFinalize: TButton;
    // ... UI components ...
    
    procedure btnFinalizeClick(Sender: TObject);
  private
    FCurrentSaleID: Integer;
    procedure CalculateTotal;
    procedure LoadProducts;
  protected
    procedure ApplyTheme; override;    // From uBaseForm
    procedure ApplyLanguage; override; // From uBaseForm
  public
    // Inherits the Constructor Create(AOwner, AConn, ATheme, ALang) automatically
    // unless we need specific Sales initialization parameters.
  end;
```

### 3.2. Transaction Logic (ACID Compliance)

When the user clicks **Finalize**:

1.  **Start Transaction:** `DBConnection.StartTransaction`.
2.  **Save Header:** Insert into `Sales` table.
3.  **Save Items:** Iterate grid/dataset and insert into `SaleItems`.
4.  **Update Stock:** Execute `UPDATE Products SET StockLevel = StockLevel - :Qty WHERE ProductID = :ID`.
5.  **Commit:** `DBConnection.Commit`.
6.  *Exception Handling:* `DBConnection.Rollback` on any error.

### 3.3. Integration with Main Form

[cite\_start]To open this screen, the Main Form [cite: 2] will use the established factory pattern:

```delphi
// Inside Form.Main.pas
procedure TfrmMain.btnNewSaleClick(Sender: TObject);
begin
  // Context is automatically passed via the OpenChildForm helper
  OpenChildForm(TfrmSales);
end;
```

-----

## Part 4: Acceptance Criteria

1.  **Initialization:** The application starts, and `uDataModule` automatically creates the `Customers`, `Sales`, and `SaleItems` tables if they don't exist.
2.  **Linkage:** A user can select a Customer and add multiple Electronics products (defined in the previous sprint) to the cart.
3.  **Persistence:** Closing and reopening the app retains the sales history.
4.  [cite\_start]**Visuals:** Switching the Theme Toggle on the Main Form [cite: 3] immediately repaints the Sales Screen to Dark/Light mode.
5.  [cite\_start]**Architecture:** The Sales Form does **not** have a `TFDConnection` component on it; it uses `DBConnection` provided by the `TfrmBase` parent[cite: 12].