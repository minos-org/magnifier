{
This unit contains the most of the procedures which are used
for processing images.

Copyright (C) 2003 - 2011 Strikos Nikolaos

This file is part of Digital Image Magnifier.

Digital Image Magnifier is free software;
you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2
as published by the Free Software Foundation.

Digital Image Magnifier is distributed in the hope
that it will be useful, but WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.

}

unit BitmapProcess;

interface

uses
  Math, Graphics, GraphType;

type
  ImageArray = array of array of single;

type TBitmapPointer = ^TBitmap;

//procedure BGRARemap(Input: TBGRABitmap; Output: TBGRABitmap; Width, Height: integer);
procedure Gauss(sigma: single; Width: integer; var kernel: ImageArray);
procedure RawPixelRepetition(InBitmap: TBitmapPointer; OutBitmap: TBitmapPointer; FM: Single; Contrast : Integer);
procedure RawBilinear(InBitmap: TBitmapPointer; OutBitmap: TBitmapPointer; FM: Single; Contrast : Integer);
procedure RawPolyrama(var inBitmap: TBitmap; var outBitmap: TBitmap; fm: single);
procedure RawCatmullRom(InBitmap: TBitmapPointer; OutBitmap: TBitmapPointer; FM: single; Contrast : Integer);
procedure RawInvertColors(var bitmap: TBitmap);
procedure RawUnsharp(var bitmap: TBitmap; var outBitmap: Tbitmap; sigma, f: single; threshold : integer);
procedure RawContrast(FBitmap : TBitmapPointer; UserContrast: Integer);
procedure RawRemap (Input, Output: TBitmapPointer; Width, Height: Integer; Red, Green, Blue: Byte);

function c(x: single): single;          //bicubic filter
function poly3(x: single): single;      //this function implements a different bicubic filter of panorama tools
function catmullrom(x: single): single; //this function implements a different bicubic filter of panorama tools
function s(x: single): single;          //quadratic filter
function hf(x: single): single;         //Hermite filter
function sinc(x: single): single;       //sinc function
function Lancf(x, a: single): single;   //Lanc filter
function mf(x: single): single;         //Mitchel filter

var
  percent: single;

implementation

{procedure BGRARemap(Input: TBGRABitmap; Output: TBGRABitmap; Width, Height: integer);
var
  i, j: integer;
  k, l: integer;
  p, pOutput: PBGRAPixel;
  g: integer;
  a, b: integer;
  x0, y0, dx, dy: integer;
  u, v: integer;
begin

  for i := 0 to Output.Height - 1 do
  begin
    pOutput := Output.ScanLine[i];
    for j := 0 to Output.Width - 1 do
    begin
      pOutput[j].red := 255;
      pOutput[j].green := 255;
      pOutput[j].blue := 255;
    end;
  end;


  //Ellipsis width, height
  a := Width;
  b := Height;

  //Image center

  x0 := Input.Width div 2;
  y0 := Input.Height div 2;


  for l := 0 to Input.Height - 1 do
  begin
    p := Input.ScanLine[l];
    dy := l - y0;

    //i:=l;
    //pOutput:=Output.ScanLine[l];
    //p := Input.ScanLine[i];
    for k := 0 to Input.Width - 1 do
    begin

      dx := k - x0;

      u := dx;
      if (dy >= 0) then
        v := Round(dy + b * exp(-(dx * dx) / (a * a)) * (1 - abs(dy) / (y0)))
      else
        v := Round(dy - b * exp(-(dx * dx) / (a * a)) * (1 - abs(dy) / (y0)));

      i := y0 + v;
      j := x0 + u;

      if (i >= 0) and (i < Output.Height) then
        pOutput := Output.ScanLine[i];

      if (j >= 0) and (j < Output.Width) then
      begin
        pOutput[j].red := p[k].red;
        pOutput[j].green := p[k].green;
        pOutput[j].blue := p[k].blue;
      end;

      //g := (p[j].red + p[j].green + p[j].blue) div 3;
      g := 255;
      //pOutput[k].red := g;
      //pOutput[k].green := g;
      //pOutput[k].blue := g;
      //pOutput[k].alpha := 255;
    end;
  end;
  Output.InvalidateBitmap; // changed by direct access
end;
}

procedure Gauss(sigma: single; Width: integer; var kernel: imageArray);
var
  Mean, Sum: single;
  x, y: integer;
begin
  Mean := Width div 2;
  Sum := 0.0;

  for x := 0 to Width - 1 do
  begin
    for y := 0 to Width - 1 do
    begin
      kernel[x][y] := Exp(-0.5 * (Power((x - mean) / sigma, 2.0) +
        Power((y - mean) / sigma, 2.0))) / (2 * pi * sigma * sigma);

      sum := sum + kernel[x][y];
    end;
  end;

  for x := 0 to Width - 1 do
  begin
    for y := 0 to Width - 1 do
    begin
      kernel[x][y] := kernel[x][y] / sum;
    end;
  end;
end;

procedure RawPixelRepetition(InBitmap: TBitmapPointer; OutBitmap: TBitmapPointer; FM: Single; Contrast : Integer);
var
  InRawImage, OutRawImage: TRawImage;
  InBytesPerPixel, OutBytesPerPixel, K, L, I, J: Integer;
  PixelPtr, OutPixelPtr: PByte;
  X, Y: Single;
  Blue, Green, Red: Integer;
  UserContrast, Factor, NewValue : Single;
