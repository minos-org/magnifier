unit BitmapThreads;

{$MODE DELPHI}{$H+}

interface

uses
  Classes, SysUtils, Graphics, UTF8Process, Math;

type
  PerformAction = (PixelRepetitionAction, BilinearAction, CatmullRomAction);

type ThreadArray = array of TThread;

type

  { TPerformThread }

  TPerformThread = class(TThread)
  private
    procedure PixelRepetition;
    procedure Bilinear;
    procedure CatmullRomEnlarge;
    procedure RawContrast;
    function CatmullRom(X: Single): Single;
  protected
    procedure Execute; override;
  public
    PAction: PerformAction;
    RStartY, REndY: Integer;
    FImageData, RImageData: PByte;
    FBytesPerPixel, RBytesPerPixel: Integer;
    FBytesPerLine, RBytesPerLine: Integer;
    FWidth, FHeight: Integer;
    RWidth, RHeight: Integer;
    FM : Single;
    Invert: Boolean;
    Completed: Boolean;
    Contrast: Integer;
    constructor Create;
  end;

type

  { TBitmapHandler }

  TBitmapHandler = class
  private
    ThreadList: ThreadArray;
    ThreadCount, NumThreadsFinished : Integer;
    OnTerminate: TNotifyEvent;
    procedure ThreadCompleted(Sender: TObject);
  public
    FBitmap: ^TBitmap;
    Bitmap: TBitmap;
    BitmapWidth, BitmapHeight: Integer;
    PAction: PerformAction;
    FM: Single;
    Invert: Boolean;
    Contrast: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure BackgroundPerform(AOnTerminate: TNotifyEvent);
    procedure Start;
    procedure Reset;
  end;

implementation

constructor TPerformThread.Create;
begin
  Completed := False;
  Contrast := 0;
  inherited Create(True);
end;

procedure TPerformThread.PixelRepetition;
var
  K, L, I, J : Integer;
  X, Y : Single;
  RPixelPtr: PByte;
  Ptr : PByte;
  Blue, Green, Red: Integer;
  UserContrast, Factor, NewValue : Single;
begin
  if Contrast > 126 then Contrast := 126;
  if Contrast < 0 then Contrast := 0;

  if (Contrast > 0) then
  begin
    UserContrast := Contrast / 127.0;
    Factor := Tan((UserContrast + 1) * Pi / 4);
  end;

  for L := RStartY to REndY - 1 do
  begin
    Y := L / FM;
    I := Trunc(Y);
    if I >= FHeight then I := FHeight - 1;

    for K := 0 to RWidth - 1 do
    begin
      X := K / FM;
      J := Trunc(X);
      if J >= FWidth then J := FWidth - 1;

      RPixelPtr := PByte(RImageData) + L * RBytesPerLine + K * RBytesPerPixel;
      Ptr := PByte(FImageData) + I * FBytesPerLine + J * FBytesPerPixel;
      Blue := Ptr^;
      Green := (Ptr+1)^;
      Red := (Ptr+2)^;

      if (Contrast > 0) then
      begin
        NewValue := (Blue - 128) * Factor + 128;
        if (NewValue > 255) then NewValue := 255
        else if (NewValue < 0) then NewValue := 0;
        Blue := Round(NewValue);

        NewValue := (Green - 128) * Factor + 128;
        if (NewValue > 255) then NewValue := 255
        else if (NewValue < 0) then NewValue := 0;
        Green := Round(NewValue);

        NewValue := (Red - 128) * Factor + 128;
        if (NewValue > 255) then NewValue := 255
        else if (NewValue < 0) then NewValue := 0;
        Red := Round(NewValue);
      end;

      if Invert then
      begin
        RPixelPtr^ := 255 - Blue;
        (RPixelPtr + 1)^ := 255 - Green;
        (RPixelPtr + 2)^ := 255 - Red;
      end
      else begin
        RPixelPtr^ := Blue;
        (RPixelPtr + 1)^ := Green;
        (RPixelPtr + 2)^ := Red;
      end;
      if Terminated then Exit;
      end;
    if Terminated then Exit;
    end;
  Completed := True;
