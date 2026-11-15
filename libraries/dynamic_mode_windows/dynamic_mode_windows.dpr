{
dynamic_mode_windows.dpr

The Pascal implementation of the dynamic mode plugin
with Windows API for the magnifier

Copyright (C) 1998 - 2009 Harri Pyy, Chris O'Donnell, Felipe Monteiro de Carvalho

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
library dynamic_mode_windows;

{$ifdef fpc}
{$mode objfpc}{$H+}
{$endif}

uses
  // RTL
  Classes, SysUtils, Math, Windows,
  // Magnifier
  plugininfo,
  // LCL
  Interfaces, Forms, LResources, Controls;

{* Global variables *}
var
  gForm: TForm;

{* Prototypes *}
procedure CreateWindow(vPluginData: TPluginData); forward;
function  Initialize(vPluginData: TPluginData): Cardinal; cdecl; forward;
procedure Finalize; cdecl; forward;
procedure HandlePluginMessage(AMessage: Cardinal); cdecl; forward;

procedure CreateWindow(vPluginData: TPluginData);
begin
  gForm := TForm.Create(vPluginData.Application^);
  gForm.BorderIcons := [];
  gForm.BorderStyle := bsNone;
  gForm.Top := 100;
  gForm.Left := 100;
  gForm.Height := 200;
  gForm.Width := 300;
end;

function Initialize(vPluginData: TPluginData): Cardinal; cdecl;
begin
  CreateWindow(vPluginData);
  gForm.Show;
end;

{*
 Finalize ()
*}
procedure Finalize; cdecl;
begin
  gForm.Free;
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
  {$I dynamic_mode_windows.lrs}
end.