begin
  try
    OutBitmap^.BeginUpdate(False);
    InRawImage := InBitmap^.RawImage;
    OutRawImage := OutBitmap^.RawImage;
    InBytesPerPixel := InRawImage.Description.BitsPerPixel div 8;
    OutBytesPerPixel := OutRawImage.Description.BitsPerPixel div 8;

    if Contrast > 126 then Contrast := 126;
    if Contrast < 0 then Contrast := 0;

    if (Contrast > 0) then
    begin
      UserContrast := Contrast / 127.0;
      Factor := Tan((UserContrast + 1) * Pi / 4);
    end;

    for L := 0 to OutBitmap^.Height - 1 do
    begin
      Y := (L + 0.5) / FM;
      I := Trunc(Y);
      if I >= InBitmap^.Height then I := inBitmap^.Height - 1;

      PixelPtr := PByte(InRawImage.Data) + I * InRawImage.Description.BytesPerLine;
      OutPixelPtr := PByte(OutRawImage.Data) + L * OutRawImage.Description.BytesPerLine;
      for K := 0 to OutBitmap^.Width - 1 do
      begin
        X := (K + 0.5) / FM;
        J := Trunc(X);
        if J >= InBitmap^.Width then J := InBitmap^.Width - 1;

        PixelPtr := PByte(InRawImage.Data) + I * InRawImage.Description.BytesPerLine + J * InBytesPerPixel;

        Blue := PixelPtr^;
        Green := (PixelPtr + 1)^;
        Red := (PixelPtr + 2)^;

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

        OutPixelPtr^ := Blue;
        (OutPixelPtr + 1)^ := Green;
        (OutPixelPtr + 2)^ := Red;

        Inc(OutPixelPtr, OutBytesPerPixel);
      end;
    end;
  finally
    outBitmap^.EndUpdate(False);
  end;
end;

procedure RawBilinear(inBitmap: TBitmapPointer; OutBitmap: TBitmapPointer; FM: Single; Contrast: Integer);
var
  InRawImage, OutRawImage: TRawImage;
  InBytesPerPixel, OutBytesPerPixel, K, L, I1, I2, J1, J2: Integer;
  P11Ptr, P12Ptr, P21Ptr, P22Ptr, OutPixelPtr: pbyte;
  X, Y, A, B: Single;
  Blue11, Green11, Red11: Byte;
  Blue12, Green12, Red12: Byte;
  Blue21, Green21, Red21: Byte;
  Blue22, Green22, Red22: Byte;
  Blue, Green, Red: Integer;
  UserContrast, Factor, NewValue : Single;
begin
  try
    OutBitmap^.BeginUpdate(False);
    InRawImage := InBitmap^.RawImage;
    OutRawImage := OutBitmap^.RawImage;
    InBytesPerPixel := InRawImage.Description.BitsPerPixel div 8;
    OutBytesPerPixel := OutRawImage.Description.BitsPerPixel div 8;

    if Contrast > 126 then Contrast := 126;
    if Contrast < 0 then Contrast := 0;

    if (Contrast > 0) then
    begin
      UserContrast := Contrast / 127.0;
      Factor := Tan((UserContrast + 1) * Pi / 4);
    end;

    OutPixelPtr := PByte(OutRawImage.Data);

    for L := 0 to outBitmap^.Height - 1 do
    begin
      Y := L / FM;
      I1 := Trunc(Y);
      A := Y - I1;
      I2 := I1 + 1;
      if I2 >= InBitmap^.Height then I2 := I1;

      //OutPixelPtr := PByte(OutRawImage.Data) + L * OutRawImage.Description.BytesPerLine;

      for K := 0 to OutBitmap^.Width - 1 do
      begin
        X := K / FM;
        J1 := Trunc(X);
        B := X - J1;
        J2 := J1 + 1;
        if J2 >= InBitmap^.Width then J2 := J1;

        P11Ptr := PByte(InRawImage.Data) + I1 * InRawImage.Description.BytesPerLine + J1 * InBytesPerPixel;
        P12Ptr := PByte(InRawImage.Data) + I1 * InRawImage.Description.BytesPerLine + J2 * InBytesPerPixel;
        P21Ptr := PByte(InRawImage.Data) + I2 * InRawImage.Description.BytesPerLine + J1 * InBytesPerPixel;
        P22Ptr := PByte(InRawImage.Data) + I2 * InRawImage.Description.BytesPerLine + J2 * InBytesPerPixel;

        Blue11 := P11Ptr^; Green11 := (P11Ptr + 1)^; Red11 := (P11Ptr + 2)^;
        Blue12 := P12Ptr^; Green12 := (P12Ptr + 1)^; Red12 := (P12Ptr + 2)^;
        Blue21 := P21Ptr^; Green21 := (P21Ptr + 1)^; Red21 := (p21Ptr + 2)^;
        Blue22 := P22Ptr^; Green22 := (P22Ptr + 1)^; Red22 := (P22Ptr + 2)^;

        Blue := Round(Blue11 * (1 - A) * (1 - B) + Blue12 * (1 - A) * B + Blue21 * A * (1 - B) + Blue22 * A * B);
        Green := Round(Green11 * (1 - A) * (1 - B) + Green12 * (1 - A) * B + Green21 * A * (1 - B) + Green22 * A * B);
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

        OutPixelPtr^ :=  Blue;
        (OutPixelPtr + 1)^ := Green;
        (OutPixelPtr + 2)^ := Red;
        Inc(OutPixelPtr, OutBytesPerPixel);
      end;
    end;
  finally
    outBitmap^.EndUpdate(False);
  end;
