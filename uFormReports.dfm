inherited frmReports: TfrmReports
  Caption = 'Business Intelligence'
  ClientHeight = 600
  ClientWidth = 1000
  StyleElements = [seFont, seClient, seBorder]
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  ExplicitWidth = 1016
  ExplicitHeight = 639
  TextHeight = 15
  object pnlSidebar: TPanel
    Left = 0
    Top = 0
    Width = 200
    Height = 600
    Align = alLeft
    BevelOuter = bvNone
    Color = 15987704
    ParentBackground = False
    TabOrder = 0
    object btnRepCustomer: TButton
      Left = 16
      Top = 24
      Width = 168
      Height = 41
      Caption = 'Sales by Customer'
      TabOrder = 0
      OnClick = btnRepCustomerClick
    end
    object btnRepProduct: TButton
      Left = 16
      Top = 80
      Width = 168
      Height = 41
      Caption = 'Sales by Product'
      TabOrder = 1
      OnClick = btnRepProductClick
    end
    object btnRepMonth: TButton
      Left = 16
      Top = 136
      Width = 168
      Height = 41
      Caption = 'Sales by Month'
      TabOrder = 2
      OnClick = btnRepMonthClick
    end
  end
  object pnlTop: TPanel
    Left = 200
    Top = 0
    Width = 800
    Height = 80
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object grpFilters: TGroupBox
      Left = 16
      Top = 8
      Width = 400
      Height = 64
      Caption = ' Filters '
      TabOrder = 0
      object lblFilter: TLabel
        Left = 16
        Top = 20
        Width = 72
        Height = 15
        Caption = 'Filter Results:'
      end
      object edtFilterText: TEdit
        Left = 16
        Top = 36
        Width = 368
        Height = 23
        TabOrder = 0
        OnChange = edtFilterTextChange
      end
    end
    object btnExportCSV: TButton
      Left = 448
      Top = 24
      Width = 120
      Height = 33
      Caption = 'Export CSV'
      TabOrder = 1
      OnClick = btnExportCSVClick
    end
    object btnExportJSON: TButton
      Left = 584
      Top = 24
      Width = 120
      Height = 33
      Caption = 'Export JSON'
      TabOrder = 2
      OnClick = btnExportJSONClick
    end
  end
  object grdReport: TDBGrid
    Left = 200
    Top = 80
    Width = 800
    Height = 520
    Align = alClient
    Color = clWhite
    DataSource = dsReport
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
  end
  object dsReport: TDataSource
    Left = 320
    Top = 160
  end
end
