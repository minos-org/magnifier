{
magnifier.dpr

Project file and main source file

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
program lente;

{*******************************************************************
*  Compatibility preprocessor code to allow the project to be compiled
* both on the Free Pascal Compiler and on Borland Delphi
*******************************************************************}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

{$IFDEF Win32}
  {$DEFINE Windows}
{$ENDIF}

{*******************************************************************
*  RC and RES Resource files are Windows only
*  Separate files for Delphi and FPC avoids the need to rebuild it
*******************************************************************}
{$IFDEF Windows}
  {$IFDEF FPC}
    {$R fpcmagnifier.rc}
  {$ELSE}
    {$R magnifier.res}
  {$ENDIF}
{$ENDIF}

uses

{$IFDEF Unix}
cmem, cthreads, UniqueInstanceRaw,
{$ENDIF}
{$IFDEF FPC}
  Interfaces,
{$ENDIF}
{$IFDEF Windows}
  Windows,
{$ENDIF}
  Forms,
  glass in 'glass.pas',
  constants in 'constants.pas',
  appsettings in 'appsettings.pas',
  app in 'app.pas',
  about in 'about.pas',
  plugins in 'plugins.pas',
  translationsvmg in 'translationsvmg.pas',
  configdlg in 'configdlg.pas',
//  lazfmlviewer in 'lazfmlviewer.pas',
//  fmlscan in 'fmldriver.pas',
  plugininfo, startform;

{$IFDEF Windows}
const
  DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = Pointer(-4);  // Win10+ per-monitor V2

  procedure ForceDpiAwareness;
var
  hUser32: HMODULE;
  SetProcessDpiAwarenessContext: function(AwarenessContext: Pointer): BOOL; stdcall;
  SetProcessDPIAware: function: BOOL; stdcall;
begin
  hUser32 := GetModuleHandle('user32.dll');
  if hUser32 = 0 then Exit;

  // Try modern API first (Win10 1607+ / Win11)
  @SetProcessDpiAwarenessContext := GetProcAddress(hUser32, 'SetProcessDpiAwarenessContext');
  if Assigned(SetProcessDpiAwarenessContext) then
  begin
    if SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2) then
      Exit;  // Success: Per-monitor V2 enabled
  end;

  // Fallback for older Win10 / Win8.1
  @SetProcessDPIAware := GetProcAddress(hUser32, 'SetProcessDPIAware');
  if Assigned(SetProcessDPIAware) then
    SetProcessDPIAware();  // System-wide aware
end;

procedure RtlGetNtVersionNumbers(out MajorVersion: DWORD; out MinorVersion: DWORD; out BuildNumber: DWORD); cdecl; external 'ntdll.dll' name 'RtlGetNtVersionNumbers';

function IsWindows10OrGreater: Boolean;
var
  Major, Minor, Build: DWORD;
begin
  RtlGetNtVersionNumbers(Major, Minor, Build);
  Build := Build and $FFFF;  // Extract low word (build number)
  Result := (Major = 10) and (Build >= 10240);
end;

{$ENDIF}

{$IFDEF Unix}
function CheckRunningInstance(Parameter: String) : Boolean;
var
   tFile: TextFile;
begin
   if InstanceRunning() then
   begin
       AssignFile(tFile, FILE_WATCH_SHORTCUT);
       rewrite(tFile);
       if (Parameter = 'mouse') then
          writeln(tFile, 'Mouse')
       else if (Parameter = '-docked') then
       	  writeln(tFile, 'Docked')
       else if (Parameter = '-bookmark') then
       	  writeln(tFile, 'Bookmark')
       else
          writeln(tFile, 'Show');
       CloseFile(tFile);
       Result := True;
   end
   else
       Result := False;
end;
{$ENDIF}


{@@
  Application Main Procedure

  This procedure is executed as soon as the program is executed
}
var
  AHandle, Semaphore: Cardinal;
  lResult, lStartForm: Boolean;
begin

{$IFDEF Windows}
  if IsWindows10OrGreater then ForceDpiAwareness;
{$ENDIF}

  lStartForm := False;

  {*******************************************************************
  *  Verifies if another instance is already running by using semaphores
  *******************************************************************}
  {$IFDEF Windows}
    Semaphore := OpenSemaphore(EVENT_ALL_ACCESS, False, szAppTitle);

    // No one is holding the semaphore, so let's create one
    if Semaphore = 0 then
     Semaphore := CreateSemaphore(nil, 3, 3, szAppTitle)
    else
    begin
      AHandle := FindWindow(nil, szAppTitle);
      if (ParamStr(1) = '-docked') then
        SendMessage(AHandle, MYWM_SHOWDOCKEDGLASS, 0, 0)
      else
        SendMessage(AHandle, MYWM_SHOWGLASS, 0, 0);
      Exit;
    end;
  {$ENDIF}

  {*******************************************************************
  *  Program initialization
  *
  *  The order in which these methods are called is very important
  *******************************************************************}
  {$IFDEF Unix}
  if CheckRunningInstance(ParamStr(1)) then Exit;
  {$ENDIF}

  Application.Initialize;
  Application.CreateForm(TMainWindow, vMainWindow);
  Application.CreateForm(TAboutWindow, vAboutWindow);
  Application.CreateForm(TConfigDialog, vConfigDialog);
//  Application.CreateForm(TFMLViewerDialog, vFMLViewerDialog);
  {$IFDEF Windows} // Start up screen on the first run in Windows
  lStartForm := vConfigurations.firstRun;
  if lStartForm then
  begin
    Application.CreateForm(TvStartWindow, vStartWindow);
    vStartWindow.Show();
  end;
  {$ENDIF}

  {*******************************************************************
  *  Features that need to be initialized at software startup are
  * processed here
  *******************************************************************}

  // The Dynamic mode only works on Windows, so force that here
  {$IFNDEF Win32}
  vConfigurations.UsePlugins := False;
  {$ENDIF}

  Application.ShowMainForm := False;

  // Initializes HotKeys
  vMainWindow.UpdateHotKey(nil);

  if ParamStr(1) = '-docked' then
  begin
    vMainWindow.ShowDockedGlass(nil);
  end
  else begin
    if vConfigurations.showDockedWhenExecuted then
      vMainWindow.CreateDockedGlass;

    // If the user selected to auto-start, handle this case here
    if vConfigurations.showWhenExecuted and (not lStartForm) then
      vMainWindow.ExecuteLens(nil);

    if vConfigurations.showDockedWhenExecuted and (not lStartForm) then
      vMainWindow.ShowDockedGlass(nil);

  end;

  { Enters the Message Loop }
  Application.Run;

  { Finalization - Release the semaphore for future instances }
  {$IFDEF Windows}
    if Semaphore <> 0 then CloseHandle(Semaphore);
  {$ENDIF}
end.

