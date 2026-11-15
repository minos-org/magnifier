{
app.pas

Main window and general user interface code

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
unit app;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

{$IFDEF Win32}
  {$DEFINE Windows}
{$ENDIF}

// This greatly increases the speed in non-Windows platforms
{$ifndef LCLWin32}
  {$define VMG_DIRECT_FORM_RENDERING}
{$ENDIF}

// This makes the magnifier a small window to help debug exceptions and other problems
// which might make the fullscreen app block the system
{.$define VMG_DEBUG_SMALL_MODE}

interface

uses
{$IFDEF Windows}

  {$IFDEF WinCE}
    Windows, Messages, Registry,
  {$ELSE}
    Windows, ShellAPI, Messages, Registry,
  {$ENDIF}

  {$IFDEF VER150} // VER150 = Delphi 7
    olddelphitrayicon,
  {$ENDIF}

{$ENDIF}

{$IFDEF UNIX}
  Unix,
{$ENDIF}
{$ifdef LCLCustomdrawn}
  customdrawnint,
{$endif}

  LCLType, LCLIntf, LMessages, LCLProc,
  Forms, Classes, SysUtils, Controls, Graphics, Menus, ExtCtrls, Clipbrd,
  glass, constants, appsettings, plugins {, lazfmlviewer}, dockedglass;

type

  { TMainWindow }

  TMainWindow = class(TForm)
  private
    MyMenuItems: array[0..22] of TMenuItem;
    MySubMenuItems: array[0..30] of TMenuItem;
    vMenu: TPopupMenu;
    SystrayIcon: TTrayIcon;
    DynamicModeTimer: TTimer;
    KeyTimer, WheelTimer: TTimer;
    Bookmark1,Bookmark2: TPoint;
    MovingLeft, MovingRight, ControlDown: Boolean;
    {$IFDEF Unix}
    CheckWatchFileTimer: TTimer;
    procedure CheckWatchFile(Sender: TObject);
    procedure CleanWatchFile;
    {$ENDIF}
    procedure ChangeInvertColors(Sender: TObject);
    procedure ChangeGraphicalBorder(Sender: TObject);
    procedure ChangeWidth(Sender: TObject);
    procedure ChangeHeight(Sender: TObject);
    procedure ChangeMagnification(Sender: TObject);
    procedure ChangeTools(Sender: TObject);
    procedure ChangeAutoRun(Sender: TObject);
    procedure ChangeAntiAliasing(Sender: TObject);
    procedure ChangeShowWhenExecuted(Sender: TObject);
    procedure ChangeLanguage(Sender: TObject);
    procedure CloseWindow(Sender: TObject);
    procedure CreateTaskbarMenu(var lpMenu: TPopupMenu);
    procedure HandleFormPaint(Sender: TObject);
    procedure HandleKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HandleKeyPress(Sender: TObject; var Key: Char);
    procedure HandleKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HandleOnClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure HandleShow(Sender: TObject);
    procedure HandleClosePlugin(Sender: TObject);
    procedure HandleMouseWheel(Sender: TObject; Shift: TShiftState;
     WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure KeyTimerTimer(Sender: Tobject);
    procedure WheelTimerTimer(Sender: Tobject);
    procedure HandleDynamicMode(Sender: TObject);
    procedure HandleHideGlass(Sender: TObject);
    procedure HideWindow(Sender: TObject);
    procedure HideMenu(Sender: TObject);
    procedure MoveGlass(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure MoveMouseRight;
    procedure MoveMouseLeft;
    procedure MoveMouseUp;
    procedure MoveMouseDown;
    function  SetTaskbarIcon(uID: Cardinal): Boolean;
    procedure ShowHomePage(Sender: TObject);
    procedure ShowAboutBox(Sender: TObject);
    procedure ShowConfigDialog(Sender: TObject);
    procedure ShowHelp(Sender: TObject);
    procedure SystrayClick(Sender: TObject);
    procedure ShowLensClick(Sender: TObject);
    procedure TranslateTaskbarMenu(Sender: TObject);
  public
    ControlToInvalidate: TWinControl;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure UpdateConfigurations;
    procedure UpdateHotKey(Sender: TObject);
    procedure ExecuteLens(Sender: TObject);
    procedure HandleDynamicModeTimer(Sender: TObject);
    procedure DoChangeLanguage(AID: Integer);
    procedure CreateDockedGlass;
    procedure ShowDockedGlass(Sender: TObject);
    {$IFDEF Win32}
    procedure WndProc(var TheMessage : TLMessage); override;
    {$ENDIF}
    function DisableFormBackgroundDrawing(AForm: TCustomForm): Boolean;
  end;

var
  vMainWindow: TMainWindow;

implementation

uses about, translationsvmg, configdlg;

{*******************************************************************
*  app.dfm is a dummy resource file required by Delphi to create the form
*******************************************************************}
{$IFNDEF FPC}
  {$R app.dfm}
{$ENDIF}

{ TMainWindow }

{*******************************************************************}
{@@
  Standard event for hiding the main window
}
{*******************************************************************}
procedure TMainWindow.HideWindow(Sender: TObject);
begin
{$ifdef wince}
  Close;
{$else}
  Hide;
{$endif}
  vGlass.BackgroundThreadStop;

  if Assigned(vDockedGlass) then
    vDockedGlass.SetLensIsShown(False);

  if (vConfigurations.ShowDockedWhenLensHides) then
    ShowDockedGlass(Self);
end;

{*******************************************************************}
{@@
  Standard event for closing the main window
}
{*******************************************************************}
procedure TMainWindow.CloseWindow(Sender: TObject);
begin
  HandleClosePlugin(nil); // Otherwise exiting might be prevented
{$IFDEF Unix}
  if FileExists(FILE_WATCH_SHORTCUT) then
     DeleteFile(FILE_WATCH_SHORTCUT);
{$ENDIF}
  Close;
  Application.Terminate;
end;

{*******************************************************************}
{@@
  Creates a object from the TAplicativo class

  @param  AOwner   The owner of the component (this may be nil)

  @return          A pointer to the newly created object
}
{*******************************************************************}
constructor TMainWindow.Create(AOwner: TComponent);
var
  lResult: LongBool;
begin
  inherited Create(AOwner);

  {$ifdef LCLCustomdrawn}
  CDWidgetSet.DisableFormBackgroundDrawingProc := DisableFormBackgroundDrawing;
  {$endif}

  // The caption is necessary so a second instance can find the glass
  Caption := szAppTitle;

  // Properties

  BorderStyle := bsNone;
  Self.KeyPreview := true; // Required to make arrow keys work on Linux

  // Creates the glass object
  vGlass := TGlass.Create(Self);
  {$ifdef VMG_DIRECT_FORM_RENDERING}
  vGlass.Visible := False;
  ControlToInvalidate := Self;
  {$else}
  ControlToInvalidate := vGlass;
  {$endif}

  // Creates the systray menu
  SystrayIcon := TTrayIcon.Create(Self); // Needs to be done before SetTaskbarIcon
  vMenu := TPopupMenu.Create(Self);
  CreateTaskbarMenu(vMenu);
  TranslateTaskbarMenu(Self);
  SetTaskbarIcon(1);

  // Creates the dynamic mode timer
  DynamicModeTimer := TTimer.Create(nil);
  DynamicModeTimer.Enabled := False;
  DynamicModeTimer.OnTimer := HandleDynamicModeTimer;
  DynamicModeTimer.Interval := 25;

  {$IFDEF Unix}
  CleanWatchFile;
  CheckWatchFileTimer := TTimer.Create(nil);
  CheckWatchFileTimer.Enabled := True;
  CheckWatchFileTimer.Interval := 1000;
  CheckWatchFileTimer.OnTimer := CheckWatchFile;
  {$ENDIF}

  WheelTimer := TTimer.Create(Self);
  WheelTimer.Interval := 1000;
  WheelTimer.Enabled := False;
  WheelTimer.OnTimer := WheelTimerTimer;
  KeyTimer := TTimer.Create(Self);
  KeyTimer.Interval := 1000;
  KeyTimer.Enabled := False;
  KeyTimer.OnTimer := KeyTimerTimer;
  MovingLeft := False;
  MovingRight := False;
  ControlDown := False;
end;

{*******************************************************************}
{@@
  Loads menu to be used in taskbar from resources.
  Sets the selections of the menu.
  Remember that this functions calls UpdateConfigurations, so
  it is not necessary to do so when it is called.

  @param  lpMenu   Object to receive the menu

  @return          Nothing
}
{*******************************************************************}
procedure TMainWindow.CreateTaskbarMenu(var lpMenu: TPopupMenu);
var
  i: Integer;
begin
  MyMenuItems[ID_MENU_ACTIVATE] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_ACTIVATE].OnClick := ShowLensClick;

  MyMenuItems[ID_MENU_DOCKED_GLASS_ACTIVATE] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_DOCKED_GLASS_ACTIVATE].OnClick := ShowDockedGlass;

  MyMenuItems[ID_MENU_WIDTH] := TMenuItem.Create(Self);

    MySubMenuItems[ID_MENU_WIDTH_64] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_64].Caption := '64';
    MySubMenuItems[ID_MENU_WIDTH_64].OnClick := ChangeWidth;

    MySubMenuItems[ID_MENU_WIDTH_96] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_96].Caption := '96';
    MySubMenuItems[ID_MENU_WIDTH_96].OnClick := ChangeWidth;

    MySubMenuItems[ID_MENU_WIDTH_128] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_128].Caption := '128';
    MySubMenuItems[ID_MENU_WIDTH_128].OnClick := ChangeWidth;

    MySubMenuItems[ID_MENU_WIDTH_192] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_192].Caption := '192';
    MySubMenuItems[ID_MENU_WIDTH_192].OnClick := ChangeWidth;

    MySubMenuItems[ID_MENU_WIDTH_256] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_256].Caption := '256';
    MySubMenuItems[ID_MENU_WIDTH_256].OnClick := ChangeWidth;

    MySubMenuItems[ID_MENU_WIDTH_320] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_320].Caption := '320';
    MySubMenuItems[ID_MENU_WIDTH_320].OnClick := ChangeWidth;

    MySubMenuItems[ID_MENU_WIDTH_416] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_416].Caption := '416';
    MySubMenuItems[ID_MENU_WIDTH_416].OnClick := ChangeWidth;

    MySubMenuItems[ID_MENU_WIDTH_512] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_512].Caption := '512';
    MySubMenuItems[ID_MENU_WIDTH_512].OnClick := ChangeWidth;

    MySubMenuItems[ID_MENU_WIDTH_640] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_640].Caption := '640';
    MySubMenuItems[ID_MENU_WIDTH_640].OnClick := ChangeWidth;

    MySubMenuItems[ID_MENU_WIDTH_768] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_768].Caption := '768';
    MySubMenuItems[ID_MENU_WIDTH_768].OnClick := ChangeWidth;

    MySubMenuItems[ID_MENU_WIDTH_1024] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_1024].Caption := '1024';
    MySubMenuItems[ID_MENU_WIDTH_1024].OnClick := ChangeWidth;

    MySubMenuItems[ID_MENU_WIDTH_1280] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_1280].Caption := '1280';
    MySubMenuItems[ID_MENU_WIDTH_1280].OnClick := ChangeWidth;

    MySubMenuItems[ID_MENU_WIDTH_1600] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_WIDTH_1600].Caption := '1600';
    MySubMenuItems[ID_MENU_WIDTH_1600].OnClick := ChangeWidth;

    for i := 0 to 12 do MyMenuItems[ID_MENU_WIDTH].Add(MySubMenuItems[i]);

  MyMenuItems[ID_MENU_HEIGHT] := TMenuItem.Create(Self);

    MySubMenuItems[ID_MENU_HEIGHT_64] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_HEIGHT_64].Caption := '64';
    MySubMenuItems[ID_MENU_HEIGHT_64].OnClick := ChangeHeight;

    MySubMenuItems[ID_MENU_HEIGHT_96] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_HEIGHT_96].Caption := '96';
    MySubMenuItems[ID_MENU_HEIGHT_96].OnClick := ChangeHeight;

    MySubMenuItems[ID_MENU_HEIGHT_128] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_HEIGHT_128].Caption := '128';
    MySubMenuItems[ID_MENU_HEIGHT_128].OnClick := ChangeHeight;

    MySubMenuItems[ID_MENU_HEIGHT_160] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_HEIGHT_160].Caption := '160';
    MySubMenuItems[ID_MENU_HEIGHT_160].OnClick := ChangeHeight;

    MySubMenuItems[ID_MENU_HEIGHT_192] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_HEIGHT_192].Caption := '192';
    MySubMenuItems[ID_MENU_HEIGHT_192].OnClick := ChangeHeight;

    MySubMenuItems[ID_MENU_HEIGHT_256] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_HEIGHT_256].Caption := '256';
    MySubMenuItems[ID_MENU_HEIGHT_256].OnClick := ChangeHeight;

    MySubMenuItems[ID_MENU_HEIGHT_320] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_HEIGHT_320].Caption := '320';
    MySubMenuItems[ID_MENU_HEIGHT_320].OnClick := ChangeHeight;

    MySubMenuItems[ID_MENU_HEIGHT_512] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_HEIGHT_512].Caption := '512';
    MySubMenuItems[ID_MENU_HEIGHT_512].OnClick := ChangeHeight;

    MySubMenuItems[ID_MENU_HEIGHT_768] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_HEIGHT_768].Caption := '768';
    MySubMenuItems[ID_MENU_HEIGHT_768].OnClick := ChangeHeight;

    MySubMenuItems[ID_MENU_HEIGHT_1024] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_HEIGHT_1024].Caption := '1024';
    MySubMenuItems[ID_MENU_HEIGHT_1024].OnClick := ChangeHeight;

    for i := 0 to 9 do MyMenuItems[ID_MENU_HEIGHT].Add(MySubMenuItems[i]);

  MyMenuItems[ID_MENU_MAGNIFICATION] := TMenuItem.Create(Self);

    MySubMenuItems[0] := TMenuItem.Create(Self);
    MySubMenuItems[0].Caption := '1x';
    MySubMenuItems[0].OnClick := ChangeMagnification;

    MySubMenuItems[1] := TMenuItem.Create(Self);
    MySubMenuItems[1].Caption := '1.5x';
    MySubMenuItems[1].OnClick := ChangeMagnification;

    MySubMenuItems[2] := TMenuItem.Create(Self);
    MySubMenuItems[2].Caption := '2x';
    MySubMenuItems[2].OnClick := ChangeMagnification;

    MySubMenuItems[3] := TMenuItem.Create(Self);
    MySubMenuItems[3].Caption := '3x';
    MySubMenuItems[3].OnClick := ChangeMagnification;

    MySubMenuItems[4] := TMenuItem.Create(Self);
    MySubMenuItems[4].Caption := '4x';
    MySubMenuItems[4].OnClick := ChangeMagnification;

    MySubMenuItems[5] := TMenuItem.Create(Self);
    MySubMenuItems[5].Caption := '8x';
    MySubMenuItems[5].OnClick := ChangeMagnification;

    MySubMenuItems[6] := TMenuItem.Create(Self);
    MySubMenuItems[6].Caption := '16x';
    MySubMenuItems[6].OnClick := ChangeMagnification;

    for i := 0 to 6 do MyMenuItems[ID_MENU_MAGNIFICATION].Add(MySubMenuItems[i]);

  MyMenuItems[ID_MENU_TOOLS] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_TOOLS].OnClick := ChangeTools;

  MyMenuItems[ID_MENU_GRAPHICAL_BORDER] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_GRAPHICAL_BORDER].OnClick := ChangeGraphicalBorder;

  MyMenuItems[ID_MENU_INVERT_COLORS] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_INVERT_COLORS].OnClick := ChangeInvertColors;

  MyMenuItems[ID_MENU_ANTIALIASING] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_ANTIALIASING].OnClick := ChangeAntiAliasing;

  MyMenuItems[ID_SEPARATOR_ONE] := TMenuItem.Create(Self);
  MyMenuItems[ID_SEPARATOR_ONE].Caption := lpSeparator;

  MyMenuItems[ID_MENU_CONFIG_DIALOG] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_CONFIG_DIALOG].OnClick := ShowConfigDialog;

  MyMenuItems[ID_MENU_TRANSLATIONS] := TMenuItem.Create(Self);

    MySubMenuItems[ID_MENU_ENGLISH] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_ENGLISH].Caption := lpEnglish;
    MySubMenuItems[ID_MENU_ENGLISH].OnClick := ChangeLanguage;

    MySubMenuItems[ID_MENU_PORTUGUESE] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_PORTUGUESE].Caption := lpPortugues;
    MySubMenuItems[ID_MENU_PORTUGUESE].OnClick := ChangeLanguage;

    MySubMenuItems[ID_MENU_SPANISH] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_SPANISH].Caption := lpEspanol;
    MySubMenuItems[ID_MENU_SPANISH].OnClick := ChangeLanguage;

    MySubMenuItems[ID_MENU_FRENCH] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_FRENCH].Caption := lpFrancais;
    MySubMenuItems[ID_MENU_FRENCH].OnClick := ChangeLanguage;

    MySubMenuItems[ID_MENU_GERMAN] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_GERMAN].Caption := lpGerman;
    MySubMenuItems[ID_MENU_GERMAN].OnClick := ChangeLanguage;

    MySubMenuItems[ID_MENU_ITALIAN] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_ITALIAN].Caption := lpItaliano;
    MySubMenuItems[ID_MENU_ITALIAN].OnClick := ChangeLanguage;

    MySubMenuItems[ID_MENU_RUSSIAN] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_RUSSIAN].Caption := lpRussian;
    MySubMenuItems[ID_MENU_RUSSIAN].OnClick := ChangeLanguage;

    MySubMenuItems[ID_MENU_POLISH] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_POLISH].Caption := lpPolish;
    MySubMenuItems[ID_MENU_POLISH].OnClick := ChangeLanguage;

    MySubMenuItems[ID_MENU_JAPANESE] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_JAPANESE].Caption := lpJapanese;
    MySubMenuItems[ID_MENU_JAPANESE].OnClick := ChangeLanguage;

    MySubMenuItems[ID_MENU_TURKISH] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_TURKISH].Caption := lpTurkish;
    MySubMenuItems[ID_MENU_TURKISH].OnClick := ChangeLanguage;

    MySubMenuItems[ID_MENU_CHINESE] := TMenuItem.Create(Self);
    MySubMenuItems[ID_MENU_CHINESE].Caption := lpChinese;
    MySubMenuItems[ID_MENU_CHINESE].OnClick := ChangeLanguage;

    for i := 0 to 10 do MyMenuItems[ID_MENU_TRANSLATIONS].Add(MySubMenuItems[i]);

  MyMenuItems[ID_MENU_SAVE] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_SAVE].OnClick := vConfigurations.Save;

  MyMenuItems[ID_MENU_USE_PLUGIN] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_USE_PLUGIN].OnClick := HandleDynamicMode;
  {$IFDEF UNIX}
  MyMenuItems[ID_MENU_USE_PLUGIN].Enabled := False;
  {$ENDIF}

  MyMenuItems[ID_MENU_CLOSE_PLUGIN] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_CLOSE_PLUGIN].OnClick := HandleClosePlugin;
  {$IFDEF UNIX}
  MyMenuItems[ID_MENU_CLOSE_PLUGIN].Enabled := False;
  {$ENDIF}

  MyMenuItems[ID_SEPARATOR_TWO] := TMenuItem.Create(Self);
  MyMenuItems[ID_SEPARATOR_TWO].Caption := lpSeparator;

  MyMenuItems[ID_MENU_HOMEPAGE] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_HOMEPAGE].OnClick := ShowHomepage;

  MyMenuItems[ID_MENU_ABOUT] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_ABOUT].OnClick := ShowAboutBox;

  MyMenuItems[ID_MENU_HELP] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_HELP].OnClick := ShowHelp;

  MyMenuItems[ID_MENU_CANCEL] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_CANCEL].OnClick := HideMenu;

  MyMenuItems[ID_MENU_TERMINATE] := TMenuItem.Create(Self);
  MyMenuItems[ID_MENU_TERMINATE].OnClick := CloseWindow;

  for i := 0 to 20 do lpMenu.Items.Add(MyMenuItems[i]);

  UpdateConfigurations;
