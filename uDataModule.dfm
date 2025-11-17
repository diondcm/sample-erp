object dmCore: TdmCore
  OnCreate = DataModuleCreate
  Height = 250
  Width = 400
  object fdConnection: TFDConnection
    Params.Strings = (
      'DriverID=SQLite')
    LoginPrompt = False
    Left = 64
    Top = 56
  end
  object fdPhysSQLite: TFDPhysSQLiteDriverLink
    Left = 160
    Top = 56
  end
  object fdGUIxWaitCursor: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 272
    Top = 56
  end
end
