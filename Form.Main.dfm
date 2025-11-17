object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Apex ERP - Main'
  ClientHeight = 600
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 16053992
    ParentBackground = False
    TabOrder = 0
    object btnToggleTheme: TButton
      Left = 864
      Top = 15
      Width = 120
      Height = 30
      Caption = 'Switch to Dark'
      TabOrder = 0
      OnClick = btnToggleThemeClick
    end
  end
  object svSidebar: TSplitView
    Left = 0
    Top = 60
    Width = 200
    Height = 540
    OpenedWidth = 200
    Placement = svpLeft
    TabOrder = 1
    object Panel1: TPanel
      Left = 0
      Top = 0
      Width = 200
      Height = 540
      Align = alClient
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object btnProducts: TButton
        Left = 16
        Top = 16
        Width = 168
        Height = 40
        Caption = 'Products (Electronics)'
        TabOrder = 0
        OnClick = btnProductsClick
      end
    end
  end
  object pnlContent: TPanel
    Left = 200
    Top = 60
    Width = 800
    Height = 540
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
  end
end
