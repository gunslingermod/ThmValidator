unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Chunks;

type
  TForm1 = class(TForm)
    Log: TMemo;
    btn_validate: TButton;
    check_autocorrect: TCheckBox;
    opendialog: TOpenDialog;
    procedure btn_validateClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btn_validateClick(Sender: TObject);
var
  i:integer;
  res:string;
begin
  opendialog.FileName:='';
  opendialog.Execute;
  if opendialog.Files.Count>0 then begin
    Log.Clear;
    for i:=0 to opendialog.Files.Count-1 do begin
      res := CheckBumpChunk(opendialog.Files[i], check_autocorrect.checked);
      if res<>'' then Log.Lines.Add(res);
    end;
    if Log.Lines.Count=0 then Log.Lines.Add('Validation completed - All OK.');
  end;

end;

end.