end;

{*******************************************************************}
{@@
  Destroys a object derived from the TApplication class
}
{*******************************************************************}
destructor TMainWindow.Destroy;
begin
  // Frees memory alocated on the Create method
  vMenu.Free;
  vGlass.Free;
  vDockedGlass.Free;
  DynamicModeTimer.Free;
  WheelTimer.Free;
  KeyTimer.Free;

  {$IFDEF Unix}
  CheckWatchFileTimer.Free;
  {$ENDIF}

  { Unregister hotkeys }

  {$IFDEF MSWindows}
    UnregisterHotKey(Handle, 0);
    UnregisterHotKey(Handle, 1);
    UnregisterHotKey(Handle, 2);
    UnregisterHotKey(Handle, 3);
    UnregisterHotKey(Handle, 4);
    UnregisterHotKey(Handle, 5);
    UnregisterHotKey(Handle, 6);
    UnregisterHotKey(Handle, 7);
    UnregisterHotKey(Handle, 8);
    UnregisterHotKey(Handle, 9);
    UnregisterHotKey(Handle, 10);
    UnregisterHotKey(Handle, 11);
    UnregisterHotKey(Handle, 12);
  {$ENDIF}

  inherited Destroy;
end;

{*******************************************************************}
{@@
  Shows the Len.
}
{*******************************************************************}
procedure TMainWindow.ExecuteLens(Sender: TObject);
var
  OSVersion: TOSVersion;
