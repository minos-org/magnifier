{
about.pas

About Box

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
unit about;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
 ExtCtrls, StdCtrls, Buttons, appsettings, constants;

type

  { TAboutWindow }

  TAboutWindow = class(TForm)
  private
    { Private declarations }
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Image5: TImage;
    lblTitulo1: TLabel;
    lblTitulo2: TLabel;
    textSupport: TLabel;
    textSupportInfo: TLabel;
    textLicense: TLabel;
    textLicenseInfo: TLabel;
    textInformation: TLabel;
    textAuthors: TLabel;
    lblAuthors1: TLabel;
    lblAuthors2: TLabel;
    lblAuthors3: TLabel;
    textContributors: TLabel;
    memoContributors: TMemo;
    btnClose: TButton;
    procedure FormShow(Sender: TObject);
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
  end;

var
  vAboutWindow: TAboutWindow;

implementation

uses
  glass, translationsvmg
{$ifdef fpc}
  , LResources
{$endif}
 ;

{$ifndef fpc}
  {$R *.DFM}
{$endif}

{ TAboutWindow }

constructor TAboutWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  OnShow := FormShow;
  Position := poScreenCenter;
  Left := 241;
  Height := 543;
  Top := 129;
  Width := 578;

  Self.VertScrollBar.Visible := False;
  Self.HorzScrollBar.Visible := False;

  Image1 := TImage.Create(Self);
  with Image1 do
  begin
    Parent := Self;
    Height := 81;
    Left := 40;
    Top := 56;
    Width := 81;
    TGlass.LoadBitmap(Picture.Bitmap, IDB_CECAE);
    Picture.Bitmap.TransparentColor := clWhite;
    Picture.Bitmap.Transparent := True;
    Transparent := True;
  end;

  Image2 := TImage.Create(Self);
  with Image2 do
  begin
    Parent := Self;
    Height := 81;
    Left := 144;
    Top := 56;
    Width := 81;
    TGlass.LoadBitmap(Picture.Bitmap, IDB_FEUSP);
    Picture.Bitmap.TransparentColor := clWhite;
    Picture.Bitmap.Transparent := True;
    Transparent := True;
  end;

  Image3 := TImage.Create(Self);
  with Image3 do
  begin
    Parent := Self;
    Height := 81;
    Left := 248;
    Top := 56;
    Width := 81;
    TGlass.LoadBitmap(Picture.Bitmap, IDB_VMG);
    Picture.Bitmap.TransparentColor := clWhite;
    Picture.Bitmap.Transparent := True;
    Transparent := True;
  end;

  Image4 := TImage.Create(Self);
  with Image4 do
  begin
    Parent := Self;
    Height := 81;
    Left := 352;
    Top := 56;
    Width := 81;
    TGlass.LoadBitmap(Picture.Bitmap, IDB_LUPA);
    Picture.Bitmap.TransparentColor := clWhite;
    Picture.Bitmap.Transparent := True;
    Transparent := True;
  end;

  Image5 := TImage.Create(Self);
  with Image5 do
  begin
    Parent := Self;
    Height := 81;
    Left := 456;
    Top := 56;
    Width := 81;
    TGlass.LoadBitmap(Picture.Bitmap, IDB_USPLEGAL);
    Picture.Bitmap.TransparentColor := clWhite;
    Picture.Bitmap.Transparent := True;
    Transparent := True;
  end;

  lblTitulo1 := TLabel.Create(Self);
  with lblTitulo1 do
  begin
    Parent := Self;
    Alignment := taCenter;
    AutoSize := False;
    Caption := szAppTitleLong + lpSpace + szAppVersion;
    Height := 33;
    Left := 16;
    Top := 9;
    Width := Self.Width - 2 * Left;
    Font.Size := 20;
    Font.Style := [fsBold];
    Font.Color := clBlack;
    Anchors := [akLeft, akRight, akTop];
  end;

  lblTitulo2 := TLabel.Create(Self);
  with lblTitulo2 do
  begin
    Parent := Self;
    Alignment := taCenter;
    AutoSize := False;
    Caption := szAppTitleLong + lpSpace + szAppVersion;
    Height := 33;
    Left := 16;
    Top := 8;
    Width := Self.Width - 2 * Left;
    Font.Size := 20;
    Font.Style := [fsBold];
    Font.Color := clNavy;
    Anchors := [akLeft, akRight, akTop];
  end;

  textSupport := TLabel.Create(Self);
  with textSupport do
  begin
    Parent := Self;
    Alignment := taCenter;
    AutoSize := False;
    Height := 24;
    Left := 16;
    Top := 144;
    Width := Self.Width - 2 * Left;
    Font.Size := 14;
    Font.Style := [fsBold];
    Anchors := [akLeft, akRight, akTop];
  end;

  textSupportInfo := TLabel.Create(Self);
  with textSupportInfo do
  begin
    Parent := Self;
    Alignment := taCenter;
    AutoSize := False;
    Height := 20;
    Left := 16;
    Top := 176;
    Width := Self.Width - 2 * Left;
    Font.Size := 12;
    Anchors := [akLeft, akRight, akTop];
  end;

  textLicense := TLabel.Create(Self);
  with textLicense do
  begin
    Parent := Self;
    Alignment := taCenter;
    AutoSize := False;
    Height := 20;
    Left := 16;
    Top := 208;
    Width := Self.Width - 2 * Left;
    Font.Size := 14;
    Font.Style := [fsBold];
    Anchors := [akLeft, akRight, akTop];
  end;

  textLicenseInfo := TLabel.Create(Self);
  with textLicenseInfo do
  begin
    Parent := Self;
    Alignment := taCenter;
    AutoSize := False;
    WordWrap := True;
    Height := 100;
    Left := 16;
    Top := 232;
    Width := Self.Width - 2 * Left;
    Font.Size := 12;
    Anchors := [akLeft, akRight, akTop];
    Transparent := True;
  end;

  textInformation := TLabel.Create(Self);
  with textInformation do
  begin
    Parent := Self;
    Alignment := taCenter;
    AutoSize := False;
    Height := 20;
    Left := 0;
    Top := 312;
    Width := Self.Width;
    Font.Size := 12;
    Anchors := [akLeft, akRight, akTop];
    Transparent := True;
  end;

  textAuthors := TLabel.Create(Self);
  with textAuthors do
  begin
    Parent := Self;
    Alignment := taCenter;
    AutoSize := False;
    Height := 24;
    Left := 16;
    Top := 336;
    Width := 221;
    Font.Size := 14;
    Font.Style := [fsBold];
  end;

  lblAuthors1 := TLabel.Create(Self);
  with lblAuthors1 do
  begin
    Parent := Self;
    Alignment := taCenter;
    Caption := 'Chris O''Donnell';
    AutoSize := False;
    Height := 20;
    Left := 16;
    Top := 368;
    Width := 221;
    Font.Size := 12;
  end;

  lblAuthors2 := TLabel.Create(Self);
  with lblAuthors2 do
  begin
    Parent := Self;
    Alignment := taCenter;
    Caption := 'Felipe Monteiro de Carvalho';
    AutoSize := False;
    Height := 24;
    Left := 16;
    Top := 396;
    Width := 221;
    Font.Size := 12;
  end;

  lblAuthors3 := TLabel.Create(Self);
  with lblAuthors3 do
  begin
    Parent := Self;
    Alignment := taCenter;
    AutoSize := False;
    Caption := 'Harri Pyy';
    Height := 24;
    Left := 16;
    Top := 424;
    Width := 221;
    Font.Size := 12;
  end;

  textContributors := TLabel.Create(Self);
  with textContributors do
  begin
    Parent := Self;
    Alignment := taCenter;
    AutoSize := False;
    Height := 24;
    Left := 262;
    Top := 336;
    Width := Self.Width - Left;
    Font.Size := 14;
    Font.Style := [fsBold];
    Anchors := [akLeft, akRight, akTop];
  end;

  memoContributors := TMemo.Create(Self);
  with memoContributors do
  begin
    Parent := Self;
    Height := 81;
    Left := 262;
    Top := 368;
    Width := Self.Width - Left - 16;
    WordWrap := False;
    ScrollBars := ssBoth;
    Anchors := [akLeft, akRight, akTop];
  end;

  btnClose := TButton.Create(Self);
  with btnClose do
  begin
    Parent := Self;
    Height := 33;
    Left := 208;
    Top := 464;
    Width := 161;
    ModalResult := mrOK;
    TabOrder := 0;
    Anchors := [akLeft, akRight, akTop];
    Font.Size := 14;
  end;

  ActiveControl := btnClose;
end;

{@@
  Translates the about box to the current language
}
procedure TAboutWindow.FormShow(Sender: TObject);
begin
  Caption := vTranslations.lpAboutWindow;
  btnClose.Caption := vTranslations.lpClose;
  textSupport.Caption := vTranslations.lpSupport;
  textSupportInfo.Caption := vTranslations.lpSupportInfo;
  textLicense.Caption := vTranslations.lpLicense;
  textLicenseInfo.Caption := vTranslations.lpLicenseInfo;
  textAuthors.Caption := vTranslations.lpAuthors;
  textContributors.Caption := vTranslations.lpContributorsTitle;
  textInformation.Caption := vTranslations.lpInformation;
  memoContributors.Lines.Text := lpContributors;
end;

end.
