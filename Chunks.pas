unit Chunks;

interface
uses SysUtils, math, windows, classes, strutils;

type float=single;
function ReadString(f:THandle; terminator:byte = 0):string;
function FindChunk(id:integer; f:THandle; ContainerStartOffset:integer=0):integer;
function ReadUsedOMFs(path:string; container:TStrings):string;
function GetNextSubStr(var data:string; var buf:string; separator:char=char($00)):boolean;
function MakeRefChunk(container:TStrings; separator:char; cnt:integer=-1):string;
function SaveRefsData(path:string; container:TStrings):string;
function CheckBumpChunk(path:string; autocorrect:boolean):string;


implementation

function CheckBumpChunk(path:string; autocorrect:boolean):string;
var
  chunk_sz:integer;
  f:THandle;
  s:string;
  new_sz:cardinal;

  chunk_ids:array of cardinal;
  chunk_nonstring_data_sz:array of cardinal;

  i:integer;
  chunk_found:boolean;
begin
  result:='';

  f := FileOpen(path, fmOpenReadWrite+fmShareExclusive);
  if f=$FFFFFFFF then begin
    result:='Cannot open file: '+path+'. This file could be read-only!';
    exit;
  end;

  setlength(chunk_ids, 2);
  setlength(chunk_nonstring_data_sz, 2);
  chunk_ids[0]:=$817;
  chunk_nonstring_data_sz[0]:=8;
  chunk_ids[1]:=$818;
  chunk_nonstring_data_sz[1]:=0;

  chunk_found:=false;
  for i:=0 to length(chunk_ids)-1 do begin
    chunk_sz:=FindChunk(chunk_ids[i], f, 0);
    if chunk_sz>0 then begin
      chunk_found:=true;
      FileSeek(f, chunk_nonstring_data_sz[i], 1);
      s:=ReadString(f, 0);
      new_sz:=length(s)+chunk_nonstring_data_sz[i]+1;
      if new_sz<>chunk_sz then begin
        result:=result+path+': invalid size for chunk '+inttohex(chunk_ids[i], 4)+'!'+chr($0d)+chr($0a);
        if autocorrect then begin
          chunk_sz:=FindChunk(chunk_ids[i], f, 0);
          FileSeek(f, -4, 1);
          FileWrite(f, new_sz, 4);
        end;
      end;
    end;
  end;

  if not chunk_found then begin
    result:=path+': No BUMP chunks!';
  end;

  FileClose(f);
end;

function ReadUsedOMFs(path:string; container:TStrings):string;
var
  chunk_begin:integer;
  f:THandle;
  readstr, tmp:string;
begin
  result:='ERROR!';
  container.Clear;
  f := FileOpen(path, fmOpenReadWrite+fmShareExclusive);
  if f=$FFFFFFFF then begin
    result:='Cannot open file: '+path+'. This file could be read-only!';
    exit;
  end;

  chunk_begin:=FindChunk($18, f, 0);
  if chunk_begin>0 then begin
    //Игнорим  число аним
    FileSeek(f,4,1);
    while (true) do begin
      readstr:=ReadString(f);
      if trim(readstr)='' then
        break
      else
        container.Add(readstr);
    end;
    FileClose(f);
    result:='';
    exit;
  end else chunk_begin:=FindChunk($13, f, 0);

  if chunk_begin>0 then begin
    readstr:=ReadString(f);
    while GetNextSubStr(readstr, tmp, ',') do begin
      container.Add(tmp);
    end;
    FileClose(f);
    result:='';
    exit;
  end else begin
    result:='Cannot find references to OMFs! Animations may be included into the OGF or OGF has unsupported format.';
    FileClose(f);
    exit;
  end;


  FileClose(f);
  result:='';
end;

function SaveRefsData(path:string; container:TStrings):string;
var
  i, cnt:integer;
  f:THandle;
  ptr:integer;
  chunk:string;