end;

procedure RawPolyrama(var InBitmap: TBitmap; var OutBitmap: TBitmap; fm: single);
var
  inRawImage, outRawImage: TRawImage;
  inBytesPerPixel, outBytesPerPixel: integer;
  k, l, i0, i1, i2, i3, j0, j1, j2, j3: integer;
  outPixelPtr: pbyte;
  p00Ptr, p01Ptr, p02Ptr, p03Ptr: pbyte;
  p10Ptr, p11Ptr, p12Ptr, p13Ptr: pbyte;
  p20Ptr, p21Ptr, p22Ptr, p23Ptr: pbyte;
  p30Ptr, p31Ptr, p32Ptr, p33Ptr: pbyte;
  x, y, a, b: single;
  blue00, green00, red00: byte;
  blue01, green01, red01: byte;
  blue02, green02, red02: byte;
  blue03, green03, red03: byte;
  blue10, green10, red10: byte;
  blue11, green11, red11: byte;
  blue12, green12, red12: byte;
  blue13, green13, red13: byte;
  blue20, green20, red20: byte;
  blue21, green21, red21: byte;
  blue22, green22, red22: byte;
  blue23, green23, red23: byte;
  blue30, green30, red30: byte;
  blue31, green31, red31: byte;
  blue32, green32, red32: byte;
  blue33, green33, red33: byte;
  ca: array of array of single;
  c1, c2, c3, c4, c5, c6, c7, c8: single;
  sum: integer;