begin
  // The Sleep here is necessary or else sometimes the popup menu
  // won't have time to be painted over and we will capture it's image
  Sleep(10);

  if Assigned(vDockedGlass) then
  begin
    vDockedGlass.SetLensIsShown(True);
    if (vConfigurations.HideDockedWhenLensShows) then
      if vDockedGlass.Visible then
        vDockedGlass.Hide;

    Application.ProcessMessages;
    Sleep(500);
  end
  else
  begin
    Application.ProcessMessages;
  end;

  {*******************************************************************
  *  Close any activated plugins
  *******************************************************************}
  HandleClosePlugin(Sender);

  // Initializes the Multimonitor support
  vGlass.GetScreenSize(vGlass.XScreen, vGlass.YScreen, vGlass.CXScreen, vGlass.CYScreen);

  {$ifdef VMG_DEBUG_SMALL_MODE}
  Self.Left := 0;
  Self.Top := 200;
  Self.Width := 200;
  Self.Height := 200;
  {$else}
  Self.Left := vGlass.XScreen;
  Self.Top := vGlass.YScreen;
  Self.Width := vGlass.CXScreen;
  Self.Height := vGlass.CYScreen;

  // In Linux we definetively need wsFullScreen, otherwise the window manager might do a
  // crazy repositioning of the window
  // In Windows we already have our system for doing the fullscreen, so no need to change whats working
  // In Carbon don't try because it makes wierd effects
  {$IFNDEF Windows}{$ifndef LCLCarbon}
  //Self.WindowState := wsFullScreen; // Requires LCL 0.9.31+
  {$ENDIF}{$ENDIF}
  {$ENDIF}

  vGlass.Left := 0;
  vGlass.Top := 0;
  vGlass.Width := vGlass.CXScreen;
  vGlass.Height := vGlass.CYScreen;

  vGlass.bmpOutput.Width := vGlass.CXScreen;
  vGlass.bmpOutput.Height := vGlass.CYScreen;

  // Initializes the Glass component
  vGlass.Align := alClient;
  vGlass.Parent := Self;
  vGlass.DoubleBuffered := True;
//  vGlass.Color := clNone;
//  Self.Color := clNone;

  // Connects the methods to events

  Self.OnShow := HandleShow;
  vGlass.OnMouseMove := MoveGlass;
  vGlass.OnClick := HideWindow;
  Self.OnHide := HandleHideGlass;

  {$ifdef VMG_DIRECT_FORM_RENDERING}
  Self.OnMouseMove := MoveGlass;
  Self.OnClick := HideWindow;
  Self.OnPaint := HandleFormPaint;
  {$endif}

  Self.OnKeyDown := HandleKeyDown;
  vGlass.OnKeyDown := HandleKeyDown;//* Bugfix for some Linux systems

  Self.OnKeyPress := HandleKeyPress;
  vGlass.OnKeyPress := HandleKeyPress;

  Self.OnKeyUp := HandleKeyUp;
  vGlass.OnKeyUp := HandleKeyUp;

  {.$ifndef Win32}
  Self.OnMouseWheel := HandleMouseWheel;
  vGlass.OnMouseWheel := HandleMouseWheel;
  {.$endif}

  // Bug fix for WinCE-LCL
  {$ifdef WinCE}
    Self.OnClose := HandleOnClose;
  {$endif}

  // Updates the position of the mouse
  vGlass.GlassTop := Mouse.CursorPos.Y - vGlass.GlassHeight div 2 - vGlass.YScreen;
  vGlass.GlassLeft := Mouse.CursorPos.X - vGlass.GlassWidth div 2 - vGlass.XScreen;

  // Updates the screen capture
  if not vGlass.GetDisplayBitmap then
    raise Exception.Create('Error in vGlass.GetDisplayBitmap');

  {*******************************************************************
  *  Shows the magnifier with a plugin
  *******************************************************************}
  if vConfigurations.UsePlugins then
  begin
    {$IFDEF USE_PLUGINS}
      { Fixs the starting position of the glass }
      { TODO: Should be removed in the future when it is more flexible }
      vGlass.FixGlassCoordinates;

      vPlugins.LoadPlugin;

      vPlugins.Initialize;
    {$ELSE}
      {$IFDEF Windows}
      // Lets turn aero off first, in the dynamic mode
      // Don't use this code in older version because then an error dialog appears
      OSVersion := vConfigurations.GetOSVersion();
      if OSVersion >= vwWinVista then
        Windows.WinExec('Rundll32 dwmApi #104', Windows.SW_HIDE);

      FormStyle := fsSystemStayOnTop;
      Windows.SetWindowLong(Handle, GWL_EXSTYLE,
        Windows.GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_TOPMOST
        or WS_EX_LAYERED or WS_EX_TRANSPARENT);
      Windows.SetLayeredWindowAttributes(Handle, 0, 255, LWA_ALPHA);

      // Updates the position of the window
      vGlass.GlassTop := Mouse.CursorPos.Y - vGlass.GlassHeight div 2 - vGlass.YScreen;
      vGlass.GlassLeft := Mouse.CursorPos.X - vGlass.GlassWidth div 2 - vGlass.XScreen;
      Self.Top := vGlass.GlassTop;
      Self.Left := vGlass.GlassLeft;
      Self.Height := vGlass.GlassHeight;
      Self.Width := vGlass.GlassWidth;

      // Avoids standard events of the standard glass
      OnShow := nil;
      OnMouseMove := nil;
      vGlass.OnMouseMove := nil;

      // Install a timer to update the image
      DynamicModeTimer.Enabled := True;

      // Now shows the glass
      ControlToInvalidate.Invalidate;
      Show;
      {$ENDIF}
    {$ENDIF}
  end
  {*******************************************************************
  *  Shows the glass without a plugin
  *******************************************************************}
  else
  begin
    // The cursor isn't visible while the glass is on
    // But this doesn't work on Carbon
    {$ifndef LCLCarbon}
      vGlass.Cursor := crNone;
    {$endif}

    {$IFDEF Windows}
    SetWindowLong(Handle, GWL_EXSTYLE,
      GetWindowLong(Handle, GWL_EXSTYLE) and not (WS_EX_TOPMOST
      or WS_EX_LAYERED or WS_EX_TRANSPARENT));
    {$endif}

    // Now shows the glass
    Show;

    // Make sure the Glass has focus
    Self.SetFocus;
  end;
end;

{*******************************************************************}
{@@
  Timer which updates the image in the dynamic mode
}
{*******************************************************************}
procedure TMainWindow.HandleDynamicModeTimer(Sender: TObject);
begin
  vGlass.GetDisplayBitmap;
  ControlToInvalidate.Invalidate;
end;

procedure TMainWindow.DoChangeLanguage(AID: Integer);
begin

end;

function TMainWindow.DisableFormBackgroundDrawing(AForm: TCustomForm): Boolean;
begin
  Result := AForm = Self;