begin
  result:='ERROR!';
  cnt:=container.Count;
  if cnt<=0 then begin
    result:='No data to save!';
    exit;
  end;

  f := FileOpen(path, fmOpenReadWrite+fmShareExclusive);
  if f=$FFFFFFFF then begin
    result:='Cannot open file: '+path;
    exit;
  end;

  ptr:=FindChunk($18, f, 0);
  if ptr>0 then begin
    //воспользуемся тем, что чанк со ссылками всегда последний
    SetEndOfFile(f);
    chunk:=MakeRefChunk(container, chr(0));
    FileSeek(f, -4, 1);
    i:=length(chunk)+4;
    FileWrite(f, i, 4);
    FileWrite(f, cnt, 4);
    i:=i-4;
    FileWrite(f, chunk[1], i);
    FileClose(f);
    result:='';
    exit;
  end else ptr:=FindChunk($13, f, 0);

  if ptr>0 then begin
    i:=MessageBox (0, PChar('File '+path+' seems to be old-formatted OGFv4. Due to format restrictions I cannot write more than 4 OMFs. Process file?'), 'Message', MB_YESNO);
    if i=ID_YES then begin
      SetEndOfFile(f);
      chunk:=MakeRefChunk(container, ',', 4);
      FileSeek(f, -4, 1);
      i:=length(chunk);
      FileWrite(f, i, 4);
      FileWrite(f, chunk[1], i);
    end;
    FileClose(f);
    result:='';
    exit;    
  end else begin
    result:='Cannot update file '+path;
    FileClose(f);
    exit;
  end;

  FileClose(f);
  result:='';
end;

function MakeRefChunk(container:TStrings; separator:char; cnt:integer=-1):string;
var i:integer;
begin
  result:='';
  if (cnt<0) or (cnt>container.Count) then cnt:=container.Count;
  for i:=0 to cnt-1 do begin
    result:=result+container[i]+separator;
  end;
  result[length(result)]:=chr(0);
end;


function FindChunk(id:integer; f:THandle; ContainerStartOffset:integer=0):integer;
var
  r_id:integer;
  r_size:integer;
  f_size:integer; //размер контейнера
  curpos:integer;
begin
  result:=-1;
  if ContainerStartOffset=0 then begin
    //контейнер чанков корневой
    f_size:=FileSeek(f,0,2);
    curpos:=FileSeek(f,0,0);
  end else begin
    //контейнер не корневой, ContainerStartOffset указывает, по какому смещению от начала файла находится его начало
    FileSeek(f,ContainerStartOffset-4,0);
    FileRead(f, f_size, 4);
//    messagebox(0,PChar('base:'+inttohex(ContainerStartOffset,8)+', findid: '+inttohex(id,2)+', csize: '+inttohex(f_size,8)), '', MB_OK);
    curpos:=0;
  end;

  if (f_size=-1) or (curpos=-1) then exit;

  while curpos<f_size do begin
    FileRead(f, r_id, 4);
    r_id := r_id and $0000ffff;
    FileRead(f, r_size, 4);
    if r_id=id then begin
      result:=r_size;
      exit;
    end;
    curpos:=FileSeek(f,r_size,1)-ContainerStartOffset;
  end;

end;

function ReadString(f:THandle; terminator:byte = 0):string;
var
symbol:byte;
res:integer;
begin
  result:='';
  while(true) do begin
    res:=FileRead(f, symbol, 1);
    if (symbol=terminator) or (res=0) then begin
      exit;
    end else begin
      result:=result+char(symbol);
    end;
  end;
end;

function GetNextSubStr(var data:string; var buf:string; separator:char=char($00)):boolean;
var p, i:integer;
begin
  p:=0;
  for i:=1 to length(data) do begin
    if data[i]=separator then begin
      p:=i;
      break;
    end;
  end;

  if p>0 then begin
    buf:=leftstr(data, p-1);
    buf:=trim(buf);
    data:=rightstr(data, length(data)-p);
    data:=trim(data);
    result:=true;
  end else begin
    if trim(data)<>'' then begin
      buf:=trim(data);
      data:='';
      result:=true;
    end else result:=false;
  end;
end;
end.