begin
  SetLength(ca, outBitmap.Width, 4);

  for k := 0 to outBitmap.Width - 1 do    //We calculate the factors of the multiplication
  begin                                   //for each row. They remain the same, so we don't have to
    x := (k / fm) + 1;                    //calculate them again for each pixel
    j1 := trunc(x);
    a := x - j1;
    ca[k][0] := poly3(1 + a);
    ca[k][1] := poly3(a);
    ca[k][2] := poly3(1 - a);
    ca[k][3] := poly3(2 - a);
  end;

  try
    outBitmap.BeginUpdate(False);
    inRawImage := inBitmap.RawImage;
    outRawImage := outBitmap.RawImage;
    inBytesPerPixel := inRawImage.Description.BitsPerPixel div 8;
    outBytesPerPixel := outRawImage.Description.BitsPerPixel div 8;
    for l := 0 to outBitmap.Height - 1 do
    begin
      y := l / fm;
      i1 := trunc(y);
      b := y - i1;

      i0 := i1 - 1;
      if (i0 < 0) then i0 := i1;
      i2 := i1 + 1;
      if i2 >= inBitmap.Height then i2 := inBitmap.Height - 1;
      i3 := i1 + 2;
      if i3 >= inBitmap.Height then i3 := inBitmap.Height - 1;

      c5 := catmullrom(1 + b);
      c6 := catmullrom(b);
      c7 := catmullrom(1 - b);
      c8 := catmullrom(2 - b);

      outPixelPtr := pbyte(outRawImage.Data) + l * OutRawImage.Description.BytesPerLine;

      for k := 0 to outBitmap.Width - 1 do
      begin
        x := k / fm;
        j1 := trunc(X);

        c1 := ca[k][0];
        c2 := ca[k][1];
        c3 := ca[k][2];
        c4 := ca[k][3];

        j0 := j1 - 1;
        if (j0 < 0) then j0 := j1;
        j2 := j1 + 1;
        if j2 >= inBitmap.Width then j2 := inBitmap.Width;
        j3 := j1 + 2;
        if j3 >= inBitmap.Width then j3 := InBitmap.Width;

        p00Ptr := pbyte(inRawImage.Data) + i0 * inRawImage.Description.BytesPerLine + j0 * inBytesPerPixel;
        p01Ptr := pbyte(inRawImage.Data) + i0 * inRawImage.Description.BytesPerLine + j1 * inBytesPerPixel;
        p02Ptr := pbyte(inRawImage.Data) + i0 * inRawImage.Description.BytesPerLine + j2 * inBytesPerPixel;
        p03Ptr := pbyte(inRawImage.Data) + i0 * inRawImage.Description.BytesPerLine + j3 * inBytesPerPixel;
        p10Ptr := pbyte(inRawImage.Data) + i1 * inRawImage.Description.BytesPerLine + j0 * inBytesPerPixel;
        p11Ptr := pbyte(inRawImage.Data) + i1 * inRawImage.Description.BytesPerLine + j1 * inBytesPerPixel;
        p12Ptr := pbyte(inRawImage.Data) + i1 * inRawImage.Description.BytesPerLine + j2 * inBytesPerPixel;
        p13Ptr := pbyte(inRawImage.Data) + i1 * inRawImage.Description.BytesPerLine + j3 * inBytesPerPixel;
        p20Ptr := pbyte(inRawImage.Data) + i2 * inRawImage.Description.BytesPerLine + j0 * inBytesPerPixel;
        p21Ptr := pbyte(inRawImage.Data) + i2 * inRawImage.Description.BytesPerLine + j1 * inBytesPerPixel;
        p22Ptr := pbyte(inRawImage.Data) + i2 * inRawImage.Description.BytesPerLine + j2 * inBytesPerPixel;
        p23Ptr := pbyte(inRawImage.Data) + i2 * inRawImage.Description.BytesPerLine + j3 * inBytesPerPixel;
        p30Ptr := pbyte(inRawImage.Data) + i3 * inRawImage.Description.BytesPerLine + j0 * inBytesPerPixel;
        p31Ptr := pbyte(inRawImage.Data) + i3 * inRawImage.Description.BytesPerLine + j1 * inBytesPerPixel;
        p32Ptr := pbyte(inRawImage.Data) + i3 * inRawImage.Description.BytesPerLine + j2 * inBytesPerPixel;
        p33Ptr := pbyte(inRawImage.Data) + i3 * inRawImage.Description.BytesPerLine + j3 * inBytesPerPixel;

        blue00 := p00Ptr^;
        green00 := (p00Ptr + 1)^;
        red00 := (p00Ptr + 2)^;
        blue01 := p01Ptr^;
        green01 := (p01Ptr + 1)^;
        red01 := (p01Ptr + 2)^;
        blue02 := p02Ptr^;
        green02 := (p02Ptr + 1)^;
        red02 := (p02Ptr + 2)^;
        blue03 := p03Ptr^;
        green03 := (p03Ptr + 1)^;
        red03 := (p03Ptr + 2)^;
        blue10 := p10Ptr^;
        green10 := (p10Ptr + 1)^;
        red10 := (p10Ptr + 2)^;
        blue11 := p11Ptr^;
        green11 := (p11Ptr + 1)^;
        red11 := (p11Ptr + 2)^;
        blue12 := p12Ptr^;
        green12 := (p12Ptr + 1)^;
        red12 := (p12Ptr + 2)^;
        blue13 := p13Ptr^;
        green13 := (p13Ptr + 1)^;
        red13 := (p13Ptr + 2)^;
        blue20 := p20Ptr^;
        green20 := (p20Ptr + 1)^;
        red20 := (p20Ptr + 2)^;
        blue21 := p21Ptr^;
        green21 := (p21Ptr + 1)^;
        red21 := (p21Ptr + 2)^;
        blue22 := p22Ptr^;
        green22 := (p22Ptr + 1)^;
        red22 := (p22Ptr + 2)^;
        blue23 := p23Ptr^;
        green23 := (p23Ptr + 1)^;
        red23 := (p23Ptr + 2)^;
        blue30 := p30Ptr^;
        green30 := (p30Ptr + 1)^;
        red30 := (p30Ptr + 2)^;
        blue31 := p31Ptr^;
        green31 := (p31Ptr + 1)^;
        red31 := (p31Ptr + 2)^;
        blue32 := p32Ptr^;
        green32 := (p32Ptr + 1)^;
        red32 := (p32Ptr + 2)^;
        blue33 := p33Ptr^;
        green33 := (p33Ptr + 1)^;
        red33 := (p33Ptr + 2)^;

        sum := Round(c5 * (blue00 * c1 + blue01 * c2 + blue02 * c3 + blue03 * c4) + c6 * (blue10 * c1 + blue11 * c2 + blue12 * c3 + blue13 * c4) + c7 * (blue20 * c1 + blue21 * c2 + blue22 * c3 + blue23 * c4) + c8 * (blue30 * c1 + blue31 * c2 + blue32 * c3 + blue33 * c4));
        if sum > 255 then sum := 255;
        if sum < 0 then sum := 0;
        outPixelPtr^ := sum;

        sum := Round(c5 * (green00 * c1 + green01 * c2 + green02 * c3 + green03 * c4) + c6 * (green10 * c1 + green11 * c2 + green12 * c3 + green13 * c4) + c7 * (green20 * c1 + green21 * c2 + green22 * c3 + green23 * c4) + c8 * (green30 * c1 + green31 * c2 + green32 * c3 + green33 * c4));
        if sum > 255 then sum := 255;
        if sum < 0 then sum := 0;
        (outPixelPtr + 1)^ := sum;

        sum := Round(c5 * (red00 * c1 + red01 * c2 + red02 * c3 + red03 * c4) + c6 * (red10 * c1 + red11 * c2 + red12 * c3 + red13 * c4) + c7 * (red20 * c1 + red21 * c2 + red22 * c3 + red23 * c4) + c8 * (red30 * c1 + red31 * c2 + red32 * c3 + red33 * c4));
        if sum > 255 then sum := 255;
        if sum < 0 then sum := 0;
        (outPixelPtr + 2)^ := sum;

        Inc(outPixelPtr, outBytesPerPixel);
      end;
    end;
  finally
    outBitmap.EndUpdate(False);
  end;
end;

procedure RawCatmullRom(InBitmap: TBitmapPointer; OutBitmap: TBitmapPointer; FM: Single; Contrast : Integer);
var
  InRawImage, OutRawImage: TRawImage;
  InBytesPerPixel, OutBytesPerPixel: Integer;
  K, L, I0, I1, I2, I3, J0, J1, J2, J3: Integer;
  OutPixelPtr: PByte;
  P00Ptr, P01Ptr, P02Ptr, P03Ptr: PByte;
  P10Ptr, P11Ptr, P12Ptr, P13Ptr: PByte;
  P20Ptr, P21Ptr, P22Ptr, P23Ptr: PByte;
  P30Ptr, P31Ptr, P32Ptr, P33Ptr: PByte;
  X, Y, A, B: Single;
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
  CA: Array of Array of Single;
  C1, C2, C3, C4, C5, C6, C7, C8: Single;
  UserContrast, Factor, NewValue : Single;
  Blue, Green, Red: Integer;
