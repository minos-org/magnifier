{
startform.pas

Start Screen

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
unit startform;

{$mode delphi}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons,
  appsettings, app, translationsvmg;

type

  { TvStartWindow }

  TvStartWindow = class(TForm)
    buttonClassic: TBitBtn;
    buttonDynamic: TBitBtn;
    Label1: TLabel;
    labelStartWindow: TLabel;
    procedure buttonClassicClick(Sender: TObject);
    procedure buttonDynamicClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    procedure UpdateInterface();
  public
    { public declarations }
  end; 

var
  vStartWindow: TvStartWindow;

implementation

{ TvStartWindow }

procedure TvStartWindow.buttonClassicClick(Sender: TObject);
begin
  vConfigurations.firstRun := False;
  vConfigurations.UsePlugins := False;
  Hide;
  vMainWindow.ExecuteLens(nil);
end;

procedure TvStartWindow.buttonDynamicClick(Sender: TObject);
begin
  vConfigurations.firstRun := False;
  vConfigurations.UsePlugins := True;
  Hide;
  vMainWindow.ExecuteLens(nil);
end;

procedure TvStartWindow.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  vConfigurations.firstRun := False;
  CloseAction := caHide;
end;

procedure TvStartWindow.FormShow(Sender: TObject);
begin
  UpdateInterface();
end;

procedure TvStartWindow.UpdateInterface();
begin
  labelStartWindow.Caption := vTranslations.lpStartWindowText;
  buttonClassic.Caption := vTranslations.lpClassicModeBtn;
  buttonDynamic.Caption := vTranslations.lpDynamicModeBtn;
end;

initialization
  {$I startform.lrs}

end.

