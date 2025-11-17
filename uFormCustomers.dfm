inherited frmCustomers: TfrmCustomers
  Caption = 'Customer Management'
  ClientHeight = 650
  ClientWidth = 1100
  StyleElements = [seFont, seClient, seBorder]
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  ExplicitWidth = 1116
  ExplicitHeight = 689
  TextHeight = 15
  object splitterGrid: TSplitter
    Left = 700
    Top = 60
    Width = 5
    Height = 590
    Align = alRight
    ExplicitLeft = 400
    ExplicitTop = 0
    ExplicitHeight = 650
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 15527664
    ParentBackground = False
    TabOrder = 0
    object pnlActions: TPanel
      Left = 0
      Top = 0
      Width = 1100
      Height = 60
      Align = alClient
      BevelOuter = bvNone
      Color = 15527664
      ParentBackground = False
      TabOrder = 0
      object btnNew: TButton
        Left = 16
        Top = 14
        Width = 100
        Height = 32
        Caption = 'New'
        TabOrder = 0
        OnClick = btnNewClick
      end
      object btnSave: TButton
        Left = 128
        Top = 14
        Width = 100
        Height = 32
        Caption = 'Save'
        TabOrder = 1
        OnClick = btnSaveClick
      end
      object btnDelete: TButton
        Left = 240
        Top = 14
        Width = 100
        Height = 32
        Caption = 'Delete'
        TabOrder = 2
        OnClick = btnDeleteClick
      end
    end
  end
  object pnlGrid: TPanel
    Left = 705
    Top = 60
    Width = 395
    Height = 590
    Align = alRight
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object gridCustomers: TDBGrid
      Left = 0
      Top = 0
      Width = 395
      Height = 590
      Align = alClient
      DataSource = dsCustomers
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -12
      TitleFont.Name = 'Segoe UI'
      TitleFont.Style = []
      OnCellClick = gridCustomersCellClick
    end
  end
  object pcDetails: TPageControl
    Left = 0
    Top = 60
    Width = 700
    Height = 590
    ActivePage = tsGeneral
    Align = alClient
    TabOrder = 2
    object tsGeneral: TTabSheet
      Caption = 'General'
      object lblCustName: TLabel
        Left = 16
        Top = 16
        Width = 94
        Height = 15
        Caption = 'Customer Name:'
      end
      object lblLegalName: TLabel
        Left = 16
        Top = 72
        Width = 67
        Height = 15
        Caption = 'Legal Name:'
      end
      object lblTaxID: TLabel
        Left = 16
        Top = 128
        Width = 130
        Height = 15
        Caption = 'Tax ID (VAT/EIN/CNPJ):'
      end
      object lblEmail: TLabel
        Left = 16
        Top = 184
        Width = 34
        Height = 15
        Caption = 'Email:'
      end
      object lblPhone: TLabel
        Left = 16
        Top = 240
        Width = 38
        Height = 15
        Caption = 'Phone:'
      end
      object lblWebsite: TLabel
        Left = 16
        Top = 296
        Width = 45
        Height = 15
        Caption = 'Website:'
      end
      object edtCustName: TEdit
        Left = 16
        Top = 37
        Width = 400
        Height = 23
        TabOrder = 0
      end
      object edtLegalName: TEdit
        Left = 16
        Top = 93
        Width = 400
        Height = 23
        TabOrder = 1
      end
      object edtTaxID: TEdit
        Left = 16
        Top = 149
        Width = 400
        Height = 23
        TabOrder = 2
      end
      object edtEmail: TEdit
        Left = 16
        Top = 205
        Width = 400
        Height = 23
        TabOrder = 3
      end
      object edtPhone: TEdit
        Left = 16
        Top = 261
        Width = 400
        Height = 23
        TabOrder = 4
      end
      object edtWebsite: TEdit
        Left = 16
        Top = 317
        Width = 400
        Height = 23
        TabOrder = 5
      end
      object chkActive: TCheckBox
        Left = 16
        Top = 360
        Width = 150
        Height = 17
        Caption = 'Active Account'
        Checked = True
        State = cbChecked
        TabOrder = 6
      end
    end
    object tsAddress: TTabSheet
      Caption = 'Address'
      ImageIndex = 1
      object lblAddress: TLabel
        Left = 16
        Top = 16
        Width = 89
        Height = 15
        Caption = 'Billing Address:'
      end
      object lblCity: TLabel
        Left = 16
        Top = 184
        Width = 27
        Height = 15
        Caption = 'City:'
      end
      object lblState: TLabel
        Left = 16
        Top = 240
        Width = 80
        Height = 15
        Caption = 'State/Province:'
      end
      object lblZip: TLabel
        Left = 16
        Top = 296
        Width = 90
        Height = 15
        Caption = 'Zip/Postal Code:'
      end
      object lblCountry: TLabel
        Left = 16
        Top = 352
        Width = 50
        Height = 15
        Caption = 'Country:'
      end
      object memAddress: TMemo
        Left = 16
        Top = 37
        Width = 400
        Height = 120
        Lines.Strings = (
          '')
        TabOrder = 0
      end
      object edtCity: TEdit
        Left = 16
        Top = 205
        Width = 400
        Height = 23
        TabOrder = 1
      end
      object edtState: TEdit
        Left = 16
        Top = 261
        Width = 400
        Height = 23
        TabOrder = 2
      end
      object edtZip: TEdit
        Left = 16
        Top = 317
        Width = 400
        Height = 23
        TabOrder = 3
      end
      object edtCountry: TEdit
        Left = 16
        Top = 373
        Width = 400
        Height = 23
        TabOrder = 4
      end
    end
    object tsFinancial: TTabSheet
      Caption = 'Financial'
      ImageIndex = 2
      object lblCreditLimit: TLabel
        Left = 16
        Top = 16
        Width = 68
        Height = 15
        Caption = 'Credit Limit:'
      end
      object lblNotes: TLabel
        Left = 16
        Top = 88
        Width = 83
        Height = 15
        Caption = 'Internal Notes:'
      end
      object edtCreditLimit: TEdit
        Left = 16
        Top = 37
        Width = 200
        Height = 23
        TabOrder = 0
        Text = '0'
      end
      object memNotes: TMemo
        Left = 16
        Top = 109
        Width = 600
        Height = 200
        Lines.Strings = (
          '')
        TabOrder = 1
      end
    end
  end
  object dsCustomers: TDataSource
    Left = 912
    Top = 128
  end
end
