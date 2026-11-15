{
pas_overlays.dpr

The Pascal implementation of the dynamic mode with overlays plugin for the magnifier

Copyright (C) 1998 - 2007 Harri Pyy, Chris O'Donnell, Felipe Monteiro de Carvalho

This file is part of Virtual Magnifying Glass.

Virtual Magnifying Glass is free software;
you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2
as published by the Free Software Foundation.

Virtual Magnifying Glass is distributed in the hope
that it will be useful, but WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.

Please note that the General Public License version 2 does not permit
incorporating Virtual Magnifying Glass into proprietary
programs.

AUTHORS: Chris O'Donnell, Felipe Monteiro de Carvalho and Harri Pyy
}
library pas_overlays;

{$ifdef fpc}
{$mode objfpc}{$H+}
{$endif}

uses
  Classes, SysUtils, Math,
  Windows, DirectDraw, plugininfo;

{*******************************************************************
* Global Variables
*******************************************************************}
var
  {*******************************************************************
  * DirectX variables
  *******************************************************************}
  g_lpdd: IDirectDraw7 = nil;
  g_lpddsPrimary: IDirectDrawSurface7 = nil;
  g_lpddsOverlay: IDirectDrawSurface7 = nil;
  g_lpddsMem: IDirectDrawSurface7 = nil;

  {*******************************************************************
  * Other global data
  *******************************************************************}

  mTimerID: THandle = 0;
  mPluginData: TPluginData;
  mTimerLocked: Boolean = False;

  {*******************************************************************
  * Variables for quick acess of the bitmap in memory
  *******************************************************************}
  bufferBmp: HBITMAP;
  FImageData: PLongWord;

  {*******************************************************************
  * Copied of the mPluginData data, to avoid unexpected changes while
  * drawing a change
  *******************************************************************}
  mviewRect: TRect;
  mviewRectWidth, mviewRectHeight: Integer;
  mMagnification: Double;
  mglassRect: TRect;
  mGlassHeight, mGlassWidth: Integer;

{*******************************************************************
*  Pixel formats
*******************************************************************}
const
  VMG_RGB_32 = 0;
  VMG_RGB_16_555 = 1;
  VMG_RGB_16_565 = 2;
  VMG_RGB_FORMATS = [VMG_RGB_32, VMG_RGB_16_555, VMG_RGB_16_565];
  VMG_UYVY = 3;
  VMG_YUY2 = 4;

  VMG_MAXSUPPORTEDMODES = 5;

type
  TPixelFormats = array[0..VMG_MAXSUPPORTEDMODES - 1] of DDPIXELFORMAT;

{*******************************************************************
* Error strings
*******************************************************************}
const
  lpDynamicModeError     = 'Dynamic Mode error';

  lpFailedInitDirectDraw = 'Failed to initialize DirectDraw';
  lpFailedSetCooperation = 'Failed to set the Cooperation level on DirectDraw';
  lpFailedPrimarySurface = 'Failed to create the primary surface';
  lpDXFunctionFailed     = 'A DirectX function failed';
  lpNoSupportForOverlays = 'The hardware does not support overlays';
  lpDXError              = 'DirectX error: ';
  lpDrawingFailed        = 'Drawing the image to the overlays surface failed';
  lpConvertionFailed     = 'Converting the image from RGB to YUV failed';
  lpDisplayOverlayFailed = 'Displaying the overlay on screen failed';
  lpNoTestedFormatSupported = 'None of the tested pixel formats was accepted';

{*******************************************************************
* Prototypes            
*******************************************************************}
procedure GetPositionRects(); forward;
function  LoadPixelFormat(ddsdOverlay: DDSURFACEDESC2;
 APixelFormats: TPixelFormats; AFormatID: Integer): Boolean; forward;
function  InitOverlays(vPluginData: TPluginData): Cardinal; cdecl; forward;
function  CaptureScreen(x, y, cx, cy: Integer): HBITMAP; forward;
procedure DrawSimpleBorder(hdcSurf: HDC); forward;
function  CreateDrawingImage(): HBITMAP; forward;
function  CopyBitmapToRGBSurface(lpDDSurf: IDirectDrawSurface7; hbm: HBITMAP; hdcImage: HDC): Boolean; forward;
function  CopyBitmapToYUVSurface(lpDDSurf: IDirectDrawSurface7; hbm: HBITMAP; hdcImage: HDC): Boolean; forward;
function  DisplayOverlay(): Boolean; forward;
procedure DrawGlass(_para1:HWND; _para2:UINT; _para3:UINT; _para4:DWORD); stdcall; forward;
function  Initialize(vPluginData: TPluginData): Cardinal; cdecl; forward;
procedure Finalize; cdecl; forward;
procedure HandlePluginMessage(AMessage: Cardinal); cdecl; forward;