end;

procedure TPerformThread.Bilinear;
var
  K, L, I1, I2, J1, J2 : Integer;
  X, Y, A, B : Single;
  RPixelPtr: PByte;
  P11Ptr, P12Ptr, P21Ptr, P22Ptr : PByte;
  Blue11, Green11, Red11: Byte;
  Blue12, Green12, Red12: Byte;
  Blue21, Green21, Red21: Byte;
  Blue22, Green22, Red22: Byte;
  Blue, Green, Red: Integer;
  UserContrast, Factor, NewValue : Single;
begin
  if Contrast > 126 then Contrast := 126;
  if Contrast < 0 then Contrast := 0;

  if (Contrast > 0) then
  begin
    UserContrast := Contrast / 127.0;
    Factor := Tan((UserContrast + 1) * Pi / 4);
  end;

  for L := RStartY to REndY - 1 do
  begin
    Y := L / FM;
    I1 := Trunc(Y);
    A := Y - I1;
    I2 := I1 + 1;
    if I1 >= FHeight then I1 := FHeight - 1;
    if I2 >= FHeight then I2 := FHeight - 1;
    RPixelPtr := PByte(RImageData) + L * RBytesPerLine;

    for K := 0 to RWidth - 1 do
    begin
      X := K / FM;
      J1 := Trunc(X);
      B := X - J1;
      J2 := J1 + 1;
      if J2 >= FWidth then J2 := J1;

      P11Ptr := PByte(FImageData) + I1 * FBytesPerLine + J1 * FBytesPerPixel;
      P12Ptr := PByte(FImageData) + I1 * FBytesPerLine + J2 * FBytesPerPixel;
      P21Ptr := PByte(FImageData) + I2 * FBytesPerLine + J1 * FBytesPerPixel;
      P22Ptr := PByte(FImageData) + I2 * FBytesPerLine + J2 * FBytesPerPixel;

      Blue11 := P11Ptr^; Green11 := (P11Ptr+1)^; Red11 := (P11Ptr+2)^;
      Blue12 := P12Ptr^; Green12 := (P12Ptr+1)^; Red12 := (P12Ptr+2)^;
      Blue21 := P21Ptr^; Green21 := (P21Ptr+1)^; Red21 := (P21Ptr+2)^;
      Blue22 := P22Ptr^; Green22 := (P22Ptr + 1)^; Red22 := (P22Ptr + 2)^;

      Blue := Round(Blue11 * (1 - A) * (1 - B) + Blue12 * (1 - A) * B + Blue21 * A * (1 - B) + Blue22 * A * B);
      Green :=  Round(Green11 * (1 - A) * (1 - B) + Green12 * (1 - A) * B + Green21 * A * (1 - B) + Green22 * A * B);
      Red := Round(Red11 * (1 - A) * (1 - B) + Red12 * (1 - A) * B + Red21 * A * (1 - B) + Red22 * A * B);

      if (Contrast > 0) then
      begin
        NewValue := (Blue - 128) * Factor + 128;
        if (NewValue > 255) then NewValue := 255
        else if (NewValue < 0) then NewValue := 0;
        Blue := Round(NewValue);

        NewValue := (Green - 128) * Factor + 128;
        if (NewValue > 255) then NewValue := 255
        else if (NewValue < 0) then NewValue := 0;
        Green := Round(NewValue);

        NewValue := (Red - 128) * Factor + 128;
        if (NewValue > 255) then NewValue := 255
        else if (NewValue < 0) then NewValue := 0;
        Red := Round(NewValue);
      end;

      if Invert then
      begin
        RPixelPtr^ := 255 - Blue;
        (RPixelPtr + 1)^ := 255 - Green;
        (RPixelPtr + 2)^ := 255 - Red;
      end
      else begin
        RPixelPtr^ := Blue;
        (RPixelPtr + 1)^ := Green;
        (RPixelPtr + 2)^ := Red;
      end;
      Inc(RPixelPtr, RBytesPerPixel);
      if Terminated then Exit;
    end;
    if Terminated then Exit;
  end;
  Completed := True;
