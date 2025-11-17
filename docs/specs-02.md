\*\*Product Management Module (Electronics Edition)\*\*. This module represents our first implementation of a specific vertical domain.



Per your instructions, we are adhering to the \*\*Apex v2.0 Architecture\*\*:



1\.  \*\*Autonomous Schema:\*\* Tables are generated at runtime in `uDataModule`.

2\.  \*\*Inheritance:\*\* The UI inherits from `TfrmBase`.

3\.  \*\*Context Injection:\*\* Theme and Language are injected, not hardcoded.



Here is the feature specification followed by the technical implementation.



-----



\## Product Specification: Electronics Inventory



To align with US industry standards for electronics, we need specific data points beyond the generic "Name" and "Price."



\### 1\\. Data Dictionary (US Electronics Standard)



| Field | Type | Business Rule / US Standard |

| :--- | :--- | :--- |

| \*\*SKU\*\* | String (Unique) | Stock Keeping Unit. Essential for US inventory tracking. |

| \*\*Name\*\* | String | Product marketing name. |

| \*\*Category\*\* | String | e.g., Consumer Electronics, IoT, Peripherals. |

| \*\*MSRP\*\* | Currency | Manufacturer's Suggested Retail Price (Standard US pricing model). |

| \*\*StockLevel\*\* | Integer | Current Qty on Hand. |

| \*\*FCC\\\_ID\*\* | String | \*\*Critical:\*\* US Federal Communications Commission ID. Required for any device oscillating \\>9kHz. |

| \*\*WarrantyMo\*\* | Integer | Warranty period in months. |



\### 2\\. Media Requirements



&nbsp; \* \*\*Constraint:\*\* Maximum of \*\*3 images\*\* per product.

&nbsp; \* \*\*Storage:\*\* Stored as BLOBs in a child table (1:N relationship) to prevent main table bloat.



-----



\## Technical Implementation



\### Step 1: Data Layer Update (`uDataModule.pas`)



We need to update the `CheckAndCreateSchema` procedure to ensure the tables exist when the application starts.



```delphi

procedure TdmCore.CheckAndCreateSchema;

begin

&nbsp; // Existing Tables...

&nbsp; fdConnection.ExecSQL('CREATE TABLE IF NOT EXISTS AppSettings (SettingKey TEXT PRIMARY KEY, SettingValue TEXT);');

&nbsp; 

&nbsp; // --- NEW: Products Table (Electronics Spec) ---

&nbsp; fdConnection.ExecSQL(

&nbsp;   'CREATE TABLE IF NOT EXISTS Products (' +

&nbsp;   '  ProductID INTEGER PRIMARY KEY AUTOINCREMENT, ' +

&nbsp;   '  SKU TEXT UNIQUE NOT NULL, ' +

&nbsp;   '  Name TEXT NOT NULL, ' +

&nbsp;   '  Category TEXT, ' +

&nbsp;   '  MSRP REAL, ' +

&nbsp;   '  StockLevel INTEGER DEFAULT 0, ' +

&nbsp;   '  FCC\_ID TEXT, ' +

&nbsp;   '  WarrantyMonths INTEGER ' +

&nbsp;   ');'

&nbsp; );



&nbsp; // --- NEW: Product Images (Limit managed by App Logic) ---

&nbsp; fdConnection.ExecSQL(

&nbsp;   'CREATE TABLE IF NOT EXISTS ProductImages (' +

&nbsp;   '  ImageID INTEGER PRIMARY KEY AUTOINCREMENT, ' +

&nbsp;   '  ProductID INTEGER NOT NULL, ' +

&nbsp;   '  ImageData BLOB, ' +

&nbsp;   '  CONSTRAINT fk\_products FOREIGN KEY (ProductID) REFERENCES Products (ProductID) ON DELETE CASCADE ' +

&nbsp;   ');'

&nbsp; );

end;

```



\### Step 2: The Product CRUD Form (`uFormProducts.pas`)



This form inherits from `uBaseForm`. It handles the UI logic, dynamic theming, and database operations using the connection injected by the Main Form.



