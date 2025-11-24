unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.WinXCtrls,
  Vcl.ComCtrls, Vcl.ImgList, FireDAC.Comp.Client,
  uDataModule, uBaseForm, uFormProducts, uFormCustomers, uFormSales, uFormReports, uFormEvaluMe, System.ImageList; // Reference the new units

type
  TfrmMain = class(TForm)
    pnlHeader: TPanel;
    svSidebar: TSplitView;
    pnlContent: TPanel; // Area where child forms will appear
    btnToggleTheme: TButton; // For testing
    btnProducts: TButton;
    btnCustomers: TButton;
    btnSales: TButton;
    btnReports: TButton;
    btnEvaluMe: TButton;
    PanelControls: TPanel;
    cmbLanguage: TComboBoxEx;
    chkCreateDocked: TCheckBox;
    imgLanguages: TImageList;
    ButtonFeedTestData: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnToggleThemeClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnProductsClick(Sender: TObject);
    procedure btnCustomersClick(Sender: TObject);
    procedure btnSalesClick(Sender: TObject);
    procedure btnReportsClick(Sender: TObject);
    procedure btnEvaluMeClick(Sender: TObject);
    procedure cmbLanguageChange(Sender: TObject);
    procedure ButtonFeedTestDataClick(Sender: TObject);
  private
    FCurrentTheme: TAppTheme;
    FCurrentLang: TAppLanguage;
    FDataModule: TdmCore; // Main Form owns the Data Module

    procedure ApplyGlobalTheme;
    procedure ApplyGlobalLanguage;
    procedure OpenChildForm(FormClass: TBaseFormClass);
    procedure GenerateTestData;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

// Example of a child form class reference (e.g., TfrmCustomers)
// functionality is usually done via class referencing or factory pattern

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Initialize Data
  FDataModule := TdmCore.Create(Self);

  // Set Defaults
  FCurrentTheme := atLight;
  FCurrentLang := alEnglish;

  // Initialize language combo box
  cmbLanguage.ItemIndex := Ord(FCurrentLang); // 0 = English, 1 = Portuguese, 2 = Spanish

  ApplyGlobalTheme;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // DataModule is owned by Self, so it auto-frees, but good practice to be explicit if needed
end;

procedure TfrmMain.ApplyGlobalTheme;
begin
  if FCurrentTheme = atDark then
  begin
    pnlHeader.Color := $001C2535; // Navy
    svSidebar.Color := $00151C28; // Darker Navy
    Self.Color := $002B1E16;
    btnToggleTheme.Caption := 'Switch to Light';
  end
  else
  begin
    pnlHeader.Color := $00F4F6F8; // Light Gray
    svSidebar.Color := clWhite;
    Self.Color := clWhite;
    btnToggleTheme.Caption := 'Switch to Dark';
  end;

  // Note: If you have open child forms, you would iterate through Screen.Forms
  // and call .ApplyTheme on them here.
end;

procedure TfrmMain.btnToggleThemeClick(Sender: TObject);
begin
  if FCurrentTheme = atLight then
    FCurrentTheme := atDark
  else
    FCurrentTheme := atLight;

  ApplyGlobalTheme;
end;

procedure TfrmMain.ButtonFeedTestDataClick(Sender: TObject);
begin
  GenerateTestData;
  ShowMessage('Test data generated successfully!');
end;

procedure TfrmMain.GenerateTestData;
var
  Conn: TFDConnection;