end;

procedure TPerformThread.CatmullRomEnlarge;
var
  CA: Array of Array of Single;
  K, L, I0, I1, I2, I3, J0, J1, J2, J3: Integer;
  X, Y, A, B : Single;
  C1, C2, C3, C4, C5, C6, C7, C8: Single;
  RPixelPtr: PByte;
  P00Ptr, P01Ptr, P02Ptr, P03Ptr: PByte;
  P10Ptr, P11Ptr, P12Ptr, P13Ptr: PByte;
  P20Ptr, P21Ptr, P22Ptr, P23Ptr: PByte;
  P30Ptr, P31Ptr, P32Ptr, P33Ptr: PByte;
  Blue00, Green00, Red00: Byte;
  Blue01, Green01, Red01: Byte;
  Blue02, Green02, Red02: Byte;
  Blue03, Green03, Red03: Byte;
  Blue10, Green10, Red10: Byte;
  Blue11, Green11, Red11: Byte;
  Blue12, Green12, Red12: Byte;
  Blue13, Green13, Red13: Byte;
  Blue20, Green20, Red20: Byte;
  Blue21, Green21, Red21: Byte;
  Blue22, Green22, Red22: Byte;
  Blue23, Green23, Red23: Byte;
  Blue30, Green30, Red30: Byte;
  Blue31, Green31, Red31: Byte;
  Blue32, Green32, Red32: Byte;
  Blue33, Green33, Red33: Byte;
  Blue, Green, Red: Integer;
  UserContrast, Factor, NewValue : Single;
