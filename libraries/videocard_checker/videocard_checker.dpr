{
videocard_checker.dpr

Plugin to check the pixel modes accepted by the video card

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
library videocard_checker;

{$ifdef fpc}
{$mode objfpc}{$H+}
{$endif}

uses
  Classes, SysUtils,
  Windows, DirectDraw, plugininfo;

{$ifndef fpc}
const
  LineEnding = #10#13;
{$endif}

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

{*******************************************************************
*  Pixel formats
*******************************************************************}
const
  VMG_YUY2 = 0;
  VMG_UYVY = 1;
  VMG_RGB  = 2;

  VMG_MAXSUPPORTEDMODES = 5;

type
  TPixelFormats = array[0..VMG_MAXSUPPORTEDMODES - 1] of DDPIXELFORMAT;

  TAcceptedFormats = array[0..VMG_MAXSUPPORTEDMODES - 1] of Boolean;

{*******************************************************************
* Other global data
*******************************************************************}
var
  mPluginData: TPluginData;
  mAcceptedFormats: TAcceptedFormats;

{*******************************************************************
* Error strings
*******************************************************************}
const
  lpDynamicModeError     = 'Dynamic Mode error';
  lpDynamicModeReport    = 'Dynamic Mode report';

  lpFailedInitDirectDraw = 'Failed to initialize DirectDraw';
  lpFailedSetCooperation = 'Failed to set the Cooperation level on DirectDraw';
  lpFailedPrimarySurface = 'Failed to create the primary surface';
  lpDXFunctionFailed     = 'A DirectX function failed';
  lpNoSupportForOverlays = 'The hardware does not support overlays';
  lpDXError              = 'DirectX error: ';
  lpDrawingFailed        = 'Drawing the image to the overlays surface failed';
  lpConvertionFailed     = 'Converting the image from RGB to YUV failed';
  lpDisplayOverlayFailed = 'Displaying the overlay on screen failed';

{*******************************************************************
* Prototypes
*******************************************************************}
function  LoadColorMode(ddsdOverlay: DDSURFACEDESC2;
 APixelFormats: TPixelFormats; AColorModeID: Integer): Boolean; cdecl; forward;
function  Initialize(vPluginData: TPluginData): Cardinal; cdecl; forward;
procedure Finalize; cdecl; forward;

{*******************************************************************
*  LoadColorMode ()
*
*  DESCRIPTION:    Tryes to load a pixel format
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
function LoadColorMode(ddsdOverlay: DDSURFACEDESC2;
 APixelFormats: TPixelFormats; AColorModeID: Integer): Boolean; cdecl;
var
  ddrval: HResult;
begin
  Result := False;

  ddsdOverlay.ddpfPixelFormat := APixelFormats[AColorModeID];

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
  if ddrval <> DD_OK then
  begin
    Windows.MessageBox(0, lpFailedSetCooperation, lpDynamicModeError, MB_OK);
    Exit;
  end;

  if g_lpdd = nil then
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
  ddsdOverlay.dwFlags := DDSD_CAPS or DDSD_HEIGHT or DDSD_WIDTH or DDSD_PIXELFORMAT;
  ddsdOverlay.dwBackBufferCount := 0;
  ddsdOverlay.dwWidth := mPluginData.GlassWidth^;
  ddsdOverlay.dwHeight := mPluginData.GlassHeight^;
  ddsdOverlay.ddsCaps.dwCaps := DDSCAPS_OVERLAY or DDSCAPS_VIDEOMEMORY;

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

  { RGB 16 bits depth 5-5-5 }
  pixelFormats[1].dwSize := SizeOf(DDPIXELFORMAT);
  pixelFormats[1].dwFlags := DDPF_RGB;
  pixelFormats[1].dwFourCC := 0;
  pixelFormats[1].dwRGBBitCount := 16;
  pixelFormats[1].dwRBitMask := $7C00;
  pixelFormats[1].dwGBitMask := $03E0;
  pixelFormats[1].dwBBitMask := $001F;

  { RGB 16 bits depth 5-6-5 }
  pixelFormats[2].dwSize := SizeOf(DDPIXELFORMAT);
  pixelFormats[2].dwFlags := DDPF_RGB;
  pixelFormats[2].dwFourCC := 0;
  pixelFormats[2].dwRgbBitCount := 16;
  pixelFormats[2].dwRBitMask := $F800;
  pixelFormats[2].dwGBitMask := $07E0;
  pixelFormats[2].dwBBitMask := $001F;

  { Generic YUV: UYVY }
  pixelFormats[3].dwSize := SizeOf(DDPIXELFORMAT);
  pixelFormats[3].dwFlags := DDPF_FOURCC;
  pixelFormats[3].dwFourCC := DWORD(Byte('U') or (Byte('Y') shl 8) or (Byte('V') shl 16) or (Byte('Y') shl 24));
  pixelFormats[3].dwYUVBitCount := 16;

  { Generic YUV: YUY2 - The most commonly supported }
  pixelFormats[4].dwSize := SizeOf(DDPIXELFORMAT);
  pixelFormats[4].dwFlags := DDPF_FOURCC;
  pixelFormats[4].dwFourCC := DWORD(Byte('Y') or (Byte('U') shl 8) or (Byte('Y') shl 16) or (Byte('2') shl 24));
  pixelFormats[4].dwYUVBitCount := 16;

  { Checks all modes }
  for i := 0 to VMG_MAXSUPPORTEDMODES - 1 do
  begin
    mAcceptedFormats[i] := LoadColorMode(ddsdOverlay, pixelFormats, i);
  end;

  { If we reach this point, there was no error }

  Result := VMG_NOERROR;
end;

function BoolToStr(ABool: Boolean): string;
begin
  if ABool then Result := 'Yes'
  else Result := 'No';
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
var
  AMsg: string;
begin
  mPluginData := vPluginData;

  { Initializes the DirectX surfaces }

  Result := InitOverlays(vPluginData);

  if Result <> VMG_NOERROR then Exit;

  { Tells the user of all supported formats }

  AMsg := 'The following color modes are supported by your video card: ' + LineEnding
   + ' RGB 32 bits depth: ' +  BoolToStr(mAcceptedFormats[0]) + LineEnding
   + ' RGB 16 bits depth 5-5-5: ' +  BoolToStr(mAcceptedFormats[1]) + LineEnding
   + ' RGB 16 bits depth 5-6-5: ' +  BoolToStr(mAcceptedFormats[2]) + LineEnding
   + ' Generic YUV: UYVY: ' +  BoolToStr(mAcceptedFormats[3]) + LineEnding
   + ' Generic YUV: YUY2: ' +  BoolToStr(mAcceptedFormats[4]);

  Windows.MessageBox(0, PChar(AMsg), lpDynamicModeReport, MB_OK);
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
  { Use UpdateOverlay() with the DDOVER_HIDE flag to remove an overlay
    from the display }
//  if (g_lpddsOverlay <> nil) then
//   g_lpddsOverlay.UpdateOverlay(nil, g_lpddsPrimary, nil, DDOVER_HIDE, nil);

  {TODO: Verify why we get access violations here if this code is uncommented }
{  if g_lpddsOverlay <> nil then
  begin
    g_lpddsOverlay._Release();
    g_lpddsOverlay := nil;
  end;

  if g_lpddsPrimary <> nil then
  begin
    g_lpddsPrimary._Release();
    g_lpddsPrimary := nil;
  end;

  if g_lpdd <> nil then
  begin
    g_lpdd._Release();
    g_lpdd := nil;
  end;      }
end;

exports
  Initialize,
  Finalize;

begin
end.