end;

{*******************************************************************}
{@@
  Event designed to receive MouseMove messages from
  the OS and respond to them moving the glass.
}
{*******************************************************************}
procedure TMainWindow.MoveGlass(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if not ControlDown then
    vGlass.GlassTop := Mouse.CursorPos.Y - vGlass.GlassHeight div 2 - vGlass.YScreen;

  vGlass.GlassLeft := Mouse.CursorPos.X - vGlass.GlassWidth div 2 - vGlass.XScreen;
  {$IFNDEF MAGNIFIER_USE_NATIVE_STRETCH}
  vGlass.FixGlassCoordinates(False);
  {$ENDIF}
  ControlToInvalidate.Invalidate;
end;

procedure TMainWindow.MoveMouseRight;
var
  CurrentPos: TPoint;
begin
   CurrentPos := Mouse.CursorPos;
   CurrentPos.X := CurrentPos.X + 10;
   if CurrentPos.X > Screen.Width then CurrentPos.X := Screen.Width;
   Mouse.CursorPos := CurrentPos;
end;

procedure TMainWindow.MoveMouseLeft;
var
  CurrentPos: TPoint;
begin
   CurrentPos := Mouse.CursorPos;
   CurrentPos.X := CurrentPos.X - 10;
   if CurrentPos.X < 0 then CurrentPos.X := 0;
   Mouse.CursorPos := CurrentPos;
end;

procedure TMainWindow.MoveMouseUp;
var
  CurrentPos: TPoint;
begin
   CurrentPos := Mouse.CursorPos;
   CurrentPos.Y := CurrentPos.Y - 10;
   if CurrentPos.Y < 0 then CurrentPos.Y := 0;
   Mouse.CursorPos := CurrentPos;
end;

procedure TMainWindow.MoveMouseDown;
var
  CurrentPos: TPoint;
begin
   CurrentPos := Mouse.CursorPos;
   CurrentPos.Y := CurrentPos.Y + 10;
   if CurrentPos.Y > Screen.Height then CurrentPos.Y := Screen.Height;
   Mouse.CursorPos := CurrentPos;
end;

{*******************************************************************}
{@@
  Adds an icon to the taskbar status area.

  @param  uID      identifier of the icon to delete

  @return          TRUE if successful or FALSE otherwise.
}
{*******************************************************************}
function TMainWindow.SetTaskbarIcon(uID: Cardinal): Boolean;
{$IFDEF UNIX}
var
  PNGImage: TPortableNetworkGraphic;
{$ENDIF}
begin
   Result := True;

{$IFDEF Windows}

  SystrayIcon.Icon.Handle := Windows.LoadIcon(hInstance, MAKEINTRESOURCE(IDI_ICON2));

{$ENDIF}
{$IFDEF UNIX}

  try
    Write('[TMainWindow.SetTaskbarIcon] Loading ' + vConfigurations.MyDirectory + 'icon3.png');
    PNGImage := TPortableNetworkGraphic.Create;
    PNGImage.LoadFromFile(vConfigurations.MyDirectory + 'icon3.png');
    SystrayIcon.Icon.Assign(PngImage);
  except
    Write(ErrorLoading);
    Result := False;
  end;

  PngImage.Free;

  WriteLn('');

{$ENDIF}

  SystrayIcon.Hint := szAppTitle;
  SystrayIcon.PopUpMenu := vMenu;
  SystrayIcon.OnClick := SystrayClick;
//  SystrayIcon.OnMouseUp := SystrayMouseUp;

  SystrayIcon.Visible := True;
end;

{*******************************************************************}
{@@
  Click Event on the System Tray Icon
}
{*******************************************************************}
procedure TMainWindow.SystrayClick(Sender: TObject);
begin
  ExecuteLens(Self);
end;

procedure TMainWindow.ShowLensClick(Sender: TObject);
begin
  Sleep(500);
  ExecuteLens(Self);
end;

{*******************************************************************}
{@@
  Call this method when information on vConfigurations has changed
}
{*******************************************************************}
procedure TMainWindow.UpdateConfigurations;
var
  i: Integer;
begin
  {*******************************************************************
  *  Updates the Glass size
  *******************************************************************}
  vGlass.GlassWidth := vConfigurations.xSquare * 32;
  vGlass.GlassHeight := vConfigurations.ySquare * 32;

  {*******************************************************************
  *  Anti-aliasing
  *******************************************************************}
  {$ifdef fpc}
  // Reactivate in laz 0.9.28
//  if vConfigurations.AntiAliasing then vGlass.Canvas.AntialiasingMode := amOn
//  else vGlass.Canvas.AntialiasingMode := amOff;
  {$endif}

  {*******************************************************************
  *  Updates the System Tray pointer to the menu
  *******************************************************************}
  SystrayIcon.PopUpMenu := vMenu;
{$ifdef fpc}
  SystrayIcon.InternalUpdate;
{$endif}

  {*******************************************************************
  *  Updates the checked menu items
  *******************************************************************}
  vMenu.Items[ID_MENU_TOOLS].Checked := vConfigurations.showTools;
  vMenu.Items[ID_MENU_GRAPHICAL_BORDER].Checked := vConfigurations.graphicalBorder;
  vMenu.Items[ID_MENU_INVERT_COLORS].Checked := vConfigurations.invertColors;
  vMenu.Items[ID_MENU_ANTIALIASING].Checked := vConfigurations.AntiAliasing;
  vMenu.Items[ID_MENU_USE_PLUGIN].Checked := vConfigurations.UsePlugins;

  {*******************************************************************
  *  Updates the checked submenu items
  *******************************************************************}
  for i := 0 to 12 do vMenu.Items[ID_MENU_WIDTH].Items[i].Checked := False;

  case vGlass.GlassWidth of
   64:   vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_64].Checked := True;
   96:   vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_96].Checked := True;
   128:  vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_128].Checked := True;
   192:  vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_192].Checked := True;
   256:  vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_256].Checked := True;
   320:  vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_320].Checked := True;
   416:  vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_416].Checked := True;
   512:  vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_512].Checked := True;
   640:  vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_640].Checked := True;
   768:  vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_768].Checked := True;
   1024: vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_1024].Checked := True;
   1280: vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_1280].Checked := True;
   1600: vMenu.Items[ID_MENU_WIDTH].Items[ID_MENU_WIDTH_1600].Checked := True;
  end;

  for i := 0 to 9 do vMenu.Items[ID_MENU_HEIGHT].Items[i].Checked := False;

  case vGlass.GlassHeight of
   64:   vMenu.Items[ID_MENU_HEIGHT].Items[ID_MENU_HEIGHT_64].Checked := True;
   96:   vMenu.Items[ID_MENU_HEIGHT].Items[ID_MENU_HEIGHT_96].Checked := True;
   128:  vMenu.Items[ID_MENU_HEIGHT].Items[ID_MENU_HEIGHT_128].Checked := True;
   160:  vMenu.Items[ID_MENU_HEIGHT].Items[ID_MENU_HEIGHT_160].Checked := True;
   192:  vMenu.Items[ID_MENU_HEIGHT].Items[ID_MENU_HEIGHT_192].Checked := True;
   256:  vMenu.Items[ID_MENU_HEIGHT].Items[ID_MENU_HEIGHT_256].Checked := True;
   320:  vMenu.Items[ID_MENU_HEIGHT].Items[ID_MENU_HEIGHT_320].Checked := True;
   512:  vMenu.Items[ID_MENU_HEIGHT].Items[ID_MENU_HEIGHT_512].Checked := True;
   768:  vMenu.Items[ID_MENU_HEIGHT].Items[ID_MENU_HEIGHT_768].Checked := True;
   1024: vMenu.Items[ID_MENU_HEIGHT].Items[ID_MENU_HEIGHT_1024].Checked := True;
  end;

  for i := 0 to 6 do vMenu.Items[ID_MENU_MAGNIFICATION].Items[i].Checked := False;

  if vConfigurations.iMagnification = 1.0 then
   vMenu.Items[ID_MENU_MAGNIFICATION].Items[ID_MENU_MAGNIFICATION_1X].Checked := True
  else if  vConfigurations.iMagnification = 1.5 then
   vMenu.Items[ID_MENU_MAGNIFICATION].Items[ID_MENU_MAGNIFICATION_1_5X].Checked := True
  else if  vConfigurations.iMagnification = 2.0 then
   vMenu.Items[ID_MENU_MAGNIFICATION].Items[ID_MENU_MAGNIFICATION_2X].Checked := True
  else if  vConfigurations.iMagnification = 3.0 then
   vMenu.Items[ID_MENU_MAGNIFICATION].Items[ID_MENU_MAGNIFICATION_3X].Checked := True
  else if  vConfigurations.iMagnification = 4.0 then
   vMenu.Items[ID_MENU_MAGNIFICATION].Items[ID_MENU_MAGNIFICATION_4X].Checked := True
  else if  vConfigurations.iMagnification = 8.0 then
   vMenu.Items[ID_MENU_MAGNIFICATION].Items[ID_MENU_MAGNIFICATION_8X].Checked := True
  else if  vConfigurations.iMagnification = 16.0 then
   vMenu.Items[ID_MENU_MAGNIFICATION].Items[ID_MENU_MAGNIFICATION_16X].Checked := True;

  // On Carbon we need to update the menu again
  {$ifdef LCLCarbon}
    SystrayIcon.InternalUpdate;
  {$endif}
end;

