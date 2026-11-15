{
configdlg.pas

Configurations Dialog

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
unit configdlg;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
 ComCtrls, ExtCtrls, StdCtrls, Buttons, appsettings, constants,
 plugininfo, fileUtil, Spin;

type

  { TConfigDialog }

  TConfigDialog = class(TForm)
  private
    { Private declarations }
    pgsCategories: TPageControl;
    lblDisabledHint: TLabel;
    { General tab }
    tabGeneral: TTabSheet;
    chkAutoRun: TCheckBox;
    chkShowWhenExecuted: TCheckBox;
    { Plugins tab }
    tabPlugins: TTabSheet;
    stPluginsList: TStaticText;
    lstPluginsList: TListBox;
    { HotKey tab }
    tabHotKey: TTabSheet;
    rgrpHotKeyInvoke: TRadioGroup;
    lblHotKeyKey: TLabel;
    txtHotKeyKey: TEdit;
    { Image tab }
    tabImage: TTabSheet;
    lblContrast: TLabel;
    lblContrastInfo: TLabel;
    sliderContrast: TTrackBar;
    rgrpAntialiasing: TRadioGroup;
    chkPostProcess: TCheckBox;
    spMemMb: TSpinEdit;
    lblMemMb: TLabel;
    { Docked glass tab}
    tabDockedGlass: TTabSheet;
    lblDockedGlassInfo: TLabel;
    chkShowDockedWhenExecuted: TCheckBox;
    chkShowDockedWhenLensHides: TCheckBox;
    chkHideDockedWhenLensShows: TCheckBox;
    lblComboMouse, lblComboFollow: TLabel;
    comboMouse, comboFollow: TComboBox;
    rgrpDockedHotKeyInvoke: TRadioGroup;
    lblDockedHotKeyKey: TLabel;
    txtDockedHotKeyKey: TEdit;
    lblRightHotKeyKey: TLabel;
    txtRightHotKeyKey: TEdit;
    lblLeftHotKeyKey: TLabel;
    txtLeftHotKeyKey: TEdit;
    lblTopHotKeyKey: TLabel;
    txtTopHotKeyKey: TEdit;
    lblBottomHotKeyKey: TLabel;
    txtBottomHotKeyKey: TEdit;
    lblbookmarkHotKeyKey: TLabel;
    txtBookmarkHotKeyKey: TEdit;
    { Remap tab }
    tabRemap: TTabSheet;
    chkRemap: TCheckBox;
    lblRemapWidth: TLabel;
    spBoxRemapWidth: TSpinEdit;
    lblRemapHeight: TLabel;
    spBoxRemapHeight: TSpinEdit;
    RemapColor: TColor;
    RemapColorChooseButton: TButton;
    RemapColorDisplay: TPanel;
    RemapColorDialog: TColorDialog;
    { Others }
    btnClose: TButton;
    procedure chkAutoRunClicked(Sender: TObject);
    procedure UpdateRemap(Sender: TObject);
    procedure ChooseRemapColor(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  public
    { Public declarations }
    procedure UpdateInterface;
    procedure SaveConfigurations;
    constructor Create(AOwner: TComponent); override;
  end;

var
  vConfigDialog: TConfigDialog;

implementation

uses
  glass, translationsvmg, app
{$ifdef fpc}
  , LResources
{$endif}
 ;

{$ifndef fpc}
  {$R *.DFM}
{$endif}

{ TConfigDialog }

{*******************************************************************}
{@@
  Allocates and initializes the configurations dialog.

  Obs: The captions are set here too because of a
  possible Lazarus bug:

  The labels of the PageControl don't show on the first
  time the form is shown if set only on OnShow, using
  Lazarus on win32.
}
{*******************************************************************}
constructor TConfigDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Position := poScreenCenter;
  Height := 670;
  Width := 745;

  OnShow := FormShow;
  OnClose := FormClose;

  Self.VertScrollBar.Visible := False;
  Self.HorzScrollBar.Visible := False;

  pgsCategories := TPageControl.Create(Self);
  with pgsCategories do
  begin
    Parent := Self;
    Height := 525;
    Left := 25;
    Top := 25;
    Width := 700;
    TabOrder := 0;
    Anchors := [akLeft, akRight, akTop];
    Font.Size := 12;
    {$IFDEF Unix}
    Font.Size := 18;
    {$ENDIF}
  end;

  { General tab }

  tabGeneral := TTabSheet.Create(Self);
  tabGeneral.PageControl := pgsCategories;
  tabGeneral.Caption := vTranslations.lpTabGeneral;

  chkAutoRun := TCheckBox.Create(Self);
  with chkAutoRun do
  begin
    Parent := tabGeneral;
    Top := 10;
    Left := 10;
    Width := 400;
    {$IFDEF Unix}
    OnClick := chkAutoRunClicked;
    {$ENDIF}
  end;

  chkShowWhenExecuted := TCheckBox.Create(Self);
  with chkShowWhenExecuted do
  begin
    Parent := tabGeneral;
    Top := 45;
    Left := 10;
    Width := 400;
  end;

  { Plugins tab }

  tabPlugins := TTabSheet.Create(Self);
  {$ifdef USE_PLUGINS}
  tabPlugins.PageControl := pgsCategories;
  {$endif}
  tabPlugins.Caption := vTranslations.lpTabPlugins;

  stPluginsList := TStaticText.Create(Self);
  with stPluginsList do
  begin
    Parent := tabPlugins;
    Top := 10;
    Left := 10;
    Width := 400;
  end;

  lstPluginsList := TListBox.Create(Self);
  with lstPluginsList do
  begin
    Parent := tabPlugins;
    Top := 35;
    Left := 10;
    Height := 200;
    Width := 400;
    MultiSelect := False;
  end;

  { HotKey tab }

  tabHotKey := TTabSheet.Create(Self);
  tabHotKey.PageControl := pgsCategories;
  tabHotKey.Caption := vTranslations.lpTabHotKey;

  lblHotKeyKey := TLabel.Create(Self);
  with lblHotKeyKey do
  begin
    Parent := tabHotKey;
    Top := 10;
    Left := 10;
    AutoSize := True;
    Caption := vTranslations.lpHotKeyKey;
  end;

  txtHotKeyKey := TEdit.Create(Self);
  with txtHotKeyKey do
  begin
    Parent := tabHotKey;
    Top := 45;
    Left := 10;
    Width := 50;
    MaxLength := 1;
  end;

  rgrpHotKeyInvoke := TRadioGroup.Create(Self);
  with rgrpHotKeyInvoke do
  begin
    Parent := tabHotKey;
    Top := 100;
    Left := 10;
    Height := 100;
    Width := 400;
    Caption := vTranslations.lpHotKeyInvoke;
    Items.Add(vTranslations.lpHotKeyDisableInvoke);
    Items.Add(vTranslations.lpHotKeyCtrlAltKey);
    Items.Add(vTranslations.lpHotKeyDisableAll);
    ItemIndex := 0;
  end;

  { Image tab }

  tabImage := TTabSheet.Create(Self);
  tabImage.PageControl := pgsCategories;
  tabImage.Caption := 'Image';

  lblContrast := TLabel.Create(Self);
  with lblContrast do
  begin
    Parent := tabImage;
    Top := 10;
    Left := 10;
    AutoSize := True;
    Caption := 'Contrast';
  end;

  sliderContrast := TTrackBar.Create(Self);
  with sliderContrast do
  begin
    Parent := tabImage;
    Top := 55;
    Left := 10;
    Width := 250;
    Height := 50;
    Frequency := 1;
    Min := 0;
    Max := 127;
  end;

  lblContrastInfo := TLabel.Create(Self);
  with lblContrastInfo do
  begin
    Parent := tabImage;
    Top := 110;
    Left := 10;
    Height := 100;
    Width := 400;
    Caption := 'Hint - You can use these keys while moving the glass' + sLineBreak
    + 'to adjust contrast: X to increase, Z to decrease, C to reset';
  end;

  rgrpAntialiasing := TRadioGroup.Create(Self);
  with rgrpAntialiasing do
  begin
    Parent := tabImage;
    Top := 175;
    Left := 10;
    Height := 100;
    Width := 400;
    Caption := 'Anti-aliasing';
    Items.Add('Simple');
    Items.Add('Extra - Higher CPU usage');
    ItemIndex := 0;
  end;

  chkPostProcess := TCheckBox.Create(Self);
  with chkPostProcess do
  begin
    Parent := tabImage;
    Top := 300;
    Left := 10;
    Height := 100;
    Width := 100;
    Caption := 'Allow post processing';
  end;

  lblMemMb := TLabel.Create(Self);
  with lblMemMb do
  begin
    Parent := tabImage;
    Top := 350;
    Left := 10;
    Height := 100;
    Width := 100;
    Caption := 'Max memory to use (MB):';
  end;

  spMemMb := TSpinEdit.Create(Self);
  with spMemMb do
  begin
    Parent := tabImage;
    Top := 345;
    Left := 300;
    Height := 100;
    Width := 100;
    MaxValue := 500;
  end;

  { Docked glass }

  tabDockedGlass := TTabSheet.Create(Self);
  tabDockedGlass.PageControl := pgsCategories;
  tabDockedGlass.Caption := 'Docked Glass';

  chkShowDockedWhenExecuted := TCheckBox.Create(Self);
  with chkShowDockedWhenExecuted do
  begin
    Parent := tabDockedGlass;
    Top := 10;
    Left := 10;
    Width := 400;
  end;

  chkShowDockedWhenLensHides := TCheckBox.Create(Self);
  with chkShowDockedWhenLensHides do
  begin
    Parent := tabDockedGlass;
    Top := 42;
    Left := 10;
    Width := 400;
  end;

  chkHideDockedWhenLensShows := TCheckBox.Create(Self);
  with chkHideDockedWhenLensShows do
  begin
    Parent := tabDockedGlass;
    Top := 74;
    Left := 10;
    Width := 400;
  end;

  lblComboMouse := TLabel.Create(Self);
  with lblComboMouse do
  begin
    Parent := tabDockedGlass;
    Top := 115;
    Left := 10;
    AutoSize := True;
    Caption := 'Select cursor:';
  end;

  lblComboFollow := TLabel.Create(Self);
  with lblComboFollow do
  begin
    Parent := tabDockedGlass;
    Top := 115;
    Left := 250;
    AutoSize := True;
    Caption := 'Select mode:';
  end;

  lblDockedGlassInfo := TLabel.Create(Self);
  with lblDockedGlassInfo do
  begin
    Parent := tabDockedGlass;
    Top := 215;
    Left := 10;
    AutoSize := True;
    Caption := 'Linux users:' +
    LineEnding + 'Please refer to the documentation for instructions' +
    LineEnding + 'on how to add shortcut for the docked glass.' +
    LineEnding + 'You can also configure keyboard shortcuts to move the mouse.';
    {$IFNDEF Unix}
    Visible := False;
    {$ENDIF}
  end;

  comboMouse := TComboBox.Create(Self);
  with comboMouse do
  begin
    Parent := tabDockedGlass;
    Top := 142;
    Left := 10;
    Width := 200;
    Items.Add('None');
    Items.Add('Light cursor');
    Items.Add('Dark cursor');
    Items.Add('Cross');
    ItemIndex := vConfigurations.DockedCursor;
  end;

  comboFollow := TComboBox.Create(Self);
  with comboFollow do
  begin
    Parent := tabDockedGlass;
    Top := 142;
    Left := 250;
    Width := 200;
    Items.Add('Follow mouse');
    Items.Add('Bookmark');
    if (vConfigurations.DockedFollowMouse) then ItemIndex := 0 else ItemIndex := 1;
  end;

  lblDockedHotKeyKey := TLabel.Create(Self);
  with lblDockedHotKeyKey do
  begin
    Parent := tabDockedGlass;
    Top := 190;
    Left := 10;
    AutoSize := True;
    Caption := vTranslations.lpHotKeyKey;
  end;

  txtDockedHotKeyKey := TEdit.Create(Self);
  with txtDockedHotKeyKey do
  begin
    Parent := tabDockedGlass;
    Top := 218;
    Left := 10;
    Width := 50;
    MaxLength := 1;
  end;

  lblRightHotKeyKey := TLabel.Create(Self);
  with lblRightHotKeyKey do
  begin
    Parent := tabDockedGlass;
    Top := 262;
    Left := 10;
    AutoSize := True;
    Caption := 'Right:';
  end;

  txtRightHotKeyKey := TEdit.Create(Self);
  with txtRightHotKeyKey do
  begin
    Parent := tabDockedGlass;
    Top := 258;
    Left := 70;
    Width := 40;
    MaxLength := 1;
  end;

  lblLeftHotKeyKey := TLabel.Create(Self);
  with lblLeftHotKeyKey do
  begin
    Parent := tabDockedGlass;
    Top := 262;
    Left := 130;
    AutoSize := True;
    Caption := 'Left:';
  end;

  txtLeftHotKeyKey := TEdit.Create(Self);
  with txtLeftHotKeyKey do
  begin
    Parent := tabDockedGlass;
    Top := 258;
    Left := 182;
    Width := 40;
    MaxLength := 1;
  end;

  lblTopHotKeyKey := TLabel.Create(Self);
  with lblTopHotKeyKey do
  begin
    Parent := tabDockedGlass;
    Top := 262;
    Left := 240;
    AutoSize := True;
    Caption := 'Up:';
  end;

  txtTopHotKeyKey := TEdit.Create(Self);
  with txtTopHotKeyKey do
  begin
    Parent := tabDockedGlass;
    Top := 258;
    Left := 280;
    Width := 40;
    MaxLength := 1;
  end;

  lblBottomHotKeyKey := TLabel.Create(Self);
  with lblBottomHotKeyKey do
  begin
    Parent := tabDockedGlass;
    Top := 262;
    Left := 335;
    AutoSize := True;
    Caption := 'Down:';
  end;

  txtBottomHotKeyKey := TEdit.Create(Self);
  with txtbottomHotKeyKey do
  begin
    Parent := tabDockedGlass;
    Top := 258;
    Left := 395;
    Width := 40;
    MaxLength := 1;
  end;


  lblBookmarkHotKeyKey := TLabel.Create(Self);
  with lblBookmarkHotKeyKey do
  begin
    Parent := tabDockedGlass;
    Top := 262;
    Left := 450;
    AutoSize := True;
    Caption := 'Bookmark:';
  end;

  txtBookmarkHotKeyKey := TEdit.Create(Self);
  with txtBookmarkHotKeyKey do
  begin
    Parent := tabDockedGlass;
    Top := 258;
    Left := 560;
    Width := 40;
    MaxLength := 1;
  end;

  rgrpDockedHotKeyInvoke := TRadioGroup.Create(Self);
  with rgrpDockedHotKeyInvoke do
  begin
    Parent := tabDockedGlass;
    Top := 320;
    Left := 10;
    Height := 100;
    Width := 400;
    Caption := vTranslations.lpHotKeyInvoke;
    Items.Add(vTranslations.lpHotKeyDisableInvoke);
    Items.Add(vTranslations.lpHotKeyCtrlAltKey);
    ItemIndex := 0;
  end;

  { Remap }
  tabRemap := TTabSheet.Create(Self);
  tabRemap.PageControl := pgsCategories;
  tabRemap.Caption := 'Blind Spot Shape';

  chkRemap := TCheckBox.Create(Self);
  with chkRemap do
  begin
    Parent := tabRemap;
    Top := 45;
    Left := 10;
    Width := 400;
    OnClick := UpdateRemap;
  end;

  lblRemapWidth := TLabel.Create(Self);
  with lblRemapWidth do
  begin
    Parent := tabRemap;
    Top := 90;
    Left := 10;
    AutoSize := True;
    Caption := 'Width:';
  end;

  spBoxRemapWidth := TSpinEdit.Create(Self);
  with spBoxRemapWidth do
  begin
    Parent := tabRemap;
    Top := 90;
    Left := 100;
    Height := 100;
    Width := 100;
    MaxValue := 500;
    MinValue := 50;
  end;

  lblRemapHeight := TLabel.Create(Self);
  with lblRemapHeight do
  begin
    Parent := tabRemap;
    Top := 150;
    Left := 10;
    AutoSize := True;
    Caption := 'Height:';
  end;

  spBoxRemapHeight := TSpinEdit.Create(Self);
  with spBoxRemapHeight do
  begin
    Parent := tabRemap;
    Top := 150;
    Left := 100;
    Height := 100;
    Width := 100;
    MaxValue := 500;
    MinValue := 50;
  end;

  RemapColorChooseButton := TButton.Create(Self);
  with RemapColorChooseButton do
  begin
    Parent := tabRemap;
    Top := 215;
    Left := 10;
    AutoSize := True;
    Caption := 'Choose color...';
    OnClick := ChooseRemapColor;
  end;

  RemapColorDisplay := TPanel.Create(Self);
  with RemapColorDisplay do
  begin
    Parent := tabRemap;
    Top := 215;
    Left := 190;
    Height := 38;
    Width := 100;
  end;

  RemapColorDialog := TColorDialog.Create(Self);

  { Others }

  lblDisabledHint := TLabel.Create(Self);
  with lblDisabledHint do
  begin
    Parent := Self;
    Left := 25;
    Top := 405;
    AutoSize := True;
    Caption := vTranslations.lpDisabledHint;
    {$IFDEF Unix}
    Visible := False;
    {$ENDIF}
  end;

  btnClose := TButton.Create(Self);
  with btnClose do
  begin
    Parent := Self;
    Height := 33;
    Left := 250;
    Top := 583;
    Width := 200;
    ModalResult := mrOK;
    TabOrder := 0;
    Anchors := [akLeft, akRight, akTop];
    Font.Size := 12;
  end;

  ActiveControl := btnClose;
end;

procedure TConfigDialog.chkAutoRunClicked(Sender: TObject);
var
  SourceFile, DestFile: string;
begin
  DestFile := GetEnvironmentVariable('HOME') + '/.config/autostart/vmg.desktop';
  SourceFile := '/usr/share/applications/vmg.desktop';

  if chkAutoRun.Checked then
    CopyFile(SourceFile, DestFile)
  else
    DeleteFile(DestFile);
end;

procedure TConfigDialog.UpdateRemap(Sender: TObject);
begin
  spBoxRemapWidth.Enabled := chkRemap.Checked;
  spBoxRemapHeight.Enabled := chkRemap.Checked;
  RemapColorChooseButton.Enabled := chkRemap.Checked;
end;

procedure TConfigDialog.ChooseRemapColor(Sender: TObject);
begin
  if RemapColorDialog.Execute then
  begin
    RemapColor := RemapColorDialog.Color;
    RemapColorDisplay.Color := RemapColor;
  end;
end;

{*******************************************************************}
{@@
  Updates the dialog every time it is shown
}
{*******************************************************************}
procedure TConfigDialog.FormShow(Sender: TObject);
begin
  UpdateInterface;
end;

{*******************************************************************}
{@@
  Updates the configurations every time the dialog closes
}
{*******************************************************************}
procedure TConfigDialog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveConfigurations;
end;

{*******************************************************************}
{@@
  Call this method to update the interface according
  to the current vConfigurations state and the
  current translation
}
{*******************************************************************}
procedure TConfigDialog.UpdateInterface;
var
  SR: TSearchRec;
  i: Integer;
begin
  {*******************************************************************
  *  Updates the translations
  *******************************************************************}

  Caption := vTranslations.lpConfigDialogTitle;

  { General tab }

  tabGeneral.Caption := vTranslations.lpTabGeneral;
  chkAutoRun.Caption := vTranslations.lpAutoRun;
  chkShowWhenExecuted.Caption := vTranslations.lpShowWhenExecuted;

  { Plugins tab }

  tabPlugins.Caption := vTranslations.lpTabPlugins;
  stPluginsList.Caption := vTranslations.lpChoosePlugin;

  { HotKey tab }

  tabHotKey.Caption := vTranslations.lpTabHotKey;
  lblHotKeyKey.Caption := vTranslations.lpHotKeyKey;

  rgrpHotKeyInvoke.Caption := vTranslations.lpHotKeyInvoke;
  rgrpHotKeyInvoke.Items.Clear;
  rgrpHotKeyInvoke.Items.Add(vTranslations.lpHotKeyDisableInvoke);
  rgrpHotKeyInvoke.Items.Add(vTranslations.lpHotKeyCtrlAltKey);
  rgrpHotKeyInvoke.Items.Add(vTranslations.lpHotKeyDisableAll);

  { Docked Glass tab }

  chkShowDockedWhenExecuted.Caption := vTranslations.lpShowDockedWhenExecuted;
  chkShowDockedWhenLensHides.Caption := vTranslations.lpShowDockedWhenLensHides;
  chkHideDockedWhenLensShows.Caption := vTranslations.lpHideDockedWhenLensShows;

  { Others }

  lblDisabledHint.Caption := vTranslations.lpDisabledHint;

  btnClose.Caption := vTranslations.lpClose;

  {*******************************************************************
  *  Updates the configurations
  *******************************************************************}

  { General tab }

  chkAutoRun.Checked := vConfigurations.autoRun;

  chkShowWhenExecuted.Checked := vConfigurations.showWhenExecuted;

  { Plugins tab }

  lstPluginsList.Items.Clear;
  lstPluginsList.ItemIndex := -1;

  if FindFirst(vConfigurations.MyDirectory + ID_PLUGIN_WILDCARD, faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr <> faDirectory) then
       lstPluginsList.Items.Add(SR.Name);
    until FindNext(SR) <> 0;
    
    // Must free up resources used by these successful finds
    FindClose(SR);
  end;
  
  { Tryes to select the plugin currently in use }
  for i := 0 to lstPluginsList.Count - 1 do
  begin
    if lstPluginsList.Items.Strings[i] = vConfigurations.PluginName then
     lstPluginsList.ItemIndex := i;
  end;

  { HotKey tab }

  rgrpHotKeyInvoke.ItemIndex := vConfigurations.HotKeyMode;

  txtHotKeyKey.Text := vConfigurations.HotKeyKey;

  { Image tab }
  sliderContrast.Position := vConfigurations.Contrast;
  if vConfigurations.ExtraAntiAliasing then
    rgrpAntialiasing.ItemIndex := 1
  else
    rgrpAntialiasing.ItemIndex := 0;
  chkPostProcess.Checked := vConfigurations.PostProcessing;
  spMemMb.Value := vConfigurations.MemMB;


  { Docked glass tab }
  chkShowDockedWhenExecuted.Checked := vConfigurations.showDockedWhenExecuted;
  chkShowDockedWhenLensHides.Checked := vConfigurations.showDockedWhenLensHides;
  chkHideDockedWhenLensshows.Checked := vConfigurations.hideDockedWhenLensShows;
  txtDockedHotKeyKey.Text := vConfigurations.DockedHotKeyKey;
  rgrpDockedHotKeyInvoke.ItemIndex := vConfigurations.DockedHotKeyMode;
  txtRightHotKeyKey.Text := vConfigurations.DockedRightHotKey;
  txtLeftHotKeyKey.Text := vConfigurations.DockedLeftHotKey;
  txtTopHotKeyKey.Text := vConfigurations.DockedUpHotKey;
  txtBottomHotKeyKey.Text := vConfigurations.DockedDownHotKey;
  txtBookmarkHotKeyKey.Text := vConfigurations.DockedBookmarkHotKey;
  if (vConfigurations.DockedFollowMouse = True) then comboFollow.ItemIndex := 0 else comboFollow.ItemIndex := 1;


{$ifdef Unix}
  lblHotKeyKey.Caption := 'Linux users:' + LineEnding + 'Please refer to the documentation for instructions' + LineEnding + 'on how to add a shortcut to the application';
  lblDockedHotKeyKey.Visible := False;
  txtHotKeyKey.Visible := False;
  rgrpHotKeyInvoke.Visible := False;
  txtDockedHotKeyKey.Enabled := False;
  txtDockedHotKeyKey.Visible := False;
  txtRightHotKeyKey.Enabled := False;
  txtRightHotKeyKey.Visible := False;
  txtLeftHotKeyKey.Enabled := False;
  txtLeftHotKeyKey.Visible := False;
  txtTopHotKeyKey.Enabled := False;
  txtTopHotKeyKey.Visible := False;
  txtBottomHotKeyKey.Enabled := False;
  txtBottomHotKeyKey.Visible := False;
  lblRightHotKeyKey.Visible := False;
  lblLeftHotKeyKey.Visible := False;
  lblTopHotKeyKey.Visible := False;
  lblBottomHotKeyKey.Visible := False;
  lblbookmarkHotKeyKey.Visible := False;
  lblbookmarkHotKeyKey.Enabled := False;
  txtBookmarkHotKeyKey.Visible := False;
  txtBookmarkHotKeyKey.Enabled := False;
  rgrpDockedHotKeyInvoke.Enabled := False;
  rgrpDockedHotKeyInvoke.Visible := False;
{$endif}

  { Remap tab }
  chkRemap.Caption := 'Enable Blind Spot';
  chkRemap.Checked := vConfigurations.RemapEnabled;
  spBoxRemapWidth.Value := vConfigurations.RemapWidth;
  spBoxRemapHeight.Value := vConfigurations.RemapHeight;
  RemapColor := vConfigurations.RemapBlue shl 16 or vConfigurations.RemapGreen shl 8 or vConfigurations.RemapRed;
  RemapColorDisplay.Color := RemapColor;
  UpdateRemap(Self);
end;

{*******************************************************************}
{@@
  Saves the dialog information to vConfigurations
}
{*******************************************************************}
procedure TConfigDialog.SaveConfigurations;
begin
  { General tab }

  vConfigurations.autoRun := chkAutoRun.Checked;
  
  vConfigurations.showWhenExecuted := chkShowWhenExecuted.Checked;

  { Plugins tab }

  if lstPluginsList.ItemIndex <> -1 then
  begin
    vConfigurations.PluginName := lstPluginsList.Items.Strings[lstPluginsList.ItemIndex];
  end;
  
  { HotKey tab }

  vConfigurations.HotKeyMode := rgrpHotKeyInvoke.ItemIndex;
  try
   vConfigurations.HotKeyKey := txtHotKeyKey.Text[1];
  except
   vConfigurations.HotKeyKey := ' ';
   vConfigurations.HotKeyMode := 0;
  end;

  vConfigurations.DockedHotKeyMode := rgrpDockedHotKeyInvoke.ItemIndex;
  try
    vConfigurations.DockedHotKeyKey := txtDockedHotKeyKey.Text[1];
  except
    vConfigurations.DockedHotKeyKey := ' ';
    vConfigurations.DockedHotKeyMode := 0;
  end;

  try
    vConfigurations.DockedRightHotKey := txtRightHotKeyKey.Text[1];
  except
    vConfigurations.DockedRightHotKey := ' ';
    vConfigurations.DockedHotKeyMode := 0;
  end;

  try
    vConfigurations.DockedLeftHotKey := txtLeftHotKeyKey.Text[1];
  except
    vConfigurations.DockedLeftHotKey := ' ';
    vConfigurations.DockedHotKeyMode := 0;
  end;

  try
    vConfigurations.DockedUpHotKey := txtTopHotKeyKey.Text[1];
  except
    vConfigurations.DockedUpHotKey := ' ';
    vConfigurations.DockedHotKeyMode := 0;
  end;

  try
    vConfigurations.DockedDownHotKey := txtBottomHotKeyKey.Text[1];
  except
    vConfigurations.DockedDownHotKey := ' ';
    vConfigurations.DockedHotKeyMode := 0;
  end;

  try
    vConfigurations.DockedBookmarkHotKey := txtBookmarkHotKeyKey.Text[1];
  except
    vConfigurations.DockedBookmarkHotKey := ' ';
    vConfigurations.DockedHotKeyMode := 0;
  end;

  vMainWindow.UpdateHotKey(Self);

  { Image tab }
  vConfigurations.Contrast := sliderContrast.Position;

  if  rgrpAntialiasing.ItemIndex = 1 then
    vConfigurations.ExtraAntiAliasing := True
  else
    vConfigurations.ExtraAntiAliasing := False;

  vConfigurations.PostProcessing := chkPostProcess.Checked;
  vConfigurations.MemMB := spMemMb.Value;

  { Docked glass tab }
  vConfigurations.showDockedWhenExecuted := chkShowDockedWhenExecuted.Checked;
  vConfigurations.showDockedWhenLensHides := chkShowDockedWhenLensHides.Checked;
  vConfigurations.hideDockedWhenLensShows := chkHideDockedWhenLensShows.Checked;
  vConfigurations.DockedCursor := comboMouse.ItemIndex;
  if (comboFollow.ItemIndex = 0) then vConfigurations.DockedFollowMouse := True
  else vConfigurations.DockedFollowMouse := False;

  { Remap }
  vConfigurations.RemapEnabled := chkRemap.Checked;
  vConfigurations.RemapWidth := spBoxRemapWidth.Value;
  vConfigurations.RemapHeight := spBoxRemapHeight.Value;
  vConfigurations.RemapRed := RemapColor and $000000FF;
  vConfigurations.RemapGreen := (RemapColor and $0000FF00) shr 8;
  vConfigurations.RemapBlue := (RemapColor and $00FF0000) shr 16;
end;

end.

