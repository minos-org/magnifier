unit dockedglass;

{$mode ObjFPC}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  LCLType, LCLIntf, Menus, appsettings, math, BitmapProcess, constants;

type

  { TDockedGlassWindow }

  TDockedGlassWindow = class(TForm)
    Image: TImage;
    BordersMenuItem: TMenuItem;
    HideMenuItem: TMenuItem;
    DockedPopupMenu: TPopupMenu;
    IncreaseWidthMenuItem: TMenuItem;
    DecreaseWidthMenuItem: TMenuItem;
    IncreaseHeightMenuItem: TMenuItem;
    DecreaseHeightMenuItem: TMenuItem;
    procedure BordersMenuItemClick(Sender: TObject);
    procedure DecreaseHeightMenuItemClick(Sender: TObject);
    procedure DecreaseWidthMenuItemClick(Sender: TObject);
    procedure FormChangeBounds(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure HideMenuItemClick(Sender: TObject);
    procedure ImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );
    procedure ImageMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure IncreaseHeightMenuItemClick(Sender: TObject);
    procedure IncreaseWidthMenuItemClick(Sender: TObject);
    procedure UpdateBookmark;
  private
    SrcBitmap, DstBitmap: TBitmap;
    BmpDisplay : TBitmap;
    Arrow, InvertedArrow : TBitmap;
    Timer : TTimer;
    MouseIsDown: Boolean; //User holds mouse down to drag the form around
    CursorX, CursorY : Integer; //global mouse coordinates around the screen - we use it to know where the mouse is
    Fm : Single;
    W, H : Integer; //Width and height of the area that will be enlarged
    PX, PY : Integer; //Coordinates of the area that should be enlarged
    MouseDrawX, MouseDrawY : Integer; //coordinates of mouse position inside the form - we use it to draw the mouse;
    LensIsShown : Boolean;
    FormX, FormY : Integer;
    {$IFDEF Unix}
    FormWidth, FormHeight : Integer;
    {$ENDIF}
    SaveCursor : TCursor;
    Bookmark: TPoint;
    procedure DrawBitmap;
    procedure HandleDockTimer(Sender: TObject);
    function OutOfBounds(X, Y : Integer) : Boolean;
    procedure CheckFm;
    procedure SizeChanged;
    procedure GetMouseCoords;
    procedure DrawBorder;
    procedure DrawMouse;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetLensIsShown(NewLensIsShown : Boolean);
  end;

var
  vDockedGlass: TDockedGlassWindow;

implementation

{ TDockedGlassWindow }

constructor TDockedGlassWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FormStyle:=fsSystemStayOnTop;
  BmpDisplay := TBitmap.Create;
  BmpDisplay.Width := Screen.Width;
  BmpDisplay.Height := Screen.Height;
  if vConfigurations.dockedBorders then
    BorderStyle := bsSizeable
  else
    BorderStyle := bsNone;
  BordersMenuItem.Checked := vConfigurations.dockedBorders;
  Fm := vConfigurations.iMagnification;
  Bookmark.X := vConfigurations.DockedBookmarkX;
  Bookmark.Y := vConfigurations.DockedBookmarkY;
  Self.Width := 500;
  Self.Height := 500;
  W := Trunc(Self.Width / Fm);
  H := Trunc(Self.Height / Fm) ;
  SrcBitmap := TBitmap.Create;
  SrcBitmap.Width := W;
  SrcBitmap.Height := H;
  DstBitmap := TBitmap.Create;
  DstBitmap.Width := Self.Width;
  DstBitmap.Height := Self.Height;
  {$IFDEF Unix}
  ShowInTaskBar := stNever;
  {$ENDIF}
  Timer := TTimer.Create(nil);
  Timer.Enabled := False;
  Timer.Interval := 100;
  Timer.OnTimer := @HandleDockTimer;
  DoubleBuffered := True;
  LensIsShown := False;
  Arrow := TBitmap.Create;
  InvertedArrow := TBitmap.Create;
  {$IFDEF Windows}
  Arrow.LoadFromResourceID(hInstance, IDB_ARROW);
  InvertedArrow.LoadFromResourceID(hInstance, IDB_INVERTED_ARROW);
  {$ELSE}
  Arrow.LoadFromFile('/usr/share/magnifier/arrow.bmp');
  InvertedArrow.LoadFromFile('/usr/share/magnifier/inverted-arrow.bmp');
  {$ENDIF}