{*******************************************************************}
{@@
  Changes the current language

  @param  Sender   The object which requested the action.
                   This handler actually uses the Sender to
                   verify which menu item has activated it.
}
{*******************************************************************}
procedure TMainWindow.ChangeLanguage(Sender: TObject);
begin
  if (Sender is TMenuItem) then
  begin
    vTranslations.TranslateToLanguage((Sender as TMenuItem).MenuIndex);
    vConfigurations.Language := (Sender as TMenuItem).MenuIndex;
  end;

  TranslateTaskbarMenu(Self);
end;

{*******************************************************************}
{@@
  Translates the menu items
}
{*******************************************************************}
procedure TMainWindow.TranslateTaskbarMenu(Sender: TObject);
begin
  vMenu.Items[ID_MENU_ACTIVATE].Caption := vTranslations.lpActivate;
  vMenu.Items[ID_MENU_DOCKED_GLASS_ACTIVATE].Caption := vTranslations.lpActivateDockedGlass;
  vMenu.Items[ID_MENU_WIDTH].Caption := vTranslations.lpWidth;
  vMenu.Items[ID_MENU_HEIGHT].Caption := vTranslations.lpHeight;
  vMenu.Items[ID_MENU_MAGNIFICATION].Caption := vTranslations.lpMagnification;
  vMenu.Items[ID_MENU_TOOLS].Caption := vTranslations.lpTools;
  vMenu.Items[ID_MENU_GRAPHICAL_BORDER].Caption := vTranslations.lpGraphicalBorder;
  vMenu.Items[ID_MENU_INVERT_COLORS].Caption := vTranslations.lpInvertColors;
  vMenu.Items[ID_MENU_ANTIALIASING].Caption := vTranslations.lpAntiAliasing;
  vMenu.Items[ID_MENU_CONFIG_DIALOG].Caption := vTranslations.lpConfigDialog;
  vMenu.Items[ID_MENU_TRANSLATIONS].Caption := vTranslations.lpTranslations;
  vMenu.Items[ID_MENU_SAVE].Caption := vTranslations.lpSave;
  vMenu.Items[ID_MENU_USE_PLUGIN].Caption := vTranslations.lpDynamicMode;
  vMenu.Items[ID_MENU_CLOSE_PLUGIN].Caption := vTranslations.lpClosePlugin;
  vMenu.Items[ID_MENU_HOMEPAGE].Caption := vTranslations.lpHomepage;
  vMenu.Items[ID_MENU_ABOUT].Caption := vTranslations.lpAbout;
  vMenu.Items[ID_MENU_HELP].Caption := vTranslations.lpHelp;
  vMenu.Items[ID_MENU_CANCEL].Caption := vTranslations.lpCancel;
  vMenu.Items[ID_MENU_TERMINATE].Caption := vTranslations.lpExit;

  // On Carbon we need to update the menu
  {$ifdef LCLCarbon}
    SystrayIcon.InternalUpdate;
  {$endif}
end;

{*******************************************************************}
{@@
  Action executed when the user clicks on the "Hide" menu item
}
{*******************************************************************}
procedure TMainWindow.HideMenu(Sender: TObject);
begin
  { Just doing nothing is enougth to hide the menu }
end;

procedure TMainWindow.HandleFormPaint(Sender: TObject);
var
  DrawInfo: TGlassDrawInfo;
begin
  {$ifdef VMG_DIRECT_FORM_RENDERING}
  // Loads the AntiAliasing configuration
  if vConfigurations.AntiAliasing then
    Canvas.AntialiasingMode := amOn
  else Canvas.AntialiasingMode := amOff;

  // Ask for update of the whole window
  vGlass.CalculateDrawInfo(Canvas, DrawInfo);
  if vConfigurations.UsePlugins then
  begin
    vGlass.DrawDynamicModeGlass(Canvas, DrawInfo);
  end
  else
  begin
    vGlass.DrawStandardGlass(Canvas, DrawInfo);
    vGlass.DrawGraphicalTools(Canvas, DrawInfo);
  end;
  {$ifend}
end;

{*******************************************************************}
{@@
  Action executed to invert the colors
}
{*******************************************************************}
procedure TMainWindow.ChangeInvertColors(Sender: TObject);
begin
  vConfigurations.invertColors := not vConfigurations.invertColors;
  UpdateConfigurations;
end;

{*******************************************************************}
{@@
  Action executed to change the graphical border state
}
{*******************************************************************}
procedure TMainWindow.ChangeGraphicalBorder(Sender: TObject);
begin
  vConfigurations.graphicalBorder := not vConfigurations.graphicalBorder;
  UpdateConfigurations;
end;

{*******************************************************************}
{@@
  Action executed to show the project's homepage

  Under Unix we first try to locate a software to
  open the default browser. If we can't find it,
  we just try to use Firefox
}
{*******************************************************************}
procedure TMainWindow.ShowHomePage(Sender: TObject);
begin
  LCLIntf.OpenURL(VMG_WEBSITE);
end;

{*******************************************************************}
{@@
  Show the about box
}
{*******************************************************************}
procedure TMainWindow.ShowAboutBox(Sender: TObject);
begin
  vAboutWindow.ShowModal;
end;

{*******************************************************************}
{@@
  Show the configurations dialog
}
{*******************************************************************}
procedure TMainWindow.ShowConfigDialog(Sender: TObject);
begin
  HandleClosePlugin(nil); // Otherwise there might be problems in the dialog
  vConfigDialog.ShowModal;
  ChangeAutoRun(Self);
end;

{*******************************************************************}
{@@
  Action executed to change the Len Height

  @param   Sender  The object which requested the action
}
{*******************************************************************}
procedure TMainWindow.ChangeHeight(Sender: TObject);
begin
  if (Sender is TMenuItem) then
  begin
    case (Sender as TMenuItem).MenuIndex of
     ID_MENU_HEIGHT_64: vConfigurations.ySquare := 2;
     ID_MENU_HEIGHT_96: vConfigurations.ySquare := 3;
     ID_MENU_HEIGHT_128: vConfigurations.ySquare := 4;
     ID_MENU_HEIGHT_160: vConfigurations.ySquare := 5;
     ID_MENU_HEIGHT_192: vConfigurations.ySquare := 6;
     ID_MENU_HEIGHT_256: vConfigurations.ySquare := 8;
     ID_MENU_HEIGHT_320: vConfigurations.ySquare := 10;
     ID_MENU_HEIGHT_512: vConfigurations.ySquare := 16;
     ID_MENU_HEIGHT_768: vConfigurations.ySquare := 24;
     ID_MENU_HEIGHT_1024: vConfigurations.ySquare := 32;
    end;
  end;
  UpdateConfigurations;
  if vConfigurations.UsePlugins then vMainWindow.Height := vGlass.GlassHeight;
end;

{*******************************************************************}
{@@
  Action executed to change the Len Width

  @param   Sender  The object which requested the action
}
{*******************************************************************}
procedure TMainWindow.ChangeWidth(Sender: TObject);
begin
  if (Sender is TMenuItem) then
  begin
    case (Sender as TMenuItem).MenuIndex of
     ID_MENU_WIDTH_64: vConfigurations.xSquare := 2;
     ID_MENU_WIDTH_96: vConfigurations.xSquare := 3;
     ID_MENU_WIDTH_128: vConfigurations.xSquare := 4;
     ID_MENU_WIDTH_192: vConfigurations.xSquare := 6;
     ID_MENU_WIDTH_256: vConfigurations.xSquare := 8;
     ID_MENU_WIDTH_320: vConfigurations.xSquare := 10;
     ID_MENU_WIDTH_416: vConfigurations.xSquare := 13;
     ID_MENU_WIDTH_512: vConfigurations.xSquare := 16;
     ID_MENU_WIDTH_640: vConfigurations.xSquare := 20;
     ID_MENU_WIDTH_768: vConfigurations.xSquare := 24;
     ID_MENU_WIDTH_1024: vConfigurations.xSquare := 32;
     ID_MENU_WIDTH_1280: vConfigurations.xSquare := 40;
     ID_MENU_WIDTH_1600: vConfigurations.xSquare := 50;
    end;
  end;
  UpdateConfigurations;
  if vConfigurations.UsePlugins then vMainWindow.Width := vGlass.GlassWidth;
end;

{*******************************************************************}
{@@
  Action executed to change the magnification status

  @param   Sender  The object which requested the action
}
{*******************************************************************}
procedure TMainWindow.ChangeMagnification(Sender: TObject);
begin
  if (Sender is TMenuItem) then
  begin
    case (Sender as TMenuItem).MenuIndex of
     ID_MENU_MAGNIFICATION_1X:   vConfigurations.iMagnification := 1.0;
     ID_MENU_MAGNIFICATION_1_5X: vConfigurations.iMagnification := 1.5;
     ID_MENU_MAGNIFICATION_2X:   vConfigurations.iMagnification := 2.0;
     ID_MENU_MAGNIFICATION_3X:   vConfigurations.iMagnification := 3.0;
     ID_MENU_MAGNIFICATION_4X:   vConfigurations.iMagnification := 4.0;
     ID_MENU_MAGNIFICATION_8X:   vConfigurations.iMagnification := 8.0;
     ID_MENU_MAGNIFICATION_16X:  vConfigurations.iMagnification := 16.0;
    end;
  end;

  UpdateConfigurations;
end;

{*******************************************************************}
{@@
}
{*******************************************************************}
procedure TMainWindow.ChangeAutoRun(Sender: TObject);
{$IFDEF Windows}
var
  Reg: TRegistry;
{$ENDIF}
begin
{$IFDEF Windows}
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', True) then
    begin
      if vConfigurations.autoRun then Reg.WriteString(szAppTitle, '"' + ParamStr(0) + '"')
      else Reg.DeleteValue(szAppTitle);
    end;
  finally
    Reg.CloseKey;
    Reg.Free;
  end;
{$ENDIF}

  UpdateConfigurations;
