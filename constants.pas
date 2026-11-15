{%encoding utf-8}
{
contants.pas

Stores global constants and type declarations

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
unit constants;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

{$IFDEF Win32}
  {$DEFINE Windows}
{$ENDIF}

interface

uses
{$IFDEF Windows}
  Windows, Messages,
{$ELSE}
  LMessages,
{$ENDIF}
  Classes, SysUtils;

{*******************************************************************
*  Resource file constants
*******************************************************************}
const
  IDI_ICON1         = 101;
  IDI_ICON2         = 115;

  IDB_TOPLEFT       = 201;
  IDB_TOPRIGHT      = 202;
  IDB_BOTTOMLEFT    = 203;
  IDB_BOTTOMRIGHT   = 204;
  IDB_TOP           = 205;
  IDB_LEFT          = 206;
  IDB_BOTTOM        = 207;
  IDB_RIGHT         = 208;

  IDB_CECAE         = 301;
  IDB_FEUSP         = 302;
  IDB_VMG           = 303;
  IDB_LUPA          = 304;
  IDB_USPLEGAL      = 305;

  IDB_ARROW         = 401;
  IDB_INVERTED_ARROW= 402;

{*******************************************************************
*  Indexes of the HotKey options on the dialog
*******************************************************************}
const
  ID_HOTKEY_NO_HOTKEY  = 0;
  ID_HOTKEY_CTRLALTKEY = 1;
  ID_HOTKEY_DISABLE_ASDW = 2;
  ID_DOCKED_HOTKEY_NO_HOTKEY = 0;
  ID_DOCKED_HOTKEY_CTRLALTKEY = 1;

  ID_DEFAULT_HOTKEY    = 'm';
  ID_DEFAULT_DOCKEDHOTKEY  = 'g';
  ID_DEFAULT_DOCKED_RIGHT_HOTKEY = 'h';
  ID_DEFAULT_DOCKED_LEFT_HOTKEY = 'f';
  ID_DEFAULT_DOCKED_UP_HOTKEY = 't';
  ID_DEFAULT_DOCKED_DOWN_HOTKEY = 'v';
  ID_DEFAULT_DOCKED_BOOKMARK_HOTKEY = 'b';

{*******************************************************************
*  Menu Item constants
*******************************************************************}
const
  ID_MENU_ACTIVATE              = 0;
  ID_MENU_DOCKED_GLASS_ACTIVATE = 1;
  ID_MENU_WIDTH                 = 2;
  ID_MENU_HEIGHT                = 3;
  ID_MENU_MAGNIFICATION         = 4;
  ID_MENU_TOOLS                 = 5;
  ID_MENU_GRAPHICAL_BORDER      = 6;
  ID_MENU_INVERT_COLORS         = 7;
  ID_MENU_ANTIALIASING          = 8;
  // Separator
  ID_MENU_CONFIG_DIALOG         = 10;
  ID_MENU_TRANSLATIONS          = 11;
  ID_MENU_SAVE                  = 12;
  ID_MENU_USE_PLUGIN            = 13;
  ID_MENU_CLOSE_PLUGIN          = 14;
  // Separator
  ID_MENU_HOMEPAGE              = 16;
  ID_MENU_ABOUT                 = 17;
  ID_MENU_HELP                  = 18;
  ID_MENU_CANCEL                = 19;
  ID_MENU_TERMINATE             = 20;

  { Separators }
  ID_SEPARATOR_ONE              = 9;
  ID_SEPARATOR_TWO              = 15;

  ID_MENU_WIDTH_64              = 0;
  ID_MENU_WIDTH_96              = 1;
  ID_MENU_WIDTH_128             = 2;
  ID_MENU_WIDTH_192             = 3;
  ID_MENU_WIDTH_256             = 4;
  ID_MENU_WIDTH_320             = 5;
  ID_MENU_WIDTH_416             = 6;
  ID_MENU_WIDTH_512             = 7;
  ID_MENU_WIDTH_640             = 8;
  ID_MENU_WIDTH_768             = 9;
  ID_MENU_WIDTH_1024            = 10;
  ID_MENU_WIDTH_1280            = 11;
  ID_MENU_WIDTH_1600            = 12;

  ID_MENU_HEIGHT_64             = 0;
  ID_MENU_HEIGHT_96             = 1;
  ID_MENU_HEIGHT_128            = 2;
  ID_MENU_HEIGHT_160            = 3;
  ID_MENU_HEIGHT_192            = 4;
  ID_MENU_HEIGHT_256            = 5;
  ID_MENU_HEIGHT_320            = 6;
  ID_MENU_HEIGHT_512            = 7;
  ID_MENU_HEIGHT_768            = 8;
  ID_MENU_HEIGHT_1024           = 9;

  ID_MENU_MAGNIFICATION_1X      = 0;
  ID_MENU_MAGNIFICATION_1_5X    = 1;
  ID_MENU_MAGNIFICATION_2X      = 2;
  ID_MENU_MAGNIFICATION_3X      = 3;
  ID_MENU_MAGNIFICATION_4X      = 4;
  ID_MENU_MAGNIFICATION_8X      = 5;
  ID_MENU_MAGNIFICATION_16X     = 6;

  ID_MENU_ENGLISH               = 0;
  ID_MENU_PORTUGUESE            = 1;
  ID_MENU_SPANISH               = 2;
  ID_MENU_FRENCH                = 3;
  ID_MENU_GERMAN                = 4;
  ID_MENU_ITALIAN               = 5;
  ID_MENU_RUSSIAN               = 6;
  ID_MENU_POLISH                = 7;
  ID_MENU_JAPANESE              = 8;
  ID_MENU_TURKISH               = 9;
  ID_MENU_CHINESE               =10;

{----------------------------------------------
  Versões do Windows
 ----------------------------------------------}
const
  VER_PLATFORM_WIN32_CE = 3;

type
  TOSVersion =
   (
    vwDesconhecida,
    {*******************************************************************}
    { Desktop Windows }
    {*******************************************************************}
    // Informações simplificadas
    Serie9x, // 32s em 3.11, 95, 98 e Me
    SerieNT, // NT 3.51, NT, 2000 e XP
    SerieCE, // Windows CE
    // Informações completas
    vwWin32sEm311,
    vwWinNT351,
    vwWin95,
    vwWinNT,
    vwWin98,
    vwWinMe,
    vwWin2000,
    vwWinXP,
    vwWin2003,
    vwWinVista,  // Ou superior
    vwWinLongHorn,  // Ou superior
    {*******************************************************************}
    { Windows CE }
    {*******************************************************************}
    vwWinCE1,
    vwWinCE2,
    vwWinCE3,
    vwWinCE4,
    vwWinCE5,
    vwWinCE6,
    vwWinCE6_5,
    vwWinCE7// Ou superior
   );

{*******************************************************************
*  Extra Windows API Constants for newer Windows Versions
*******************************************************************}
const
  CAPTUREBLT = $40000000;

const
  SM_XVIRTUALSCREEN = 76;
  SM_YVIRTUALSCREEN = 77;
  SM_CXVIRTUALSCREEN = 78;
  SM_CYVIRTUALSCREEN = 79;

{ Windows Key constants for Delphi }  
{$IFNDEF FPC}

  VK_0 = 48;
  VK_1 = 49;
  VK_2 = 50;
  VK_3 = 51;
  VK_4 = 52;
  VK_5 = 53;
  VK_6 = 54;
  VK_7 = 55;
  VK_8 = 56;
  VK_9 = 57;
  VK_A = $41;
  VK_B = $42;
  VK_D = $44;
  VK_E = $45;
  VK_Q = $51;
  VK_S = $53;
  VK_W = $57;

{$ENDIF}

{*******************************************************************
*  Strings not to be translated
*******************************************************************}
const

  szAppTitle = 'Magnifying Glass';
  szAppTitleLong = 'Virtual Magnifying Glass';
  szAppVersion = '3.10';

  VMG_WEBSITE = 'http://magnifier.sourceforge.net';

  lpSeparator = '-';
  lpSpace = ' ';

{$ifdef fpc}
  lpEspanol   = 'Español';
  lpEnglish   = 'English';
  lpPortugues = 'Português';
  lpFrancais  = 'Français';
  lpGerman    = 'Deutsch';
  lpItaliano  = 'Italiano';
  lpRussian   = 'Русский';
  lpPolish    = 'Polski';
  lpJapanese  = '日本語';
  lpTurkish   = 'Türkçe';
  lpChinese   = '中文';
{$else}
  lpEspanol   = 'Espa�ol';
  lpEnglish   = 'English';
  lpPortugues = 'Portugu�s';
  lpFrancais  = 'Fran�ais';
  lpGerman    = 'Deutsch';
  lpItaliano  = 'Italiano';
  lpRussian   = 'Русский';
  lpPolish    = 'Polski';
  lpJapanese  = 'Japanese';
  lpTurkish   = 'Turkish';
  lpChinese   = 'Chinese';
{$endif}

// Constant which Delphi lacks
{$ifndef fpc}
  LineEnding = #13#10;
{$endif}

  lpContributors =
   'Carlos Eduardo Reinaldo Gimenes - Distribution' + LineEnding +
   'Giovanni Ferreira - Spanish Translation' + LineEnding +
   'jkedarnath - Web Designer' + LineEnding +
   'Rafael Sodre Craice - Images' + LineEnding +
   'William W. Wells - Beta Tester' + LineEnding +
   'Jean-Claude - French Translation' + LineEnding +
   'Michele Catalano - German Translation'  + LineEnding +
   'David Guadagnini - Italian Translation' + LineEnding +
   'Alexey Misharev - Russian Translation' + LineEnding +
   'Katarzyna Plak - Polish Translation' + LineEnding +
   'Gonzalo Ferreira da Silva - Spanish Translation' + LineEnding +
   'Monica - French Translation' + LineEnding +
   'Michał Trzebiatowski - Polish Translation' + LineEnding +
   'Asabukuro - Japanese Translation' + LineEnding +
   'K. Deniz Yilmaz - Turkish Translation'
   ;

  ErrorLoading = ' *Error*';

  lpCannotLoadPlugin = 'An error occured while loading the plugin dll.';
  lpPluginError = 'Plugin error';

{$ifdef GoboLinux}
  DefaultDirectory = '/Programs/Magnifier/' + szAppVersion + '/';
{$else}
  DefaultDirectory = '/usr/share/magnifier/';
{$endif}
  BundleResourcesDirectory = '/Contents/Resources/';

  SectionGeneral = 'General';
  SectionUnix = 'UNIX';
  SectionWindows = 'Windows';
  SectionPlugins = 'Plugins';

  IdentgraphicalBorder = 'graphicalBorder';
  IdentxSquare = 'xSquare';
  IdentySquare = 'Square';
  IdentiMagnification = 'iMagnification';
  IdentTools = 'GraphicsTools';
  IdentAutoRun = 'AutoRun';
  IdentLanguage = 'Language';
  IdentShowWhenExecuted = 'ShowWhenExecuted';
  IdentShowDockedWhenExecuted = 'ShowDockedWhenExecuted';
  IdentShowDockedWhenLensHides = 'ShowDockedWhenLensHides';
  IdentHideDockedWhenLensShows = 'HideDockedWhenLensShows';
  IdentInvertColors = 'InvertColors';
  IdentAntiAliasing = 'AntiAliasing';
  IdentExtraAntiAliasing = 'ExtraAntiAliasing';
  IdentPostProcessing = 'PostProcessing';
  IdentMemMB = 'MemMB';
  IdentReadingSpeed = 'ReadingSpeed';
  IdentFirstRun = 'FirstRun';
  IdentContrast = 'Contrast';
  IdentDockedX = 'DockedX';
  IdentDockedY = 'DockedY';
  IdentDockedFollowMouse = 'DockedFollowMouse';
  IdentDockedBookmarkX = 'DockedBookmarkX';
  IdentDockedBookmarkY = 'DockedBookmarkY';
  IdentDockedWidth = 'DockedWidth';
  IdentDockedHeight = 'DockedHeight';
  IdentDockedCursor = 'DockedCursor';
  IdentDockedBorder = 'DockedBorders';

  IdentMyDirectory = 'MyDirectory';

  IdentHotKeyMode = 'HotKeyMode';
  IdentHotKeyKey = 'HotKeyKey';
  IdentDockedHotKeyMode = 'DockedHotKeyMode';
  IdentDockedHotKeyKey = 'DockedHotKeyKey';
  IdentDockedRightHotKey = 'DockedRightHotKey';
  IdentDockedLeftHotKey = 'DockedLeftHotKey';
  IdentDockedUpHotKey = 'DockedUpHotKey';
  IdentDockedDownHotKey = 'DockedHotDownKey';
  IdentDockedBookmarkHotKey = 'DockedBookmarkHotKey';

  IdentRemapEnabled = 'RemapEnabled';
  IdentRemapWidth = 'RemapWidth';
  IdentRemapHeight = 'RemapHeight';
  IdentRemapRed = 'RemapRed';
  IdentRemapGreen = 'RemapGreen';
  IdentRemapBlue = 'RemapBlue';

  IdentUsePlugins = 'UsePlugins';
  IdentPluginName = 'PluginName';
  IdentPluginData = 'PluginData';

{*******************************************************************
*  Custom Signals
*******************************************************************}
const
  MYWM_NOTIFYICON = WM_USER + 77;
  MYWM_SHOWGLASS = WM_USER + 78;
  MYWM_SHOWDOCKEDGLASS = WM_USER + 79;
{$IFDEF Unix}
  FILE_WATCH_SHORTCUT = '/tmp/magnifier_shortcut';
{$ENDIF}

implementation

end.