end;

destructor TDockedGlassWindow.Destroy;
begin
  BmpDisplay.Free;
  SrcBitmap.Free;
  DstBitmap.Free;
  Timer.Free;
  Arrow.Free;
  InvertedArrow.Free;
  inherited Destroy;
end;

procedure TDockedGlassWindow.HandleDockTimer(Sender: TObject);
begin
  if not MouseIsDown then
    DrawBitmap;
end;

function TDockedGlassWindow.OutOfBounds(X, Y: Integer): Boolean;
begin
  if  (X > Self.Left)
  AND (X < Self.Left + Self.Width)
  AND (Y > Self.Top)
  AND (Y < Self.Top + Self.Height) then
    Result := True
  else
    Result := False;
end;

procedure TDockedGlassWindow.CheckFm;
begin
  //This check is necessary because the user may have changed
  //iMagnification from system tray

  if (not LensIsShown) then
  begin
    if ( Fm <> vConfigurations.iMagnification) then
    begin
      Fm := vConfigurations.iMagnification;
      SizeChanged;
    end;
  end;
end;

procedure TDockedGlassWindow.SizeChanged;
begin
  Image.Picture.Bitmap.SetSize(Image.Width, Image.Height);
  W := Trunc(Self.Width / Fm);
  H := Trunc(Self.Height / Fm);
  if Assigned(SrcBitmap) then
  begin
    FreeAndNil(SrcBitmap);
    SrcBitmap := TBitmap.Create;
    SrcBitmap.Width := W;
    SrcBitmap.Height := H;
  end;
  if Assigned(DstBitmap) then
  begin
    FreeAndNil(DstBitmap);
    DstBitmap := TBitmap.Create;
    DstBitmap.Width := Self.Width;
    DstBitmap.Height := Self.Height;
  end;
  if Width < 25 then Width := 25;
  if Height < 25 then Height := 25;
  vConfigurations.DockedWidth := Self.Width;
  vConfigurations.DockedHeight := Self.Height;
end;

procedure TDockedGlassWindow.GetMouseCoords;
var
  Offset, Right, Bottom : Integer;

begin
  PX := CursorX - W div 2; //Holds top left x-coordinate of the area that should be magnified
  PY := CursorY - H div 2; //Holds top left y-coordinate of the area that should be magnified

  MouseDrawX := Image.Width div 2;  //Holds where mouse should be painted x-coordinate inside dock
  MouseDrawY := Image.Height div 2; //Holds where mouse should be painted y-coordinate inside dock
                                    //Normally mouseDrawX and mouseDrawY are in the middle of the form

  if PX < 0 then //If mouse goes to the left of the screen
  begin
    Offset := Round(PX * Fm);
    MouseDrawX := mouseDrawX + offset;  //If mouse goes to the left, we have to subtract offset
    					//So the mouse will be drawn to the left of the middle
         				//px is negative so we add it, not subtract it
    PX := 0;
  end;

  if PY < 0 then //if mouse goes to the top of the screen
  begin
    Offset := Round(PY * Fm);
    MouseDrawY := MouseDrawY + Offset;
    PY := 0;
  end;

  //Check right
  Right := PX + W;
  Offset := Right - Screen.Width;
  if Offset > 0 then  //If mouse goes to the right of the screen
  begin
    Offset := Round(Offset * Fm);          //Scale offset
    MouseDrawX := MouseDrawX + Offset;     //So the mouse will be draw to the right of the middle
    PX := Screen.Width - W;		   //This is as far we can go to the right
  end;

  //Check bottom
  Bottom := PY + H;
  Offset := Bottom - Screen.Height;
  if Offset > 0 then
  begin
    Offset := Round( Offset * Fm);
    MouseDrawY := MouseDrawY + Offset;
    PY := Screen.Height - H;               //This is as far we can go to the bottom
  end;
end;