end;

{*******************************************************************}
{@@
  Updates the HotKey state according to vConfigurations
}
{*******************************************************************}
procedure TMainWindow.UpdateHotKey(Sender: TObject);
begin
{$IFDEF Windows}
  {$IFNDEF WinCE}
    case vConfigurations.HotKeyMode of
     ID_HOTKEY_NO_HOTKEY:
     begin
       UnregisterHotKey(Handle, 0);
       RegisterHotKey(vMainWindow.Handle, 1, MOD_ALT or MOD_CONTROL, VK_LEFT);
       RegisterHotKey(vMainWindow.Handle, 2, MOD_ALT or MOD_CONTROL, VK_UP);
       RegisterHotKey(vMainWindow.Handle, 3, MOD_ALT or MOD_CONTROL, VK_RIGHT);
       RegisterHotKey(vMainWindow.Handle, 4, MOD_ALT or MOD_CONTROL, VK_DOWN);
       RegisterHotKey(vMainWindow.Handle, 5, MOD_ALT or MOD_CONTROL, VK_A);
       RegisterHotKey(vMainWindow.Handle, 6, MOD_ALT or MOD_CONTROL, VK_W);
       RegisterHotKey(vMainWindow.Handle, 7, MOD_ALT or MOD_CONTROL, VK_D);
       RegisterHotKey(vMainWindow.Handle, 8, MOD_ALT or MOD_CONTROL, VK_S);
       RegisterHotKey(vMainWindow.Handle, 9, MOD_ALT or MOD_CONTROL, VK_NumPad4);
       RegisterHotKey(vMainWindow.Handle, 10, MOD_ALT or MOD_CONTROL, VK_NumPad8);
       RegisterHotKey(vMainWindow.Handle, 11, MOD_ALT or MOD_CONTROL, VK_NumPad5);
       RegisterHotKey(vMainWindow.Handle, 12, MOD_ALT or MOD_CONTROL, VK_NumPad6);
     end;
     ID_HOTKEY_CTRLALTKEY:
     begin
       RegisterHotKey(Handle, 0, MOD_ALT or MOD_CONTROL, VkKeyScan(vConfigurations.HotKeyKey));
       RegisterHotKey(vMainWindow.Handle, 1, MOD_ALT or MOD_CONTROL, VK_LEFT);
       RegisterHotKey(vMainWindow.Handle, 2, MOD_ALT or MOD_CONTROL, VK_UP);
       RegisterHotKey(vMainWindow.Handle, 3, MOD_ALT or MOD_CONTROL, VK_RIGHT);
       RegisterHotKey(vMainWindow.Handle, 4, MOD_ALT or MOD_CONTROL, VK_DOWN);
       RegisterHotKey(vMainWindow.Handle, 5, MOD_ALT or MOD_CONTROL, VK_A);
       RegisterHotKey(vMainWindow.Handle, 6, MOD_ALT or MOD_CONTROL, VK_W);
       RegisterHotKey(vMainWindow.Handle, 7, MOD_ALT or MOD_CONTROL, VK_D);
       RegisterHotKey(vMainWindow.Handle, 8, MOD_ALT or MOD_CONTROL, VK_S);
       RegisterHotKey(vMainWindow.Handle, 9, MOD_ALT or MOD_CONTROL, VK_NumPad4);
       RegisterHotKey(vMainWindow.Handle, 10, MOD_ALT or MOD_CONTROL, VK_NumPad8);
       RegisterHotKey(vMainWindow.Handle, 11, MOD_ALT or MOD_CONTROL, VK_NumPad5);
       RegisterHotKey(vMainWindow.Handle, 12, MOD_ALT or MOD_CONTROL, VK_NumPad6);
     end;
     ID_HOTKEY_DISABLE_ASDW:
     begin
       UnregisterHotKey(Handle, 0);
       RegisterHotKey(vMainWindow.Handle, 1, MOD_ALT or MOD_CONTROL, VK_LEFT);
       RegisterHotKey(vMainWindow.Handle, 2, MOD_ALT or MOD_CONTROL, VK_UP);
       RegisterHotKey(vMainWindow.Handle, 3, MOD_ALT or MOD_CONTROL, VK_RIGHT);
       RegisterHotKey(vMainWindow.Handle, 4, MOD_ALT or MOD_CONTROL, VK_DOWN);
       UnregisterHotKey(Handle, 5);
       UnregisterHotKey(Handle, 6);
       UnregisterHotKey(Handle, 7);
       UnregisterHotKey(Handle, 8);
       UnregisterHotKey(Handle, 9);
       UnregisterHotKey(Handle, 10);
       UnregisterHotKey(Handle, 11);
       UnregisterHotKey(Handle, 12);
     end;
    end;

   case vConfigurations.DockedHotKeyMode of
    ID_DOCKED_HOTKEY_NO_HOTKEY:
    begin
      UnregisterHotKey(Handle, 13);
      UnregisterHotKey(Handle, 14);
      UnregisterHotKey(Handle, 15);
      UnregisterHotKey(Handle, 16);
      UnregisterHotKey(Handle, 17);
    end;
    ID_HOTKEY_CTRLALTKEY:
    begin
      RegisterHotKey(Handle, 13, MOD_ALT or MOD_CONTROL, VkKeyScan(vConfigurations.DockedHotKeyKey));
      RegisterHotKey(Handle, 14, MOD_ALT or MOD_CONTROL, VkKeyScan(vConfigurations.DockedRightHotKey));
      RegisterHotKey(Handle, 15, MOD_ALT or MOD_CONTROL, VkKeyScan(vConfigurations.DockedLeftHotKey));
      RegisterHotKey(Handle, 16, MOD_ALT or MOD_CONTROL, VkKeyScan(vConfigurations.DockedUpHotKey));
      RegisterHotKey(Handle, 17, MOD_ALT or MOD_CONTROL, VkKeyScan(vConfigurations.DockedDownHotKey));
      RegisterHotKey(Handle, 18, MOD_ALT or MOD_CONTROL, VkKeyScan(vConfigurations.DockedBookmarkHotKey));
    end;
   end;

  {$ENDIF}
{$ENDIF}
end;

{$IFDEF Win32}
{*******************************************************************}
{@@
  Window function of the main window.
  Only handles manually the messages for the taskbar icon.
  Other messages are forwarded to the Component Library
}
{*******************************************************************}
procedure TMainWindow.WndProc(var TheMessage: TLMessage);
var
  i: Integer;
  delta: ShortInt;
  wheel_delta: ShortInt;
  rotation: Double;
  VK, DockedVK, DockedRight_VK, DockedLeft_VK, DockedUp_VK, DockedDown_VK, DockedBookmark_VK: Word;
begin
  case TheMessage.Msg of
    WM_HOTKEY:
    begin
      case HiWord(TheMessage.lParam) of
       VK_UP, VK_NumPad8, VK_W:
       begin
         if vMainWindow.Visible then begin
           vGlass.GlassTop := vGlass.GlassTop - 10;
           vGlass.FixGlassCoordinates;
           {$IFNDEF USE_PLUGINS}
           if vConfigurations.UsePlugins then vMainWindow.Top := vGlass.GlassTop;
             ControlToInvalidate.Invalidate;
           {$ENDIF}
         end else
           if HiWord(TheMessage.lParam) = LoWord(VkKeyScan(vConfigurations.DockedUpHotKey)) then
             if vDockedGlass.Visible then
               MoveMouseUp;
       end;
       VK_DOWN, VK_NumPad5, VK_S:
       begin
         if vMainWindow.Visible then begin
           vGlass.GlassTop := vGlass.GlassTop + 10;
           vGlass.FixGlassCoordinates;
           {$IFNDEF USE_PLUGINS}
           if vConfigurations.UsePlugins then vMainWindow.Top := vGlass.GlassTop;
             ControlToInvalidate.Invalidate;
           {$ENDIF}
         end else
           if HiWord(TheMessage.lParam) = LoWord(VkKeyScan(vConfigurations.DockedDownHotKey)) then
             if vDockedGlass.Visible then
               MoveMouseDown;
       end;
       VK_RIGHT, VK_NumPad6, VK_D:
       begin
         if vMainWindow.Visible then begin
           vGlass.GlassLeft := vGlass.GlassLeft + 10;
           vGlass.FixGlassCoordinates;
           {$IFNDEF USE_PLUGINS}
           if vConfigurations.UsePlugins then vMainWindow.Left := vGlass.GlassLeft;
             ControlToInvalidate.Invalidate;
           {$ENDIF}
         end else
           if HiWord(TheMessage.lParam) = LoWord(VkKeyScan(vConfigurations.DockedRightHotKey)) then
             if vDockedGlass.Visible then
               MoveMouseRight;
       end;
       VK_LEFT, VK_NumPad4, VK_A:
       begin
         if vMainWindow.Visible then begin
           vGlass.GlassLeft := vGlass.GlassLeft - 10;
           vGlass.FixGlassCoordinates;
           {$IFNDEF USE_PLUGINS}
           if vConfigurations.UsePlugins then vMainWindow.Left := vGlass.GlassLeft;
             ControlToInvalidate.Invalidate;
           {$ENDIF}
         end else
           if HiWord(TheMessage.lParam) = LoWord(VkKeyScan(vConfigurations.DockedLeftHotKey)) then
             if vDockedGlass.Visible then
               MoveMouseLeft;
       end;
      else
        begin
          VK := LoWord(VkKeyScan(vConfigurations.HotKeyKey));
          DockedVK := LoWord(VkKeyScan(vConfigurations.DockedHotKeyKey));
          DockedRight_VK := LoWord(VkKeyScan(vConfigurations.DockedRightHotKey));
          DockedLeft_VK := LoWord(VkKeyScan(vConfigurations.DockedLeftHotKey));
          DockedUp_VK := LoWord(VkKeyScan(vConfigurations.DockedUpHotKey));
          DockedDown_VK := LoWord(VkKeyScan(vConfigurations.DockedDownHotKey));
          DockedBookmark_VK := LoWord(VkKeyScan(vConfigurations.DockedBookmarkHotKey));
          if HiWord(TheMessage.lParam) = DockedVK then
          begin
            if (vDockedGlass <> nil) then
            begin
              if (vDockedGlass.Visible) then
                vDockedGlass.Hide
              else
                ShowDockedGlass(nil)
            end
            else
              ShowDockedGlass(nil)
          end
          else if HiWord(TheMessage.lParam) = DockedRight_VK then
            MoveMouseRight
          else if HiWord(TheMessage.lParam) = DockedLeft_VK then
            MoveMouseLeft
          else if HiWord(TheMessage.lParam) = DockedUp_VK then
            MoveMouseUp
          else if HiWord(TheMessage.lParam) = DockedDown_VK then
            MoveMouseDown
          else if HiWord(TheMessage.lParam) = DockedBookmark_VK then
          begin
            if Assigned(vDockedGlass) then vDockedGlass.UpdateBookmark;
          end
          else if HiWord(TheMessage.lParam) = VK then
            vMainWindow.ExecuteLens(vMainWindow);
        end;
      end;
    end;

