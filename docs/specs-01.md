

\# Product Definition: Apex ERP (v2.0)



\## Part 1: Project Specifications



\### 1.1. Core Architecture \& Data Strategy



&nbsp; \* \*\*Database Engine:\*\* SQLite (Local).

&nbsp; \* \*\*Connectivity:\*\* FireDAC.

&nbsp; \* \*\*Self-Healing Schema:\*\* The application must utilize a "Code-First" approach for the database. Upon initialization, the Data Module must check for the existence of the database file and required tables (`Users`, `Settings`, `Logs`, etc.). If they do not exist, they must be generated automatically via DDL execution.

&nbsp; \* \*\*Session Context Injection:\*\* To ensure decoupling and testability, \*\*no form (except the Main) handles its own connections globally.\*\* Every child form is a "dumb" view that must be injected with:

&nbsp;   1.  Active Database Connection.

&nbsp;   2.  Current Language Context (`en-US`, `pt-BR`, `es-ES`).

&nbsp;   3.  Current UI Theme (`Light`, `Dark`).



\### 1.2. UX/UI \& Theming System



The application requires a toggleable \*\*Semantic Theming Engine\*\*. We are not just changing colors; we are changing "modes."



&nbsp; \* \*\*Light Mode:\*\* Standard enterprise look. Off-white backgrounds, dark text, high contrast.

&nbsp; \* \*\*Dark Mode:\*\* Low-light environment optimized. Dark grey/Navy backgrounds, light text, desaturated accent colors to reduce eye strain.

&nbsp; \* \*\*Asset Management:\*\* Icons must update based on the theme (e.g., a black "Save" icon in Light Mode becomes a white "Save" icon in Dark Mode).



-----



\## Part 2: Technical Implementation



To support the requirement of passing parameters to every screen, we must abandon the standard `TForm.Create(Application)` method and utilize \*\*Visual Form Inheritance\*\* with a custom `Reintroduce` constructor.



\### 2.1. The Data Module (`uDataModule.pas`)



This unit handles the connection and auto-creation of tables.



```delphi

unit uDataModule;



interface



uses

&nbsp; System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,

&nbsp; FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,

&nbsp; FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,

&nbsp; FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.VCLUI.Wait,

&nbsp; FireDAC.Comp.Client, FireDAC.Comp.UI, Data.DB;



type

&nbsp; TdmCore = class(TDataModule)

&nbsp;   fdConnection: TFDConnection;

&nbsp;   fdPhysSQLite: TFDPhysSQLiteDriverLink;

&nbsp;   fdGUIxWaitCursor: TFDGUIxWaitCursor;

&nbsp;   procedure DataModuleCreate(Sender: TObject);

&nbsp; private

&nbsp;   procedure CheckAndCreateSchema;

&nbsp; public

&nbsp;   function GetConnection: TFDConnection;

&nbsp; end;



var

&nbsp; dmCore: TdmCore;



implementation



{%CLASSGROUP 'Vcl.Controls.TControl'}



{$R \*.dfm}



procedure TdmCore.DataModuleCreate(Sender: TObject);

begin

&nbsp; // Configure for local SQLite

&nbsp; fdConnection.DriverName := 'SQLite';

&nbsp; // Ideally, path should be relative to AppData or Exe

&nbsp; fdConnection.Params.Values\['Database'] := ExtractFilePath(ParamStr(0)) + 'ApexData.db';

&nbsp; fdConnection.Params.Values\['OpenMode'] := 'CreateUTF8'; 

&nbsp; 

&nbsp; try

&nbsp;   fdConnection.Connected := True;

&nbsp;   CheckAndCreateSchema;

&nbsp; except

&nbsp;   on E: Exception do

&nbsp;     // Log error here in a real app

&nbsp;     raise Exception.Create('Critical DB Error: ' + E.Message);

&nbsp; end;

end;



procedure TdmCore.CheckAndCreateSchema;

begin

&nbsp; // Simple DDL execution to ensure tables exist

&nbsp; fdConnection.ExecSQL(

&nbsp;   'CREATE TABLE IF NOT EXISTS AppSettings (' +

&nbsp;   '  SettingKey TEXT PRIMARY KEY, ' +

&nbsp;   '  SettingValue TEXT ' +

&nbsp;   ');'

&nbsp; );

&nbsp; 

&nbsp; fdConnection.ExecSQL(

&nbsp;   'CREATE TABLE IF NOT EXISTS AuditLogs (' +

&nbsp;   '  LogID INTEGER PRIMARY KEY AUTOINCREMENT, ' +

&nbsp;   '  LogDate DATETIME, ' +

&nbsp;   '  Message TEXT ' +

&nbsp;   ');'

&nbsp; );

end;



function TdmCore.GetConnection: TFDConnection;

begin

&nbsp; Result := fdConnection;

end;



end.

```