begin
  if Contrast > 126 then Contrast := 126;
  if Contrast < 0 then Contrast := 0;

  if (Contrast > 0) then
  begin
    UserContrast := Contrast / 127.0;
    Factor := Tan((UserContrast + 1) * Pi / 4);
  end;

  SetLength(CA, RWidth, 4);

  for K := 0 to RWidth - 1 do
  begin
    X := (K / FM) + 1;
    J1 := Trunc(X);
    A := X - J1;
    CA[K][0] := CatmullRom(1 + A);
    CA[K][1] := CatmullRom(A);
    CA[K][2] := CatmullRom(1 - A);
    CA[K][3] := CatmullRom(2 - A);
  end;

  for L := RStartY to REndY - 1 do
  begin
    Y := L / FM;
    I1 := Trunc(Y);
    B := Y - I1;
    I0 := I1 - 1;
    if (I0 < 0) then I0 := I1;
    I2 := I1 + 1;
    if I2 >= FHeight then I2 := FHeight - 1;
    I3 := I1 + 2;
    if I3 >= FHeight then I3 := FHeight - 1;

    C5 := CatmullRom(1 + B);
    C6 := CatmullRom(B);
    C7 := CatmullRom(1 - B);
    C8 := CatmullRom(2 - B);

    for K := 0 to RWidth - 1 do
    begin
      X := K / FM;
      J1 := Trunc(X);

      C1 := CA[K][0];
      C2 := CA[K][1];
      C3 := CA[K][2];
      C4 := CA[K][3];

      J0 := J1 - 1;
      if (J0 < 0) then J0 := J1;
      J2 := J1 + 1;
      if J2 >= FWidth then J2 := FWidth - 1;
      J3 := J1 + 2;
      if J3 >= FWidth then j3 := FWidth - 1;

      RPixelPtr := PByte(RImageData) + L * RBytesPerLine + K * RBytesPerPixel;
      P00Ptr := PByte(FImageData) + I0 * FBytesPerLine + J0 * FBytesPerPixel;
      P01Ptr := PByte(FImageData) + I0 * FBytesPerLine + J1 * FBytesPerPixel;
      P02Ptr := PByte(FImageData) + I0 * FBytesPerLine + J2 * FBytesPerPixel;
      P03Ptr := PByte(FImageData) + I0 * FBytesPerLine + J3 * FBytesPerPixel;
      P10Ptr := PByte(FImageData) + I1 * FBytesPerLine + J0 * FBytesPerPixel;
      P11Ptr := PByte(FImageData) + I1 * FBytesPerLine + J1 * FBytesPerPixel;
      P12Ptr := PByte(FImageData) + I1 * FBytesPerLine + J2 * FBytesPerPixel;
      P13Ptr := PByte(FImageData) + I1 * FBytesPerLine + J3 * FBytesPerPixel;
      P20Ptr := PByte(FImageData) + I2 * FBytesPerLine + J0 * FBytesPerPixel;
      P21Ptr := PByte(FImageData) + I2 * FBytesPerLine + J1 * FBytesPerPixel;
      P22Ptr := PByte(FImageData) + I2 * FBytesPerLine + J2 * FBytesPerPixel;
      P23Ptr := PByte(FImageData) + I2 * FBytesPerLine + J3 * FBytesPerPixel;
      P30Ptr := PByte(FImageData) + I3 * FBytesPerLine + J0 * FBytesPerPixel;
      P31Ptr := PByte(FImageData) + I3 * FBytesPerLine + J1 * FBytesPerPixel;
      P32Ptr := PByte(FImageData) + I3 * FBytesPerLine + J2 * FBytesPerPixel;
      P33Ptr := PByte(FImageData) + I3 * FBytesPerLine + J3 * FBytesPerPixel;

      Blue00 := P00Ptr^; Green00 := (P00Ptr + 1)^; Red00 := (P00Ptr + 2)^;
      Blue01 := P01Ptr^; Green01 := (P01Ptr + 1)^; Red01 := (P01Ptr + 2)^;
      Blue02 := P02Ptr^; Green02 := (P02Ptr + 1)^; Red02 := (P02Ptr + 2)^;
      Blue03 := P03Ptr^; Green03 := (P03Ptr + 1)^; Red03 := (P03Ptr + 2)^;
      Blue10 := P10Ptr^; Green10 := (P10Ptr + 1)^; Red10 := (P10Ptr + 2)^;
      Blue11 := P11Ptr^; Green11 := (P11Ptr + 1)^; Red11 := (P11Ptr + 2)^;
      Blue12 := P12Ptr^; Green12 := (P12Ptr + 1)^; Red12 := (P12Ptr + 2)^;
      Blue13 := P13Ptr^; Green13 := (P13Ptr + 1)^; Red13 := (P13Ptr + 2)^;
      Blue20 := P20Ptr^; Green20 := (P20Ptr + 1)^; Red20 := (P20Ptr + 2)^;
      Blue21 := P21Ptr^; Green21 := (P21Ptr + 1)^; Red21 := (P21Ptr + 2)^;
      Blue22 := P22Ptr^; Green22 := (P22Ptr + 1)^; Red22 := (P22Ptr + 2)^;
      Blue23 := P23Ptr^; Green23 := (P23Ptr + 1)^; Red23 := (P23Ptr + 2)^;
      Blue30 := P30Ptr^; Green30 := (P30Ptr + 1)^; Red30 := (P30Ptr + 2)^;
      Blue31 := P31Ptr^; Green31 := (P31Ptr + 1)^; Red31 := (P31Ptr + 2)^;
      Blue32 := P32Ptr^; Green32 := (P32Ptr + 1)^; Red32 := (P32Ptr + 2)^;
      Blue33 := P33Ptr^; Green33 := (P33Ptr + 1)^; Red33 := (P33Ptr + 2)^;


      Blue := Round(C5 * (Blue00 * C1 + Blue01 * C2 + Blue02 * C3 + Blue03 * C4) +
                    C6 * (Blue10 * C1 + Blue11 * C2 + Blue12 * C3 + Blue13 * C4) +
                    C7 * (Blue20 * C1 + Blue21 * C2 + Blue22 * C3 + Blue23 * C4) +
                    C8 * (Blue30 * C1 + Blue31 * C2 + Blue32 * C3 + Blue33 * C4));
      if Blue > 255 then Blue := 255;
      if blue < 0 then Blue := 0;

      Green := Round(C5 * (Green00 * C1 + Green01 * C2 + Green02 * C3 + Green03 * C4) +
                     C6 * (Green10 * C1 + Green11 * C2 + Green12 * C3 + Green13 * C4) +
                     C7 * (Green20 * C1 + Green21 * C2 + Green22 * C3 + Green23 * C4) +
                     C8 * (Green30 * C1 + Green31 * C2 + Green32 * C3 + Green33 * C4));
      if Green > 255 then Green := 255;
      if Green < 0 then Green := 0;

      Red := Round(C5 * (Red00 * C1 + Red01 * C2 + Red02 * C3 + Red03 * C4) +
                   C6 * (Red10 * C1 + Red11 * C2 + Red12 * C3 + Red13 * C4) +
                   C7 * (Red20 * C1 + Red21 * C2 + Red22 * C3 + Red23 * C4) +
                   C8 * (Red30 * C1 + Red31 * C2 + Red32 * C3 + Red33 * C4));
      if Red > 255 then Red := 255;
      if Red < 0 then Red := 0;

      if (Contrast > 0) then
      begin
        NewValue := (Blue - 128) * Factor + 128;
        if (NewValue > 255) then NewValue := 255
        else if (NewValue < 0) then NewValue := 0;
        Blue := Round(NewValue);

        NewValue := (Green - 128) * Factor + 128;
        if (NewValue > 255) then NewValue := 255
        else if (NewValue < 0) then NewValue := 0;
        Green := Round(NewValue);

        NewValue := (Red - 128) * Factor + 128;
        if (NewValue > 255) then NewValue := 255
        else if (NewValue < 0) then NewValue := 0;
        Red := Round(NewValue);
      end;

      if Invert then
      begin
        RPixelPtr^ := 255 - Blue;
        (RPixelPtr + 1)^ := 255 - Green;
        (RPixelPtr + 2)^ := 255 - Red;
      end
      else begin
        RPixelPtr^ := Blue;
        (RPixelPtr + 1)^ := Green;
        (RPixelPtr + 2)^ := Red;
      end;
      if Terminated then Exit;
    end;
    if Terminated then Exit;
  end;
  Completed := True;
