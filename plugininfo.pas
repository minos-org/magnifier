unit plugininfo;

{$ifdef fpc}
  {$mode objfpc}{$H+}
{$endif}

{$IFDEF Win32}
  {$DEFINE Windows}
{$ENDIF}

interface

uses
  {$ifndef fpc} Windows, {$endif}
  Classes, SysUtils, Forms;
 
{*******************************************************************
*  Plugin library extension
*******************************************************************}
const
{$IFDEF Windows}
  ID_PLUGIN_EXTENSION = 'dll';
{$ENDIF}
{$IFDEF UNIX}
{$IFDEF DARWIN}
  ID_PLUGIN_EXTENSION = 'dylib';
{$ELSE}
  ID_PLUGIN_EXTENSION = 'so';
{$ENDIF}
{$ENDIF}

  ID_PLUGIN_WILDCARD  = '*.' + ID_PLUGIN_EXTENSION;
   
{*******************************************************************
*  Plugin error codes
*******************************************************************}
const
  VMG_NOERROR = 0;
  VMG_ERROR   = 1;

{*******************************************************************
*  Plugin data structure
*******************************************************************}
type

  TCalculateViewRectFunc = procedure (var viewRect, drawGlassRect: TRect;
    const screenRect: TRect; AMagnification: double) of object; cdecl;

  PApplication = ^TApplication;

  TPluginData = record
    { System Information }

    DesktopPos: TRect;
    Application: PApplication;

    { Glass information }

    Magnification: PDouble;
    GlassLeft, GlassTop: PInteger;
    GlassWidth, GlassHeight: PInteger;

    { Custom information from the configuration file }
    PluginData: Integer;

    { Callbacks for utility function in the main application }
    CalculateViewRectFunc: TCalculateViewRectFunc;
  end;

implementation

end.
