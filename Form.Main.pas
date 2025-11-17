unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.WinXCtrls,
  Vcl.ComCtrls, Vcl.ImgList,
  uDataModule, uBaseForm, uFormProducts, uFormCustomers, uFormSales; // Reference the new units

type
  TfrmMain = class(TForm)
    pnlHeader: TPanel;
    svSidebar: TSplitView;
    pnlContent: TPanel; // Area where child forms will appear
    btnToggleTheme: TButton; // For testing
    btnProducts: TButton;
    btnCustomers: TButton;
    btnSales: TButton;
    Panel1: TPanel;
    cmbLanguage: TComboBoxEx;
    chkCreateDocked: TCheckBox;
    imgLanguages: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure btnToggleThemeClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnProductsClick(Sender: TObject);
    procedure btnCustomersClick(Sender: TObject);
    procedure btnSalesClick(Sender: TObject);
    procedure cmbLanguageChange(Sender: TObject);
  private
    FCurrentTheme: TAppTheme;
    FCurrentLang: TAppLanguage;
    FDataModule: TdmCore; // Main Form owns the Data Module

    procedure ApplyGlobalTheme;
    procedure ApplyGlobalLanguage;
    procedure OpenChildForm(FormClass: TBaseFormClass);
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
  // Iterate through all controls in the content panel
  for i := 0 to pnlContent.ControlCount - 1 do
  begin
    // Check if the control is a child form (TfrmBase)
    if pnlContent.Controls[i] is TfrmBase then
    begin
      ChildForm := TfrmBase(pnlContent.Controls[i]);
      // Update the language property and apply it
      ChildForm.Language := FCurrentLang;
      ChildForm.ApplyLanguage;
    end;
  end;
end;

end.