begin
  SetLength(CA, OutBitmap^.Width, 4);

  if Contrast > 126 then Contrast := 126;
  if Contrast < 0 then Contrast := 0;

  if (Contrast > 0) then
  begin
    UserContrast := Contrast / 127.0;
    Factor := Tan((UserContrast + 1) * Pi / 4);
  end;

  for K := 0 to OutBitmap^.Width - 1 do
  begin
    X := (K / FM) + 1;
    J1 := Trunc(X);
    A := X - J1;
    CA[K][0] := Catmullrom(1 + A);
    CA[K][1] := Catmullrom(A);
    CA[K][2] := Catmullrom(1 - A);
    CA[K][3] := Catmullrom(2 - A);
  end;

  try
    OutBitmap^.BeginUpdate(False);
    InRawImage := InBitmap^.RawImage;
    OutRawImage := OutBitmap^.RawImage;
    InBytesPerPixel := InRawImage.Description.BitsPerPixel div 8;
    OutBytesPerPixel := OutRawImage.Description.BitsPerPixel div 8;
    for L := 0 to OutBitmap^.Height - 1 do
    begin
      Y := L / FM;
      I1 := Trunc(Y);
      B := Y - I1;

      I0 := I1 - 1;
      if (I0 < 0) then I0 := I1;
      I2 := I1 + 1;
      if I2 >= InBitmap^.Height then I2 := InBitmap^.Height - 1;
      I3 := I1 + 2;
      if I3 >= InBitmap^.Height then i3 := InBitmap^.Height - 1;

      C5 := Catmullrom(1 + B);
      C6 := Catmullrom(B);
      C7 := Catmullrom(1 - B);
      C8 := Catmullrom(2 - B);

      OutPixelPtr := PByte(OutRawImage.Data) + L * OutRawImage.Description.BytesPerLine;

      for K := 0 to OutBitmap^.Width - 1 do
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
        if J2 >= InBitmap^.Width then J2 := InBitmap^.Width;
        J3 := J1 + 2;
        if J3 >= InBitmap^.Width then J3 := InBitmap^.Width;

        P00Ptr := PByte(InRawImage.Data) + I0 * InRawImage.Description.BytesPerLine + J0 * InBytesPerPixel;
        P01Ptr := PByte(InRawImage.Data) + I0 * InRawImage.Description.BytesPerLine + J1 * InBytesPerPixel;
        P02Ptr := PByte(InRawImage.Data) + I0 * InRawImage.Description.BytesPerLine + J2 * InBytesPerPixel;
        P03Ptr := PByte(InRawImage.Data) + I0 * InRawImage.Description.BytesPerLine + J3 * InBytesPerPixel;
        P10Ptr := PByte(InRawImage.Data) + I1 * InRawImage.Description.BytesPerLine + J0 * InBytesPerPixel;
        P11Ptr := PByte(InRawImage.Data) + I1 * InRawImage.Description.BytesPerLine + J1 * InBytesPerPixel;
        P12Ptr := PByte(InRawImage.Data) + I1 * InRawImage.Description.BytesPerLine + J2 * InBytesPerPixel;
        P13Ptr := PByte(InRawImage.Data) + I1 * InRawImage.Description.BytesPerLine + J3 * InBytesPerPixel;
        P20Ptr := PByte(InRawImage.Data) + I2 * InRawImage.Description.BytesPerLine + J0 * InBytesPerPixel;
        P21Ptr := PByte(InRawImage.Data) + I2 * InRawImage.Description.BytesPerLine + J1 * InBytesPerPixel;
        P22Ptr := PByte(InRawImage.Data) + I2 * InRawImage.Description.BytesPerLine + J2 * InBytesPerPixel;
        P23Ptr := PByte(InRawImage.Data) + I2 * InRawImage.Description.BytesPerLine + J3 * InBytesPerPixel;
        P30Ptr := PByte(InRawImage.Data) + I3 * InRawImage.Description.BytesPerLine + J0 * InBytesPerPixel;
        P31Ptr := PByte(InRawImage.Data) + I3 * InRawImage.Description.BytesPerLine + J1 * InBytesPerPixel;
        P32Ptr := PByte(InRawImage.Data) + I3 * InRawImage.Description.BytesPerLine + J2 * InBytesPerPixel;
        P33Ptr := PByte(InRawImage.Data) + I3 * InRawImage.Description.BytesPerLine + J3 * InBytesPerPixel;

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
        if Blue < 0 then Blue := 0;

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

        OutPixelPtr^ := Blue;
        (OutPixelPtr + 1)^ := Green;
        (OutPixelPtr + 2)^ := Red;
        Inc(OutPixelPtr, OutBytesPerPixel);
      end;
    end;
  finally
    OutBitmap^.EndUpdate(False);
  end;
end;

procedure RawInvertColors(var bitmap: TBitmap);
var
  rawImage: TRawImage;
  bytesPerPixel, i, j: integer;
  pixelPtr: pbyte;
