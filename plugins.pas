{
plugins.pas

Controls the plugins

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
unit plugins;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

{$IFDEF Win32}
  {$DEFINE Windows}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  dynlibs, lcltype,
{$ELSE}
  Windows,
{$ENDIF}
  Classes, SysUtils, Forms, Dialogs, constants, plugininfo;

type
  TFunc_Initialize = function (vPluginData: TPluginData): Cardinal; cdecl;
  TFunc_Finalize = procedure; cdecl;
  TFunc_HandlePluginMessage = procedure(AMessage: Cardinal); cdecl;
  
  { TPlugins }

  TPlugins = class(TObject)
  private
    Handle: THandle;
    vInitialize: TFunc_Initialize;
    vFinalize: TFunc_Finalize;
    vHandlePluginMessage: TFunc_HandlePluginMessage;
  public
    Loaded: Boolean;
    Initialized: Boolean;
    { Methods }
    procedure LoadPlugin;
    procedure UnloadPlugin;
    function  Initialize: Cardinal;
    procedure Finalize;
    procedure HandlePluginMessage(AMessage: Cardinal);
  end;

var
  vPlugins: TPlugins;
  
implementation

uses glass, appsettings;

{ TPlugins }

{*******************************************************************
*  TPlugins.LoadPlugin ()
*
*  DESCRIPTION:    Loads a plugin.
*
*  PARAMETERS:     AName   - The name of the library of the plugin to be loaded
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TPlugins.LoadPlugin;
begin
{$IFDEF FPC}
  Handle := LoadLibrary(vConfigurations.PluginName);
{$ELSE}
  Handle := LoadLibrary(PChar(vConfigurations.PluginName));
{$ENDIF}

  if Handle = 0 then
  begin
    Application.MessageBox(lpCannotLoadPlugin, lpPluginError, MB_OK);
    Exit;
  end;

{$IFDEF FPC}
  vInitialize := GetProcedureAddress(Handle, 'Initialize');
  vFinalize := GetProcedureAddress(Handle, 'Finalize');
  vHandlePluginMessage := GetProcedureAddress(Handle, 'HandlePluginMessage');
{$ELSE}
  vInitialize := GetProcAddress(Handle, 'Initialize');
  vFinalize := GetProcAddress(Handle, 'Finalize');
  vHandlePluginMessage := GetProcAddress(Handle, 'HandlePluginMessage');
{$ENDIF}

  Loaded := True;
end;

{*******************************************************************
*  TPlugins.UnloadPlugin ()
*
*  DESCRIPTION:    Unloads the currently loaded plugin.
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TPlugins.UnloadPlugin;
begin
{$IFDEF FPC}
  UnloadLibrary(Handle);
{$ELSE}
  FreeLibrary(Handle);
{$ENDIF}

  Handle := 0;

  Loaded := False;
end;

{*******************************************************************
*  TPlugins.Initialize ()
*
*  DESCRIPTION:    Initializes the plugin.
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
function TPlugins.Initialize: Cardinal;
var
  vPluginData: TPluginData;
begin
  Initialized := False;

  Result := VMG_ERROR;

  if (Handle = 0) then Exit;

  { System Information }
  vPluginData.DesktopPos.Left := vGlass.XScreen;
  vPluginData.DesktopPos.Top := vGlass.YScreen;
  vPluginData.DesktopPos.Right := vGlass.XScreen + vGlass.CXScreen;
  vPluginData.DesktopPos.Bottom := vGlass.YScreen + vGlass.CYScreen;
  vPluginData.Application := @Application;
  { Glass information }
  vPluginData.Magnification := @vConfigurations.iMagnification;
  vPluginData.GlassTop := @vGlass.GlassTop;
  vPluginData.GlassLeft := @vGlass.GlassLeft;
  vPluginData.GlassWidth := @vGlass.GlassWidth;
  vPluginData.GlassHeight := @vGlass.GlassHeight;
  vPluginData.PluginData := vConfigurations.PluginData;
  { Callbacks for utility function in the main application }
  vPluginData.CalculateViewRectFunc := vGlass.CalculateViewRect;

  Result := vInitialize(vPluginData);

  Initialized := True;
end;

{*******************************************************************
*  TPlugins.Finalize ()
*
*  DESCRIPTION:    Finalizes the plugin.
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TPlugins.Finalize;
begin
  if Handle <> 0 then vFinalize();

  Initialized := False;
end;

procedure TPlugins.HandlePluginMessage(AMessage: Cardinal);
begin
  if not Initialized then Exit;

  vHandlePluginMessage(AMessage);
end;

initialization

  vPlugins := TPlugins.Create;

finalization

  if vPlugins.Initialized then vPlugins.Finalize;

  if vPlugins.Loaded then vPlugins.UnloadPlugin;

  FreeAndNil(vPlugins);

end.