procedure TDockedGlassWindow.DrawBorder;
{$IFDEF Unix}
var
  Margin : Integer;
{$ENDIF}
begin
  {$IFDEF Unix}
  Image.Canvas.Pen.Color:= clBlack;
  for Margin := 0 to 4 do
  begin
    Image.Canvas.MoveTo(0 + Margin, 0 + Margin);
    Image.Canvas.LineTo(Image.Width - Margin, 0 + Margin);
    Image.Canvas.MoveTo(0 + Margin, 0 + Margin);
    Image.Canvas.LineTo(0 + Margin, 0 + Image.Height - Margin);
    Image.Canvas.MoveTo(Image.Width - Margin, 0 + Margin);
    Image.Canvas.LineTo(0 + Image.Width - Margin, 0 + Image.Height - Margin);
    Image.Canvas.MoveTo(0 + Margin, 0 + Image.Height - Margin);
    Image.Canvas.LineTo(0 + Image.Width - Margin, 0 + Image.Height - Margin);
  end;
  {$ELSE}
  Image.Canvas.Brush.Color := clBlack;
  Image.Canvas.FrameRect(Bounds(0, 0, Image.Width, Image.Height));
  Image.Canvas.FrameRect(Bounds(0 + 1, 0 + 1, Image.Width - 2, Image.Height - 2));
  Image.Canvas.Brush.Color := clGray;
  Image.Canvas.FrameRect(Bounds(0 + 2, 0 + 2, Image.Width - 4, Image.Height - 4));
  Image.Canvas.FrameRect(Bounds(0 + 3, 0 + 3, Image.Width - 6, Image.Height - 6));
  {$ENDIF}
end;

procedure TDockedGlassWindow.DrawMouse;
begin
  if vConfigurations.DockedCursor = 1 then
  begin
    Image.Canvas.Draw(MouseDrawX - 10, MouseDrawY - 7, Arrow);
  end
  else if vConfigurations.DockedCursor = 2 then
  begin
    Image.Canvas.Draw(MouseDrawX - 10, MouseDrawY - 7, InvertedArrow);
  end
  else if vConfigurations.DockedCursor = 3 then
  begin
    Image.Canvas.Pen.Width := 4;
    Image.Canvas.Pen.Color:= clRed;
    Image.Canvas.MoveTo(MouseDrawX, MouseDrawY - 50);
    Image.Canvas.LineTo(MouseDrawX, MouseDrawY + 50);
    Image.Canvas.MoveTo(MouseDrawX - 50, MouseDrawY);
    Image.Canvas.LineTo(MouseDrawX + 50, MouseDrawY);
  end;
end;

procedure TDockedGlassWindow.SetLensIsShown(NewLensIsShown: Boolean);
begin
  LensIsShown := NewLensIsShown;
  if (LensIsShown) then
  begin
    Fm := 1.0;
    SizeChanged;
  end;
end;

procedure TDockedGlassWindow.FormHide(Sender: TObject);
begin
  Timer.Enabled := False;
  vConfigurations.DockedX := Left;
  vConfigurations.DockedY := Top;
  vConfigurations.DockedWidth := Width;
  vConfigurations.DockedHeight := Height;
end;

procedure TDockedGlassWindow.BordersMenuItemClick(Sender: TObject);
{$IFDEF Unix}
//With gtk2 form hides when changing border style
//This is a workaround
var
  TempForm : TForm;
{$ENDIF}
begin
{$IFDEF Unix}
  FormX := Left;
  FormY := Top;
  FormWidth := Width;
  FormHeight := Height;
{$ENDIF}
  if BorderStyle = bsNone then
  begin
    BorderStyle := bsSizeable;
    BordersMenuItem.Checked := True;
  end
  else if BorderStyle = bsSizeable then
  begin
    BorderStyle := bsNone;
    BordersMenuItem.Checked := False;
  end;

  Left := vConfigurations.DockedX;
  Top := vConfigurations.DockedY;
  vConfigurations.dockedBorders := BordersMenuItem.Checked;

{$IFDEF Unix}
  TempForm := TForm.Create(nil);
  try
    Parent := TempForm;
    Parent := nil;
  finally
    TempForm.Free;
  end;
  Left := FormX;
  Top := FormY;
  Width := FormWidth;
  Height := FormHeight;
{$ENDIF}
end;

procedure TDockedGlassWindow.FormChangeBounds(Sender: TObject);
begin
    vConfigurations.DockedX := Left;
    vConfigurations.DockedY := Top;
end;

procedure TDockedGlassWindow.FormResize(Sender: TObject);
begin
  SizeChanged;
end;

