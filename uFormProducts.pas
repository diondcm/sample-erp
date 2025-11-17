unit uFormProducts;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBaseForm, FireDAC.Comp.Client, Data.DB,
  FireDAC.Stan.Param, Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids, Vcl.ExtCtrls, Vcl.Mask,
  FireDAC.DApt, Vcl.ExtDlgs, Vcl.Imaging.jpeg, Vcl.Imaging.pngimage;

type
  TfrmProducts = class(TfrmBase) // Inherits from our Architecture Base
    pnlControls: TPanel;
    grdProducts: TDBGrid;
    lblSKU: TLabel;
    edtSKU: TEdit;
    lblName: TLabel;
    edtName: TEdit;
    lblFCC: TLabel;
    edtFCC: TEdit;
    lblMSRP: TLabel;
    edtMSRP: TEdit;
    btnSave: TButton;
    btnDelete: TButton;
    dsProducts: TDataSource;
    pnlImages: TPanel;
    imgProduct1: TImage;
    imgProduct2: TImage;
    imgProduct3: TImage;
    lblImagesInfo: TLabel;
    lblCategory: TLabel;
    edtCategory: TEdit;
    lblStockLevel: TLabel;
    edtStockLevel: TEdit;
    lblWarrantyMonths: TLabel;
    edtWarrantyMonths: TEdit;
    btnLoadImage1: TButton;
    btnLoadImage2: TButton;
    btnLoadImage3: TButton;
    btnClearImage1: TButton;
    btnClearImage2: TButton;
    btnClearImage3: TButton;
    btnNew: TButton;

    procedure FormCreate(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure grdProductsCellClick(Column: TColumn);
    procedure btnLoadImage1Click(Sender: TObject);
    procedure btnLoadImage2Click(Sender: TObject);
    procedure btnLoadImage3Click(Sender: TObject);
    procedure btnClearImage1Click(Sender: TObject);
    procedure btnClearImage2Click(Sender: TObject);
    procedure btnClearImage3Click(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FQuery: TFDQuery;
    FCurrentProductID: Integer;
    procedure RefreshGrid;
    procedure ClearInputs;
    procedure LoadImages(AProductID: Integer);
    procedure SaveImages(AProductID: Integer);
    procedure LoadImageToControl(AImageControl: TImage; AImageIndex: Integer);
    procedure ClearImage(AImageControl: TImage);
  protected
    procedure ApplyTheme; override;
    procedure ApplyLanguage; override;
  public
    constructor Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage); override;
  end;

implementation

{$R *.dfm}

constructor TfrmProducts.Create(AOwner: TComponent; AConn: TFDConnection; ATheme: TAppTheme; ALang: TAppLanguage);
begin
  // 1. Call the Magic Constructor of the Base
  inherited Create(AOwner, AConn, ATheme, ALang);

  // 2. Setup internal Query using the INJECTED connection
  FQuery := TFDQuery.Create(Self);
  FQuery.Connection := DBConnection;

  dsProducts.DataSet := FQuery;
  FCurrentProductID := -1;

  RefreshGrid;
end;

procedure TfrmProducts.FormCreate(Sender: TObject);
begin
  // VCL Init if needed
  // Images setup
  imgProduct1.Stretch := True;
  imgProduct2.Stretch := True;
  imgProduct3.Stretch := True;

  imgProduct1.Center := True;
  imgProduct2.Center := True;
  imgProduct3.Center := True;
end;

procedure TfrmProducts.FormDestroy(Sender: TObject);
begin
  if Assigned(FQuery) then
    FQuery.Free;
end;

// --- CRUD OPERATIONS ---

procedure TfrmProducts.RefreshGrid;
begin
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT * FROM Products ORDER BY Name';
  FQuery.Open;
end;

procedure TfrmProducts.btnNewClick(Sender: TObject);
begin
  ClearInputs;
  FCurrentProductID := -1;
  edtSKU.SetFocus;
end;

procedure TfrmProducts.btnSaveClick(Sender: TObject);
var
  SQL: string;
  NewProductID: Integer;
  qryCheck: TFDQuery;
begin
  // Validation
  if Trim(edtSKU.Text) = '' then
  begin
    ShowMessage('SKU is required!');
    edtSKU.SetFocus;
    Exit;
  end;

  if Trim(edtName.Text) = '' then
  begin
    ShowMessage('Product Name is required!');
    edtName.SetFocus;
    Exit;
  end;

  qryCheck := TFDQuery.Create(nil);
  try
    qryCheck.Connection := DBConnection;

    // Check if this is an update or insert
    if FCurrentProductID > 0 then
    begin
      // UPDATE existing product
      SQL := 'UPDATE Products SET SKU = :sku, Name = :name, Category = :cat, ' +
             'MSRP = :msrp, StockLevel = :stock, FCC_ID = :fcc, WarrantyMonths = :warranty ' +
             'WHERE ProductID = :id';

      DBConnection.ExecSQL(SQL, [
        edtSKU.Text,
        edtName.Text,
        edtCategory.Text,
        StrToFloatDef(edtMSRP.Text, 0),
        StrToIntDef(edtStockLevel.Text, 0),
        edtFCC.Text,
        StrToIntDef(edtWarrantyMonths.Text, 0),
        FCurrentProductID
      ]);

      NewProductID := FCurrentProductID;
    end
    else
    begin
      // INSERT new product
      SQL := 'INSERT INTO Products (SKU, Name, Category, MSRP, StockLevel, FCC_ID, WarrantyMonths) ' +
             'VALUES (:sku, :name, :cat, :msrp, :stock, :fcc, :warranty)';

      DBConnection.ExecSQL(SQL, [
        edtSKU.Text,
        edtName.Text,
        edtCategory.Text,
        StrToFloatDef(edtMSRP.Text, 0),
        StrToIntDef(edtStockLevel.Text, 0),
        edtFCC.Text,
        StrToIntDef(edtWarrantyMonths.Text, 0)
      ]);

      // Get the new ProductID
      qryCheck.SQL.Text := 'SELECT last_insert_rowid() AS NewID';
      qryCheck.Open;
      NewProductID := qryCheck.FieldByName('NewID').AsInteger;
      qryCheck.Close;
    end;

    // Save images
    SaveImages(NewProductID);

    RefreshGrid;
    ClearInputs;
    ShowMessage('Product saved successfully!');

  finally
    qryCheck.Free;
  end;
end;

procedure TfrmProducts.btnDeleteClick(Sender: TObject);
begin
  if not FQuery.IsEmpty then
  begin
    if MessageDlg('Are you sure you want to delete this product?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      DBConnection.ExecSQL('DELETE FROM Products WHERE ProductID = :id', [FQuery.FieldByName('ProductID').AsInteger]);
      RefreshGrid;
      ClearInputs;
      ShowMessage('Product deleted successfully!');
    end;
  end
  else
    ShowMessage('No product selected!');
end;

procedure TfrmProducts.grdProductsCellClick(Column: TColumn);
begin
  if not FQuery.IsEmpty then
  begin
    FCurrentProductID := FQuery.FieldByName('ProductID').AsInteger;
    edtSKU.Text  := FQuery.FieldByName('SKU').AsString;
    edtName.Text := FQuery.FieldByName('Name').AsString;
    edtCategory.Text := FQuery.FieldByName('Category').AsString;
    edtMSRP.Text := FQuery.FieldByName('MSRP').AsString;
    edtStockLevel.Text := FQuery.FieldByName('StockLevel').AsString;
    edtFCC.Text  := FQuery.FieldByName('FCC_ID').AsString;
    edtWarrantyMonths.Text := FQuery.FieldByName('WarrantyMonths').AsString;

    LoadImages(FCurrentProductID);
  end;
end;

procedure TfrmProducts.LoadImages(AProductID: Integer);
var
  qryImages: TFDQuery;
  ImageIndex: Integer;
begin
  // Clear all images first
  ClearImage(imgProduct1);
  ClearImage(imgProduct2);
  ClearImage(imgProduct3);

  qryImages := TFDQuery.Create(nil);
  try
    qryImages.Connection := DBConnection;
    qryImages.SQL.Text := 'SELECT ImageID, ImageData FROM ProductImages WHERE ProductID = :id ORDER BY ImageID';
    qryImages.ParamByName('id').AsInteger := AProductID;
    qryImages.Open;

    ImageIndex := 0;
    while not qryImages.Eof do
    begin
      case ImageIndex of
        0: LoadImageToControl(imgProduct1, ImageIndex);
        1: LoadImageToControl(imgProduct2, ImageIndex);
        2: LoadImageToControl(imgProduct3, ImageIndex);
      end;

      Inc(ImageIndex);
      qryImages.Next;

      if ImageIndex >= 3 then
        Break; // Max 3 images
    end;

  finally
    qryImages.Free;
  end;
end;

procedure TfrmProducts.LoadImageToControl(AImageControl: TImage; AImageIndex: Integer);
var
  qryImages: TFDQuery;
  Stream: TMemoryStream;
begin
  qryImages := TFDQuery.Create(nil);
  Stream := TMemoryStream.Create;
  try
    qryImages.Connection := DBConnection;
    qryImages.SQL.Text := 'SELECT ImageData FROM ProductImages WHERE ProductID = :id ORDER BY ImageID LIMIT 1 OFFSET :offset';
    qryImages.ParamByName('id').AsInteger := FCurrentProductID;
    qryImages.ParamByName('offset').AsInteger := AImageIndex;
    qryImages.Open;

    if not qryImages.IsEmpty and not qryImages.FieldByName('ImageData').IsNull then
    begin
      TBlobField(qryImages.FieldByName('ImageData')).SaveToStream(Stream);
      Stream.Position := 0;
      AImageControl.Picture.LoadFromStream(Stream);
    end;

  finally
    Stream.Free;
    qryImages.Free;
  end;
end;

procedure TfrmProducts.SaveImages(AProductID: Integer);
var
  Stream: TMemoryStream;
  qryDelete: TFDQuery;

  procedure SaveImageControl(AImage: TImage);
  var
    SQL: string;
  begin
    if Assigned(AImage.Picture.Graphic) and not AImage.Picture.Graphic.Empty then
    begin
      Stream.Clear;
      AImage.Picture.SaveToStream(Stream);
      Stream.Position := 0;

      SQL := 'INSERT INTO ProductImages (ProductID, ImageData) VALUES (:pid, :data)';
      DBConnection.ExecSQL(SQL, [AProductID, Stream]);
    end;
  end;

begin
  // First, delete all existing images for this product
  qryDelete := TFDQuery.Create(nil);
  Stream := TMemoryStream.Create;
  try
    qryDelete.Connection := DBConnection;
    qryDelete.ExecSQL('DELETE FROM ProductImages WHERE ProductID = :id', [AProductID]);

    // Save up to 3 images
    SaveImageControl(imgProduct1);
    SaveImageControl(imgProduct2);
    SaveImageControl(imgProduct3);

  finally
    Stream.Free;
    qryDelete.Free;
  end;
end;

procedure TfrmProducts.btnLoadImage1Click(Sender: TObject);
var
  OpenDialog: TOpenPictureDialog;
begin
  OpenDialog := TOpenPictureDialog.Create(nil);
  try
    OpenDialog.Filter := 'Image Files|*.bmp;*.jpg;*.jpeg;*.png;*.gif';
    if OpenDialog.Execute then
    begin
      imgProduct1.Picture.LoadFromFile(OpenDialog.FileName);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TfrmProducts.btnLoadImage2Click(Sender: TObject);
var
  OpenDialog: TOpenPictureDialog;
begin
  OpenDialog := TOpenPictureDialog.Create(nil);
  try
    OpenDialog.Filter := 'Image Files|*.bmp;*.jpg;*.jpeg;*.png;*.gif';
    if OpenDialog.Execute then
    begin
      imgProduct2.Picture.LoadFromFile(OpenDialog.FileName);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TfrmProducts.btnLoadImage3Click(Sender: TObject);
var
  OpenDialog: TOpenPictureDialog;
begin
  OpenDialog := TOpenPictureDialog.Create(nil);
  try
    OpenDialog.Filter := 'Image Files|*.bmp;*.jpg;*.jpeg;*.png;*.gif';
    if OpenDialog.Execute then
    begin
      imgProduct3.Picture.LoadFromFile(OpenDialog.FileName);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TfrmProducts.btnClearImage1Click(Sender: TObject);
begin
  ClearImage(imgProduct1);
end;

procedure TfrmProducts.btnClearImage2Click(Sender: TObject);
begin
  ClearImage(imgProduct2);
end;

procedure TfrmProducts.btnClearImage3Click(Sender: TObject);
begin
  ClearImage(imgProduct3);
end;

procedure TfrmProducts.ClearImage(AImageControl: TImage);
begin
  AImageControl.Picture := nil;
end;

procedure TfrmProducts.ClearInputs;
begin
  edtSKU.Clear;
  edtName.Clear;
  edtCategory.Clear;
  edtMSRP.Clear;
  edtStockLevel.Clear;
  edtFCC.Clear;
  edtWarrantyMonths.Clear;

  ClearImage(imgProduct1);
  ClearImage(imgProduct2);
  ClearImage(imgProduct3);

  FCurrentProductID := -1;
end;

// --- ARCHITECTURE OVERRIDES ---

procedure TfrmProducts.ApplyTheme;
begin
  inherited; // Sets Form Color

  if AppTheme = atDark then
  begin
    pnlControls.Color := $002B1E16;
    pnlImages.Color := $002B1E16;
    grdProducts.Color := $00382E26; // Slightly lighter than background
    grdProducts.Font.Color := clWhite;
    grdProducts.TitleFont.Color := clWhite;

    lblSKU.Font.Color := clSilver;
    lblName.Font.Color := clSilver;
    lblCategory.Font.Color := clSilver;
    lblMSRP.Font.Color := clSilver;
    lblStockLevel.Font.Color := clSilver;
    lblFCC.Font.Color := clSilver;
    lblWarrantyMonths.Font.Color := clSilver;
    lblImagesInfo.Font.Color := clSilver;

    edtSKU.Color := $00382E26;
    edtName.Color := $00382E26;
    edtCategory.Color := $00382E26;
    edtMSRP.Color := $00382E26;
    edtStockLevel.Color := $00382E26;
    edtFCC.Color := $00382E26;
    edtWarrantyMonths.Color := $00382E26;

    edtSKU.Font.Color := clWhite;
    edtName.Font.Color := clWhite;
    edtCategory.Font.Color := clWhite;
    edtMSRP.Font.Color := clWhite;
    edtStockLevel.Font.Color := clWhite;
    edtFCC.Font.Color := clWhite;
    edtWarrantyMonths.Font.Color := clWhite;
  end
  else
  begin
    pnlControls.Color := clWhite;
    pnlImages.Color := clWhite;
    grdProducts.Color := clWhite;
    grdProducts.Font.Color := clBlack;
    grdProducts.TitleFont.Color := clBlack;

    lblSKU.Font.Color := clBlack;
    lblName.Font.Color := clBlack;
    lblCategory.Font.Color := clBlack;
    lblMSRP.Font.Color := clBlack;
    lblStockLevel.Font.Color := clBlack;
    lblFCC.Font.Color := clBlack;
    lblWarrantyMonths.Font.Color := clBlack;
    lblImagesInfo.Font.Color := clBlack;

    edtSKU.Color := clWhite;
    edtName.Color := clWhite;
    edtCategory.Color := clWhite;
    edtMSRP.Color := clWhite;
    edtStockLevel.Color := clWhite;
    edtFCC.Color := clWhite;
    edtWarrantyMonths.Color := clWhite;

    edtSKU.Font.Color := clBlack;
    edtName.Font.Color := clBlack;
    edtCategory.Font.Color := clBlack;
    edtMSRP.Font.Color := clBlack;
    edtStockLevel.Font.Color := clBlack;
    edtFCC.Font.Color := clBlack;
    edtWarrantyMonths.Font.Color := clBlack;
  end;
end;

procedure TfrmProducts.ApplyLanguage;
begin
  inherited;

  // Simple Switch based on Context
  case AppLanguage of
    alEnglish:
      begin
        Caption := 'Product Management - Electronics';
        lblSKU.Caption := 'SKU (Stock Keeping Unit):';
        lblName.Caption := 'Product Name:';
        lblCategory.Caption := 'Category:';
        lblMSRP.Caption := 'MSRP (USD):';
        lblStockLevel.Caption := 'Stock Level:';
        lblFCC.Caption := 'FCC ID (Reg.):';
        lblWarrantyMonths.Caption := 'Warranty (Months):';
        lblImagesInfo.Caption := 'Product Images (Max 3):';
        btnSave.Caption := 'Save Product';
        btnDelete.Caption := 'Delete Product';
        btnNew.Caption := 'New Product';
        btnLoadImage1.Caption := 'Load';
        btnLoadImage2.Caption := 'Load';
        btnLoadImage3.Caption := 'Load';
        btnClearImage1.Caption := 'Clear';
        btnClearImage2.Caption := 'Clear';
        btnClearImage3.Caption := 'Clear';
      end;
    alPortuguese:
      begin
        Caption := 'Gestão de Produtos - Eletrônicos';
        lblSKU.Caption := 'SKU (Unidade de Estoque):';
        lblName.Caption := 'Nome do Produto:';
        lblCategory.Caption := 'Categoria:';
        lblMSRP.Caption := 'MSRP (USD):';
        lblStockLevel.Caption := 'Nível de Estoque:';
        lblFCC.Caption := 'ID FCC (Regulação):';
        lblWarrantyMonths.Caption := 'Garantia (Meses):';
        lblImagesInfo.Caption := 'Imagens do Produto (Máx 3):';
        btnSave.Caption := 'Salvar Produto';
        btnDelete.Caption := 'Excluir Produto';
        btnNew.Caption := 'Novo Produto';
        btnLoadImage1.Caption := 'Carregar';
        btnLoadImage2.Caption := 'Carregar';
        btnLoadImage3.Caption := 'Carregar';
        btnClearImage1.Caption := 'Limpar';
        btnClearImage2.Caption := 'Limpar';
        btnClearImage3.Caption := 'Limpar';
      end;
    alSpanish:
      begin
        Caption := 'Gestión de Productos - Electrónicos';
        lblSKU.Caption := 'SKU (Unidad de Inventario):';
        lblName.Caption := 'Nombre del Producto:';
        lblCategory.Caption := 'Categoría:';
        lblMSRP.Caption := 'MSRP (USD):';
        lblStockLevel.Caption := 'Nivel de Stock:';
        lblFCC.Caption := 'ID FCC (Regulación):';
        lblWarrantyMonths.Caption := 'Garantía (Meses):';
        lblImagesInfo.Caption := 'Imágenes del Producto (Máx 3):';
        btnSave.Caption := 'Guardar Producto';
        btnDelete.Caption := 'Eliminar Producto';
        btnNew.Caption := 'Nuevo Producto';
        btnLoadImage1.Caption := 'Cargar';
        btnLoadImage2.Caption := 'Cargar';
        btnLoadImage3.Caption := 'Cargar';
        btnClearImage1.Caption := 'Limpiar';
        btnClearImage2.Caption := 'Limpiar';
        btnClearImage3.Caption := 'Limpiar';
      end;
  end;
end;

end.