\### 2.2. The Base Form (`uBaseForm.pas`)



\*\*Crucial Step:\*\* Create a "Base Form" that all other forms (Customers, Invoices, Settings) will inherit from. This enforces the rule that every screen receives the context parameters.



```delphi

unit uBaseForm;



interface



uses

&nbsp; Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,

&nbsp; Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Comp.Client;



type

&nbsp; // Enumerations for Context

&nbsp; TAppTheme = (atLight, atDark);

&nbsp; TAppLanguage = (alEnglish, alPortuguese, alSpanish);



&nbsp; TfrmBase = class(TForm)

&nbsp;   procedure FormClose(Sender: TObject; var Action: TCloseAction);

&nbsp; private

&nbsp;   FConnection: TFDConnection;

&nbsp;   FTheme: TAppTheme;

&nbsp;   FLanguage: TAppLanguage;

&nbsp; protected

&nbsp;   // Override these in child forms to update UI elements

&nbsp;   procedure ApplyTheme; virtual;

&nbsp;   procedure ApplyLanguage; virtual;

&nbsp; public

&nbsp;   // The Magic Constructor

&nbsp;   constructor Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage); reintroduce; overload; virtual;

&nbsp;   

&nbsp;   property AppTheme: TAppTheme read FTheme;

&nbsp;   property AppLanguage: TAppLanguage read FLanguage;

&nbsp;   property DBConnection: TFDConnection read FConnection;

&nbsp; end;



implementation



{$R \*.dfm}



constructor TfrmBase.Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage);

begin

&nbsp; inherited Create(AOwner); // Call standard VCL create

&nbsp; FConnection := AConn;

&nbsp; FTheme := ATheme;

&nbsp; FLanguage := ALang;

&nbsp; 

&nbsp; // Apply settings immediately upon creation

&nbsp; ApplyTheme;

&nbsp; ApplyLanguage;

end;



procedure TfrmBase.ApplyTheme;

begin

&nbsp; // Base implementation: Set background color

&nbsp; if FTheme = atDark then

&nbsp;   Self.Color := $002B1E16 // Dark

&nbsp; else

&nbsp;   Self.Color := clWhite;  // Light

end;



procedure TfrmBase.ApplyLanguage;

begin

&nbsp; // Base implementation (optional)

end;



procedure TfrmBase.FormClose(Sender: TObject; var Action: TCloseAction);

begin

&nbsp; Action := caFree; // Ensure memory is freed when form closes

end;



end.

```



\### 2.3. The Main Form (`MainUnit.pas`) Refactored



The Main form now acts as the "Controller." It owns the DataModule and manages the state of the Theme and Language, passing them down to children.