begin
  try
    bitmap.BeginUpdate(False);
    rawImage := bitmap.RawImage;
    bytesPerPixel := rawImage.Description.BitsPerPixel div 8;
    for i := 0 to bitmap.Height - 1 do
    begin
      pixelPtr := pbyte(rawImage.Data) + i * rawImage.Description.BytesPerLine;
      for j := 0 to bitmap.Width - 1 do
      begin
        pixelPtr^ := 255 - pixelPtr^;              //blue
        (pixelPtr + 1)^ := 255 - (pixelPtr + 1)^;  //green
        (pixelPtr + 2)^ := 255 - (pixelPtr + 2)^;  //red
        Inc(pixelPtr, bytesPerPixel);
      end;
    end;
  finally
    bitmap.EndUpdate(False);
  end;
end;

procedure RawUnsharp(var bitmap: TBitmap; var outBitmap: TBitmap; sigma, f: single; threshold : integer);
var
  i, j, i0, i2, j0, j2, kernelWidth: integer;
  blurRed, blurGreen, blurBlue, maskRed, maskGreen, maskBlue: array of array of single;
  Kernel: ImageArray;
  pixelPtr, outPixelPtr: pbyte;
  p00Ptr, p01Ptr, p02Ptr: pbyte;
  p10Ptr, p11Ptr, p12Ptr: pbyte;
  p20Ptr, p21Ptr, p22Ptr: pbyte;
  rawImage, outRawImage: TRawImage;
  bytesPerPixel, outBytesPerPixel: integer;
  blue00, green00, red00: byte;
  blue01, green01, red01: byte;
  blue02, green02, red02: byte;
  blue10, green10, red10: byte;
  blue11, green11, red11: byte;
  blue12, green12, red12: byte;
  blue20, green20, red20: byte;
  blue21, green21, red21: byte;
  blue22, green22, red22: byte;
  Value: single;

begin
  SetLength(maskRed, bitmap.Height, bitmap.Width);
  SetLength(maskGreen, bitmap.Height, bitmap.Width);
  SetLength(maskBlue, bitmap.Height, bitmap.Width);
  SetLength(blurRed, bitmap.Height, bitmap.Width);
  SetLength(blurGreen, bitmap.Height, bitmap.Width);
  SetLength(blurBlue, bitmap.Height, bitmap.Width);

  kernelWidth := 3;

  SetLength(kernel, kernelWidth, kernelWidth);
  Gauss(sigma, kernelWidth, kernel);

  outBitmap.BeginUpdate(False);
  rawImage := bitmap.RawImage;
  outRawImage := outBitmap.RawImage;
  bytesPerPixel := rawImage.Description.BitsPerPixel div 8;
  outBytesPerPixel := outRawImage.Description.BitsPerPixel div 8;
  for i := 0 to bitmap.Height - 1 do
  begin
    i0 := i - 1;
    if (i0 < 0) then i0 := 0;
    i2 := i + 1;
    if i2 >= bitmap.Height then i2 := bitmap.Height - 1;

    pixelPtr := pbyte(rawImage.Data) + i * rawImage.Description.BytesPerLine;

    for j := 0 to bitmap.Width - 1 do
    begin
      j0 := j - 1;
      if j0 < 0 then j0 := 0;
      j2 := j + 1;
      if j2 >= bitmap.Width then j2 := bitmap.Width - 1;


      p00Ptr := pbyte(rawImage.Data) + i0 * rawImage.Description.BytesPerLine + j0 * bytesPerPixel;
      p01Ptr := pbyte(rawImage.Data) + i0 * rawImage.Description.BytesPerLine + j * bytesPerPixel;
      p02Ptr := pbyte(rawImage.Data) + i0 * rawImage.Description.BytesPerLine + j2 * bytesPerPixel;
      p10Ptr := pbyte(rawImage.Data) + i * rawImage.Description.BytesPerLine + j0 * bytesPerPixel;
      p11Ptr := pbyte(rawImage.Data) + i * rawImage.Description.BytesPerLine + j * bytesPerPixel;
      p12Ptr := pbyte(rawImage.Data) + i * rawImage.Description.BytesPerLine + j2 * bytesPerPixel;
      p20Ptr := pbyte(rawImage.Data) + i2 * rawImage.Description.BytesPerLine + j0 * bytesPerPixel;
      p21Ptr := pbyte(rawImage.Data) + i2 * rawImage.Description.BytesPerLine + j * bytesPerPixel;
      p22Ptr := pbyte(rawImage.Data) + i2 * rawImage.Description.BytesPerLine + j2 * bytesPerPixel;

      blue00 := p00Ptr^;
      green00 := (p00Ptr + 1)^;
      red00 := (p00Ptr + 2)^;
      blue01 := p01Ptr^;
      green01 := (p01Ptr + 1)^;
      red01 := (p01Ptr + 2)^;
      blue02 := p02Ptr^;
      green02 := (p02Ptr + 1)^;
      red02 := (p02Ptr + 2)^;
      blue10 := p10Ptr^;
      green10 := (p10Ptr + 1)^;
      red10 := (p10Ptr + 2)^;
      blue11 := p11Ptr^;
      green11 := (p11Ptr + 1)^;
      red11 := (p11Ptr + 2)^;
      blue12 := p12Ptr^;
      green12 := (p12Ptr + 1)^;
      red12 := (p12Ptr + 2)^;
      blue20 := p20Ptr^;
      green20 := (p20Ptr + 1)^;
      red20 := (p20Ptr + 2)^;
      blue21 := p21Ptr^;
      green21 := (p21Ptr + 1)^;
      red21 := (p21Ptr + 2)^;
      blue22 := p22Ptr^;
      green22 := (p22Ptr + 1)^;
      red22 := (p22Ptr + 2)^;


      blurBlue[i][j] := (blue00 + blue01 + blue02 + blue10 + blue11 + blue12 + blue20 + blue21 + blue22) / 9;

      blurGreen[i][j] := (green00 + green01 + green02 + green10 + green11 + green12 + green20 + green21 + green22) / 9;

      blurRed[i][j] := (red00 + red01 + red02 + red10 + red11 + red12 + red20 + red21 + red22) / 9;

      Inc(pixelPtr, bytesPerPixel);
    end;
  end;

  for i := 0 to bitmap.Height - 1 do
  begin
    pixelPtr := pbyte(rawImage.Data) + i * rawImage.Description.BytesPerLine;
    for j := 0 to bitmap.Width - 1 do
    begin
      maskBlue[i][j] := pixelPtr^ - BlurBlue[i][j];
      maskGreen[i][j] := (pixelPtr + 1)^ - BlurGreen[i][j];
      maskRed[i][j] := (pixelPtr + 2)^ - BlurRed[i][j];
      if (abs(maskBlue[i][j] - threshold) < 0) then maskBlue[i][j] := 0;
      if (abs(maskGreen[i][j] - threshold) < 0) then maskGreen[i][j] := 0;
      if (abs(maskRed[i][j] - threshold) < 0) then maskRed[i][j] := 0;
      Inc(pixelPtr, bytesPerPixel);
    end;
  end;

  for i := 0 to outBitmap.Height - 1 do
  begin
    pixelPtr := pbyte(rawImage.Data) + i * rawImage.Description.BytesPerLine;
    outPixelPtr := pbyte(outRawImage.Data) + i * outRawImage.Description.BytesPerLine;

    for j := 0 to outBitmap.Width - 1 do
    begin

      Value := (pixelPtr)^ + f * maskBlue[i][j];
      if Value < 0 then Value := 0;
      if Value > 255 then Value := 255;
      (outPixelPtr)^ := Round(Value);

      Value := (pixelPtr + 1)^ + f * maskGreen[i][j];
      if Value < 0 then Value := 0;
      if Value > 255 then Value := 255;
      (outPixelPtr + 1)^ := Round(Value);

      Value := (pixelPtr + 2)^ + f * maskRed[i][j];
      if Value < 0 then Value := 0;
      if Value > 255 then Value := 255;
      (outPixelPtr + 2)^ := Round(Value);

      Inc(pixelPtr, bytesPerPixel);
      Inc(outPixelPtr, outBytesPerPixel);
    end;
  end;



  //finally
  outBitmap.EndUpdate(False);
  //end;

  maskRed := nil;
  maskGreen := nil;
  maskBlue := nil;
  blurRed := nil;
  blurGreen := nil;
  blurBlue := nil;
  kernel := nil;
