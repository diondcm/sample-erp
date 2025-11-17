inherited frmSales: TfrmSales
  Caption = 'Sales Management'
  ClientHeight = 600
  ClientWidth = 900
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  ExplicitWidth = 916
  ExplicitHeight = 639
  PixelsPerInch = 96
  TextHeight = 13
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 80
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblCustomer: TLabel
      Left = 16
      Top = 16
      Width = 51
      Height = 13
      Caption = 'Customer:'
    end
    object lblDate: TLabel
      Left = 320
      Top = 16
      Width = 50
      Height = 13
      Caption = 'Sale Date:'
    end
    object lblStatus: TLabel
      Left = 560
      Top = 16
      Width = 34
      Height = 13
      Caption = 'Status:'
    end
    object lblStatusValue: TLabel
      Left = 560
      Top = 35
      Width = 40
      Height = 13
      Caption = 'DRAFT'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGreen
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object cmbCustomer: TComboBox
      Left = 16
      Top = 35
      Width = 281
      Height = 21
      Style = csDropDownList
      TabOrder = 0
    end
    object dtpSaleDate: TDateTimePicker
      Left = 320
      Top = 35
      Width = 186
      Height = 21
      Date = 45000.000000000000000000
      Time = 45000.000000000000000000
      TabOrder = 1
    end
    object btnNewSale: TButton
      Left = 704
      Top = 16
      Width = 120
      Height = 40
      Caption = 'New Sale'
      TabOrder = 2
      OnClick = btnNewSaleClick
    end
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 520
    Width = 900
    Height = 80
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object lblGrandTotal: TLabel
      Left = 16
      Top = 16
      Width = 64
      Height = 13
      Caption = 'Grand Total:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblGrandTotalValue: TLabel
      Left = 16
      Top = 35
      Width = 33
      Height = 19
      Caption = '$0.00'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnFinalize: TButton
      Left = 520
      Top = 16
      Width = 120
      Height = 48
      Caption = 'Finalize Sale'
      TabOrder = 0
      OnClick = btnFinalizeClick
    end
    object btnCancel: TButton
      Left = 656
      Top = 16
      Width = 120
      Height = 48
      Caption = 'Cancel Sale'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object pnlMiddle: TPanel
    Left = 0
    Top = 80
    Width = 900
    Height = 440
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object pnlAddItem: TPanel
      Left = 0
      Top = 0
      Width = 900
      Height = 60
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object lblProduct: TLabel
        Left = 16
        Top = 8
        Width = 40
        Height = 13
        Caption = 'Product:'
      end
      object lblQuantity: TLabel
        Left = 600
        Top = 8
        Width = 46
        Height = 13
        Caption = 'Quantity:'
      end
      object cmbProduct: TComboBox
        Left = 16
        Top = 27
        Width = 561
        Height = 21
        Style = csDropDownList
        TabOrder = 0
        OnChange = cmbProductChange
      end
      object edtQuantity: TEdit
        Left = 600
        Top = 27
        Width = 80
        Height = 21
        TabOrder = 1
        Text = '1'
      end
      object btnAddItem: TButton
        Left = 704
        Top = 16
        Width = 120
        Height = 32
        Caption = 'Add Item'
        TabOrder = 2
        OnClick = btnAddItemClick
      end
    end
    object grdItems: TDBGrid
      Left = 0
      Top = 60
      Width = 900
      Height = 340
      Align = alClient
      DataSource = dsItems
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
      OnCellClick = grdItemsCellClick
    end
    object btnDeleteItem: TButton
      Left = 16
      Top = 406
      Width = 120
      Height = 25
      Caption = 'Delete Item'
      TabOrder = 2
      OnClick = btnDeleteItemClick
    end
  end
  object dsItems: TDataSource
    Left = 320
    Top = 240
  end
end
