unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.WinXCtrls,
  uDataModule, uBaseForm; // Reference the new units

type
  TfrmMain = class(TForm)
    pnlHeader: TPanel;
    svSidebar: TSplitView;
    pnlContent: TPanel; // Area where child forms will appear
    btnToggleTheme: TButton; // For testing
    procedure FormCreate(Sender: TObject);
    procedure btnToggleThemeClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FCurrentTheme: TAppTheme;
    FCurrentLang: TAppLanguage;
    FDataModule: TdmCore; // Main Form owns the Data Module

    procedure ApplyGlobalTheme;
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

  // Embed it into the main content panel
  NewForm.Parent := pnlContent;
  NewForm.BorderStyle := bsNone;
  NewForm.Align := alClient;
  NewForm.Show;
end;

end.