end;

procedure RawContrast(FBitmap: TBitmapPointer; UserContrast: Integer);
var
  X, Y: Integer;
  Width, Height : Integer;
  FImageData: PByte;
  PixelPtr: PByte;
  FBytesPerPixel, FBytesPerLine: Integer;
  R, G, B: Single;
  RedValue, GreenValue, BlueValue: Integer;
  Contrast, Factor : Single;
  NewValue : Single;
begin

  Width := FBitmap^.Width;
  Height := FBitmap^.Height;

  FImageData := FBitmap^.RawImage.Data;
  FBytesPerPixel := FBitmap^.RawImage.Description.BitsPerPixel div 8;
  FBytesPerLine := FBitmap^.RawImage.Description.BytesPerLine;

  if UserContrast > 126 then UserContrast := 126;
  if UserContrast < 0 then UserContrast := 0;

  Contrast := UserContrast / 127.0;
  Factor := Tan((Contrast + 1) * Pi / 4);

  for Y := 0 to Height - 1 do
  begin
    for X := 0 to Width - 1 do
    begin
      PixelPtr := PByte(FImageData) + Y * FBytesPerLine + X * FBytesPerPixel;
      B := PixelPtr^;
      G := (PixelPtr + 1)^;
      R := (PixelPtr + 2)^;
      NewValue := (B - 128) * Factor + 128;
      if (NewValue > 255) then NewValue := 255
      else if (NewValue < 0) then NewValue := 0;
      BlueValue := Round(NewValue);

      NewValue := (G - 128) * Factor + 128;
      if (NewValue > 255) then NewValue := 255
      else if (NewValue < 0) then NewValue := 0;
      GreenValue := Round(NewValue);

      NewValue := (R - 128) * Factor + 128;
      if (NewValue > 255) then NewValue := 255
      else if (NewValue < 0) then NewValue := 0;
      RedValue := Round(NewValue);

      PixelPtr^ := BlueValue;
      (PixelPtr + 1)^ := GreenValue;
      (PixelPtr + 2)^ := RedValue;
    end;
  end;
end;