end;

procedure TPerformThread.RawContrast;
var
  X, Y: Integer;
  Width, Height : Integer;
  RPixelPtr: PByte;
  R, G, B: Single;
  RedValue, GreenValue, BlueValue: Integer;
  Contrast, Factor, UserContrast : Single;
  NewValue : Single;
begin
  Width := RWidth;
  Height := RHeight;

  if Contrast > 126 then Contrast := 126;
  if Contrast < 0 then Contrast := 0;

  if (Contrast > 0) then
  begin
    UserContrast := Contrast / 127.0;
    Factor := Tan((UserContrast + 1) * Pi / 4);
  end;

  //UserContrast := Self.Contrast;//33;//Round(Contrast);
  //if UserContrast > 126 then UserContrast := 126;
  //if UserContrast < 0 then UserContrast := 0;

  //Contrast := UserContrast / 127.0;
  //Factor := Tan((Contrast + 1) * Pi / 4);

  for Y := 0 to Height - 1 do
  begin
    for X := 0 to Width - 1 do
    begin
      RPixelPtr := PByte(RImageData) + Y * RBytesPerLine + X * RBytesPerPixel;
      B := RPixelPtr^ / 255.0;
      G := (RPixelPtr + 1)^ / 255.0;
      R := (RPixelPtr + 2)^ / 255.0;
      NewValue := (B - 0.5) * Factor + 0.5;
      if (NewValue > 1) then NewValue := 1
      else if (NewValue < 0) then NewValue := 0;
      BlueValue := Round(255 * NewValue);

      NewValue := (G - 0.5) * Factor + 0.5;
      if (NewValue > 1) then NewValue := 1
      else if (NewValue < 0) then NewValue := 0;
      GreenValue := Round(255 * NewValue);

      NewValue := (R - 0.5) * Factor + 0.5;
      if (NewValue > 1) then NewValue := 1
      else if (NewValue < 0) then NewValue := 0;
      RedValue := Round(255 * NewValue);

      RPixelPtr^ := BlueValue;
      (RPixelPtr + 1)^ := GreenValue;
      (RPixelPtr + 2)^ := RedValue;
      if Terminated then Exit;
    end;
    if Terminated then Exit;
  end;
  Completed := True;