{*******************************************************************
*  GetPositionRects ()
*
*  DESCRIPTION:    Fills and calculates the mviewRect and mGlassRect
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure GetPositionRects();
begin
  mglassRect := Bounds(mPluginData.GlassLeft^, mPluginData.GlassTop^,
    mPluginData.GlassHeight^, mPluginData.GlassWidth^);

  mPluginData.CalculateViewRectFunc(mviewRect, mglassRect,
   mPluginData.DesktopPos, mPluginData.Magnification^);
   
  mviewRectHeight := mviewRect.Bottom - mviewRect.Top;
  mviewRectWidth := mviewRect.Right - mviewRect.Left;
  mMagnification := mPluginData.Magnification^;
  mGlassHeight := mglassRect.Bottom - mglassRect.Top;
  mGlassWidth := mglassRect.Right - mglassRect.Left;
end;

{*******************************************************************
*  LoadPixelFormat ()
*
*  DESCRIPTION:    Tryes to load a pixel format
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
function LoadPixelFormat(ddsdOverlay: DDSURFACEDESC2;
 APixelFormats: TPixelFormats; AFormatID: Integer): Boolean;
var
  ddrval: HResult;
begin
  Result := False;

  ddsdOverlay.ddpfPixelFormat := APixelFormats[AFormatID];

  ddrval := g_lpdd.CreateSurface(ddsdOverlay, g_lpddsOverlay, nil);

  if (ddrval <> DD_OK) or (g_lpddsOverlay = nil) then Exit;

// ToDo: Mark a LOG about the errors
//    Windows.MessageBox(0, PChar(lpDXError + IntToHex(ddrval, 8)), lpDynamicModeError, MB_OK);
//    Windows.MessageBox(0, lpDXFunctionFailed, lpDynamicModeError, MB_OK);

  Result := True;
end;

{*******************************************************************
*  InitOverlays ()
*
*  DESCRIPTION:    Initializes the DirectX surfaces
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
function InitOverlays(vPluginData: TPluginData): Cardinal; cdecl;
var
  ddsd, ddsdOverlay: DDSURFACEDESC2;
  capsDrv: TDDCaps;
  pixelFormats: TPixelFormats;
  ddrval: HResult;
  i: Integer;
begin
  Result := VMG_ERROR;

  { Init DirectDraw }

  ddrval := DirectDrawCreateEx(nil, g_lpdd, IID_IDirectDraw7, nil);
  if ddrval <> DD_OK then
  begin
    Windows.MessageBox(0, lpFailedInitDirectDraw, lpDynamicModeError, MB_OK);
    Exit;
  end;

  { For NORMAL cooperative level we no longer need to provide an HWND }

  ddrval := g_lpdd.SetCooperativeLevel(0, DDSCL_NORMAL);
  if (ddrval <> DD_OK) or (g_lpdd = nil) then
  begin
    Windows.MessageBox(0, lpFailedSetCooperation, lpDynamicModeError, MB_OK);
    Exit;
  end;

  {*******************************************************************
  * Create the primary surface
  *
  * The primary surface represents what the user sees on the screen
  *******************************************************************}

  FillChar(ddsd, sizeof(ddsd), #0);
  ddsd.dwSize := sizeof(ddsd);
  ddsd.dwFlags := DDSD_CAPS;
  ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE;
  ddrval := g_lpdd.CreateSurface(ddsd, g_lpddsPrimary, nil);

  if ddrval <> DD_OK then
  begin
    Windows.MessageBox(0, lpFailedPrimarySurface, lpDynamicModeError, MB_OK);
    Exit;
  end;

  { Get driver capabilities to determine Overlay support }

  FillChar(capsDrv, sizeof(capsDrv), #0);
  capsDrv.dwSize := sizeof(capsDrv);
  ddrval := g_lpdd.GetCaps(@capsDrv, nil);

  if ddrval <> DD_OK  then
  begin
    Windows.MessageBox(0, lpDXFunctionFailed, lpDynamicModeError, MB_OK);
    Exit;
  end;

  {*******************************************************************
    Does the driver support overlays in the current mode?
    (Currently the DirectDraw emulation layer does not support overlays.
    Overlay related APIs will fail without hardware support)
  *******************************************************************}

  if (capsDrv.dwCaps and DDCAPS_OVERLAY) = 0 then
  begin
    Windows.MessageBox(0, lpNoSupportForOverlays, lpDynamicModeError, MB_OK);
    Exit;
  end;

  {*******************************************************************
  * Setup the overlay surface
  *
  * With the current DirectX functions it is impossible to determine
  * which color mode the hardware supports for overlays.
  *
  * One possibility is to try many different modes until one works.
  *
  * The user may also set the color mode manually.
  *******************************************************************}

  FillChar(ddsdOverlay, sizeof(ddsdOverlay), #0);
  ddsdOverlay.dwSize := sizeof(ddsdOverlay);
  ddsdOverlay.dwFlags := DDSD_CAPS or DDSD_HEIGHT or
   DDSD_WIDTH or DDSD_BACKBUFFERCOUNT or DDSD_PIXELFORMAT;
  ddsdOverlay.dwBackBufferCount := 2;
  ddsdOverlay.dwWidth := mGlassWidth;
  ddsdOverlay.dwHeight := mGlassHeight;
  ddsdOverlay.ddsCaps.dwCaps := DDSCAPS_OVERLAY or
   DDSCAPS_VIDEOMEMORY or DDSCAPS_FLIP or DDSCAPS_COMPLEX;

  {*******************************************************************
    Fills many possible pixel formats to be utilized.
    The pixel format which offer the best quality is RGB, so it is
    utilized by default
  *******************************************************************}

  { RGB 32 bits depth }
  pixelFormats[0].dwSize := SizeOf(DDPIXELFORMAT);
  pixelFormats[0].dwFlags := DDPF_RGB;
  pixelFormats[0].dwFourCC := 0;
  pixelFormats[0].dwRGBBitCount := 32;
  pixelFormats[0].dwRBitMask := $00FF0000;
  pixelFormats[0].dwGBitMask := $0000FF00;
  pixelFormats[0].dwBBitMask := $000000FF;
  pixelFormats[0].dwRGBAlphaBitMask := 0;

  { RGB 16 bits depth 5-5-5 }
  pixelFormats[1].dwSize := SizeOf(DDPIXELFORMAT);
  pixelFormats[1].dwFlags := DDPF_RGB;
  pixelFormats[1].dwFourCC := 0;
  pixelFormats[1].dwRGBBitCount := 16;
  pixelFormats[1].dwRBitMask := $7C00;
  pixelFormats[1].dwGBitMask := $03E0;
  pixelFormats[1].dwBBitMask := $001F;
  pixelFormats[1].dwRGBAlphaBitMask := 0;

  { RGB 16 bits depth 5-6-5 }
  pixelFormats[2].dwSize := SizeOf(DDPIXELFORMAT);
  pixelFormats[2].dwFlags := DDPF_RGB;
  pixelFormats[2].dwFourCC := 0;
  pixelFormats[2].dwRgbBitCount := 16;
  pixelFormats[2].dwRBitMask := $F800;
  pixelFormats[2].dwGBitMask := $07E0;
  pixelFormats[2].dwBBitMask := $001F;
  pixelFormats[2].dwRGBAlphaBitMask := 0;

  { Generic YUV: UYVY }
  pixelFormats[3].dwSize := SizeOf(DDPIXELFORMAT);
  pixelFormats[3].dwFlags := DDPF_FOURCC;
  pixelFormats[3].dwFourCC := MAKEFOURCC('U', 'Y', 'V', 'Y');
  pixelFormats[3].dwYUVBitCount := 0;
  pixelFormats[3].dwYBitMask := 0;
  pixelFormats[3].dwUBitMask := 0;
  pixelFormats[3].dwVBitMask := 0;
  pixelFormats[3].dwYUVAlphaBitMask := 0;

  { Generic YUV: YUY2 - The most commonly supported }
  pixelFormats[4].dwSize := SizeOf(DDPIXELFORMAT);
  pixelFormats[4].dwFlags := DDPF_FOURCC;
  pixelFormats[4].dwFourCC := MAKEFOURCC('Y', 'U', 'Y', '2');
  pixelFormats[4].dwYUVBitCount := 0;
  pixelFormats[4].dwYBitMask := 0;
  pixelFormats[4].dwUBitMask := 0;
  pixelFormats[4].dwVBitMask := 0;
  pixelFormats[4].dwYUVAlphaBitMask := 0;

  { Verifyes if the user selected any data.
    mPluginData.PluginData = -1 indicates that no specific mode
    was selected, and we should test all possible ones }
  if (mPluginData.PluginData <= -1) then
  begin
    for i := 0 to VMG_MAXSUPPORTEDMODES - 1 do
    begin
      if LoadPixelFormat(ddsdOverlay, pixelFormats, i) then
      begin
        Result := VMG_NOERROR;
        mPluginData.PluginData := i;
        Exit;
      end;
    end;
    
    { If we arrived here, no mode worked }
    Windows.MessageBox(0, lpNoTestedFormatSupported, lpDynamicModeError, MB_OK);
    Exit;
  end
  else
  begin
    { Validates the data entered by the used }
    if (mPluginData.PluginData >= VMG_MAXSUPPORTEDMODES) then
     mPluginData.PluginData := VMG_MAXSUPPORTEDMODES - 1;

    if not LoadPixelFormat(ddsdOverlay, pixelFormats, mPluginData.PluginData) then
    begin
      Windows.MessageBox(0, lpDXFunctionFailed, lpDynamicModeError, MB_OK);
      Exit;
    end;
  end;

  { If we reach this point, there was no error }

  Result := VMG_NOERROR;
end;

{*******************************************************************
*  CaptureScreen ()
*
*  DESCRIPTION:    Takes a area limited screenshot
*
*  PARAMETERS:     x, y, cx, cy   - The rectangle to be captures
*
*  RETURNS:        The screenshot as a HBITMAP
*
*******************************************************************}
function CaptureScreen(x, y, cx, cy: Integer): HBITMAP;
var
  screenDC, memDC: HDC;
begin
  { Get a DC for the screen }
  screenDC := GetWindowDC(GetDesktopWindow);

  { Create a memory device context }
  memDC := CreateCompatibleDC(screenDC);
  Result := CreateCompatibleBitmap(screenDC, cx, cy);

  SelectObject(memDC, Result);

  { Get the display:  copy from display dc to memory dc }
  BitBlt(memDC,
        0, 0,
        cx,
        cy,
        screenDC,
        x, y,
        SRCCOPY{ or CAPTUREBLT on XP});

  { Clean up }
  DeleteDC(memDC);
  DeleteDC(screenDC);
end;

{*******************************************************************
*  drawSimpleBorder ()
*
*  DESCRIPTION:    Draws a simple rectangular border
*
*  PARAMETERS:     hdcSurf        - The DC where to paint to
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure DrawSimpleBorder(hdcSurf: HDC);
var
  pen, oldpen: HPEN;
begin
  { First the outer black frame }
  pen := CreatePen(PS_SOLID, 2, $000000);
  oldPen := HPEN(SelectObject(hdcSurf, pen));
  MoveToEx(hdcSurf, 0, 0, nil);
  LineTo(hdcSurf, mGlassWidth, 0);
  LineTo(hdcSurf, mGlassWidth, mGlassHeight);
  LineTo(hdcSurf, 0, mGlassHeight);
  LineTo(hdcSurf, 0, 0);
  SelectObject(hdcSurf, oldPen);
  DeleteObject(pen);

  { And then the inner grey frame }
  pen := CreatePen(PS_SOLID, 2, $A0A0A0);
  oldPen := HPEN(SelectObject(hdcSurf, pen));
  MoveToEx(hdcSurf, 1, 1, nil);
  LineTo(hdcSurf, mGlassWidth - 2, 1);
  LineTo(hdcSurf, mGlassWidth - 2, mGlassHeight - 2);
  LineTo(hdcSurf, 1, mGlassHeight - 2);
  LineTo(hdcSurf, 1, 1);
  SelectObject(hdcSurf, oldPen);
  DeleteObject(pen);
end;

{*******************************************************************
*  CreateDrawingImage ()
*
*  DESCRIPTION:    Creates our buffer bitmap, where the final image is
*                  stored prior to being rendered on the overlay
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
function CreateDrawingImage(): HBITMAP;
var
  TempDC: HDC;
  BitmapInfo: TBitmapInfo;
  FStride: Integer;
begin
  FStride := mPluginData.DesktopPos.Right * 4;

  BitmapInfo.bmiHeader.biClrUsed := 0;

  with BitmapInfo.bmiHeader do
  begin
    biSize := SizeOf(TBitmapInfoHeader);
    biWidth := mGlassWidth;
    biHeight := mGlassHeight;
    biPlanes := 1;
    biBitCount := 32;
    biCompression := 0;
    biSizeImage := 4 * biWidth * biHeight;
    biXPelsPerMeter := 0;
    biYPelsPerMeter := 0;
    biClrImportant := 0;
  end;

  FImageData := nil;

  TempDC := GetDC(0);
  Result := Windows.CreateDIBSection(TempDC, BitmapInfo, DIB_RGB_COLORS, Pointer(FImageData), 0, 0);
  ReleaseDC(0, TempDC);
end;

{*******************************************************************
*  CopyBitmapToRGBSurface ()
*
*  DESCRIPTION:    Draws the image to a surface using GDI
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
function CopyBitmapToRGBSurface(lpDDSurf: IDirectDrawSurface7; hbm: HBITMAP; hdcImage: HDC): Boolean;
var
  hdcSurf: HDC;
  ddrval: HResult;
begin
  Result := False;
  
  { Get the DC from the overlay surface }

  hdcSurf := 0;

  ddrval := g_lpddsOverlay.GetDC(hdcSurf);

  if (ddrval <> DD_OK) then
  begin
    if (hdcSurf <> 0) then g_lpddsOverlay.ReleaseDC(hdcSurf);

    Exit;
  end;

  { Draws the image }

  StretchBlt(
    hdcSurf,
    0, 0,
    mGlassWidth, mGlassHeight,
    hdcImage,
    0, 0,
    mGlassWidth, mGlassHeight,
    SRCCOPY);

  { Releases the DC }

  g_lpddsOverlay.ReleaseDC(hdcSurf);

  Result := True;
end;

{*******************************************************************
*  CopyBitmapToYUVSurface ()
*
*  DESCRIPTION:    Converts a RGB 32-bits Windows bitmap to a YUV surface
*
*                  The width of both the bitmap and the surface must be a multiple of 2 pixels
*
*                  Currently supported formats:
*                  -  YUY2
*                  -  UYVY
*
*                  The "YUY2" YUV pixel format looks like this:
*                  As a series of BYTES:    [Y0][U][Y1][V] (reverse it for a double word)
*
*                  The "UYVY" YUV pixel format looks like this:
*                  As a series of BYTES:    [U][Y0][V][Y1] (reverse it for a double word)
*
*                  Both formats pack two pixels into a single double word.
*
*                  This function also supports some conditional defines:
*
*                  USE_GET_PIXEL  - Instead of direct memory access, call GetPixel.
*                                   This is much slower
*
*  PARAMETERS:     lpDDSurf       - The target DirectDraw surface
*
*  RETURNS:        Nothing
*
*******************************************************************}
function CopyBitmapToYUVSurface(lpDDSurf: IDirectDrawSurface7; hbm: HBITMAP; hdcImage: HDC): Boolean;
var
  ddrval: HRESULT;
  ddsd: DDSURFACEDESC2;
  x, y, dy, dwWidth, dwHeight: Cardinal;
  lPitch: Integer;
  pSurf: PByte;
  dwBytesInRow: Cardinal;
  color: COLORREF;
  R, G, B, Y0, Y1, U, V: Byte;
  TmpInt: Integer;
  myFile: TextFile;
  FImageDataTmp: pLongWord;
begin
  Result := False;

  { Checks the parameters }
  if (hbm = 0) or (lpDDSurf = nil) then Exit;

  { Structure initialization }
  FillChar(ddsd, sizeof(ddsd), #0);
  ddsd.dwSize := sizeof(ddsd);

  { Lock down the surface so we can modify it's contents }
  ddrval := lpDDSurf.Lock(nil, ddsd, DDLOCK_SURFACEMEMORYPTR or DDLOCK_WAIT, 0);

  { Exit silently if we can't lock the surface }
  if ddrval <> DD_OK then Exit;

  { Stores some surface data in local variables }
  dwWidth := ddsd.dwWidth;
  dwHeight := ddsd.dwHeight;
  lPitch := ddsd.lPitch;
  pSurf := PByte(ddsd.lpSurface);
  dwBytesInRow := ddsd.dwWidth * 2;

  { Go through the image 2 pixels at a time and convert to YUV }
  for y := 0 to mGlassHeight - 1 do
  begin
    x := 0;
    while (x < mGlassWidth) do
    begin
      {*******************************************************************
        Windows stores bitmaps with the Y axis inverted,
        so we need to use the complement of y here
      *******************************************************************}
      dy := mGlassHeight - y;

      { Get the first pixel }
      {$ifdef USE_GET_PIXEL}
        color := GetPixel(hdcImage, x,y);
      {$else}
        {$ifdef FPC}
          color := FImageData[x + dy * mGlassWidth];
        {$else}
          FImageDataTmp := FImageData;
          Inc(FImageDataTmp, (x + dy * mGlassWidth));
          color := FImageDataTmp^;
        {$endif}
      {$endif}
      R := GetRValue(color);
      G := GetGValue(color);
      B := GetBValue(color);
      // The defined range for Y is [16,235] (220 steps)
      TmpInt := Round(0.29*R + 0.59*G + 0.14*B);
      if TmpInt > 235 then Y0 := 235
      else if TmpInt < 16 then Y0 := 16
      else Y0 := TmpInt;
      //  The valid ranges for U and V are [16,239] (235 steps)
      TmpInt := Trunc(128.0 - 0.14*R - 0.29*G + 0.43*B);
      if TmpInt > 239 then U := 239
      else if TmpInt < 16 then U := 16
      else U := TmpInt;

      { Get the Second pixel }
      {$ifdef USE_GET_PIXEL}
        color := GetPixel(hdcImage, x+1,y);
      {$else}
        {$ifdef FPC}
          color := FImageData[x + 1 + dy * mGlassWidth];
        {$else}
          FImageDataTmp := FImageData;
          Inc(FImageDataTmp, (x + 1 + dy * mGlassWidth));
          color := FImageDataTmp^;
        {$endif}
      {$endif}
      R := GetRValue(color);
      G := GetGValue(color);
      B := GetBValue(color);
      // The defined range for Y is [16,235] (220 steps)
      TmpInt := Round(0.29*R + 0.57*G + 0.14*B);
      if TmpInt > 235 then Y1 := 235
      else if TmpInt < 16 then Y1 := 16
      else Y1 := TmpInt;
      //  The valid ranges for U and V are [16,239] (235 steps)
      TmpInt := Round(128.0 + 0.36*R - 0.29*G - 0.07*B);
      if TmpInt > 239 then V := 239
      else if TmpInt < 16 then V := 16
      else V := TmpInt;

      { Draw it to the overlay, acording to the encoding }
      case mPluginData.PluginData of
        VMG_YUY2:
        begin
          pSurf^ := Y0;
          Inc(pSurf);
          pSurf^ := U;
          Inc(pSurf);
          pSurf^ := Y1;
          Inc(pSurf);
          pSurf^ := V;
          Inc(pSurf);
        end;
        
        VMG_UYVY:
        begin
          pSurf^ := U;
          Inc(pSurf);
          pSurf^ := Y0;
          Inc(pSurf);
          pSurf^ := V;
          Inc(pSurf);
          pSurf^ := Y1;
          Inc(pSurf);
        end;
      end;

      x := x + 2;
    end;
    Inc(pSurf, (lPitch - dwBytesInRow));
  end;

  { Unlocks the surface when exiting }
  lpDDSurf.Unlock(nil);

  Result := True;
end;

{*******************************************************************
*  DisplayOverlay ()
*
*  DESCRIPTION:    Displays the overlay on the primary surface
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
function DisplayOverlay(): Boolean;
var
  ddrval: HRESULT;
  srcRect, dstRect: Windows.TRECT;
  ovfx: DDOVERLAYFX;
  capsDrv: TDDCaps;
  offset, horOffset, verOffset: Integer;
  uStretchFactor1000, uDestSizeAlign, uSrcSizeAlign: Integer;
  dwUpdateFlags: Cardinal;
begin
  Result := False;

  { Get driver capabilities }
  FillChar(capsDrv, sizeof(capsDrv), #0);
  capsDrv.dwSize := sizeof(capsDrv);
  ddrval := g_lpdd.GetCaps(@capsDrv, nil);

  if capsDrv.dwMinOverlayStretch > 1000 then uStretchFactor1000 :=  capsDrv.dwMinOverlayStretch
  else uStretchFactor1000 := 1000;
  
  uDestSizeAlign := capsDrv.dwAlignSizeDest;
  uSrcSizeAlign := capsDrv.dwAlignSizeSrc;

  { Source rectangle }

  srcRect.left := 0;
  srcRect.top := 0;
  srcRect.right := mGlassWidth;
  srcRect.bottom := mGlassHeight;

{  // Additional alignment considerations
  if (capsDrv.dwCaps and DDCAPS_ALIGNSIZESRC and uSrcSizeAlign) <> 0 then
   srcRect.right := srcRect.right - srcRect.right mod uSrcSizeAlign;

  // Update Flags
  dwUpdateFlags := DDOVER_SHOW;// or DDOVER_DDFX;

  // -- Setup dest rect on primary surface...
  // Note: We use the source rect dimensions, not the surface dimensions in
  // case they differ.
  // UpdateOverlay will fail unless the minimum stretch value is observed.  }

  dstRect.left := mGlassRect.Left;
  dstRect.top := mGlassRect.Top;
  dstRect.right := mGlassRect.Right;
  dstRect.bottom := mGlassRect.Bottom;

{  dstRect.left := mPluginData.GlassLeft^ - (mPluginData.GlassWidth^ div 2);
  offset := ((srcRect.right * uStretchFactor1000 + 999) div 1000); // adding 999 takes care of integer truncation problems.
  horOffset := 0;
  if (dstRect.left < 0) then
  begin
    // At left border, adjust both src/dst rects
    horOffset := -dstRect.left;
    srcRect.left := horOffset;
    dstRect.left := 0;
    dstRect.right := dstRect.left + offset - horOffset;
  end
  else if ((dstRect.left + offset) > mPluginData.DesktopWidth) then
  begin
    // At right border, adjust both src/dst rects
    horOffset := (dstRect.left + offset) - mPluginData.DesktopWidth;
    dstRect.right := mPluginData.DesktopWidth;
    srcRect.right := srcRect.right - horOffset;
  end
  else
  begin
    // In middle, no adjustments
    dstRect.right := dstRect.left + offset;
  end;

  dstRect.top := mPluginData.GlassTop^ - (mPluginData.DesktopHeight div 2);
  offset := (srcRect.bottom * uStretchFactor1000 div 1000);
  verOffset := 0;
  if (dstRect.top < 0) then
  begin
    // At top border, adjust both src/dst rects
    verOffset := -dstRect.top;
    srcRect.top := verOffset;
    dstRect.top := 0;
    dstRect.bottom := dstRect.top + offset - verOffset;
  end
  else if((dstRect.top + offset) > mPluginData.DesktopHeight) then
  begin
    // At bottom border, adjust both src/dst rects
    verOffset := (dstRect.top + offset) - mPluginData.DesktopHeight;
    dstRect.bottom := mPluginData.DesktopHeight;
    srcRect.bottom := srcRect.bottom - verOffset;
  end
  else
  begin
      // In middle, no adjustments
      dstRect.bottom := dstRect.top + offset;
  end;

  // More alignment considerations
  if (capsDrv.dwCaps and DDCAPS_ALIGNSIZEDEST and uDestSizeAlign) <> 0 then
  begin
      dstRect.right := Round( ( (dstRect.right + uDestSizeAlign - 1) / uDestSizeAlign) * uDestSizeAlign);
  end;         }

  { Update the overlay to the primary surface }
  ddrval := g_lpddsOverlay.UpdateOverlay(
   @srcRect, g_lpddsPrimary, @dstRect, DDOVER_SHOW, nil{@ovfx});

  if ddrval <> DD_OK then Exit;

  Result := True;
end;

{*******************************************************************
*  DrawGlass ()
*
*  DESCRIPTION:    Callback function for the timer
*
*                  This function uses a locking mechanism to drop frames
*                  if the timer is faster then our hability to paint on the
*                  screen.pas_overlays
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure DrawGlass(_para1:HWND; _para2:UINT; _para3:UINT; _para4:DWORD); stdcall;
var
  cxOverlay, cyOverlay: Integer;
  xCapture, yCapture, cxCapture, cyCapture: Integer;
  hdcImage, hdcScreen: HDC;
  screenBmp: HBITMAP;
  addbfx: DDBltFX;
  ddrval: HResult;
  bmp: TBitmap;
begin
  { Locking mechanism }
  if mTimerLocked then Exit
  else mTimerLocked := True;

  { Update position values }
  GetPositionRects();

  { Creates a DC for our drawing }
  hdcImage := Windows.CreateCompatibleDC(0);
  Windows.SelectObject(hdcImage, bufferBmp);

  { Setup the bitmap for the Blt to the overlay surface
    Magnifier window size, also size of the overlay buffer }
  cxOverlay := mGlassWidth;
  cyOverlay := mGlassHeight;
  // Only capture what is necessary, get the correct size
  cxCapture := Round(cxOverlay / mMagnification);
  cyCapture := Round(cyOverlay / mMagnification);
  // Get the origin for the capture
  xCapture := mGlassRect.Left + (cxCapture div 4);
  yCapture := mGlassRect.Top + (cyCapture div 4);

  screenBmp := CaptureScreen(xCapture, yCapture, cxCapture, cyCapture);

  hdcScreen := CreateCompatibleDC(hdcImage);
  SelectObject(hdcScreen, screenBmp);

  // Magnify the captured portion, blits to the DC from the overlay surface
  // Deliberately not using CAPTUREBLT here, it doesn't seem to be necessary,
  // this is probably because there is no real window over the source graphics
  StretchBlt(
      hdcImage,
      0, 0,
      cxOverlay, cyOverlay,
      hdcScreen,
      0, 0,
      cxCapture, cyCapture,
      SRCCOPY);

  DeleteDC(hdcScreen);
  
  // Add the border
  DrawSimpleBorder(hdcImage);

{  hdcScreen := GetDC(0);
  StretchBlt(
      hdcImage,
      0, 0,
      cxOverlay, cyOverlay,
      hdcScreen,
      0, 0,
      cxCapture, cyCapture,
      SRCCOPY);}

  // If we are using YUV mode, convert the bytes to RGB

  if mPluginData.PluginData in VMG_RGB_FORMATS then
  begin
    if not CopyBitmapToRGBSurface(g_lpddsOverlay, bufferBmp, hdcImage) then
    begin
      Windows.KillTimer(0, mTimerID);
      mTimerID := 0;
      Windows.MessageBox(0, lpDrawingFailed, lpDynamicModeError, MB_OK);
      Exit;
    end;
  end
  else
  begin
    if not CopyBitmapToYUVSurface(g_lpddsOverlay, bufferBmp, hdcImage) then
    begin
      Windows.KillTimer(0, mTimerID);
      mTimerID := 0;
      Windows.MessageBox(0, lpConvertionFailed, lpDynamicModeError, MB_OK);
      Exit;
    end;
  end;
  
  // Display the overlay on screen
  if not DisplayOverlay() then
  begin
    Windows.KillTimer(0, mTimerID);
    mTimerID := 0;
    Windows.MessageBox(0, lpDisplayOverlayFailed, lpDynamicModeError, MB_OK);
    Exit;
  end;

  DeleteDC(hdcImage);

  { Locking mechanism }
  mTimerLocked := False;
end;

{*******************************************************************
*  Initialize ()
*
*  DESCRIPTION:    Plugin initialization routine
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
function Initialize(vPluginData: TPluginData): Cardinal; cdecl;
begin
  mPluginData := vPluginData;

  { Copies the current values of the glass properties,
    because if they change while the dynamic mode is on,
    a crash will occur }

  GetPositionRects();

  { Initializes the DirectX surfaces }

  Result := InitOverlays(vPluginData);
  
  if Result <> VMG_NOERROR then Exit;
  
  { Allocates memory for our buffer bitmap }

  bufferBmp := CreateDrawingImage();

  { Setup the timerProc }
  mTimerID := Windows.SetTimer(0, 0, 50, @DrawGlass);
end;

{*******************************************************************
*  Finalize ()
*
*  DESCRIPTION:    Plugin finalization routine
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure Finalize; cdecl;
begin
  { Kill the timer }
  if (mTimerID <> 0) then
  begin
    Windows.KillTimer(0, mTimerID);
    mTimerID := 0;
  end;

  { Use UpdateOverlay() with the DDOVER_HIDE flag to remove an overlay
    from the display }
  if (g_lpddsOverlay <> nil) then
   g_lpddsOverlay.UpdateOverlay(nil, g_lpddsPrimary, nil, DDOVER_HIDE, nil);

  { Release interfaces }
  g_lpddsOverlay := nil;
  g_lpddsPrimary := nil;
  g_lpdd := nil;

  { Cleans the allocated bitmap }
  Windows.DeleteObject(bufferBmp);
end;

procedure HandlePluginMessage(AMessage: Cardinal); cdecl;
begin
  case AMessage of
   VK_UP:
   begin
//     mPluginData.CenterY := mPluginData.CenterY - 10;
   end;
   VK_DOWN:
   begin
//     mPluginData.CenterY := mPluginData.CenterY + 10;
   end;
   VK_RIGHT:
   begin
//     mPluginData.CenterX := mPluginData.CenterX + 10;
   end;
   VK_LEFT:
   begin
//     mPluginData.CenterX := mPluginData.CenterX - 10;
   end;
  end;
end;

exports
  Initialize,
  Finalize,
  HandlePluginMessage;

begin
end.