procedure RawRemap (Input, Output: TBitmapPointer; Width, Height: Integer; Red, Green, Blue: Byte);
var
  I, J: Integer;
  K, L: Integer;
  A, B: Integer;
  X0, Y0, DX, DY: Integer;
  U, V: Integer;
  ImageData, OutImageData: PByte;
  PixelPtr, OutPixelPtr: PByte;
  BytesPerPixel, BytesPerLine, OutBytesPerPixel, OutBytesPerLine: Integer;
begin
  ImageData := Input^.RawImage.Data;
  BytesPerPixel := Input^.RawImage.Description.BitsPerPixel div 8;
  BytesPerLine := Input^.RawImage.Description.BytesPerLine;

  OutImageData := Output^.RawImage.Data;
  OutBytesPerPixel := Output^.RawImage.Description.BitsPerPixel div 8;
  OutBytesPerLine := Output^.RawImage.Description.BytesPerLine;

  for I := 0 to Output^.Height - 1 do
  begin
    for J := 0 to Output^.Width - 1 do
    begin
      OutPixelPtr := PByte(OutImageData) + I * OutBytesPerLine + J * OutBytesPerPixel;
      OutPixelPtr^ := Blue;
      (OutPixelPtr + 1)^ := Green;
      (OutPixelPtr + 2)^ := Red;
    end;
  end;

  //Ellipsis width, height
  A := Width;
  B := Height;
  //Image center
  X0 := Input^.Width div 2;
  Y0 := Input^.Height div 2;


  for L := 0 to Input^.Height-1 do
  begin
    DY := L - Y0;
    for K := 0 to Input^.Width-1 do
    begin
      PixelPtr := PByte(ImageData) + L * BytesPerLine + K * BytesPerPixel;
      DX := K - X0;
      U := DX;
      if (DY >=0 ) then
         V := Round ( DY + B * exp(-(DX * DX)/(A*A)) * (1 - abs(DY)/(Y0)) )
      else
         V := Round ( DY - B * exp(-(DX * DX)/(A*A)) * (1 - abs(DY)/(Y0)) );

      I := Y0 + V;
      J := X0 + U;

      if (I >= 0) AND (I < Output^.Height) AND (J >= 0) AND (J < Output^.Width) then
      begin
        OutPixelPtr := PByte(OutImageData) + I * OutBytesPerLine + J * OutBytesPerPixel;
        OutPixelPtr^ := PixelPtr^;
        (OutPixelPtr + 1)^ := (PixelPtr + 1)^;
        (OutPixelPtr + 2)^ := (PixelPtr + 2)^;
      end;
    end;
  end;
end;

function c(x: single): single;  //this function implements the bicubic filter
begin
  if (abs(x) >= 0) and (abs(x) <= 1) then
    Result := 0.5 * abs(x * x * x) - sqr(x) + 2 / 3
  else if (abs(x) > 1) and (abs(x) <= 2) then
    Result := -1 / 6 * abs(x * x * x) + sqr(x) - 2 * x + 4 / 3
  else
    Result := 0;
end;

function poly3(x: single): single;
  //this function implements a different bicubic filter of panorama tools
var
  A: single;
begin
  A := -0.75;
  if (abs(x) >= 0) and (abs(x) <= 1) then
    Result := (A + 2) * x * x * x - (A + 3) * x * x + 1
  else if (abs(x) > 1) and (abs(x) <= 2) then
    Result := A * x * x * x - 5 * A * x * x + 8 * A * x - 4 * A
  else
    Result := 0;
end;

function catmullrom(x: single): single;
  //this function implements catmull-rom bicubic filter
var
  A, B: single;
begin
  A := 1 - abs(x);
  B := 2 - abs(x);
  if (abs(x) >= 0) and (abs(x) <= 1) then
    Result := 0.5 * (-3 * A * A * A + 4 * A * A + A)
  else if (abs(x) > 1) and (abs(x) <= 2) then
    Result := 0.5 * (B * B * B - B * B)
  else
    Result := 0;
end;

function s(x: single): single;  //this function implements the quadratic filter
begin
  if (abs(x) >= 0) and (abs(x) <= 0.5) then
    Result := -sqr(x) + 0.75
  else if (abs(x) > 0.5) and (abs(x) <= 1.5) then
    Result := 0.5 * sqr(x) - 1.5 * abs(x) + 9 / 8
  else
    Result := 0;

end;

function hf(x: single): single;  //this function implements the hermite filter
begin
  if abs(x) <= 1 then
    Result := 2 * (abs(x) * abs(x) * abs(x)) - 3 * (abs(x) * abs(x)) + 1
  else
    Result := 0;
end;

function Lancf(x, a: single): single; //this function implements the lanc filter
begin
  if abs(x) <= a then
  begin
    if x <> 0 then Result := a * sin(Pi * x) * sin(Pi / a * x) / (Pi * Pi * x * x)
    else
      Result := 1;
  end
  else
    Result := 0;
end;

function sinc(x: single): single;     //the sinc function
begin
  if x <> 0 then Result := sin(Pi * x) / (Pi * x)
  else
    Result := 1;
end;

function mf(x: single): single; //this function implements the mitchel filter;
begin
  if abs(x) <= 1 then
    Result := 1 / 6 * (7 * abs(x) * abs(x) * abs(x) - 12 * x * x + 16 / 3)
  else if (abs(x) > 1) and (abs(x) < 2) then
    Result := 1 / 6 * (-7 / 3 * abs(x * x * x) + 12 * x * x - 20 * abs(x) + 32 / 3)
  else
    Result := 0;
end;

end.