end;

function TPerformThread.CatmullRom(X: Single): Single;
var
  A, B, ABSX: single;
begin
  ABSX := abs(x);
  A := 1 - ABSX;
  B := 2 - ABSX;
  if (ABSX >= 0) and (ABSX <= 1) then
    Result := 0.5 * (-3 * A * A * A + 4 * A * A + A)
  else if (ABSX > 1) and (ABSX <= 2) then
    Result := 0.5 * (B * B * B - B * B)
  else
    Result := 0;
end;

procedure TPerformThread.Execute;
begin
  if PAction = PixelRepetitionAction then
    PixelRepetition
  else if PAction = BilinearAction then
    Bilinear
  else if PAction = CatmullRomAction then
    CatmullRomEnlarge;
end;

{ TBitmapHandler }

constructor TBitmapHandler.Create;
var
  I: Integer;
begin
  ThreadCount := GetSystemThreadCount;
  SetLength(ThreadList, ThreadCount);

  for I := 0 to ThreadCount - 1 do
  begin
    ThreadList[i] := nil;
  end;
end;

destructor TBitmapHandler.Destroy;
var
  I: Integer;
begin
  for I := 0 to ThreadCount - 1 do
  begin
    if TPerformThread(ThreadList[I]) <> nil then
      TPerformThread(ThreadList[I]).Free;
    end;

  if Assigned(Bitmap) then
    Bitmap.Free;
  inherited Destroy;
end;

procedure TBitmapHandler.ThreadCompleted(Sender: TObject);
begin
  if TPerformThread(Sender).Completed then
    Inc(NumThreadsFinished);
  if NumThreadsFinished = ThreadCount then
  begin
    OnTerminate(Self);
  end;
end;

procedure TBitmapHandler.Start;
var
  I: Integer;
  Thread: TPerformThread;
  StripHeight, StartY, EndY: Integer;
begin
  NumThreadsFinished := 0;
  for I := 0 to ThreadCount - 1 do
  begin
      Thread := TPerformThread.Create;
      ThreadList[I] := Thread;
  end;

  if Assigned(Bitmap) then
    Bitmap.Free;

  Bitmap := TBitmap.Create;
  Bitmap.Width := BitmapWidth;
  Bitmap.Height := BitmapHeight;

  StripHeight := Trunc(Bitmap.Height / ThreadCount);
  StartY := 0;

  for I := 0 to ThreadCount - 1 do
  begin
    if I = ThreadCount - 1 then
      EndY := Bitmap.Height
    else
      EndY := StartY + StripHeight;

    TPerformThread(ThreadList[I]).RStartY := StartY;
    TPerformThread(ThreadList[I]).FImageData := FBitmap^.RawImage.Data;
    TPerformThread(ThreadList[I]).FBytesPerLine := FBitmap^.RawImage.Description.BytesPerLine;
    TPerformThread(ThreadList[I]).FBytesPerPixel := FBitmap^.RawImage.Description.BitsPerPixel div 8;
    TPerformThread(ThreadList[I]).FHeight := FBitmap.Height;
    TPerformThread(ThreadList[I]).RImageData := Bitmap.RawImage.Data;
    TPerformThread(ThreadList[I]).RBytesPerLine := Bitmap.RawImage.Description.BytesPerLine;
    TPerformThread(ThreadList[I]).RBytesPerPixel := Bitmap.RawImage.Description.BitsPerPixel div 8;
    TPerformThread(ThreadList[I]).FHeight := FBitmap.Height;
    TPerformThread(ThreadList[I]).FWidth := FBitmap.Width;
    TPerformThread(ThreadList[I]).RHeight := Bitmap.Height;
    TPerformThread(ThreadList[I]).RWidth := Bitmap.Width;
    TPerformThread(ThreadList[I]).REndY := EndY;
    TPerformThread(ThreadList[I]).FM := FM;
    TPerformThread(ThreadList[I]).Invert := Invert;
    TPerformThread(ThreadList[I]).Contrast := Contrast;
    TPerformThread(ThreadList[I]).PAction := PAction;
    StartY := EndY;
  end;

  for I := 0 to ThreadCount - 1 do
  begin
    TThread(ThreadList[I]).Start;
  end;

  for I := 0 to ThreadCount - 1 do
  begin
    TThread(ThreadList[I]).WaitFor;
  end;

  for I := 0 to ThreadCount - 1 do
  begin
    TThread(ThreadList[I]).Free;
    ThreadList[I] := nil;
  end;
