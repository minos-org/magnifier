{
glass.pas

Class which implements the magnifying effect

Copyright (C) 1998 - 2010 Harri Pyy, Chris O'Donnell, Felipe Monteiro de Carvalho

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
unit glass;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

{$IFDEF Win32}
  {$DEFINE Windows}
{$ENDIF}

{$IF DEFINED(Windows) or defined(LCLCustomDrawn) or defined(UNIX)}
  {$DEFINE MAGNIFIER_USE_NATIVE_STRETCH}
{$ENDIF}

interface

uses
  BitmapProcess, BitmapThreads,
{$IFDEF Windows}
  {$IFDEF WinCE}
    Windows, Messages,
  {$ELSE}
    Windows, Messages, ShellAPI, jwawinuser,
  {$ENDIF}
{$ENDIF}

{$IFDEF UNIX}
  Unix, LCLType,
{$ENDIF}

  // fcl-image
  fpcanvas, fpimage, fpimgcanv,
  // LCL
  Graphics, Controls, Classes, SysUtils, ExtCtrls, Forms,
  constants, appsettings, translationsvmg, LMessages,
  IntfGraphics, LCLIntf, lazcanvas;

type

  {@@
    viewRect       - The area on the screen which needs to be enlarged.
                     Is completely filled by CalculateViewRect
    drawGlassRect  - The default glass position.
    screenRect     - The size and position of the screen.
  }
  TGlassDrawInfo = packed record
    BorderSize: Integer;
    viewRect, drawGlassRect, screenRect: TRect;
    { Pre-calculated width and height for optimization }
    drawGlassWidth, drawGlassHeight, viewRectWidth, viewRectHeight: Integer;
  end;

  { TGlass }

  TGlass = class(TCustomControl)
  private
    OSVersion: TOSVersion;
    // Bitmaps for the loaded images
    bmpTopLeft, bmpTopRight, bmpBottomLeft, bmpBottomRight: TBitmap;
    bmpTop, bmpLeft, bmpBottom, bmpRight: TBitmap;
    // Used for non-native stretching
    {$IFNDEF MAGNIFIER_USE_NATIVE_STRETCH}
    Image, SecImage: TLazIntfImage;
    TmpBitmap: TBitmap;
    {$IFEND}
    BitmapHandler: TBitmapHandler;
    BackgroundBitmapHandler: TBitmapHandler;
    function  LoadImages: Boolean;
    procedure BackgroundThreadDone(Sender: TObject);
    function CheckBitmapMemorySize(Width, Height: Integer) : Boolean;
  public
    BackgroundThreadFinished: Boolean;
    procedure CalculateDrawInfo(DestCanvas: TCanvas; var DrawInfo: TGlassDrawInfo);
    procedure DrawStandardGlass(DestCanvas: TCanvas; DrawInfo: TGlassDrawInfo);
    procedure DrawGraphicalTools(DestCanvas: TCanvas; DrawInfo: TGlassDrawInfo);
    procedure DrawDynamicModeGlass(DestCanvas: TCanvas; DrawInfo: TGlassDrawInfo);
    procedure BackgroundThreadStart;
    procedure BackgroundThreadStop;
  public
    WindowList: TFPList;
    // Location of the Glass
    GlassTop, GlassLeft, GlassWidth, GlassHeight: Integer;
    // Multimonitor support properties
    XScreen, YScreen, CXScreen, CYScreen: Integer;
    // Bitmaps with size of the display
    bmpDisplay: TBitmap;              { For the original content of the display }
    bmpEnlargedDisplay: TBitmap;      { Temporary image - Only utilized on UNIX}
    bmpOutput: TBitmap;
    Height, Width: Integer;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function  GetDisplayBitmap: Boolean;
    procedure Paint; override;
    procedure EraseBackground(DC: HDC); override;
    procedure WMEraseBkgnd(var Message: TLMEraseBkgnd); message LM_ERASEBKGND;
    class function  LoadBitmap(bmp: TBitmap; NomeDoRecurso: Integer): Boolean;
    function GetCenterPoint(): TPoint;
    // Functions exported to plugins
    function  GetScreenSize(var vXScreen, vYScreen, vCXScreen, vCYScreen: Integer): Boolean; cdecl;
    procedure CalculateViewRect(var viewRect, drawGlassRect: TRect;
      const screenRect: TRect; AMagnification: double); cdecl;
    procedure FixGlassCoordinates(AFixHard: Boolean = False); cdecl;
    // makes inherited events public
    property OnMouseMove;
    property OnClick;
    property OnKeyDown;
    property OnKeyPress;
    property OnMouseWheel;
  end;

var
  vGlass: TGlass;

implementation

{@@
  On different operating systems and different widgetsets
  the behavior of drawing to a rectagle outside the boundaries
  of the paint area are very different. The best way to
  guarantee the same correct behavior everywhere it to
  avoid drawing to ractangles partially outside the paint
  area.

  This function will clip the glassRect rectangle to fit into
  screenRect and calculates a smaller viewRect rectangle that
  represents the area to be enlarged to glassRect to produce
  the screen magnification effect.

  Plugins can access this method.

  @param  viewRect      The area on the screen which needs to be enlarged.
                        Is completely filled by CalculateViewRect
  @param drawGlassRect  Should input the default glass position.
                        Do not pass the glass position variables themselves,
                        but rather a copy of their value, because this function
                        will modify this rectangle to avoid having a glassRect
                        that goes out of the screen.
  @param screenRect     The size and position of the screen.
  @param AMagnification The magnification factor to be applied.
}
procedure TGlass.CalculateViewRect(var viewRect, drawGlassRect: TRect;
  const screenRect: TRect; AMagnification: double); cdecl;
var
  virtGlassTop, virtGlassLeft, virtGlassWidth, virtGlassHeight,
   virtGlassRight, virtGlassBottom: Integer;
begin
  { Initializes helper values }
  virtGlassTop := drawGlassRect.Top;
  virtGlassLeft := drawGlassRect.Left;
  virtGlassWidth := drawGlassRect.Right - drawGlassRect.Left;
  virtGlassHeight := drawGlassRect.Bottom - drawGlassRect.Top;
  virtGlassRight := drawGlassRect.Right;
  virtGlassBottom := drawGlassRect.Bottom;

  { Calculates the initial view area }
  viewRect := Bounds(
   Round(virtGlassLeft + (virtGlassWidth / 2) - (virtGlassWidth) / (2 * AMagnification)),
   Round(virtGlassTop + (virtGlassHeight / 2) - (virtGlassHeight) / (2 * AMagnification)),
   Round(virtGlassWidth / AMagnification),
   Round(virtGlassHeight / AMagnification));

  { Clips the glassRect to fit the screen }
  if drawGlassRect.Left < 0 then drawGlassRect.Left := 0;
  if drawGlassRect.Top < 0 then drawGlassRect.Top := 0;
  if drawGlassRect.Right > screenRect.Right then drawGlassRect.Right := screenRect.Right;
  if drawGlassRect.Bottom > screenRect.Bottom then drawGlassRect.Bottom := screenRect.Bottom;

  { Adjusts the viewRect if the glassRect was clipped }
  if virtGlassLeft <> drawGlassRect.Left then
    viewRect.Left := Round(viewRect.Left - virtGlassLeft / AMagnification);

  if virtGlassTop <> drawGlassRect.Top then
    viewRect.Top := Round(viewRect.Top - virtGlassTop / AMagnification);

  if virtGlassRight <> drawGlassRect.Right then
    viewRect.Right := Round(viewRect.Right - (virtGlassRight - screenRect.Right) / AMagnification);

  if virtGlassBottom <> drawGlassRect.Bottom then
    viewRect.Bottom := Round(viewRect.Bottom - (virtGlassBottom - screenRect.Bottom) / AMagnification);
end;

{@@
  Loads bitmap from an internal resource to a bitmap object
}
class function TGlass.LoadBitmap(bmp: TBitmap; NomeDoRecurso: Integer): Boolean;
var
  buffer: THandle;
  memstream: TMemoryStream;
  FileName: string;
begin
  Result := False;

{$IFDEF Win32}

  bmp.LoadFromResourceID(hInstance, NomeDoRecurso);

{$ENDIF}
{$IFDEF Unix}

  case NomeDoRecurso of
   IDB_TOPLEFT: FileName := 'topleft.bmp';
   IDB_TOPRIGHT: FileName := 'topright.bmp';
   IDB_BOTTOMLEFT: FileName := 'bottomleft.bmp';
   IDB_BOTTOMRIGHT: FileName := 'bottomright.bmp';
   IDB_TOP: FileName := 'top.bmp';
   IDB_LEFT: FileName := 'left.bmp';
   IDB_BOTTOM: FileName := 'bottom.bmp';
   IDB_RIGHT: FileName := 'right.bmp';
   IDB_CECAE: FileName := 'cecae.bmp';
   IDB_FEUSP: FileName := 'feusp.bmp';
   IDB_VMG: FileName := 'vmg.bmp';
   IDB_LUPA: FileName := 'lupa.bmp';
   IDB_USPLEGAL: FileName := 'usplegal.bmp';
  else
    WriteLn('Wrong image name');
    Exit;
  end;

  Write('[TGlass.LoadBitmap] Loading ' + vConfigurations.MyDirectory + FileName);

  try
    bmp.LoadFromFile(vConfigurations.MyDirectory + FileName);
  except
    WriteLn(ErrorLoading);
    Exit;
  end;

  WriteLn('');

{$ENDIF}

  Result := True;
end;

{@@
  Calculates the point in the middle of the center display pixel
}
function TGlass.GetCenterPoint(): TPoint;
begin
  Result.X := GlassLeft + (GlassWidth div 2);
  Result.Y := GlassTop + (GlassHeight div 2);
end;

{@@
  Load bitmaps required by the Magnifying Glass
  This function loads and generates the rectangular glass
}
function TGlass.LoadImages: Boolean;
begin
  Result := True;

  if (not LoadBitmap(bmpTopLeft, IDB_TOPLEFT)) then Result := False;
  bmpTopLeft.Transparent := True;
  bmpTopLeft.TransparentColor := clFuchsia;

  if (not LoadBitmap(bmpTopRight, IDB_TOPRIGHT)) then Result := False;
  bmpTopRight.Transparent := True;
  bmpTopRight.TransparentColor := clFuchsia;

  if (not LoadBitmap(bmpBottomLeft, IDB_BOTTOMLEFT)) then Result := False;
  bmpBottomLeft.Transparent := True;
  bmpBottomLeft.TransparentColor := clFuchsia;

  if (not LoadBitmap(bmpBottomRight, IDB_BOTTOMRIGHT)) then Result := False;
  bmpBottomRight.Transparent := True;
  bmpBottomRight.TransparentColor := clFuchsia;

  if (not LoadBitmap(bmpTop, IDB_TOP)) then Result := False;
  bmpTop.Transparent := True;
  bmpTop.TransparentColor := clFuchsia;

  if (not LoadBitmap(bmpLeft, IDB_LEFT)) then Result := False;
  bmpLeft.Transparent := True;
  bmpLeft.TransparentColor := clFuchsia;

  if (not LoadBitmap(bmpBottom, IDB_BOTTOM)) then Result := False;
  bmpBottom.Transparent := True;
  bmpBottom.TransparentColor := clFuchsia;

  if (not LoadBitmap(bmpRight, IDB_RIGHT)) then Result := False;
  bmpRight.Transparent := True;
  bmpRight.TransparentColor := clFuchsia;

  // Check the sizes
  if ((bmpTopLeft.Width <> bmpTopRight.Width) or
        (bmpTopLeft.Height <> bmpTopRight.Height) or
        (bmpBottomLeft.Width <> bmpBottomRight.Width) or
        (bmpBottomLeft.Height <> bmpBottomRight.Height)) // Sizes must match
        then Result := False;

  // Check the sizes
  if ((bmpLeft.Width <> bmpRight.Width) or
      (bmpLeft.Height <> bmpRight.Height) or
      (bmpTop.Width <> bmpBottom.Width) or
      (bmpTop.Height <> bmpBottom.Height)) // Sizes must match
      then Result := False;

end;

{@@
  Creates a object from the TAplicativo class

  @param  AOwner   The owner of the component (this may be nil)

  @return          A pointer to the newly created object
}
constructor TGlass.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  WindowList := TFPList.Create;
  OSVersion := vConfigurations.GetOSVersion();

  // Create bitmap holding objects
  bmpDisplay := TBitmap.Create;
  bmpEnlargedDisplay := TBitmap.Create;
  bmpOutput := TBitmap.Create;
  bmpTopLeft := TBitmap.Create;
  bmpTopRight := TBitmap.Create;
  bmpBottomLeft := TBitmap.Create;
  bmpBottomRight := TBitmap.Create;
  bmpTop := TBitmap.Create;
  bmpLeft := TBitmap.Create;
  bmpBottom := TBitmap.Create;
  bmpRight := TBitmap.Create;

  // Load bitmaps
  if not LoadImages then
  begin
{$ifdef Unix}
    WriteLn('Error loading bitmaps');
{$endif}
  end;

{$IFNDEF MAGNIFIER_USE_NATIVE_STRETCH}
  Image := TLazIntfImage.Create(0, 0);
  TmpBitmap := TBitmap.Create;
  SecImage := TLazIntfImage.Create(0, 0);
{$IFEND}
  BitmapHandler := TBitmapHandler.Create;
  BackgroundBitmapHandler := TBitmapHandler.Create;
  DoubleBuffered := True;
end;

{@@
  Destroys a object derived from the TGlass class
}
destructor TGlass.Destroy;
begin
  {$IFNDEF MAGNIFIER_USE_NATIVE_STRETCH}
  TmpBitmap.Free;
  Image.Free;
  SecImage.Free;
  {$IFEND}

  bmpDisplay.Free;
  bmpEnlargedDisplay.Free;
  bmpOutput.Free;
  bmpTopLeft.Free;
  bmpTopRight.Free;
  bmpBottomLeft.Free;
  bmpBottomRight.Free;
  bmpTop.Free;
  bmpLeft.Free;
  bmpBottom.Free;
  bmpRight.Free;

  WindowList.Free;
  BitmapHandler.Free;
  BackgroundBitmapHandler.Free;

  inherited Destroy;
end;

{@@

  Makes sure that the glass coordinates don't
  go outside the screen area. Utilized by plugins.

  @param AFixHard   If true, then it won't let the glass leave the screen area at all
                    If false, it will let the glass go up to it's half width and height
                    outside the screen area, just like the standard glass does, to catch
                    the edges with the standard central focus.
}
procedure TGlass.FixGlassCoordinates(AFixHard: Boolean = False); cdecl;
var
  halfWidth, halfHeight: Integer;
begin
  if AFixHard then
  begin
    if vGlass.GlassLeft < 0 then vGlass.GlassLeft := 0;
    if vGlass.GlassTop < 0 then vGlass.GlassTop := 0;
    if vGlass.GlassLeft + vGlass.GlassWidth > vGlass.CXScreen then
      vGlass.GlassLeft := vGlass.CXScreen - vGlass.GlassWidth;
    if vGlass.GlassTop + vGlass.GlassHeight > vGlass.CYScreen then
      vGlass.GlassTop := vGlass.CYScreen - vGlass.GlassHeight;
  end
  else
  begin
    halfWidth := vGlass.GlassWidth div 2;
    halfHeight := vGlass.GlassHeight div 2;
    if vGlass.GlassLeft < -halfWidth then vGlass.GlassLeft := -halfWidth;
    if vGlass.GlassTop < -halfHeight then vGlass.GlassTop := -halfHeight;
    if vGlass.GlassLeft + halfWidth > vGlass.CXScreen then
      vGlass.GlassLeft := vGlass.CXScreen - halfWidth;
    if vGlass.GlassTop + halfHeight > vGlass.CYScreen then
      vGlass.GlassTop := vGlass.CYScreen - halfHeight;
  end;
end;

{@@
  Get the RECT of the desktop, note that the origin
  will have a negative xCoord if a multi-monitor
  system doesn't have the primary monitor on the left
}
function TGlass.GetScreenSize(var vXScreen, vYScreen, vCXScreen, vCYScreen: Integer): Boolean; cdecl;
begin
{$IFDEF Windows}
  vXScreen := 0;
  vYScreen := 0;

{$ifdef wince}
  if (OSVersion >= vwWinCE4) then
{$else}
  if (OSVersion >= vwWin98) then
{$endif}
  begin
    vCXScreen := GetSystemMetrics(SM_CXVIRTUALSCREEN);
    vCYScreen := GetSystemMetrics(SM_CYVIRTUALSCREEN);
    vXScreen := GetSystemMetrics(SM_XVIRTUALSCREEN);
    vYScreen := GetSystemMetrics(SM_YVIRTUALSCREEN);
  end
  else
  begin
    // NOTE:  VIRTUALSCREEN doesn't seem to be supported on win95, nt4
    // And also on Windows CE <= 3.0
    // (according to MSDN).  This will only get the screen size of
    // the primary monitor, and thus, this app won't have multi-
    // monitor support.  It may be possible to get the virtual screen
    // resolution another way.
    vCXScreen := GetSystemMetrics(SM_CXSCREEN);
    vCYScreen := GetSystemMetrics(SM_CYSCREEN);
  end;
{$ENDIF}
{$IFDEF Unix}
  vCXScreen := Screen.Width;
  vCYScreen := Screen.Height;
  vXScreen := 0;
  vYScreen := 0;
{$ENDIF}

  Result := True;
end;

{$IFDEF WINDOWS}
function GetDisplayBitmap_EnumCallback(_para1:HWND; _para2:LPARAM):WINBOOL;stdcall;
begin
  Result := True;
  if not IsWindowVisible(_para1) then Exit;
  if _para1 = vGlass.Parent.Handle then Exit;
  vGlass.WindowList.Add(Pointer(_para1));
end;
{$ENDIF}

{@@
  Get contents of the display
}
function TGlass.GetDisplayBitmap: Boolean;
var
  c: TCanvas;
  srcRect, destRect: TRect;
  ScreenDC: HDC;
  lCurWindow, lVMGWindow: HWND;
  lCurWindowText: array[0..255] of WideChar;
  i: Integer;
  // for Mac OS X
  bmpRetinaDisplay: TBitmap;

  {$IFDEF WINDOWS}
  procedure GetDisplayBitmap_PrintWindowToHDC(AWindow: HWND; ADest: HDC);
  var
    wi: jwawinuser.WINDOWINFO;
    lClientRect, lWindowRect: TRect;
    lBorderX, lBorderY: Integer;
    lWindowDC: HDC;
  begin
    jwawinuser.GetWindowInfo(AWindow, wi);
    lWindowDC := Windows.GetDC(AWindow);

    // Take into account the border difference
    Windows.GetClientRect(AWindow, lClientRect);
    Windows.GetClientRect(AWindow, lWindowRect);
    lBorderX := (lWindowRect.right - lWindowRect.left) - lClientRect.right;
    lBorderY := (lWindowRect.bottom - lWindowRect.top) - lClientRect.bottom;

    Windows.BitBlt(ADest, wi.rcWindow.Left + lBorderX, wi.rcWindow.Top + lBorderY,
      wi.rcWindow.Right - wi.rcWindow.left,
      wi.rcWindow.bottom - wi.rcWindow.top,
      lWindowDC, 0, 0, SRCCOPY);
    Windows.ReleaseDC(AWindow, lWindowDC);
  end;
  {$ENDIF}

begin
  Result := True;

{$IFDEF Windows}

  c := TCanvas.Create;
  try
    try
      c.Handle := GetWindowDC(GetDesktopWindow());

      srcRect := Classes.Bounds(XScreen, YScreen, CXScreen, CYScreen);

      destRect := Classes.Bounds(0, 0, CXScreen, CYScreen);

      {*******************************************************************
      *  Fix for an issue with Windows 98 on StretchBlt
      *******************************************************************}
      if OSVersion >= vwWin2000 then
      begin
        bmpDisplay.Width := CXScreen;
        bmpDisplay.Height := CYScreen;
      end
      else
      begin
        bmpDisplay.Width := CXScreen * 2;
        bmpDisplay.Height := CYScreen * 2;
      end;

      if not vConfigurations.UsePlugins then
      begin
        bmpDisplay.Canvas.CopyRect(destRect, c, srcRect);
      end
      {*******************************************************************
      *  Dynamic mode screenshot improvement by drawing all windows in an iteration
      *******************************************************************}
      else
      begin
        lVMGWindow := Parent.Handle;
        //WriteLn('===============================');
        WindowList.Clear;
        Windows.EnumWindows(@GetDisplayBitmap_EnumCallback, bmpDisplay.Canvas.Handle);

        for i := 0 to WindowList.Count-1 do
        begin
          lCurWindow := HWND(WindowList.Items[WindowList.Count-1-i]);
          //PrintWindow(lCurWindow, bmpDisplay.Canvas.Handle, 0);
          GetDisplayBitmap_PrintWindowToHDC(lCurWindow, bmpDisplay.Canvas.Handle);
          GetWindowTextW(lCurWindow, lCurWindowText, 255);
          //WriteLn('Printing window _para1='+IntToHex(lCurWindow, 8)+' title='+lCurWindowText);
        end;
      end;
    finally
      ReleaseDC(0, c.Handle);
      c.Free;
    end;
  except
    Result := False;
    Exit;
  end;

{$ENDIF}
{$IFDEF Unix}

  ScreenDC := GetDC(0);

  {$ifdef Darwin}
  bmpRetinaDisplay := TBitmap.Create;
  bmpRetinaDisplay.LoadFromDevice(ScreenDC);
  bmpDisplay.Width := CXScreen;
  bmpDisplay.Height := CYScreen;
  StretchBlt(bmpDisplay.Canvas.Handle, 0, 0, CXScreen, CYScreen,
    bmpRetinaDisplay.Canvas.Handle, 0, 0, bmpRetinaDisplay.Width, bmpRetinaDisplay.Height,
    SRCCOPY);
  bmpRetinaDisplay.Free;
  {$else}
  bmpDisplay.LoadFromDevice(ScreenDC);
  {$endif}

  ReleaseDC(0, ScreenDC);
{$ENDIF}
BackgroundThreadStart;
end;

{@@

  @param  DestCanvas  The canvas where it will be drawn
  @param  DrawInfo    Record with drawing position information
}
procedure TGlass.CalculateDrawInfo(DestCanvas: TCanvas; var DrawInfo: TGlassDrawInfo);
begin
  with DrawInfo do
  begin
  if vConfigurations.graphicalBorder and
   not vConfigurations.UsePlugins then BorderSize := 10
  else BorderSize := 2;

  {*******************************************************************
  *  Calculates the rectangle (ScreenRect) to be magnified to fit ClientRect
  *  For example 4x magnification means that 1/4 of the picture is enlarged
  * to fill the whole picture
  *******************************************************************}
  screenRect.Left := XScreen;
  screenRect.Top := YScreen;
  screenRect.Right := CXScreen;
  screenRect.Bottom := CYScreen;

  {*******************************************************************
  *  Calculates the necessary rectangles and allows CalculateViewRect
  *  to return the drawing coordinates
  *******************************************************************}
  drawGlassRect.Left := GlassLeft + BorderSize;
  drawGlassRect.Top := GlassTop + BorderSize;
  drawGlassRect.Right := GlassLeft + GlassWidth - BorderSize;
  drawGlassRect.Bottom := GlassTop + GlassHeight - BorderSize;

  CalculateViewRect(viewRect, drawGlassRect, screenRect, vConfigurations.iMagnification);

  { Pre-Calculates the Width and Height of the rectangles to simplify the drawing code }
  drawGlassWidth := drawGlassRect.Right - drawGlassRect.Left;
  drawGlassHeight := drawGlassRect.Bottom - drawGlassRect.Top;

  viewRectWidth := viewRect.Right - viewRect.Left;
  viewRectHeight := viewRect.Bottom - viewRect.Top;
  end; // with
end;

{@@
  Draws the glass to a Canvas.
  There are 3 layers to be painted:

  1 - The screen outside the corners. Exists only when
      graphicalBorder is True;
  2 - The magnified screen.
  3 - The Border, either transparent or not;

  @param  DestCanvas  The canvas where it will be drawn
  @param  DrawInfo    Record with drawing position information
}
procedure TGlass.DrawStandardGlass(DestCanvas: TCanvas; DrawInfo: TGlassDrawInfo);
var
  I: Integer;
  dwROP: Cardinal;
  ImageCanvas: TFPImageCanvas = nil;
{$IFDEF MAGNIFIER_USE_NATIVE_STRETCH}
  fm: Single;
  inBitmap, outBitmap, Remap, Tmp: TBitmap;
  Threading: Boolean;
{$IFEND}
begin
  Threading := True;
  with DrawInfo do
  begin
  {*******************************************************************
  *  Color invertion
  *******************************************************************}
  if vConfigurations.invertColors then dwROP := SRCINVERT
  else dwROP := SRCCOPY;

  {*******************************************************************
  *  The part outside the glass shows the background as it is (1:1 magnification)
  *  In MacBook with Retina display we need to make sure the image is scaled
  *  to fit the screen
  *******************************************************************}
  DestCanvas.Draw(0, 0, bmpDisplay);

  if (vConfigurations.PostProcessing = False) OR
     (vConfigurations.AntiAliasing = False) OR
     (BackgroundThreadFinished = False)   then
  begin

  {*******************************************************************
  *  Draws the enlarged glass contents
  *******************************************************************}
{$IFDEF MAGNIFIER_USE_NATIVE_STRETCH}

    fm := vConfigurations.iMagnification;
    inBitmap := TBitmap.Create;
    inBitmap.Width := viewRectWidth;
    inBitmap.Height := viewRectHeight;
    inBitmap.Canvas.CopyRect(Bounds(0, 0, viewRectWidth, viewRectHeight), bmpDisplay.Canvas, viewRect);
{$IFDEF Unix}
  Threading := False;
{$ENDIF}
    if (Threading = False) AND not (vConfigurations.AntiAliasing)   then
    begin
      outBitmap := TBitmap.Create;
      outBitmap.Width := Round(viewRectWidth * fm);
      outBitmap.Height := Round(viewRectHeight * fm);
      if vConfigurations.AntiAliasing then
        RawBilinear(@inBitmap, @outBitmap, FM, vConfigurations.Contrast)
      else
        RawPixelRepetition(@inBitmap, @outBitmap, FM, vConfigurations.Contrast);

      if vConfigurations.RemapEnabled then
      begin
        Remap := TBitmap.Create;
        Remap.Width := outBitmap.Width;
        Remap.Height := outBitmap.Height;
        RawRemap(@outBitmap, @remap, vConfigurations.RemapWidth, vConfigurations.RemapHeight, vConfigurations.RemapRed, vConfigurations.RemapGreen, vConfigurations.RemapBlue);
        if vConfigurations.invertColors then
          RawInvertColors(Remap);
        DestCanvas.Draw(drawGlassRect.Left, drawGlassRect.Top, Remap);
        Remap.Free;
      end
      else
      begin
        if vConfigurations.invertColors then
          RawInvertColors(outBitmap);
        DestCanvas.Draw(drawGlassRect.Left, drawGlassRect.Top, outBitmap);
      end;

      outBitmap.Free;

    end
    else
    begin
      BitmapHandler.FBitmap := @inBitmap;
      BitmapHandler.BitmapWidth := Round(viewRectWidth * fm);
      BitmapHandler.BitmapHeight := Round(viewRectHeight * fm);
      BitmapHandler.FM := fm;
      BitmapHandler.Invert := vConfigurations.invertColors;
      BitmapHandler.Contrast := vConfigurations.Contrast;
      if vConfigurations.AntiAliasing then
        if vConfigurations.ExtraAntiAliasing then
          BitmapHandler.PAction := CatmullRomAction
        else
          BitmapHandler.PAction := BilinearAction
      else
        BitmapHandler.PAction := PixelRepetitionAction;
      BitmapHandler.Start;

      if vConfigurations.RemapEnabled then
      begin
        Remap := TBitmap.Create;
        Remap.Width := BitmapHandler.BitmapWidth;
        Remap.Height := BitmapHandler.BitmapHeight;
        RawRemap(@BitmapHandler.Bitmap, @remap, vConfigurations.RemapWidth, vConfigurations.RemapHeight, vConfigurations.RemapRed, vConfigurations.RemapGreen, vConfigurations.RemapBlue);
        DestCanvas.CopyRect(drawGlassRect, remap.Canvas, Bounds(0, 0, BitmapHandler.BitmapWidth, BitmapHandler.BitmapHeight));
        Remap.Free;
      end
      else
      begin
        DestCanvas.CopyRect(drawGlassRect, BitmapHandler.Bitmap.Canvas, Bounds(0, 0, BitmapHandler.BitmapWidth, BitmapHandler.BitmapHeight));
      end;
    end;
    inBitmap.Free;
  end
  else
    begin
      if vConfigurations.RemapEnabled then
      begin
        Tmp := TBitmap.Create;
        Tmp.Width := Trunc(viewRectWidth * vConfigurations.iMagnification);
        Tmp.Height := Trunc(viewRectHeight * vConfigurations.iMagnification);
        Tmp.Canvas.CopyRect(Bounds(0, 0, tmp.Width, tmp.Height),
                            BackgroundBitmapHandler.Bitmap.Canvas,
                            Bounds(Trunc(viewRect.Left * vConfigurations.iMagnification),
                                   Trunc(viewRect.Top * vConfigurations.iMagnification),
                                   Trunc(viewRectWidth * vConfigurations.iMagnification),
                                   Trunc(viewRectHeight * vConfigurations.iMagnification)));
        Remap := TBitmap.Create;
        Remap.Width := Tmp.Width;
        Remap.Height := Tmp.Height;
        RawRemap(@tmp, @remap, vConfigurations.RemapWidth, vConfigurations.RemapHeight, vConfigurations.RemapRed, vConfigurations.RemapGreen, vConfigurations.RemapBlue);
        DestCanvas.CopyRect(drawGlassRect,
                            remap.Canvas,
                            Bounds(0, 0, remap.Width, remap.Height));
        Remap.Free;
        Tmp.Free;
      end
      else
      begin
        DestCanvas.CopyRect(drawGlassRect,
                            BackgroundBitmapHandler.Bitmap.Canvas,
                            Bounds(Trunc(viewRect.Left * vConfigurations.iMagnification),
                                   Trunc(viewRect.Top * vConfigurations.iMagnification),
                                   Trunc(viewRectWidth * vConfigurations.iMagnification),
                                   Trunc(viewRectHeight * vConfigurations.iMagnification)));
      end;







    end;
{$ELSE}

  // First we need to load the TLazIntfImage from a dummy bitmap to initialize it
  TmpBitmap.Width := drawGlassWidth;
  TmpBitmap.Height := drawGlassHeight;
  Image.LoadFromBitmap(TmpBitmap.Handle, 0);

  // Now build a Canvas for our destination image
  ImageCanvas := TFPImageCanvas.create(Image);
  if vConfigurations.AntiAliasing then
    ImageCanvas.Interpolation := TMitchelInterpolation.Create
  else
    ImageCanvas.Interpolation := TFPSharpInterpolation.Create;

  // Now Copy a section of the display
  bmpEnlargedDisplay.Height := viewRectHeight;
  bmpEnlargedDisplay.Width := viewRectWidth;
  bmpEnlargedDisplay.Canvas.CopyRect(
   Bounds(0, 0, viewRectWidth, viewRectHeight),
   bmpDisplay.Canvas, viewRect);
  SecImage.LoadFromBitmap(bmpEnlargedDisplay.Handle, 0);

  // Enlarge this section of the display
  ImageCanvas.StretchDraw(
    0, 0, drawGlassWidth, drawGlassHeight,
    SecImage);

  // And draw the result to our Canvas via a temporary bitmap
  TmpBitmap.LoadFromIntfImage(Image);
  DestCanvas.Draw(drawGlassRect.Left, drawGlassRect.Top, TmpBitmap);

  ImageCanvas.Interpolation.Free;
  ImageCanvas.Interpolation := nil;
  ImageCanvas.Free;
{$IFEND}

  {*******************************************************************
  *  Draws the graphical border
  *******************************************************************}
  if vConfigurations.graphicalBorder then
  begin
    // Corners
    DestCanvas.Draw(GlassLeft, GlassTop, bmpTopLeft);
    DestCanvas.Draw(GlassLeft + GlassWidth - 32, GlassTop, bmpTopRight);
    DestCanvas.Draw(GlassLeft, GlassTop + GlassHeight - 32, bmpBottomLeft);
    DestCanvas.Draw(GlassLeft + GlassWidth - 32, GlassTop + GlassHeight - 32, bmpBottomRight);

    // Sides
    for i := 1 to vConfigurations.xSquare - 2 do
     DestCanvas.Draw(GlassLeft + 32 * i, GlassTop, bmpTop);
    for i := 1 to vConfigurations.xSquare - 2 do
     DestCanvas.Draw(GlassLeft + 32 * i, GlassTop + GlassHeight - 32, bmpBottom);
    for i := 1 to vConfigurations.ySquare - 2 do
     DestCanvas.Draw(GlassLeft, GlassTop + 32 * i, bmpLeft);
    for i := 1 to vConfigurations.ySquare - 2 do
     DestCanvas.Draw(GlassLeft + GlassWidth - 32, GlassTop + 32 * i, bmpRight);
  end
  else
  {*******************************************************************
  *  Draws the rectangular border
  *******************************************************************}
  begin
    DestCanvas.Brush.Color := clBlack;
    DestCanvas.FrameRect(Bounds(GlassLeft, GlassTop, GlassWidth, GlassHeight));
    DestCanvas.FrameRect(Bounds(GlassLeft + 1, GlassTop + 1, GlassWidth - 2, GlassHeight - 2));
    DestCanvas.Brush.Color := clGray;
    DestCanvas.FrameRect(Bounds(GlassLeft + 2, GlassTop + 2, GlassWidth - 4, GlassHeight - 4));
    DestCanvas.FrameRect(Bounds(GlassLeft + 3, GlassTop + 3, GlassWidth - 6, GlassHeight - 6));
  end;
  end; // with
end;

procedure TGlass.BackgroundThreadStart;
var
  Width, Height: Integer;
begin
  if not (vConfigurations.PostProcessing) then Exit;
  if not (vConfigurations.AntiAliasing) then Exit;

  Width := Round(bmpDisplay.Width * vConfigurations.iMagnification);
  Height := Round(bmpDisplay.Height * vConfigurations.iMagnification);

  if not (CheckBitmapMemorySize(Width, Height)) then Exit;

  BackgroundThreadFinished := False;
  BackgroundBitmapHandler.Reset;
  BackgroundBitmapHandler.FBitmap := @bmpDisplay;
  BackgroundBitmapHandler.BitmapWidth := Width;
  BackgroundBitmapHandler.BitmapHeight := Height;
  BackgroundBitmapHandler.FM := vConfigurations.iMagnification;
  BackgroundBitmapHandler.Invert := vConfigurations.invertColors;
  BackgroundBitmapHandler.Contrast := vConfigurations.Contrast;
  if vConfigurations.AntiAliasing then
    if vConfigurations.ExtraAntiAliasing then
      BackgroundBitmapHandler.PAction := CatmullRomAction
    else
      BackgroundBitmapHandler.PAction := BilinearAction
  else
    BackgroundBitmapHandler.PAction := PixelRepetitionAction;
  BackgroundBitmapHandler.BackgroundPerform(BackgroundThreadDone);
end;

procedure TGlass.BackgroundThreadDone(Sender: TObject);
begin
  BackgroundThreadFinished := True;
  Paint;
  Self.Invalidate;
end;

procedure TGlass.BackgroundThreadStop;
begin
  BackgroundBitmapHandler.Reset;
end;

function TGlass.CheckBitmapMemorySize(Width, Height: Integer): Boolean;
var
  MemoryAvailable, MemoryRequired: Int64;
begin
  MemoryAvailable := Int64(vConfigurations.MemMb) * 1024 * 1024;
  MemoryRequired := Int64(Width) * Int64(Height) * 4;
  Result := MemoryRequired < MemoryAvailable;
end;

{@@
  Graphical Tools
}
//  The commented parts are code from 2.35 version not merged here yet
procedure TGlass.DrawGraphicalTools(DestCanvas: TCanvas; DrawInfo: TGlassDrawInfo);
var
  i, MinWidth, MinHeight: Integer;
  GlassMinusBorderLeft, GlassMinusBorderTop: Integer;
  CentralColor: TColor;
  centerPt: TPoint;
  { Tickmarks }
  step, stepMinor, tickSize, tickCount: Integer;
  R, G, B: Byte;
begin
  with DrawInfo do
  begin
  if (vConfigurations.showTools) then
  begin
    { Pre-calculates some coordinates to simplify the code }
    GlassMinusBorderLeft := drawGlassRect.Left - BorderSize;
    GlassMinusBorderTop := drawGlassRect.Top - BorderSize;

    // Standard properties of the Canvas
    DestCanvas.Brush.Color := clGray;
    DestCanvas.Brush.Style := bsSolid;
    DestCanvas.Font.Color := clWhite;
    DestCanvas.Font.Style := [fsBold];
    DestCanvas.Font.Name := 'Arial';
    DestCanvas.Font.Size := 10;

    // It's better to draw the background ourselves
    DestCanvas.Rectangle(
      GlassMinusBorderLeft + 10,
      GlassMinusBorderTop + 10,
      GlassMinusBorderLeft + 150,
      GlassMinusBorderTop + 80
    );

    // Gets the RGB value of the center pixel
    CenterPt := GetCenterPoint();
    {$ifdef LCLCocoa}
    CentralColor := bmpDisplay.Canvas.Pixels[centerPt.X, centerPt.Y];
    {$else}
    CentralColor := DestCanvas.Pixels[centerPt.X, centerPt.Y];
    {$endif}

    // Draws the color in decimal
    {$ifdef fpc}
    R := Red(CentralColor);
    G := Green(CentralColor);
    B := Blue(CentralColor);
    {$else}
    R := GetRValue(ColorToRGB(CentralColor));
    G := GetGValue(ColorToRGB(CentralColor));
    B := GetBValue(ColorToRGB(CentralColor));
    {$endif}
    DestCanvas.TextOut(GlassMinusBorderLeft + 10, GlassMinusBorderTop + 10,
     Format('%.3d, %.3d, %.3d RGB', [R, G, B]));

    // Draws the color in hexadecimal
    DestCanvas.TextOut(GlassMinusBorderLeft + 10, GlassMinusBorderTop + 30,
     Format('%.2x, %.2x, %.2x RGB %.1fX', [R, G, B,
     vConfigurations.iMagnification]));

    // Draws the location of the central pixel
    DestCanvas.TextOut(GlassMinusBorderLeft + 10, GlassMinusBorderTop + 50,
     Format(vTranslations.lpGTMouse + lpSpace + vTranslations.lpGTX + lpSpace +
     '%d' + lpSpace + vTranslations.lpGTY + lpSpace + '%d',
     [Mouse.CursorPos.X, Mouse.CursorPos.Y]));

    // Tickmarks
//    centerOffset := 1;
//    lineOffset := Round( (vConfigurations.iMagnification / 2) + 0.50);

//    HPEN pen = CreatePen(PS_DOT, 1, 0x000000);
//    HPEN oldPen = (HPEN)SelectObject(bmpMasked1.hdcMem, pen);

    if (vConfigurations.iMagnification >= 4.0) then
    begin
      step := Round(5 * vConfigurations.iMagnification);
      stepMinor := Round(vConfigurations.iMagnification);
      tickSize := step;

{      // Right side ticks
      tickCount := GlassWidth div (2 * step);
      for i := 1 to tickCount do
      begin
        DestCanvas.MoveTo(centerX + i * step, centerY - tickSize);
        DestCanvas.LineTo(centerX + i * step, centerY + tickSize);
        // Alternates large and small ticks
        if i mod 2 = 0 then tickSize := tickSize * 2
        else tickSize := tickSize div 2;
      end

      i := centerX + stepMinor;
      while (i < GlassLeft + GlassWidth - 17) do
      begin
        if (i - (centerX + step)) mod step <> 0 then tickScale := 2
        else tickScale := 1;
        DestCanvas.MoveTo(i, centerY - (tickScale * lineOffset));
        DestCanvas.LineTo(i, centerY + (tickScale * lineOffset) + 1);
        i := i + stepMinor;
      end;

      i := centerX - stepMinor;
      for(int i = centerX - stepMinor; i > 17; i -= stepMinor)
      begin
          tickScale = (i - (centerX - step)) % step ? 1 : 2;
          drawLine(bmpMasked1.hdcMem, i, centerY - (tickScale * lineOffset), i, centerY + (tickScale * lineOffset) + 1);
      end;
      for(int i = centerY + stepMinor; i < cyGlass - 17; i += stepMinor)
      begin
          tickScale = (i - (centerY + step)) % step ? 1 : 2;
          drawLine(bmpMasked1.hdcMem, centerX - (tickScale * lineOffset), i, centerX + (tickScale * lineOffset) + 1, i);
      end;
      for(int i = centerY - stepMinor; i > 17; i -= stepMinor)
      begin
          tickScale = (i - (centerY + step)) % step ? 1 : 2;
          drawLine(bmpMasked1.hdcMem, centerX - (tickScale * lineOffset), i, centerX + (tickScale * lineOffset) + 1, i);
      end;}
    end;

    // Center crosshair

    // Top
    DestCanvas.MoveTo(GlassLeft + GlassWidth div 2, GlassTop + BorderSize);
    DestCanvas.LineTo(GlassLeft + GlassWidth div 2, GlassTop + GlassHeight div 2 - 1);

    // Bottom
    DestCanvas.MoveTo(GlassLeft + GlassWidth div 2, GlassTop + GlassHeight - BorderSize);
    DestCanvas.LineTo(GlassLeft + GlassWidth div 2, GlassTop + GlassHeight div 2 + 1);

    // Left
    DestCanvas.MoveTo(GlassLeft + BorderSize, GlassTop + GlassHeight div 2);
    DestCanvas.LineTo(GlassLeft + GlassWidth div 2 - 1, GlassTop + GlassHeight div 2);

    // Right
    DestCanvas.MoveTo(GlassLeft + GlassWidth - BorderSize, GlassTop + GlassHeight div 2);
    DestCanvas.LineTo(GlassLeft + GlassWidth div 2 + 1, GlassTop + GlassHeight div 2);
  end;
  end; // with
end;

{@@
  Draws the Glass for the Dynamic Mode

  @param  DestCanvas  The canvas where it will be drawn
  @param  DrawInfo    Record with drawing position information
}
procedure TGlass.DrawDynamicModeGlass(DestCanvas: TCanvas;
  DrawInfo: TGlassDrawInfo);
var
  I: Integer;
  MagMousePt, centerPt: TPoint;
begin
  with DrawInfo do
  begin
  DestCanvas.Draw(0, 0, bmpDisplay);

  {*******************************************************************
  *  Draws the enlarged glass contents
  *******************************************************************}
  StretchBlt(DestCanvas.Handle,
   drawGlassRect.Left - GlassLeft, drawGlassRect.Top - GlassTop,
   drawGlassWidth, drawGlassHeight,
   bmpDisplay.Canvas.Handle, viewRect.Left, viewRect.Top,
   viewRectWidth, viewRectHeight, SRCCOPY);

  {*******************************************************************
  *  Draws the rectangular border
  *******************************************************************}
  DestCanvas.Brush.Color := clBlack;
  DestCanvas.FrameRect(Bounds(0, 0, GlassWidth, GlassHeight));
  DestCanvas.FrameRect(Bounds(1, 1, GlassWidth - 2, GlassHeight - 2));
  DestCanvas.Brush.Color := clGray;
  DestCanvas.FrameRect(Bounds(2, 2, GlassWidth - 4, GlassHeight - 4));
  DestCanvas.FrameRect(Bounds(3, 3, GlassWidth - 6, GlassHeight - 6));

  {*******************************************************************
  *  If the mouse is inside the window, draw the mouse too
  *******************************************************************}
  if PtInRect(Bounds(GlassLeft, GlassTop, GlassWidth, GlassHeight), Mouse.CursorPos) then
  begin
    centerPt.X := GlassLeft + GlassWidth div 2;
    centerPt.Y := GlassTop + GlassHeight div 2;
    // Mouse position in the magnifier window in client coordinates
    MagMousePt.X := Round((Mouse.CursorPos.X - centerPt.X)
      * vConfigurations.iMagnification + GlassWidth div 2);
    MagMousePt.Y := Round((Mouse.CursorPos.Y - centerPt.Y)
      * vConfigurations.iMagnification + GlassHeight div 2);
    // Hack fix for the new dynamic mode =( ToDo: Figure out a proper fix
    MagMousePt.Y := MagMousePt.Y - 70;
    MagMousePt.X := MagMousePt.X - 20;

    DestCanvas.Pen.Color := clBlack;
    DestCanvas.Pen.Width := 3;
    DestCanvas.Line(MagMousePt.X - 20, MagMousePt.Y, MagMousePt.X + 20, MagMousePt.Y);
    DestCanvas.Line(MagMousePt.X, MagMousePt.Y - 20, MagMousePt.X, MagMousePt.Y + 20);
  end;

  end; // with
end;

{@@
  Processes Paint messages for the TGlass control
}
procedure TGlass.Paint;
var
  DrawInfo: TGlassDrawInfo;
begin
  // Loads the AntiAliasing configuration
  if vConfigurations.AntiAliasing then
    Canvas.AntialiasingMode := amOn
  else Canvas.AntialiasingMode := amOff;

  {$if defined(Unix) and not defined(Darwin)}
    // Cleans the bitmap to solve a bug on some systems
    bmpOutput.Canvas.Brush.Color := clWhite;
    bmpOutput.Canvas.FillRect(Bounds(0, 0, CXScreen, CYScreen));
  {$ifend}

  // Ask for update of the whole window
  CalculateDrawInfo(bmpOutput.Canvas, DrawInfo);
  if vConfigurations.UsePlugins then
  begin
    DrawDynamicModeGlass(bmpOutput.Canvas, DrawInfo);
  end
  else
  begin
    DrawStandardGlass(bmpOutput.Canvas, DrawInfo);
    DrawGraphicalTools(bmpOutput.Canvas, DrawInfo);
  end;

  // Copies the buffer bitmap to the canvas
  Canvas.Draw(0, 0, bmpOutput);

  inherited Paint;
end;

procedure TGlass.EraseBackground(DC: HDC);
begin

end;

procedure TGlass.WMEraseBkgnd(var Message: TLMEraseBkgnd);
begin
  Message.Result := 1;
end;

end.

