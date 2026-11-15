{
lazfmlviewer.pas

FML Help Viewer

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
unit lazfmlviewer;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses StrUtils, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, Buttons, {$ifdef fpc} LCLIntf, LCLType, {$endif}
  fmlscan;

type

  { TFMLViewer }
  
  TFMLViewer = class(TCustomControl)
  public
    bmpOutput: TBitmap;
    CurrentPage: string;
    CurrentPageIndex: Cardinal;
    TopicTokens: array of TFMLTokens;
    { Constructors / Destructors }
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    { Drawing methods }
    procedure   DrawBackground(ACanvas: TCanvas); virtual;
    procedure   DrawCurrentPage(ACanvas: TCanvas); virtual;
    procedure   Paint; override;
    procedure   UpdateImage;
  end;

  { TFMLViewerDialog }

  TFMLViewerDialog = class(TForm)
  private
    procedure DoAddTopic(aTopic: string);
    procedure DoAddTokenToTopic(aTopic: Cardinal; AToken: TFMLTokenItem);
    procedure DoSetTitle(aTitle: string);
  public
    { Components }
    fmlViewer: TFMLViewer;
    fmlIndex: TTreeView;
    currentFileName: string;
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy(); override;
    procedure LoadFromFile(AFileName: string);
    procedure LoadFromTokens(ATokens: TFMLTokens);
    { Event handlers }
    procedure HandleIndexSelChanged(ASender: TObject);
    procedure HandleRePaint(ASender: TObject);
  end;

const
  INT_TOPIC_TITLE_MARGIN = 25;
  INT_TOPIC_TEXT_MARGIN = 25;

var
  vFMLViewerDialog: TFMLViewerDialog;

implementation

{$ifndef fpc}
  {$R *.DFM}
{$endif}

{ TFMLViewer }

constructor TFMLViewer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  bmpOutput := TBitmap.Create;
end;

destructor TFMLViewer.Destroy;
begin
  bmpOutput.Free;

  inherited Destroy;
end;

procedure TFMLViewer.DrawBackground(ACanvas: TCanvas);
begin
  ACanvas.Brush.Color := clWhite;
  ACanvas.FillRect(Bounds(0, 0, Width, Height));
end;

procedure TFMLViewer.DrawCurrentPage(ACanvas: TCanvas);
var
  CurrentToken: Cardinal;
  currentPos: TPoint;
  Text: string;
  TextBox: TRect;
begin
  { First draw the title }

  ACanvas.Font.Size := 30;
  ACanvas.Font.Underline := True;

  ACanvas.TextOut(INT_TOPIC_TITLE_MARGIN,
    INT_TOPIC_TITLE_MARGIN * 2 + ACanvas.Font.Height, CurrentPage);

  { Initializes currentPos for writing the contents of the topic }
  currentPos.X := INT_TOPIC_TITLE_MARGIN;
  currentPos.Y := INT_TOPIC_TITLE_MARGIN * 4 + ACanvas.Font.Height;

  { Now draw the text }
  ACanvas.Font.Size := 14;
  ACanvas.Font.Underline := False;

  for CurrentToken := 0 to Length(TopicTokens[CurrentPageIndex]) - 1 do
  begin
    case TopicTokens[CurrentPageIndex][CurrentToken].id of
      ttText:
      begin
        Text := TopicTokens[CurrentPageIndex][CurrentToken].Value;

        // First calculate the text size then draw it
        TextBox := Rect(0, currentPos.Y, Width, High(Integer));
        DrawText(ACanvas.Handle, PChar(Text), Length(Text),
          TextBox, DT_WORDBREAK or DT_INTERNAL or DT_CALCRECT);

        DrawText(ACanvas.Handle, PChar(Text), Length(Text),
          TextBox, DT_WORDBREAK or DT_INTERNAL);

        currentPos.Y := TextBox.Bottom + INT_TOPIC_TEXT_MARGIN;
      end;
    end;
  end;
end;

procedure TFMLViewer.Paint;
begin
  // Copies the buffer bitmap to the canvas
  Canvas.Draw(0, 0, bmpOutput);
end;

procedure TFMLViewer.UpdateImage;
begin
  bmpOutput.Width := Width;
  bmpOutput.Height := Height;

  DrawBackground(bmpOutput.Canvas);
  DrawCurrentPage(bmpOutput.Canvas);
  
  Invalidate;
end;

{ TFMLViewerDialog }

procedure TFMLViewerDialog.DoAddTopic(aTopic: string);
var
  LastTopic: Cardinal;
begin
  LastTopic := Length(fmlViewer.TopicTokens);
  SetLength(fmlViewer.TopicTokens, LastTopic + 1);

  vFMLViewerDialog.fmlIndex.Items.AddChild(nil, aTopic);
end;

procedure TFMLViewerDialog.DoAddTokenToTopic(aTopic: Cardinal;
  AToken: TFMLTokenItem);
var
  LastToken: Cardinal;
begin
  LastToken := Length(fmlViewer.TopicTokens[aTopic]);
  SetLength(fmlViewer.TopicTokens[aTopic], LastToken + 1);

  fmlViewer.TopicTokens[aTopic][LastToken] := AToken;
end;

procedure TFMLViewerDialog.DoSetTitle(aTitle: string);
begin
  vFMLViewerDialog.Caption := '' + aTitle;
end;

constructor TFMLViewerDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  { Sets initial form properties }
  
  Position := poScreenCenter;
  OnWindowStateChange := HandleRePaint;
  
  { Creates child components }
  
  fmlIndex := TTreeView.Create(Self);
  fmlIndex.Parent := Self;
  fmlIndex.Align := alLeft;
  fmlIndex.Width := 200;
  fmlIndex.OnSelectionChanged := HandleIndexSelChanged;
  fmlIndex.OnResize := HandleRePaint;

  fmlViewer := TFMLViewer.Create(Self);
  fmlViewer.Parent := Self;
  fmlViewer.Left := fmlIndex.Width;
  fmlViewer.Width := Width - fmlIndex.Width;
  fmlViewer.Align := alClient;
end;

destructor TFMLViewerDialog.Destroy();
begin
  inherited Destroy();
end;

procedure TFMLViewerDialog.LoadFromFile(AFileName: string);
var
  AFile: TFileStream;
begin
  currentFileName := AFileName;

  if not FileExists(AFileName) then
  begin
    Application.MessageBox(
     PChar('File not found: ' + AFileName),
     'FML Viewer', MB_OK);
    Application.ProcessMessages;
    Close;
    Exit;
  end;

  AFile := TFileStream.Create(AFileName, fmOpenRead);
  try
    FMLScanner.FFileStream := AFile;
    FMLScanner.RunLex;
    FMLScanner.PrintTokenList;
    LoadFromTokens(FMLScanner.Tokens);
  finally
    AFile.Free;
  end;
end;

procedure TFMLViewerDialog.LoadFromTokens(ATokens: TFMLTokens);
var
  CurrentToken, State, TopicID: Cardinal;

  procedure HandleStructuralToken;
  begin
    case ATokens[CurrentToken].id of
      ttTitle: State := 1;
      ttTopic: State := 2;
    end;
  end;

begin
  State := 0;
  TopicID := 0;

  for CurrentToken := 0 to Length(ATokens) - 1 do
  begin
    // Looking for structural tokens
    if State = 0 then
    begin
      HandleStructuralToken;
    end
    // Setting the title of the document
    else if State = 1 then
    begin
      DoSetTitle(ATokens[CurrentToken].Value);
      State := 0;
    end
    // Adding a new topic
    else if State = 2 then
    begin
      DoAddTopic(ATokens[CurrentToken].Value);
      State := 10;
    end
    // Textual tokens inside a topic
    else if State = 10 then
    begin
      if ATokens[CurrentToken].id in Set_Structural_Tokens then
      begin
        HandleStructuralToken;
        Inc(TopicID);
      end
      else DoAddTokenToTopic(TopicID, ATokens[CurrentToken]);
    end;
  end;
end;

procedure TFMLViewerDialog.HandleIndexSelChanged(ASender: TObject);
begin
  fmlViewer.CurrentPage := fmlIndex.Selected.Text;
  fmlViewer.CurrentPageIndex := fmlIndex.Selected.Index;

  fmlViewer.UpdateImage;
end;

procedure TFMLViewerDialog.HandleRePaint(ASender: TObject);
begin
  fmlViewer.UpdateImage;
end;

end.