end;

procedure TBitmapHandler.Reset;
var
  I: Integer;
begin
  for I := 0 to ThreadCount - 1 do
  begin
    if ThreadList[I] <> nil then
    begin
      if not (TPerformThread(ThreadList[I]).Completed) then
      begin
        TPerformThread(ThreadList[I]).Terminate;
        TPerformThread(ThreadList[I]).WaitFor;
        TPerformThread(ThreadList[I]).Free;
      end;
      ThreadList[I] := nil;
    end;
  end;
  NumThreadsFinished := 0;

  if Assigned(Bitmap) then
    FreeAndNil(Bitmap);
end;

procedure TBitmapHandler.BackgroundPerform(AOnTerminate: TNotifyEvent);
var
  I, StripHeight, StartY, EndY: Integer;
  Thread: TPerformThread;
begin
  OnTerminate := AOnTerminate;

  if Assigned(Bitmap) then
    Bitmap.Free;

  Bitmap := TBitmap.Create;
  Bitmap.Width := BitmapWidth;
  Bitmap.Height := BitmapHeight;

  for I := 0 to ThreadCount - 1 do
  begin
    Thread := TPerformThread.Create;
    ThreadList[I] := Thread;
  end;

  StripHeight := Trunc(Bitmap.Height / ThreadCount);
  StartY := 0;

  for I := 0 to ThreadCount - 1 do
  begin
    if I = ThreadCount - 1 then
      EndY := Bitmap.Height
    else
      EndY := StartY + StripHeight;

    TPerformThread(ThreadList[I]).RStartY := StartY;
    TPerformThread(ThreadList[I]).FImageData := FBitmap^.RawImage.Data;
    TPerformThread(ThreadList[I]).FBytesPerLine := FBitmap^.RawImage.Description.BytesPerLine;
    TPerformThread(ThreadList[I]).FBytesPerPixel := FBitmap^.RawImage.Description.BitsPerPixel div 8;
    TPerformThread(ThreadList[I]).RImageData := Bitmap.RawImage.Data;
    TPerformThread(ThreadList[I]).RBytesPerLine := Bitmap.RawImage.Description.BytesPerLine;
    TPerformThread(ThreadList[I]).RBytesPerPixel := Bitmap.RawImage.Description.BitsPerPixel div 8;
    TPerformThread(ThreadList[I]).FHeight := FBitmap.Height;
    TPerformThread(ThreadList[I]).FWidth := FBitmap.Width;
    TPerformThread(ThreadList[I]).RHeight := Bitmap.Height;
    TPerformThread(ThreadList[I]).RWidth := Bitmap.Width;
    TPerformThread(ThreadList[I]).REndY := EndY;
    TPerformThread(ThreadList[I]).FM := FM;
    TPerformThread(ThreadList[I]).Invert := Invert;
    TPerformThread(ThreadList[I]).Contrast := Contrast;
    TPerformThread(ThreadList[I]).PAction := PAction;

    StartY := EndY;
  end;

  for I := 0 to ThreadCount - 1 do
  begin
    TThread(ThreadList[I]).Start;
    TThread(ThreadList[I]).OnTerminate := ThreadCompleted;
  end;
end;

end.