begin
  Conn := FDataModule.GetConnection;
  
  // 1. Products Data
  // Clear existing data to avoid unique constraint violations on SKU
  Conn.ExecSQL('DELETE FROM Products');
  Conn.ExecSQL('DELETE FROM sqlite_sequence WHERE name=''Products'''); // Reset AutoInc

  Conn.ExecSQL('INSERT INTO Products (SKU, Name, Category, MSRP, StockLevel, FCC_ID, WarrantyMonths) VALUES ' +
    '(''TECH-001'', ''Smartphone X Pro'', ''Smartphones'', 999.99, 50, ''FCC-SM-X'', 24)');
    
  Conn.ExecSQL('INSERT INTO Products (SKU, Name, Category, MSRP, StockLevel, FCC_ID, WarrantyMonths) VALUES ' +
    '(''TECH-002'', ''Laptop UltraSlim'', ''Laptops'', 1499.50, 20, ''FCC-LT-US'', 36)');
    
  Conn.ExecSQL('INSERT INTO Products (SKU, Name, Category, MSRP, StockLevel, FCC_ID, WarrantyMonths) VALUES ' +
    '(''AUDIO-001'', ''Noise Cancel Headphones'', ''Audio'', 299.00, 100, ''FCC-AU-NC'', 12)');
    
  Conn.ExecSQL('INSERT INTO Products (SKU, Name, Category, MSRP, StockLevel, FCC_ID, WarrantyMonths) VALUES ' +
    '(''HOME-001'', ''Smart Thermostat'', ''Smart Home'', 199.00, 75, ''FCC-SH-TH'', 24)');
    
  Conn.ExecSQL('INSERT INTO Products (SKU, Name, Category, MSRP, StockLevel, FCC_ID, WarrantyMonths) VALUES ' +
    '(''ACC-001'', ''Wireless Charger'', ''Accessories'', 49.99, 200, ''FCC-AC-WC'', 12)');


  // 2. Customers Data
  Conn.ExecSQL('DELETE FROM Customers');
  Conn.ExecSQL('DELETE FROM sqlite_sequence WHERE name=''Customers'''); // Reset AutoInc

  Conn.ExecSQL('INSERT INTO Customers (CustomerName, LegalName, TaxID, Email, Phone, Website, ' +
    'BillingAddress, BillingCity, BillingState, BillingZip, BillingCountry, CreditLimit, IsActive, Notes) VALUES ' +
    '(''Acme Corp'', ''Acme Corporation Inc.'', ''12-3456789'', ''contact@acme.com'', ''555-0101'', ''www.acme.com'', ' +
    '(''123 Industrial Way''), ''Metropolis'', ''NY'', ''10001'', ''USA'', 50000.00, 1, ''Key account with high volume.'')');
    
  Conn.ExecSQL('INSERT INTO Customers (CustomerName, LegalName, TaxID, Email, Phone, Website, ' +
    'BillingAddress, BillingCity, BillingState, BillingZip, BillingCountry, CreditLimit, IsActive, Notes) VALUES ' +
    '(''Global Tech'', ''Global Technology Solutions'', ''98-7654321'', ''info@globaltech.com'', ''555-0102'', ''www.globaltech.com'', ' +
    '(''456 Tech Park''), ''Silicon Valley'', ''CA'', ''94000'', ''USA'', 25000.00, 1, ''Rapidly growing tech startup.'')');
    
  Conn.ExecSQL('INSERT INTO Customers (CustomerName, LegalName, TaxID, Email, Phone, Website, ' +
    'BillingAddress, BillingCity, BillingState, BillingZip, BillingCountry, CreditLimit, IsActive, Notes) VALUES ' +
    '(''Joe''''s Local Electronics'', ''Joe''''s Local Electronics LLC'', ''11-2223333'', ''joe@localshop.com'', ''555-0103'', '''', ' +
    '(''789 Main St''), ''Smalltown'', ''TX'', ''75000'', ''USA'', 5000.00, 1, ''Loyal local customer.'')');
    
  Conn.ExecSQL('INSERT INTO Customers (CustomerName, LegalName, TaxID, Email, Phone, Website, ' +
    'BillingAddress, BillingCity, BillingState, BillingZip, BillingCountry, CreditLimit, IsActive, Notes) VALUES ' +
    '(''Inactive LLC'', ''Inactive Holdings'', ''00-0000000'', ''admin@inactive.com'', ''555-0000'', '''', ' +
    '(''100 Empty Rd''), ''Nowhere'', ''NV'', ''89000'', ''USA'', 0.00, 0, ''Account suspended due to non-payment.'')');

  Conn.ExecSQL('INSERT INTO Customers (CustomerName, LegalName, TaxID, Email, Phone, Website, ' +
    'BillingAddress, BillingCity, BillingState, BillingZip, BillingCountry, CreditLimit, IsActive, Notes) VALUES ' +
    '(''Euro Import'', ''Euro Import GmbH'', ''DE-12345678'', ''purchasing@euroimport.de'', ''+49-30-123456'', ''www.euroimport.de'', ' +
    '(''Berliner Str. 10''), ''Berlin'', '''', ''10115'', ''Germany'', 100000.00, 1, ''Major European distributor.'')');
end;

// This is how you open ANY new screen in the system
procedure TfrmMain.OpenChildForm(FormClass: TBaseFormClass);
var
  NewForm: TfrmBase;
begin
  // Instantiate using the custom constructor
  // Passing the Connection, Theme, and Language
  NewForm := FormClass.Create(Self, FDataModule.GetConnection, FCurrentTheme, FCurrentLang);

  // Check if user wants docked or floating windows
  if chkCreateDocked.Checked then
  begin
    // Docked mode: Embed it into the main content panel
    NewForm.Parent := pnlContent;
    NewForm.BorderStyle := bsNone;
    NewForm.Align := alClient;
  end
  else
  begin
    // Floating mode: Leave as separate window
    // Do not set Parent, BorderStyle, or Align
    // The form will appear as a separate window
  end;

  NewForm.Show;
end;

// Event handler for Products button
procedure TfrmMain.btnProductsClick(Sender: TObject);
begin
  // The beauty of the architecture:
  // We just pass the class type. The logic handles the injection.
  OpenChildForm(TfrmProducts);
end;

// Event handler for Customers button
procedure TfrmMain.btnCustomersClick(Sender: TObject);
begin
  // Injects the Connection, Theme, and Language automatically via TBaseForm logic
  OpenChildForm(TfrmCustomers);
end;

// Event handler for Sales button
procedure TfrmMain.btnSalesClick(Sender: TObject);
begin
  // Injects the Connection, Theme, and Language automatically via TBaseForm logic
  OpenChildForm(TfrmSales);
end;

// Event handler for Reports button
procedure TfrmMain.btnReportsClick(Sender: TObject);
begin
  // Injects the Connection, Theme, and Language automatically via TBaseForm logic
  OpenChildForm(TfrmReports);
end;

// Event handler for EvaluMe button
procedure TfrmMain.btnEvaluMeClick(Sender: TObject);
begin
  OpenChildForm(TfrmEvaluMe);
end;

// Event handler for Language change
procedure TfrmMain.cmbLanguageChange(Sender: TObject);
begin
  // Update current language based on combo selection
  case cmbLanguage.ItemIndex of
    0: FCurrentLang := alEnglish;
    1: FCurrentLang := alPortuguese;
    2: FCurrentLang := alSpanish;
  end;

  // Apply language to all currently open child forms
  ApplyGlobalLanguage;
end;

// Apply language to all currently open child forms
procedure TfrmMain.ApplyGlobalLanguage;
var
  i: Integer;
  ChildForm: TfrmBase;
begin
  // Task 1: Apply languages as selected on the PanelControls buttons
  case FCurrentLang of
    alEnglish:
      begin
        btnProducts.Caption := 'Products (Electronics)';
        btnCustomers.Caption := 'Customers';
        btnSales.Caption := 'Sales';
        btnReports.Caption := 'Reports';
        btnEvaluMe.Caption := 'EvaluMe API';
      end;
    alPortuguese:
      begin
        btnProducts.Caption := 'Produtos (Eletrônicos)';
        btnCustomers.Caption := 'Clientes';
        btnSales.Caption := 'Vendas';
        btnReports.Caption := 'Relatórios';
        btnEvaluMe.Caption := 'API EvaluMe';
      end;
    alSpanish:
      begin
        btnProducts.Caption := 'Productos (Electrónicos)';
        btnCustomers.Caption := 'Clientes';
        btnSales.Caption := 'Ventas';
        btnReports.Caption := 'Informes';
        btnEvaluMe.Caption := 'API EvaluMe';
      end;
  end;

  // Iterate through all controls in the content panel
  for i := 0 to pnlContent.ControlCount - 1 do
  begin
    // Check if the control is a child form (TfrmBase)
    if pnlContent.Controls[i] is TfrmBase then
    begin
      ChildForm := TfrmBase(pnlContent.Controls[i]);
      // Update the language property and apply it
      ChildForm.Language := FCurrentLang;
//      ChildForm.ApplyLanguage;
    end;
  end;
end;

end.