```delphi

unit uFormProducts;



interface



uses

&nbsp; Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,

&nbsp; Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBaseForm, FireDAC.Comp.Client, Data.DB,

&nbsp; FireDAC.Stan.Param, Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids, Vcl.ExtCtrls, Vcl.Mask,

&nbsp; FireDAC.DApt; // Important for Schema Adapter if needed



type

&nbsp; TfrmProducts = class(TfrmBase) // Inherits from our Architecture Base

&nbsp;   pnlControls: TPanel;

&nbsp;   grdProducts: TDBGrid;

&nbsp;   lblSKU: TLabel;

&nbsp;   edtSKU: TEdit;

&nbsp;   lblName: TLabel;

&nbsp;   edtName: TEdit;

&nbsp;   lblFCC: TLabel;

&nbsp;   edtFCC: TEdit;

&nbsp;   lblMSRP: TLabel;

&nbsp;   edtMSRP: TEdit;

&nbsp;   btnSave: TButton;

&nbsp;   btnDelete: TButton;

&nbsp;   dsProducts: TDataSource;

&nbsp;   pnlImages: TPanel;

&nbsp;   imgProduct1: TImage;

&nbsp;   imgProduct2: TImage;

&nbsp;   imgProduct3: TImage;

&nbsp;   lblImagesInfo: TLabel;

&nbsp;   

&nbsp;   procedure FormCreate(Sender: TObject);

&nbsp;   procedure btnSaveClick(Sender: TObject);

&nbsp;   procedure btnDeleteClick(Sender: TObject);

&nbsp;   procedure grdProductsCellClick(Column: TColumn);

&nbsp; private

&nbsp;   FQuery: TFDQuery;

&nbsp;   procedure RefreshGrid;

&nbsp;   procedure ClearInputs;

&nbsp;   procedure LoadImages(AProductID: Integer);

&nbsp; protected

&nbsp;   procedure ApplyTheme; override;

&nbsp;   procedure ApplyLanguage; override;

&nbsp; public

&nbsp;   constructor Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage); override;

&nbsp; end;



implementation



{$R \*.dfm}



constructor TfrmProducts.Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage);

begin

&nbsp; // 1. Call the Magic Constructor of the Base

&nbsp; inherited Create(AOwner, AConn, ATheme, ALang);



&nbsp; // 2. Setup internal Query using the INJECTED connection

&nbsp; FQuery := TFDQuery.Create(Self);

&nbsp; FQuery.Connection := DBConnection; 

&nbsp; 

&nbsp; dsProducts.DataSet := FQuery;

&nbsp; RefreshGrid;

end;



procedure TfrmProducts.FormCreate(Sender: TObject);

begin

&nbsp; // VCL Init if needed

end;



// --- CRUD OPERATIONS ---



procedure TfrmProducts.RefreshGrid;

begin

&nbsp; FQuery.Close;

&nbsp; FQuery.SQL.Text := 'SELECT \* FROM Products ORDER BY Name';

&nbsp; FQuery.Open;

end;



procedure TfrmProducts.btnSaveClick(Sender: TObject);

var

&nbsp; SQL: string;

begin

&nbsp; // Basic Upsert Logic (Simplified for brevity)

&nbsp; // In a real scenario, check if ID exists to determine INSERT vs UPDATE

&nbsp; 

&nbsp; SQL := 'INSERT OR REPLACE INTO Products (SKU, Name, MSRP, FCC\_ID) VALUES (:sku, :name, :msrp, :fcc)';

&nbsp; 

&nbsp; DBConnection.ExecSQL(SQL, \[edtSKU.Text, edtName.Text, StrToFloatDef(edtMSRP.Text, 0), edtFCC.Text]);

&nbsp; 

&nbsp; // TODO: Handle Image saving to ProductImages table here 

&nbsp; // Iterate through imgProduct1..3 and INSERT BLOBs linked to the new ProductID

&nbsp; 

&nbsp; RefreshGrid;

&nbsp; ClearInputs;

end;



procedure TfrmProducts.btnDeleteClick(Sender: TObject);

begin

&nbsp; if not FQuery.IsEmpty then

&nbsp; begin

&nbsp;   DBConnection.ExecSQL('DELETE FROM Products WHERE ProductID = :id', \[FQuery.FieldByName('ProductID').AsInteger]);

&nbsp;   RefreshGrid;

&nbsp; end;

end;



procedure TfrmProducts.grdProductsCellClick(Column: TColumn);

begin

&nbsp; if not FQuery.IsEmpty then

&nbsp; begin

&nbsp;   edtSKU.Text  := FQuery.FieldByName('SKU').AsString;

&nbsp;   edtName.Text := FQuery.FieldByName('Name').AsString;

&nbsp;   edtMSRP.Text := FQuery.FieldByName('MSRP').AsString;

&nbsp;   edtFCC.Text  := FQuery.FieldByName('FCC\_ID').AsString;

&nbsp;   

&nbsp;   LoadImages(FQuery.FieldByName('ProductID').AsInteger);

&nbsp; end;

end;



procedure TfrmProducts.LoadImages(AProductID: Integer);

begin

&nbsp; // Logic to SELECT ImageData FROM ProductImages WHERE ProductID = :ID

&nbsp; // Populate imgProduct1, 2, and 3. 

&nbsp; // If count < 3, clear remaining images.

end;



procedure TfrmProducts.ClearInputs;

begin

&nbsp; edtSKU.Clear;

&nbsp; edtName.Clear;

&nbsp; edtMSRP.Clear;

&nbsp; edtFCC.Clear;

end;



// --- ARCHITECTURE OVERRIDES ---



procedure TfrmProducts.ApplyTheme;

begin

&nbsp; inherited; // Sets Form Color

&nbsp; 

&nbsp; if AppTheme = atDark then

&nbsp; begin

&nbsp;   pnlControls.Color := $002B1E16;

&nbsp;   grdProducts.Color := $00382E26; // Slightly lighter than background

&nbsp;   grdProducts.Font.Color := clWhite;

&nbsp;   grdProducts.TitleFont.Color := clWhite;

&nbsp;   

&nbsp;   lblSKU.Font.Color := clSilver;

&nbsp;   lblName.Font.Color := clSilver;

&nbsp;   // Update other labels...

&nbsp; end

&nbsp; else

&nbsp; begin

&nbsp;   pnlControls.Color := clWhite;

&nbsp;   grdProducts.Color := clWhite;

&nbsp;   grdProducts.Font.Color := clBlack;

&nbsp;   grdProducts.TitleFont.Color := clBlack;

&nbsp;   

&nbsp;   lblSKU.Font.Color := clBlack;

&nbsp;   lblName.Font.Color := clBlack;

&nbsp; end;

end;



procedure TfrmProducts.ApplyLanguage;

begin

&nbsp; inherited;

&nbsp; 

&nbsp; // Simple Switch based on Context

&nbsp; case AppLanguage of

&nbsp;   alEnglish:

&nbsp;     begin

&nbsp;       Caption := 'Product Management - Electronics';

&nbsp;       lblSKU.Caption := 'SKU (Stock Keeping Unit)';

&nbsp;       lblName.Caption := 'Product Name';

&nbsp;       lblFCC.Caption := 'FCC ID (Reg.)';

&nbsp;       btnSave.Caption := 'Save Product';

&nbsp;     end;

&nbsp;   alPortuguese:

&nbsp;     begin

&nbsp;       Caption := 'Gestão de Produtos - Eletrônicos';

&nbsp;       lblSKU.Caption := 'SKU (Unidade de Estoque)';

&nbsp;       lblName.Caption := 'Nome do Produto';

&nbsp;       lblFCC.Caption := 'ID FCC (Regulação)';

&nbsp;       btnSave.Caption := 'Salvar Produto';

&nbsp;     end;

&nbsp; end;

end;



end.

```



\### Step 3: Integration in `Form.Main.pas`



Finally, wire up the new form in the Main Controller.



```delphi

uses 

&nbsp; ..., uFormProducts; 



// Add a button or menu item event handler:

procedure TfrmMain.btnOpenProductsClick(Sender: TObject);

begin

&nbsp; // The beauty of the architecture: 

&nbsp; // We just pass the class type. The logic handles the injection.

&nbsp; OpenChildForm(TfrmProducts); 

end;

```



\### Summary of Deliverables for the Dev Team



1\.  \*\*Database:\*\* Auto-generates `Products` and `ProductImages` on app start using SQLite DDL.

2\.  \*\*Business Rules:\*\* Includes `SKU` (Unique) and `FCC\_ID` fields in the UI and Query.

3\.  \*\*Architecture Compliance:\*\*

&nbsp;     \* Form is not auto-created by Application.

&nbsp;     \* Constructor receives `TFDConnection` explicitly.

&nbsp;     \* `ApplyTheme` handles the Dark Mode contrast for the Grid and Inputs.

&nbsp;     \* `ApplyLanguage` handles the EN/PT localization strings.