procedure TDockedGlassWindow.FormShow(Sender: TObject);
begin
  Left := vConfigurations.DockedX;
  Top := vConfigurations.DockedY;
  Width := vConfigurations.DockedWidth;
  Height := vConfigurations.DockedHeight;
  Timer.Enabled := True;
end;

procedure TDockedGlassWindow.HideMenuItemClick(Sender: TObject);
begin
  Hide;
end;

procedure TDockedGlassWindow.ImageMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then begin
    MouseIsDown := True;
    FormX := X;
    FormY := Y;
    SaveCursor := Image.Cursor;
    Image.Cursor := crHandPoint;
  end
  else if Button = mbRight then begin
    DockedPopupMenu.PopUp;
  end;
end;

procedure TDockedGlassWindow.ImageMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if MouseIsDown then
  begin
    Left := Left + (X - FormX);
    Top := Top + (Y - FormY);
    vConfigurations.DockedX := Left;
    vConfigurations.DockedY := Top;
  end;
end;

procedure TDockedGlassWindow.ImageMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then begin;
    MouseIsDown := False;
    Image.Cursor := SaveCursor;
  end;
end;

procedure TDockedGlassWindow.IncreaseWidthMenuItemClick(Sender: TObject);
begin
  Width := Width + 1;
end;

procedure TDockedGlassWindow.DecreaseWidthMenuItemClick(Sender: TObject);
begin
  Width := Width - 1;
  if Width < 25 then Width := 25;
end;

procedure TDockedGlassWindow.IncreaseHeightMenuItemClick(Sender: TObject);
begin
  Height := Height + 1;
end;

procedure TDockedGlassWindow.DecreaseHeightMenuItemClick(Sender: TObject);
begin
  Height := Height - 1;
  if Height < 25 then Height := 25;
end;

procedure TDockedGlassWindow.UpdateBookmark;
begin
  GetCursorPos(Bookmark);
  vConfigurations.DockedBookmarkX := Bookmark.X;
  vConfigurations.DockedBookmarkY := Bookmark.Y;
end;

procedure TDockedGlassWindow.DrawBitmap;
var
  ScreenDC: HDC;
  P : TPoint;
begin
  if (vConfigurations.DockedFollowMouse) then
    GetCursorPos(P)
  else
    P := Bookmark;

  CursorX := p.x;
  CursorY := p.y;

  if OutOfBounds(CursorX, CursorY) then
    Exit;

  CheckFm;
  GetMouseCoords;
  ScreenDC := GetDC(0);

  {$IFDEF WINDOWS}
  BitBlt(srcBitmap.Canvas.Handle, //destination HDC
         0, 0, srcBitmap.Width, srcBitmap.Height, // destination size
         ScreenDC, //source HDC
         PX, PY, // source size
         SrcCopy);


  if vConfigurations.invertColors then
    StretchBlt(
      DstBitmap.Canvas.Handle,    // destination DC
      0, 0, DstBitmap.Width, DstBitmap.Height,          // destination rectangle
      SrcBitmap.Canvas.Handle,    // source DC
      0, 0, W, H,  // source rectangle
      NOTSRCCOPY                  // raster operation
    )

    else
      StretchBlt(
        DstBitmap.Canvas.Handle,    // destination DC
        0, 0, DstBitmap.Width, DstBitmap.Height,          // destination rectangle
        SrcBitmap.Canvas.Handle,    // source DC
        0, 0, W, H,  // source rectangle
        SRCCOPY                  // raster operation
      );

  {$ELSE}
  BmpDisplay.LoadFromDevice(ScreenDC);
  SrcBitmap.Canvas.CopyRect(Bounds(0, 0, W, H),
                            BmpDisplay.Canvas,
                            Bounds(PX, PY, W, H));

  if vConfigurations.invertColors then
    RawInvertColors(SrcBitmap);

  StretchBlt(
    DstBitmap.Canvas.Handle,    // destination DC
    0, 0, DstBitmap.Width, DstBitmap.Height,          // destination rectangle
    SrcBitmap.Canvas.Handle,    // source DC
    0, 0, W, H,  // source rectangle
    SRCCOPY                  // raster operation
  );
  {$ENDIF}

  Image.Canvas.Draw(0, 0, DstBitmap);

  DrawBorder;
  DrawMouse;
  ReleaseDC(0, ScreenDC);
end;

initialization
  {$I dockedglass.lrs}

end.

