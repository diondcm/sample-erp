unit uBaseForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Comp.Client;

type
  // Enumerations for Context
  TAppTheme = (atLight, atDark);
  TAppLanguage = (alEnglish, alPortuguese, alSpanish);

  TBaseFormClass = class of TfrmBase;

  TfrmBase = class(TForm)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FConnection: TFDConnection;
    FTheme: TAppTheme;
    FLanguage: TAppLanguage;
  protected
    // Override these in child forms to update UI elements
    procedure ApplyTheme; virtual;
    procedure ApplyLanguage; virtual;
  public
    // The Magic Constructor
    constructor Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage); reintroduce; overload; virtual;

    property AppTheme: TAppTheme read FTheme;
    property AppLanguage: TAppLanguage read FLanguage;
    property DBConnection: TFDConnection read FConnection;
  end;

implementation

{$R *.dfm}

constructor TfrmBase.Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage);
begin
  inherited Create(AOwner); // Call standard VCL create
  FConnection := AConn;
  FTheme := ATheme;
  FLanguage := ALang;

  // Apply settings immediately upon creation
  ApplyTheme;
  ApplyLanguage;
end;

procedure TfrmBase.ApplyTheme;
begin
  // Base implementation: Set background color
  if FTheme = atDark then
    Self.Color := $002B1E16 // Dark
  else
    Self.Color := clWhite;  // Light
end;

procedure TfrmBase.ApplyLanguage;
begin
  // Base implementation (optional)
end;

procedure TfrmBase.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree; // Ensure memory is freed when form closes
end;

end.