```delphi

unit MainUnit;



interface



uses

&nbsp; Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,

&nbsp; Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.WinXCtrls,

&nbsp; uDataModule, uBaseForm; // Reference the new units



type

&nbsp; TfrmMain = class(TForm)

&nbsp;   pnlHeader: TPanel;

&nbsp;   svSidebar: TSplitView;

&nbsp;   pnlContent: TPanel; // Area where child forms will appear

&nbsp;   btnToggleTheme: TButton; // For testing

&nbsp;   procedure FormCreate(Sender: TObject);

&nbsp;   procedure btnToggleThemeClick(Sender: TObject);

&nbsp;   procedure FormDestroy(Sender: TObject);

&nbsp; private

&nbsp;   FCurrentTheme: TAppTheme;

&nbsp;   FCurrentLang: TAppLanguage;

&nbsp;   FDataModule: TdmCore; // Main Form owns the Data Module

&nbsp;   

&nbsp;   procedure ApplyGlobalTheme;

&nbsp;   procedure OpenChildForm(FormClass: class of TfrmBase);

&nbsp; public

&nbsp;   { Public declarations }

&nbsp; end;



var

&nbsp; frmMain: TfrmMain;



implementation



{$R \*.dfm}



// Example of a child form class reference (e.g., TfrmCustomers)

// functionality is usually done via class referencing or factory pattern



procedure TfrmMain.FormCreate(Sender: TObject);

begin

&nbsp; // Initialize Data

&nbsp; FDataModule := TdmCore.Create(Self);

&nbsp; 

&nbsp; // Set Defaults

&nbsp; FCurrentTheme := atLight; 

&nbsp; FCurrentLang := alEnglish;

&nbsp; 

&nbsp; ApplyGlobalTheme;

end;



procedure TfrmMain.FormDestroy(Sender: TObject);

begin

&nbsp; // DataModule is owned by Self, so it auto-frees, but good practice to be explicit if needed

end;



procedure TfrmMain.ApplyGlobalTheme;

begin

&nbsp; if FCurrentTheme = atDark then

&nbsp; begin

&nbsp;   pnlHeader.Color := $001C2535; // Navy

&nbsp;   svSidebar.Color := $00151C28; // Darker Navy

&nbsp;   Self.Color := $002B1E16;

&nbsp;   btnToggleTheme.Caption := 'Switch to Light';

&nbsp; end

&nbsp; else

&nbsp; begin

&nbsp;   pnlHeader.Color := $00F4F6F8; // Light Gray

&nbsp;   svSidebar.Color := clWhite;

&nbsp;   Self.Color := clWhite;

&nbsp;   btnToggleTheme.Caption := 'Switch to Dark';

&nbsp; end;

&nbsp; 

&nbsp; // Note: If you have open child forms, you would iterate through Screen.Forms 

&nbsp; // and call .ApplyTheme on them here.

end;



procedure TfrmMain.btnToggleThemeClick(Sender: TObject);

begin

&nbsp; if FCurrentTheme = atLight then

&nbsp;   FCurrentTheme := atDark

&nbsp; else

&nbsp;   FCurrentTheme := atLight;

&nbsp;   

&nbsp; ApplyGlobalTheme;

end;



// This is how you open ANY new screen in the system

procedure TfrmMain.OpenChildForm(FormClass: class of TfrmBase);

var

&nbsp; NewForm: TfrmBase;

begin

&nbsp; // Instantiate using the custom constructor

&nbsp; // Passing the Connection, Theme, and Language

&nbsp; NewForm := FormClass.Create(Self, FDataModule.GetConnection, FCurrentTheme, FCurrentLang);

&nbsp; 

&nbsp; // Embed it into the main content panel

&nbsp; NewForm.Parent := pnlContent; 

&nbsp; NewForm.BorderStyle := bsNone;

&nbsp; NewForm.Align := alClient;

&nbsp; NewForm.Show;

end;



end.

```



\## Part 3: Next Steps for Development Team



1\.  \*\*Create `TfrmBase`:\*\* This is the highest priority. All future forms (Customer List, Invoice Detail) must inherit from this, not `TForm`.

2\.  \*\*Icon Strategy:\*\* You need two ImageLists. One for Light Mode (dark icons) and one for Dark Mode (white/light icons). The `ApplyTheme` method in `TfrmBase` should swap the `Images` property of buttons/menus based on the selected theme.

3\.  \*\*Localization:\*\* In the `ApplyLanguage` method of `TfrmBase`, implementing a simple Dictionary lookup or a ResourceString switch (e.g., `lblTitle.Caption := GetTranslatedString('TITLE\_HOME', FLanguage)`) is required.





