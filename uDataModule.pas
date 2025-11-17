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
end;

function TdmCore.GetConnection: TFDConnection;
begin
  Result := fdConnection;
end;

end.
