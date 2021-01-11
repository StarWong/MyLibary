unit MultiProgressbar;

interface

uses
  SysUtils, Classes, Controls, ExtCtrls, Graphics, SyncObjs,
  Generics.Collections;

type
  TMultiProgressbar = class(TImage)
  private
    type
      PDrawStyle = ^TDrawStyle;

      TDrawStyle = record
        totalValue: UInt64;
        CurrValue: UInt64;
        var
          brush: record
            Color: TColor;
            Style: TBrushStyle;
          end;
        var
          pen: record
            Style: TPenStyle;
            Width: Cardinal;
          end;
      end;

      TDrawStyles = array of TDrawStyle;

      TStatus = record
        percentage: Single;
        color: TColor;
      end;
    const
      MaxValue = 100;
      DrawStyle: TDrawStyle = (
    totalValue: $FFFFFFFFFFFFFFFF;
    CurrValue: 0;
    brush: (
    color: 0;
    Style: bsSolid
  );
    pen: (
    Style: psClear;
    Width: 1
  );
  );
  strict private
    FDrawStyles: TDrawStyles;
    Fborder: LongBool;
    sync: TCriticalSection;

    FBackgroundColor, FBorderColor: TColor;
    FTasks: Cardinal;
    FRunning: LongBool;
    FTotalValue: Cardinal;
    FImgWidth: Cardinal;
    FList: array of PDrawStyle;
  strict private
    procedure TakeSnapshot(const B:TBitmap);
    procedure SetTasks(const count: Cardinal);
    procedure Sort;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    procedure DrawEx;
    procedure SetLength(const nIndex: Cardinal; const NewLength: UInt64);
    procedure AddLength(const nIndex: Cardinal; const Length: UInt64);
    procedure mStart;
    procedure mStop;
  public
    property DrawStyles: TDrawStyles read FDrawStyles write FDrawStyles;
  published
    property BackgroundColor: TColor read FBackgroundColor write FBackgroundColor;
    property border: LongBool read Fborder write Fborder;
    property nTasks: Cardinal read FTasks write SetTasks;
    property TotalValue: Cardinal read FTotalValue write FTotalValue;
    property BorderColor: TColor read FBorderColor write FBorderColor;
  end;

procedure Register;

implementation
procedure Register;
begin
  RegisterComponents('Additional', [TMultiProgressbar]);
end;

//function InterlockedCompareExchange64(var Destination:UInt64;ExChange,Comperand:UInt64):UInt64;
//stdcall;external 'kernel32.dll' name 'InterlockedCompareExchange64';
//function  InterlockedExchangeAdd64(var Addend: UInt64; Value: UInt64): UInt64;
//begin
//    repeat
//    Result := Addend;
//  until (InterlockedCompareExchange64(Addend, Result + Value, Result) = Result);
//end;

{ TMultiProgressbar }

function InterlockedExchange(var LongBool;value:LongBool):LongBool;
stdcall;external 'kernel32.dll' name 'InterlockedExchange';

procedure TMultiProgressbar.AddLength(const nIndex: Cardinal; const Length: UInt64);
begin
  sync.Enter;
  FDrawStyles[nIndex].CurrValue := FDrawStyles[nIndex].CurrValue + Length;
  Self.Repaint;
  sync.Leave;
end;

constructor TMultiProgressbar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRunning := False;
  FTotalValue := MaxValue;
  sync:=TCriticalSection.Create;
end;

destructor TMultiProgressbar.Destroy;
begin
  FreeAndNil(sync);
  sync.Free;
  inherited;
end;


procedure TMultiProgressbar.DrawEx;
var
B: TBitmap;
begin
  if not FRunning then Exit;
  if FTotalValue <> 0 then
  begin
  B := TBitmap.Create;
  try
  B.Width := Self.Width;
  B.Height := Self.Height;
  B.Canvas.Brush.Color := FBackgroundColor;
  B.Canvas.Brush.Style := bsSolid;
  B.Canvas.Pen.Style := psClear;
  B.Canvas.Pen.Width := 1;
  FImgWidth := Self.Width;
  B.Canvas.FillRect(Rect(0, 0, B.Width, B.Height));
  Self.TakeSnapshot(B);
  B.Canvas.Pen.Color := BorderColor;
  B.Canvas.Pen.Style := psSolid;
  B.Canvas.Brush.Style := bsClear;
  B.Canvas.Rectangle(0, 0, B.Width, B.Height);
  Self.Picture.Assign(B);
  finally
     FreeAndNil(B);
  end;
  end;
end;

procedure TMultiProgressbar.SetLength(const nIndex: Cardinal; const NewLength: UInt64);
begin
  sync.Enter;
  FDrawStyles[nIndex].CurrValue := NewLength;
  //Self.Repaint;
  sync.Leave;
end;

procedure TMultiProgressbar.SetTasks(const count: Cardinal);
var
  I: Integer;
begin
  System.SetLength(Self.FDrawStyles, count);
  System.SetLength(Self.FList, count);
  FTasks := count;
  if FTasks > 0 then
  begin
    for I := 0 to FTasks - 1 do
    begin
      Self.FDrawStyles[I] := DrawStyle;
    end;
  end;

end;

procedure TMultiProgressbar.TakeSnapshot(const B:TBitmap);
var
  I: Cardinal;

  procedure draw(const index: Cardinal);
  begin
    B.Canvas.Brush.Color := Self.FDrawStyles[index].brush.Color;
    if (Self.FDrawStyles[index].CurrValue / Self.FDrawStyles[index].totalValue) > 1 then
      B.Canvas.FillRect(Rect(0, 0, Self.FImgWidth, B.Height))
    else
      B.Canvas.FillRect(
      Rect(0, 0, Trunc((Self.FDrawStyles[index].CurrValue / Self.FDrawStyles[index].totalValue) * Self.FImgWidth), B.Height)
      );
  end;

begin
  case FTasks of
    0:
      begin
        Exit;
      end;
    1:
      begin
        draw(0);
      end;
  else
    begin
      FillChar(FList[0], FTasks, #0);
      for I := 0 to FTasks - 1 do
      begin
        FList[I] := @(Self.FDrawStyles[I]);
      end;
      Self.Sort;
      for I := 0 to FTasks - 2 do
      begin
        draw(I);
      end;
    end;
  end;

end;

procedure TMultiProgressbar.Sort;
var
  I, J: Cardinal;
  Len: Cardinal;

  function GetMax(var index: Cardinal): LongBool;
  var
    _I: Cardinal;
    tmp: PDrawStyle;
  begin
    Result := True;
    for _I := 0 to index do
    begin
      if Flist[_I].CurrValue < Flist[_I + 1].CurrValue then
      begin
        tmp := Flist[_I];
        Flist[_I] := Flist[_I + 1];
        Flist[_I + 1] := tmp;
      end;
    end;
    if index = 0 then
      Result := False
    else
      Dec(index);
  end;

begin
  Len := Self.FTasks;
  case Len of
    0:
      begin
        Exit;
      end;
    1:
      begin
        Exit;
      end;
  else
    begin
      J := Len - 2;
      for I := 0 to J do
      begin
        if not GetMax(J) then
          Break;
      end;
    end;
  end;
end;

procedure TMultiProgressbar.mStart;
begin
  InterlockedExchange(self.FRunning,True);
end;

 procedure TMultiProgressbar.mStop;
 begin
 InterlockedExchange(self.FRunning,False);
 end;



end.

