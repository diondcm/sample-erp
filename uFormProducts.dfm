inherited frmProducts: TfrmProducts
  Caption = 'Product Management - Electronics'
  ClientHeight = 600
  ClientWidth = 1000
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlControls: TPanel
    Left = 0
    Top = 0
    Width = 400
    Height = 600
    Align = alLeft
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblSKU: TLabel
      Left = 16
      Top = 24
      Width = 125
      Height = 15
      Caption = 'SKU (Stock Keeping Unit):'
    end
    object lblName: TLabel
      Left = 16
      Top = 72
      Width = 80
      Height = 15
      Caption = 'Product Name:'
    end
    object lblCategory: TLabel
      Left = 16
      Top = 120
      Width = 51
      Height = 15
      Caption = 'Category:'
    end
    object lblMSRP: TLabel
      Left = 16
      Top = 168
      Width = 67
      Height = 15
      Caption = 'MSRP (USD):'
    end
    object lblStockLevel: TLabel
      Left = 16
      Top = 216
      Width = 65
      Height = 15
      Caption = 'Stock Level:'
    end
    object lblFCC: TLabel
      Left = 16
      Top = 264
      Width = 77
      Height = 15
      Caption = 'FCC ID (Reg.):'
    end
    object lblWarrantyMonths: TLabel
      Left = 16
      Top = 312
      Width = 103
      Height = 15
      Caption = 'Warranty (Months):'
    end
    object edtSKU: TEdit
      Left = 16
      Top = 42
      Width = 360
      Height = 23
      TabOrder = 0
    end
    object edtName: TEdit
      Left = 16
      Top = 90
      Width = 360
      Height = 23
      TabOrder = 1
    end
    object edtCategory: TEdit
      Left = 16
      Top = 138
      Width = 360
      Height = 23
      TabOrder = 2
    end
    object edtMSRP: TEdit
      Left = 16
      Top = 186
      Width = 360
      Height = 23
      TabOrder = 3
    end
    object edtStockLevel: TEdit
      Left = 16
      Top = 234
      Width = 360
      Height = 23
      TabOrder = 4
      Text = '0'
    end
    object edtFCC: TEdit
      Left = 16
      Top = 282
      Width = 360
      Height = 23
      TabOrder = 5
    end
    object edtWarrantyMonths: TEdit
      Left = 16
      Top = 330
      Width = 360
      Height = 23
      TabOrder = 6
      Text = '0'
    end
    object btnNew: TButton
      Left = 16
      Top = 368
      Width = 110
      Height = 32
      Caption = 'New Product'
      TabOrder = 7
      OnClick = btnNewClick
    end
    object btnSave: TButton
      Left = 136
      Top = 368
      Width = 110
      Height = 32
      Caption = 'Save Product'
      TabOrder = 8
      OnClick = btnSaveClick
    end
    object btnDelete: TButton
      Left = 256
      Top = 368
      Width = 120
      Height = 32
      Caption = 'Delete Product'
      TabOrder = 9
      OnClick = btnDeleteClick
    end
    object pnlImages: TPanel
      Left = 0
      Top = 410
      Width = 400
      Height = 190
      Align = alBottom
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 10
      object lblImagesInfo: TLabel
        Left = 16
        Top = 8
        Width = 142
        Height = 15
        Caption = 'Product Images (Max 3):'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object imgProduct1: TImage
        Left = 16
        Top = 32
        Width = 100
        Height = 100
        Stretch = True
      end
      object imgProduct2: TImage
        Left = 144
        Top = 32
        Width = 100
        Height = 100
        Stretch = True
      end
      object imgProduct3: TImage
        Left = 272
        Top = 32
        Width = 100
        Height = 100
        Stretch = True
      end
      object btnLoadImage1: TButton
        Left = 16
        Top = 140
        Width = 45
        Height = 25
        Caption = 'Load'
        TabOrder = 0
        OnClick = btnLoadImage1Click
      end
      object btnClearImage1: TButton
        Left = 68
        Top = 140
        Width = 45
        Height = 25
        Caption = 'Clear'
        TabOrder = 1
        OnClick = btnClearImage1Click
      end
      object btnLoadImage2: TButton
        Left = 144
        Top = 140
        Width = 45
        Height = 25
        Caption = 'Load'
        TabOrder = 2
        OnClick = btnLoadImage2Click
      end
      object btnClearImage2: TButton
        Left = 196
        Top = 140
        Width = 45
        Height = 25
        Caption = 'Clear'
        TabOrder = 3
        OnClick = btnClearImage2Click
      end
      object btnLoadImage3: TButton
        Left = 272
        Top = 140
        Width = 45
        Height = 25
        Caption = 'Load'
        TabOrder = 4
        OnClick = btnLoadImage3Click
      end
      object btnClearImage3: TButton
        Left = 324
        Top = 140
        Width = 45
        Height = 25
        Caption = 'Clear'
        TabOrder = 5
        OnClick = btnClearImage3Click
      end
    end
  end
  object grdProducts: TDBGrid
    Left = 400
    Top = 0
    Width = 600
    Height = 600
    Align = alClient
    DataSource = dsProducts
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
    OnCellClick = grdProductsCellClick
  end
  object dsProducts: TDataSource
    Left = 704
    Top = 48
  end
end