{    WM_MOUSEWHEEL:
    begin
      // Why was the old code like this?
//      wheel_delta := HiWord(Message.WParam);
//      Move(wheel_delta, delta, SizeOf(Word));
//      rotation := delta / WHEEL_DELTA;

//      if (rotation > 0.0) then delta := Round(rotation + 0.5)
//      else delta := Round(rotation - 0.5);

      // New better code, based on MSDN docs
      wheel_delta := HiWord(Message.WParam);
      delta := wheel_delta div 120;

      for i := 1 to abs(delta) do
      begin
        // Call same code as from VK_ADD, VK_SUBTRACT handlers
        if (delta > 0.0) then
         vConfigurations.iMagnification := vConfigurations.iMagnification + 0.5
        else vConfigurations.iMagnification := vConfigurations.iMagnification - 0.5;
      end;

      // Hard limits for the magnification
      if vConfigurations.iMagnification < 1.0 then vConfigurations.iMagnification := 1.0
      else if vConfigurations.iMagnification > 16 then vConfigurations.iMagnification := 16;

      vGlass.Repaint;
    end;}

    MYWM_SHOWGLASS:
    begin
      // This check fixes a bug when using multiple times the keyboard shortcut
      // The glass is shown multiple times causes it to screenshot the previous one
      if not vMainWindow.Visible then vMainWindow.ExecuteLens(nil);
    end;
    MYWM_SHOWDOCKEDGLASS:
    begin
      ShowDockedGlass(nil);
    end;
  end;

  inherited WndProc(TheMessage);
end;
{$ENDIF}

{*******************************************************************}
{@@
  Action executed when the user clicks on the "Anti-Aliasing" menu item
}
{*******************************************************************}
procedure TMainWindow.ChangeAntiAliasing(Sender: TObject);
begin
  vConfigurations.AntiAliasing := not vConfigurations.AntiAliasing;

  UpdateConfigurations;
end;

{*******************************************************************}
{@@
  Action executed to change the tools status
}
{*******************************************************************}
procedure TMainWindow.ChangeTools(Sender: TObject);
begin
  vConfigurations.showTools := not vConfigurations.showTools;
  UpdateConfigurations;
end;

{*******************************************************************}
{@@
  Handles the keyboard key actions
}
{*******************************************************************}
procedure TMainWindow.HandleKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Step: Integer;
begin
  if vConfigurations.iMagnification < 12.0 then Step := 10 else Step := 1;
  case Key of
   VK_UP:
   begin
     vConfigurations.ySquare := vConfigurations.ySquare - 1;
     if vConfigurations.ySquare <= 2 then vConfigurations.ySquare := 2;
     UpdateConfigurations;
     if vConfigurations.UsePlugins then vMainWindow.Height := vGlass.GlassHeight;
   end;
   VK_DOWN:
   begin
     vConfigurations.ySquare := vConfigurations.ySquare + 1;
     if vConfigurations.ySquare >= 32 then vConfigurations.ySquare := 32;
     UpdateConfigurations;
     if vConfigurations.UsePlugins then vMainWindow.Height := vGlass.GlassHeight;
   end;
   VK_RIGHT:
   begin
     vConfigurations.xSquare := vConfigurations.xSquare + 1;
     if vConfigurations.xSquare >= 50 then vConfigurations.xSquare := 50;
     UpdateConfigurations;
     if vConfigurations.UsePlugins then vMainWindow.Width := vGlass.GlassWidth;
   end;
   VK_LEFT:
   begin
     vConfigurations.xSquare := vConfigurations.xSquare - 1;
     if vConfigurations.xSquare <= 2 then vConfigurations.xSquare := 2;
     UpdateConfigurations;
     if vConfigurations.UsePlugins then vMainWindow.Width := vGlass.GlassWidth;
   end;
   VK_W:
   begin
     Mouse.CursorPos := Point(Mouse.CursorPos.X, Mouse.CursorPos.Y - Step);
     Bookmark2 := Mouse.CursorPos;
   end;
   VK_S:
   begin
     Mouse.CursorPos := Point(Mouse.CursorPos.X, Mouse.CursorPos.Y + Step);
     Bookmark2 := Mouse.CursorPos;
   end;
   VK_D: Mouse.CursorPos := Point(Mouse.CursorPos.X + Step, Mouse.CursorPos.Y);
   VK_A: Mouse.CursorPos := Point(Mouse.CursorPos.X - Step, Mouse.CursorPos.Y);
   VK_PRIOR: Mouse.CursorPos := Point(Mouse.CursorPos.X, Mouse.CursorPos.Y - 50); // Page Up
   VK_NEXT: Mouse.CursorPos := Point(Mouse.CursorPos.X, Mouse.CursorPos.Y + 50);  // Page Down
   VK_ESCAPE: HideWindow(Self);
   VK_RETURN: HideWindow(Self);
   VK_B: ChangeGraphicalBorder(Self);
   VK_Q: CloseWindow(Self);
   VK_C: if Shift = [ssCtrl] then Clipboard.AsText := '';
   VK_G:
   begin
     ShowDockedGlass(nil);
     vDockedGlass.SetLensIsShown(True);
   end;
   VK_1: Bookmark1 := Mouse.CursorPos;
   VK_F1: Mouse.CursorPos := Bookmark1;
   VK_SPACE: Mouse.CursorPos := Bookmark2;
   VK_Y:
   begin
     if not (MovingLeft) then
       Bookmark2 := Mouse.CursorPos;
   end;
   VK_T:
   begin
     if not (MovingRight) then
       Bookmark2 := Mouse.CursorPos;
   end;
   VK_H: Mouse.CursorPos := Point(Mouse.CursorPos.X, Mouse.CursorPos.Y + 2);
   VK_LCL_OPEN_BRACKET:
   begin
     Dec(vConfigurations.ReadingSpeed);
     if (vConfigurations.ReadingSpeed) < 1 then vConfigurations.ReadingSpeed := 1;
   end;
   VK_LCL_CLOSE_BRACKET:
   begin
     Inc(vConfigurations.ReadingSpeed);
     if (vConfigurations.ReadingSpeed) > 25 then vConfigurations.ReadingSpeed := 25;
   end;
   VK_CONTROL:
   begin
     if ControlDown = False then
     begin
       ControlDown := True;
       Bookmark2 := Mouse.CursorPos;
     end;
   end;
  else
    Exit;
  end;

  // Hard limits for the magnification
  if vConfigurations.iMagnification < 1.0 then vConfigurations.iMagnification := 1.0
  else if vConfigurations.iMagnification > 16 then vConfigurations.iMagnification := 16;

  // Carbon doesn't generate an OnMove when the cursor is programatically changed
  {$ifdef LCLCarbon}
  Self.MoveGlass(nil, [], 0, 0);
  {$endif}

  ControlToInvalidate.Invalidate;
end;

