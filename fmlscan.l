%{
{
    Copyright (c) 2008 by Felipe Monteiro de Carvalho

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 ****************************************************************************}
unit fmlscan;

{$ifdef fpc}
  {$mode delphi}
{$endif}

interface

uses
  strings, sysutils, lexlib;

type
  TFMLBlock = (fbStructure, fbText);
  
  TFMLScannerDelegate = class
  public
    procedure DoAddTopic(aTopic: string); virtual; abstract;
    procedure DoSetTextColor(aColor: string); virtual; abstract;
    procedure DoSetTitle(aTitle: string); virtual; abstract;
    procedure DoWriteChars(aChars: string); virtual; abstract;
  end;

const
  currentBlock: TFMLBlock = fbStructure;

var
  scannerDelegate: TFMLScannerDelegate;

function yylex : integer;
function act_token : string;

implementation

%}

DIGIT         [0-9]
LETTER        [a-zA-Z]
NOTLETTER     ^[a-zA-Z]

%%

(\{title\}).*\n
    if currentBlock = fbStructure then
    begin
      scannerDelegate.DoSetTitle(System.Copy(yytext, 8, Length(yytext) - 8));
    end
    else raise Exception.Create('Tag {title} in invalid document position');

(\{topic\}).*\n
    if currentBlock = fbStructure then
    begin
      scannerDelegate.DoAddTopic(System.Copy(yytext, 8, Length(yytext) - 8));
    end
    else raise Exception.Create('Tag {topic} in invalid document position');

\{color=LETTER*\}
    if currentBlock = fbText then
    begin
      scannerDelegate.DoSetTextColor(yytext);
    end;

.
    if currentBlock = fbText then
    begin
      scannerDelegate.DoWriteChars(yytext);
    end;

%%

function act_token: string;
begin
  Result := yytext;
end;

{ Overrides the default yywrap function to avoid having the input
  file being closed. Returns True to indicate that yylex should
  terminate when the end-of-file marker is found }
function fml_yywrap(): Boolean;
begin
  Result := True;
end;

initialization
  lexlib.yywrap := @fml_yywrap;
end.

