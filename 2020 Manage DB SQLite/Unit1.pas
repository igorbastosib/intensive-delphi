unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Forms, FMX.Controls, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.FMXUI.Wait, FireDAC.Comp.UI, Data.DB,
  FireDAC.Comp.Client, FireDAC.DApt,


  System.IOUtils;

type
  TForm1 = class(TForm)
    Layout1: TLayout;
    Button1: TButton;
    FDConn: TFDConnection;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    Layout2: TLayout;
    Button2: TButton;
    Layout3: TLayout;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    function GetTables: TDataSet;
    function GetTableInfo(const ATable: string): TDataSet;
    procedure CreateDB;
    procedure UpdateDB;
    procedure DeleteDB;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
begin
  UpdateDB;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  DeleteDB;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  CreateDB;
end;

procedure TForm1.CreateDB;
var
  LPath: string;
  LFile: TextFile;
begin
{$IFDEF MSWINDOWS}
  LPath := System.SysUtils.GetCurrentDir;
{$ELSE}
  LPath := System.IOUtils.TPath.GetDocumentsPath;
{$ENDIF}
  LPath := System.IOUtils.TPath.Combine(LPath, 'Database');
  ForceDirectories(LPath);
  LPath := System.IOUtils.TPath.Combine(LPath, 'SeuArquivoDeBD.db');
  if not(FileExists(LPath)) then
  begin
    try
      AssignFile(LFile, LPath);
      Rewrite(LFile);
    finally
      CloseFile(LFile);
    end;
  end;
  FDConn.Params.Values['Database'] := LPath;
end;

procedure TForm1.DeleteDB;
begin
  FDConn.Connected := False;
  if FileExists(FDConn.Params.Values['Database']) then
    DeleteFile(FDConn.Params.Values['Database']);
end;

procedure TForm1.UpdateDB;
var
  LDSTables: TDataSet;
  LDSTableInfo: TDataSet;

  LTable: string;
  LField: string;
  LSqlCreatePerson: string;
begin
  try
    LDSTables := nil;
    LDSTableInfo := nil;

    LDSTables := GetTables;

// Criacao
    LSqlCreatePerson :=
      'CREATE TABLE Person (' + #13 +
      'Id INTEGER NOT NULL PRIMARY KEY,' + #13 +
      'FirstName VARCHAR(50) NOT NULL,' + #13 +
      'Email VARCHAR(100),' + #13 +
      'Birthday DATE' + #13 +
      ');'
      ;
    if not LDSTables.Locate('name', 'Person', []) then
    begin
      FDConn.ExecSQL(LSqlCreatePerson);
    end;

// Atualizacao
    begin
      LTable := 'Person';
      LDSTableInfo := GetTableInfo(LTable);

      LField := 'Email';
      if not(LDSTableInfo.Locate('name', LField, [])) then
        FDConn.ExecSQL('alter table ' + LTable + ' add column ' + LField + ' VARCHAR(100)');

      if (LDSTableInfo.Locate('name;pk', VarArrayOf(['Id', '0']), [])) then
      begin
        FDConn.ExecSQL('PRAGMA foreign_keys = OFF;');
        FDConn.ExecSQL('ALTER TABLE ' + LTable + ' RENAME TO ' +  LTable + '2;');
        FDConn.ExecSQL(LSqlCreatePerson);
        FDConn.ExecSQL(
          'insert into ' + LTable + #13 +
          'select' + #13 +
          'Id,' + #13 +
          'FirstName,' + #13 +
          'Email,' + #13 +
          'Birthday' + #13 +
          'from ' + LTable + '2'
          );
        FDConn.ExecSQL('DROP TABLE ' + LTable + '2;');
        FDConn.ExecSQL('PRAGMA foreign_keys = ON;');
      end;
    end;
  finally
    FreeAndNil(LDSTables);
  end;
end;

function TForm1.GetTableInfo(const ATable: string): TDataSet;
begin
  try
    Result := TFDQuery.Create(nil);
    TFDQuery(Result).Connection := FDConn;
    TFDQuery(Result).SQL.Add('PRAGMA table_info("' + ATable + '")');
    TFDQuery(Result).Open;
  except
    FreeAndNil(Result);
    raise ;
  end;
end;

function TForm1.GetTables: TDataSet;
begin
  try
    Result := TFDQuery.Create(nil);
    TFDQuery(Result).Connection := FDConn;
    TFDQuery(Result).SQL.Add('select name from sqlite_master where type="table"');
    TFDQuery(Result).Open;
  except
    FreeAndNil(Result);
    raise ;
  end;
end;

end.