{*******************************************************************}
{@@
  Handles the keyboard key actions
}
{*******************************************************************}
procedure TMainWindow.HandleKeyPress(Sender: TObject; var Key: Char);
begin
  { We need to Handle + and - in OnKeyPress and not OnKeyDown to
    allow for building this characters with key combos. OnKeyDown
    works for single key presses, not combos }
  case Key of
   '+': vConfigurations.iMagnification := vConfigurations.iMagnification + 0.5;
   '-': vConfigurations.iMagnification := vConfigurations.iMagnification - 0.5;
   'X': vConfigurations.Contrast := vConfigurations.Contrast + 1;
   'x': vConfigurations.Contrast := vConfigurations.Contrast + 1;
   'Z': vConfigurations.Contrast := vConfigurations.Contrast - 1;
   'z': vConfigurations.Contrast := vConfigurations.Contrast - 1;
   'C': vConfigurations.Contrast := 0;
   'c': vConfigurations.Contrast := 0;
   'y':
   begin
     MovingLeft := True;
     Mouse.CursorPos := Point(Mouse.CursorPos.X + vConfigurations.ReadingSpeed, Mouse.CursorPos.Y);
   end;
   'Y':
   begin
     MovingLeft := True;
     Mouse.CursorPos := Point(Mouse.CursorPos.X + vconfigurations.ReadingSpeed, Mouse.CursorPos.Y);
   end;
   't':
   begin
     MovingRight := True;
     Mouse.CursorPos := Point(Mouse.CursorPos.X - vConfigurations.ReadingSpeed, Mouse.CursorPos.Y);
   end;
   'T':
   begin
     MovingRight := True;
     Mouse.CursorPos := Point(Mouse.CursorPos.X - vconfigurations.ReadingSpeed, Mouse.CursorPos.Y);
   end;
  else
    Exit;
  end;

  // Hard limits for the magnification
  if vConfigurations.iMagnification < 1.0 then vConfigurations.iMagnification := 1.0
  else if vConfigurations.iMagnification > 16 then vConfigurations.iMagnification := 16;

  // Hard limits for the contrast
  if vConfigurations.Contrast < 0 then vConfigurations.Contrast := 1
  else if vConfigurations.Contrast > 126 then vConfigurations.Contrast := 126;

  KeyTimer.Enabled := False;
  KeyTimer.Enabled := True;
  vGlass.BackgroundThreadFinished := False;
  ControlToInvalidate.Invalidate;
end;

procedure TMainWindow.HandleKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
   VK_Y:
   begin
     MovingLeft := False;
     Mouse.CursorPos := Bookmark2;
   end;
   VK_T:
   begin
     MovingRight := False;
     Mouse.CursorPos := Bookmark2;
   end;
   VK_CONTROL:
   begin
     ControlDown := False;
     Mouse.CursorPos := Bookmark2;
   end;
  end;
end;

{*******************************************************************
*  TMainWindow.HandleOnClose ()
*
*  PARAMETERS:     Sender -
*
*  DESCRIPTOON:   This procedure is fixes a bug on Windows CE Lazarus
*                 Component Library that prevents the main window from
*                 closing
*
*******************************************************************}
procedure TMainWindow.HandleOnClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Self.Close;
end;

{*******************************************************************
*  TMainWindow.HandleShow ()
*
*  PARAMETERS:     Sender -
*
*  DESCRIPTOON:   This procedure is required because setting the position
*                 of a window on MS Windows to a negative value will fail
*                 before the window is shown, and this is required to
*                 support multiple monitors
*
*******************************************************************}
procedure TMainWindow.HandleShow(Sender: TObject);
begin
  {$ifndef VMG_DEBUG_SMALL_MODE}
  Self.Left := vGlass.XScreen;
  Self.Top := vGlass.YScreen;
  Self.Width := vGlass.CXScreen;
  Self.Height := vGlass.CYScreen;
  {$endif}

  {$if defined(LCLQt)} // Under Carbon don't even try, as it makes things worse
  vGlass.Cursor := crNone;
  {$ifend}
end;

{*******************************************************************
*  TMainWindow.HandleMouseWheel ()
*
*  PARAMETERS:    Sender -
*
*  DESCRIPTOON:   Handles mouse wheel scrolling
*
*******************************************************************}
procedure TMainWindow.HandleMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  i, delta: Integer;
begin
  delta := wheeldelta div 120;

  if not ControlDown then
  begin
    for i := 1 to abs(delta) do
    begin
      // Call same code as from VK_ADD, VK_SUBTRACT handlers
      if (WheelDelta > 0.0) then
       vConfigurations.iMagnification := vConfigurations.iMagnification + 0.5
      else vConfigurations.iMagnification := vConfigurations.iMagnification - 0.5;
    end;

    // Hard limits for the magnification
    if vConfigurations.iMagnification < 1.0 then vConfigurations.iMagnification := 1.0
    else if vConfigurations.iMagnification > 16 then vConfigurations.iMagnification := 16;

    vGlass.BackgroundThreadFinished := False;
    ControlToInvalidate.Invalidate;
    WheelTimer.Enabled := False;
    WheelTimer.Enabled := True;
  end
  else
  begin
    if (WheelDelta > 0.0) then
      Mouse.CursorPos := Point(Mouse.CursorPos.X - vconfigurations.ReadingSpeed, Mouse.CursorPos.Y)
    else
      Mouse.CursorPos := Point(Mouse.CursorPos.X + vconfigurations.ReadingSpeed, Mouse.CursorPos.Y);
  end;
end;

procedure TMainWindow.KeyTimerTimer(Sender: Tobject);
begin
  KeyTimer.Enabled := False;
  vGlass.BackgroundThreadStart;
end;

procedure TMainWindow.WheelTimerTimer(Sender: Tobject);
begin
  WheelTimer.Enabled := False;
  vGlass.BackgroundThreadStart;
end;

{*******************************************************************
*  TMainWindow.HandleDynamicMode ()
*
*  DESCRIPTION:
*
*  PARAMETERS:     Sender -
*
*******************************************************************}
procedure TMainWindow.HandleDynamicMode(Sender: TObject);
begin
  // First close the plugin to avoid clashes
  HandleClosePlugin(Sender);

  vConfigurations.UsePlugins := not vConfigurations.UsePlugins;

  UpdateConfigurations;
end;

{*******************************************************************
*  TMainWindow.HandleHideGlass ()
*
*  DESCRIPTION:     Under Carbon and Qt the cursor keeps disappearing after the glass is hidden,
*                   so a workaround is needed
*
*******************************************************************}
procedure TMainWindow.HandleHideGlass(Sender: TObject);
begin
  DynamicModeTimer.Enabled := False;
  // Some widgetsets have trouble with mouse cursors
  // Under Carbon it would be necessary, but we don't even try setting the cursor
  {$if defined(LCLQt)}
  vGlass.Cursor := crArrow;
  {$ifend}
end;

{*******************************************************************
*  TMainWindow.ShowHelp ()
*
*  DESCRIPTION:    Action executed to show the project's homepage
*
*                  Under Unix we first try to locate a software to
*                  open the default application. If we can't find it,
*                  we just try to use XPDF
*
*  PARAMETERS:     Sender - The object which requested the action
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TMainWindow.ShowHelp(Sender: TObject);
var
  Lang, HelpFileName: string;
begin
  case vConfigurations.Language of
   ID_MENU_PORTUGUESE: Lang := 'PT';
//   ID_MENU_SPANISH: ;
//   ID_MENU_FRENCH: ;
  else
   Lang := 'EN';
  end;

  HelpFileName := vConfigurations.MyDirectory + 'README-' + Lang + '.pdf';

//  HelpFileName := vConfigurations.MyDirectory + 'README-' + Lang + '.fml';

//  vFMLViewerDialog.LoadFromFile(HelpFileName);

//  vFMLViewerDialog.Show;

  LCLIntf.OpenDocument(HelpFileName);
end;

procedure TMainWindow.CreateDockedGlass;
begin
  if (vDockedGlass = nil) then
    vDockedGlass :=  TDockedGlassWindow.Create(nil);
end;

procedure TMainWindow.ShowDockedGlass(Sender: TObject);
begin
  if (vDockedGlass = nil) then
    vDockedGlass :=  TDockedGlassWindow.Create(nil);
  vDockedGlass.Show;
end;

{*******************************************************************
*  TMainWindow.ChangeShowWhenExecuted ()
*
*  DESCRIPTION:
*
*  PARAMETERS:     Sender -
*
*******************************************************************}
procedure TMainWindow.ChangeShowWhenExecuted(Sender: TObject);
begin
  vConfigurations.showWhenExecuted := not vConfigurations.showWhenExecuted;

  UpdateConfigurations;
end;

{*******************************************************************}
{@@
}
{*******************************************************************}
procedure TMainWindow.HandleClosePlugin(Sender: TObject);
begin
  {$IFDEF WINDOWS}
  {$IFDEF USE_PLUGINS}
  if vPlugins.Initialized then vPlugins.Finalize;

  if vPlugins.Loaded then vPlugins.UnloadPlugin;
  {$ELSE}
  Hide;
  {$ENDIF}
  {$ENDIF}
end;

{$IFDEF Unix}
procedure TMainWindow.CheckWatchFile(Sender: TObject);
var
  tFile: TextFile;
  FileContents : String;

begin

  if vMainWindow.Visible = False then
  begin
       AssignFile(tFile, FILE_WATCH_SHORTCUT);

       if FileExists(FILE_WATCH_SHORTCUT) then
       begin
            reset(tFile);
            while not eof(tFile) do
            begin
                 readln(tFile, FileContents);
            end;
            CloseFile(tFile);
       end;

       if FileContents = 'Docked' then
       begin
           CleanWatchFile;

           if Assigned(vDockedGlass) then
           begin
             if vDockedGlass.Visible = True then
               vDockedGlass.Hide
             else
               vDockedGlass.Show;
           end
           else
       	     ShowDockedGlass(nil);
       end
       else if FileContents = 'Show' then
       begin
           CleanWatchFile;
           vMainWindow.ExecuteLens(nil);
       end
       else if FileContents = 'Bookmark' then
       begin
         CleanWatchFile;
         if Assigned(vDockedGlass) then
         begin
           vDockedGlass.UpdateBookmark;
         end;
       end;
       //else if FileContents = 'Mouse' then
       //begin
       //    CleanWatchFile;
       //    ShowDockedGlass;
       //end
  end;
end;

procedure TMainWindow.CleanWatchFile;
var
  tFile: TextFile;
begin
     AssignFile(tFile, FILE_WATCH_SHORTCUT);
     rewrite(tFile);
     writeln(tFile, '');
     CloseFile(tFile);
end;

{$ENDIF}

end.

