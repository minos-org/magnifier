{
appsettings.pas

Class which stores the program settings

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
unit appsettings;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

{$IFDEF Win32}
  {$DEFINE Windows}
{$ENDIF}

interface

uses
{$IFDEF Windows}
  Windows, shlobj,
{$ENDIF}
  Classes, SysUtils, Forms, IniFiles, translationsvmg, constants;

type
  { TConfigurations }

  TConfigurations = class(TObject)
  private
    ConfigFilePath: string;
  public
    iMagnification: Double;
    iMagnificationMax: Integer;
    xSquare, ySquare: Integer;
    xSquareMax, ySquareMax: Integer;
    showTools, graphicalBorder, AntiAliasing, ExtraAntiAliasing: Boolean;
    PostProcessing: Boolean;
    MemMB, ReadingSpeed: Integer;
    showWhenExecuted, showDockedWhenExecuted, autoRun: Boolean;
    showDockedWhenLensHides, hideDockedWhenLensShows: Boolean;
    dockedBorders: Boolean;
    invertColors: Boolean;
    MyDirectory: string;
    Language: Integer;
    firstRun: Boolean;
    // Hot Key
    HotKeyMode: Integer;
    DockedHotKeyMode: Integer;
    HotKeyKey, DockedHotKeyKey, DockedBookmarkHotKey: Char;
    DockedRightHotKey, DockedLeftHotKey, DockedUpHotKey, DockedDownHotKey: Char;
    // Plugins
    UsePlugins: Boolean;
    PluginName: string;
    PluginData: Integer;
    Contrast: Integer;
    DockedX, DockedY, DockedWidth, DockedHeight: Integer;
    DockedBookmarkX, DockedBookmarkY: Integer;
    DockedCursor : Integer;
    DockedFollowMouse: Boolean;
    RemapEnabled: Boolean;
    RemapWidth, RemapHeight: Integer;
    RemapRed, RemapGreen, RemapBlue: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure ReadFromFile(Sender: TObject);
    procedure Save(Sender: TObject);
    function GetConfigFilePath: string;
    function GetMyDirectory: string;
    function GetSystemLanguage: Integer;
    function GetOSVersion: TOSVersion;
  end;

var
  vConfigurations: TConfigurations;

implementation

{$ifdef Darwin}
uses
  MacOSAll;
{$endif}

{ TConfigurations }

{*******************************************************************
*  TConfigurations.Create ()
*
*  DESCRIPTION:    Creates an object,
*                  populates the class with the default configurations and
*                  then tryes to load the configurations from the XML file
*
*                  Under Mac OS X there is also the need to find the location
*                  of the Application Bundle
*
*  PARAMETERS:     None
*
*  RETURNS:        A pointer to the newly created object
*
*******************************************************************}
constructor TConfigurations.Create;
begin
  { First we use some good defaults in case the configuration file doesn't yet exist }

  iMagnification := 2.0;
  xSquare := 16;
  ySquare := 10;
  showTools := False;
  graphicalBorder := True;
  AntiAliasing := False;
  PostProcessing := False;
  MemMB := 500;
  ReadingSpeed := 10;
  showWhenExecuted := True;
  showDockedWhenExecuted := False;
  showDockedWhenLensHides := False;
  hideDockedWhenLensShows := False;
  dockedBorders := True;
  autoRun := False;
  invertColors := False;
  Language := GetSystemLanguage();
  HotKeyMode := 1;
  HotKeyKey := 'm';
  DockedHotKeyMode := 1;
  DockedHotKeyKey := 'g';
  DockedRightHotKey := 'd';
  DockedLeftHotKey := 'a';
  DockedUpHotKey := 'w';
  DockedDownHotKey := 's';
  DockedBookmarkHotKey := 'b';
  UsePlugins := False;
  PluginName := 'pas_overlays.dll';
  PluginData := -1;
  Contrast := 0;
  DockedX := 100;
  DockedY := 100;
  DockedWidth := 500;
  DockedHeight := 500;
  DockedCursor := 1;
  DockedFollowMouse := True;
  DockedBookmarkX := 0;
  DockedBookmarkY := 0;
  RemapEnabled := False;
  RemapWidth := 50;
  RemapHeight := 50;
  RemapRed := 0;
  RemapGreen := 0;
  RemapBlue := 0;

  { Now identifies where the configuration file should be }
  ConfigFilePath := GetConfigFilePath();

  // Under Mac OS X we need to get the location of the bundle
  MyDirectory := GetMyDirectory;

  ReadFromFile(nil);

  vTranslations.TranslateToLanguage(Language);
end;

{*******************************************************************
*  TConfigurations.Destroy ()
*
*  DESCRIPTION:    Dont call this method directly. Use Free instead.
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
destructor TConfigurations.Destroy;
begin
  Save(nil);

  inherited Destroy;
end;

{*******************************************************************
*  TConfigurations.ReadFromFile ()
*
*  DESCRIPTION:
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TConfigurations.ReadFromFile(Sender: TObject);
var
  MyFile: TIniFile;
begin
  if not FileExists(ConfigFilePath) then Exit;

  MyFile := TIniFile.Create(ConfigFilePath);
  try
    xSquare := MyFile.ReadInteger(SectionGeneral, IdentxSquare, 16);
    ySquare := MyFile.ReadInteger(SectionGeneral, IdentySquare, 10);
    iMagnification := MyFile.ReadFloat(SectionGeneral, IdentiMagnification, 2.0);
    showTools := MyFile.ReadBool(SectionGeneral, IdentTools, False);
    graphicalBorder := MyFile.ReadBool(SectionGeneral, IdentgraphicalBorder, True);
    invertColors := MyFile.ReadBool(SectionGeneral, IdentInvertColors, False);
    AntiAliasing := MyFile.ReadBool(SectionGeneral, IdentAntiAliasing, False);
    ExtraAntiAliasing := MyFile.ReadBool(SectionGeneral, IdentExtraAntiAliasing, False);
    PostProcessing := MyFile.ReadBool(SectionGeneral, IdentPostProcessing, False);
    MemMB := MyFile.ReadInteger(SectionGeneral, IdentMemMB, 500);
    ReadingSpeed := MyFile.ReadInteger(SectionGeneral, IdentReadingSpeed, 10);
    showWhenExecuted := MyFile.ReadBool(SectionGeneral, IdentShowWhenExecuted, True);
    showDockedWhenExecuted :=  MyFile.ReadBool(SectionGeneral, IdentShowDockedWhenExecuted, False);
    showDockedWhenLensHides :=  MyFile.ReadBool(SectionGeneral, IdentShowDockedWhenLensHides, False);
    hideDockedWhenLensShows :=  MyFile.ReadBool(SectionGeneral, IdentHideDockedWhenLensShows, False);
    autoRun := MyFile.ReadBool(SectionGeneral, IdentAutoRun, False);
    Language := MyFile.ReadInteger(SectionGeneral, IdentLanguage, ID_MENU_ENGLISH);
    firstRun := MyFile.ReadBool(SectionGeneral, IdentFirstRun, True);
    Contrast := MyFile.ReadInteger(SectionGeneral, IdentContrast, 0);
    DockedX := MyFile.ReadInteger(SectionGeneral, IdentDockedX, 100);
    DockedY := MyFile.ReadInteger(SectionGeneral, IdentDockedY, 100);
    DockedFollowMouse := MyFile.ReadBool(SectionGeneral, IdentDockedFollowMouse, True);
    DockedBookmarkX := MyFile.ReadInteger(SectionGeneral, IdentDockedBookmarkX, 0);
    DockedBookmarkY := MyFile.ReadInteger(SectionGeneral, IdentDockedBookmarkY, 0);
    DockedWidth := MyFile.ReadInteger(SectionGeneral, IdentDockedWidth, 500);
    if (DockedWidth < 25) then DockedWidth := 25;
    DockedHeight := MyFile.ReadInteger(SectionGeneral, IdentDockedHeight, 500);
    if (DockedHeight < 25) then DockedHeight := 25;
    DockedCursor := MyFile.ReadInteger(SectionGeneral, IdentDockedCursor, 1);
    dockedBorders := MyFile.ReadBool(SectionGeneral, IdentDockedBorder, True);

    {$ifdef UNIX}
      {$ifndef DARWIN}
        MyDirectory := MyFile.ReadString(SectionUnix, IdentMyDirectory, DefaultDirectory);
      {$endif}
    {$endif}

    HotKeyMode := MyFile.ReadInteger(SectionWindows, IdentHotKeyMode, ID_HOTKEY_CTRLALTKEY);
    try
      HotKeyKey := MyFile.ReadString(SectionWindows, IdentHotKeyKey, ID_DEFAULT_HOTKEY)[1];
    except
      HotKeyMode := 0;
      HotKeyKey := ' ';
    end;
    DockedHotKeyMode := MyFile.ReadInteger(SectionWindows, IdentDockedHotKeyMode, ID_DOCKED_HOTKEY_CTRLALTKEY);
    try
      DockedHotKeyKey := MyFile.ReadString(SectionWindows, IdentDockedHotKeyKey, ID_DEFAULT_DOCKEDHOTKEY)[1];
    except
      DockedHotKeyMode := 0;
      DockedHotKeyKey := ' ';
    end;
    try
      DockedRightHotKey := MyFile.ReadString(SectionWindows, IdentDockedRightHotKey, ID_DEFAULT_DOCKED_RIGHT_HOTKEY)[1];
    except
      DockedHotKeyMode := 0;
      DockedRightHotKey := ' ';
    end;
    try
      DockedLeftHotKey := MyFile.ReadString(SectionWindows, IdentDockedLeftHotKey, ID_DEFAULT_DOCKED_LEFT_HOTKEY)[1];
    except
      DockedHotKeyMode := 0;
      DockedLeftHotKey := ' ';
    end;
    try
      DockedUpHotKey := MyFile.ReadString(SectionWindows, IdentDockedUpHotKey, ID_DEFAULT_DOCKED_UP_HOTKEY)[1];
    except
      DockedHotKeyMode := 0;
      DockedUpHotKey := ' ';
    end;
    try
      DockedDownHotKey := MyFile.ReadString(SectionWindows, IdentDockedDownHotKey, ID_DEFAULT_DOCKED_DOWN_HOTKEY)[1];
    except
      DockedHotKeyMode := 0;
      DockedDownHotKey := ' ';
    end;
    try
      DockedBookmarkHotKey := MyFile.ReadString(SectionWindows, IdentDockedBookmarkHotKey, ID_DEFAULT_DOCKED_BOOKMARK_HOTKEY)[1];
    except
      DockedHotKeyMode := 0;
      DockedDownHotKey := ' ';
    end;

    RemapEnabled := MyFile.ReadBool(SectionGeneral, IdentRemapEnabled, False); ;
    RemapWidth := MyFile.ReadInteger(SectionGeneral, IdentRemapWidth, 50);
    RemapHeight := MyFile.ReadInteger(SectionGeneral, IdentRemapHeight, 50);
    RemapRed := MyFile.ReadInteger(SectionGeneral, IdentRemapRed, 0);
    RemapGreen := MyFile.ReadInteger(SectionGeneral, IdentRemapGreen, 0);
    RemapBlue := MyFile.ReadInteger(SectionGeneral, IdentRemapBlue, 0);

    UsePlugins := MyFile.ReadBool(SectionPlugins, IdentUsePlugins, False);
    PluginName := MyFile.ReadString(SectionPlugins, IdentPluginName, 'pas_overlays.dll');
    PluginData := MyFile.ReadInteger(SectionPlugins, IdentPluginData, 0);
  finally
    MyFile.Free;

    {*******************************************************************
    *  Fix for the default value apparently not working on Windows for Float
    *******************************************************************}
    if iMagnification = 0.0 then iMagnification := 2.0;
  end;
end;

{*******************************************************************
*  TConfigurations.Save ()
*
*  DESCRIPTION:
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TConfigurations.Save(Sender: TObject);
var
  MyFile: TIniFile;
begin
  MyFile := TIniFile.Create(ConfigFilePath);
  try
    MyFile.WriteInteger(SectionGeneral, IdentxSquare, xSquare);
    MyFile.WriteInteger(SectionGeneral, IdentySquare, ySquare);
    MyFile.WriteFloat(SectionGeneral, IdentiMagnification, iMagnification);
    MyFile.WriteBool(SectionGeneral, IdentTools, showTools);
    MyFile.WriteBool(SectionGeneral, IdentgraphicalBorder, graphicalBorder);
    MyFile.WriteBool(SectionGeneral, IdentInvertColors, invertColors);
    MyFile.WriteBool(SectionGeneral, IdentAntiAliasing, AntiAliasing);
    MyFile.WriteBool(SectionGeneral, IdentExtraAntiAliasing, ExtraAntiAliasing);
    MyFile.WriteBool(SectionGeneral, IdentPostProcessing, PostProcessing);
    MyFile.WriteInteger(SectionGeneral, IdentMemMB, MemMB);
    MyFile.WriteInteger(SectionGeneral, IdentReadingSpeed, ReadingSpeed);
    MyFile.WriteBool(SectionGeneral, IdentShowWhenExecuted, showWhenExecuted);
    MyFile.WriteBool(SectionGeneral, IdentShowDockedWhenExecuted, showDockedWhenExecuted);
    MyFile.WriteBool(SectionGeneral, IdentShowDockedWhenLensHides, showDockedWhenLensHides);
    MyFile.WriteBool(SectionGeneral, IdentHideDockedWhenLensShows, hideDockedWhenLensShows);
    MyFile.WriteBool(SectionGeneral, IdentAutoRun, autoRun);
    MyFile.WriteInteger(SectionGeneral, IdentLanguage, Language);
    MyFile.WriteBool(SectionGeneral, IdentFirstRun, firstRun);
    MyFile.WriteInteger(SectionGeneral, IdentContrast, Contrast);
    MyFile.WriteInteger(SectionGeneral, IdentDockedX, DockedX);
    MyFile.WriteInteger(SectionGeneral, IdentDockedY, DockedY);
    MyFile.WriteInteger(SectionGeneral, IdentDockedWidth, DockedWidth);
    MyFile.WriteInteger(SectionGeneral, IdentDockedHeight, DockedHeight);
    MyFile.WriteBool(SectionGeneral, IdentDockedFollowMouse, DockedFollowMouse);
    MyFile.WriteInteger(SectionGeneral, IdentDockedBookmarkX, DockedBookmarkX);
    MyFile.WriteInteger(SectionGeneral, IdentDockedBookmarkY, DockedBookmarkY);
    MyFile.WriteInteger(SectionGeneral, IdentDockedCursor, DockedCursor);
    MyFile.WriteBool(SectionGeneral, IdentDockedBorder, DockedBorders);

    MyFile.WriteString(SectionUnix, IdentMyDirectory, MyDirectory);

    MyFile.WriteInteger(SectionWindows, IdentHotKeyMode, HotKeyMode);
    MyFile.WriteString(SectionWindows, IdentHotKeyKey, HotKeyKey);
    MyFile.WriteInteger(SectionWindows, IdentDockedHotKeyMode, DockedHotKeyMode);
    MyFile.WriteString(SectionWindows, IdentDockedHotKeyKey, DockedHotKeyKey);
    MyFile.WriteString(SectionWindows, IdentDockedRightHotKey, DockedRightHotKey);
    MyFile.WriteString(SectionWindows, IdentDockedLeftHotKey, DockedLeftHotKey);
    MyFile.WriteString(SectionWindows, IdentDockedUpHotKey, DockedUpHotKey);
    MyFile.WriteString(SectionWindows, IdentDockedDownHotKey, DockedDownHotKey);
    MyFile.WriteString(SectionWindows, IdentDockedBookmarkHotKey, DockedBookmarkHotKey);

    MyFile.WriteBool(SectionGeneral, IdentRemapEnabled, RemapEnabled);
    MyFile.WriteInteger(SectionGeneral, IdentRemapWidth, RemapWidth);
    MyFile.WriteInteger(SectionGeneral, IdentRemapHeight, RemapHeight);
    MyFile.WriteInteger(SectionGeneral, IdentRemapRed, RemapRed);
    MyFile.WriteInteger(SectionGeneral, IdentRemapGreen, RemapGreen);
    MyFile.WriteInteger(SectionGeneral, IdentRemapBlue, RemapBlue);

    MyFile.WriteBool(SectionPlugins, IdentUsePlugins, UsePlugins);
    MyFile.WriteString(SectionPlugins, IdentPluginName, PluginName);
    MyFile.WriteInteger(SectionPlugins, IdentPluginData, PluginData);
  finally
    MyFile.Free;
  end;
end;

function TConfigurations.GetConfigFilePath: string;
var
  APath : Array[0..MAX_PATH] of char;
  LocalConfigFile: string;
  attrs: Integer;
begin
{$ifdef Windows}

  // First tryes to use a configuration file in the application directory
  // Necessary to use the magnifier as a "portable" application
  LocalConfigFile := ExtractFilePath(Application.EXEName) + 'magnifier.ini';

  // Only uses the file if it exist, isn't readonly and isn't a directory
  attrs := FileGetAttr(LocalConfigFile);

  if FileExists(LocalConfigFile) and (attrs and faReadOnly = 0)
   and (attrs and faDirectory = 0) then
  begin
    Result := LocalConfigFile;
  end
  else
  begin
    // GetAppConfigFile from FPC is too unstable to be used
    // Microsoft recomends CSIDL_APPDATA\Company\Product\Version\

    Result := '';

    SHGetSpecialFolderPath(0, APath, CSIDL_APPDATA, True);

//  Another option: uses shfolder  SHGetFolderPath(0, CSIDL_APPDATA or CSIDL_FLAG_CREATE,0,0,@APATH[0]);

    Result := IncludeTrailingPathDelimiter(StrPas(@APath[0])) + 'Magnifier\';

    ForceDirectories(Result);

    Result := Result + 'magnifier.ini';
  end;
{$endif}
{$ifdef Unix}
  Result := GetEnvironmentVariable('HOME') + '/.magnifier.ini';
{$endif}
end;

function TConfigurations.GetMyDirectory: string;
{$ifdef Darwin}
var
  pathRef: CFURLRef;
  pathCFStr: CFStringRef;
  pathStr: shortstring;
{$endif}
begin
{$ifdef UNIX}
{$ifdef Darwin}
  pathRef := CFBundleCopyBundleURL(CFBundleGetMainBundle());
  pathCFStr := CFURLCopyFileSystemPath(pathRef, kCFURLPOSIXPathStyle);
  CFStringGetPascalString(pathCFStr, @pathStr, 255, CFStringGetSystemEncoding());
  CFRelease(pathRef);
  CFRelease(pathCFStr);

  Result := pathStr + BundleResourcesDirectory;
{$else}
  Result := DefaultDirectory;
{$endif}
{$endif}

{$ifdef Windows}
  Result := ExtractFilePath(Application.EXEName);
{$endif}
end;

function TConfigurations.GetSystemLanguage: Integer;
  {$ifdef Windows}
var
  LangId: Word;
  MainLangId: Byte;
begin
  LangId := GetSystemDefaultLangID;
  MainLangId := LangId;
  case MainLangId of

    LANG_PORTUGUESE: Result := ID_MENU_PORTUGUESE;
    LANG_SPANISH: Result := ID_MENU_SPANISH;
    LANG_FRENCH: Result := ID_MENU_FRENCH;
    LANG_GERMAN: Result := ID_MENU_GERMAN;
    LANG_ITALIAN: Result := ID_MENU_ITALIAN;
    LANG_RUSSIAN: Result := ID_MENU_RUSSIAN;
    LANG_POLISH: Result := ID_MENU_POLISH;
    LANG_JAPANESE: Result := ID_MENU_JAPANESE;

  else
    Result := ID_MENU_ENGLISH;
  end;
end;
  {$endif}
  {$ifdef UNIX}
begin
  Result := ID_MENU_ENGLISH;
end;
  {$endif}

{@@
  Returns the Windows Version
}
function TConfigurations.GetOSVersion: TOSVersion;
{$IFDEF Windows}
var
  Versao: TOSVersionInfo;
  WinMajorVersion, WinMinorVersion: Cardinal;
begin
  Result := vwDesconhecida;

  {----------------------------------------------
    Inicializations
   ----------------------------------------------}
  Versao.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if not GetVersionEx(Versao) then Exit;
  WinMajorVersion := Versao.dwMajorVersion;
  WinMinorVersion := Versao.dwMinorVersion;

  {----------------------------------------------
    Identifyes the Operating System
   ----------------------------------------------
    Series 9x
   ----------------------------------------------}
  if Versao.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS then
  begin
    if (WinMajorVersion = 4) and
     (WinMinorVersion = 90) then
     Result := vwWinMe
    else if (WinMajorVersion = 4) and
     (WinMinorVersion = 10) then
     Result := vwWin98
    else Result := vwWin95;
  end
  {----------------------------------------------
    Series NT
   ----------------------------------------------}
  else if Versao.dwPlatformId = VER_PLATFORM_WIN32_NT then
  begin
    if (WinMajorVersion = 3) and
     (WinMinorVersion = 10) then
     Result := vwWinNT351
    else if (WinMajorVersion = 4) then
     Result := vwWinNT
    else if (WinMajorVersion = 5) and (WinMinorVersion = 0) then
     Result := vwWin2000
    else if (WinMajorVersion = 5) and (WinMinorVersion = 1) then
     Result := vwWinXP
    else if (WinMajorVersion = 5) and (WinMinorVersion = 2) then
     Result := vwWin2003
    else if (WinMajorVersion >= 6) then
     Result := vwWinVista;
  end
  {----------------------------------------------
    Windows CE
   ----------------------------------------------}
  else if Versao.dwPlatformId = VER_PLATFORM_WIN32_CE then
  begin
    case WinMajorVersion of
     1: Result := vwWinCE1;
     2: Result := vwWinCE2;
     3: Result := vwWinCE3;
     4: Result := vwWinCE4;
    else
     Result := vwWinCE5;
    end;
  end;
end;
{$ELSE}
begin
  Result := vwDesconhecida;
end;
{$ENDIF}

{*******************************************************************
*  Initialization section
*
*  DESCRIPTION:    Upon startup an instance of the TConfigurations object
*                  is created to make the configuration info available for
*                  TGlass.
*
*******************************************************************}
initialization

  vConfigurations := TConfigurations.Create;

{*******************************************************************
*  Finalization section
*
*  DESCRIPTION:    Free memory allocated on the initialization section
*
*******************************************************************}
finalization

  FreeAndNil(vConfigurations);

end.
