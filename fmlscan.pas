{
}
unit fmlscan;

{$ifdef fpc}
  {$mode delphi}
{$endif}

interface

uses
  Classes, SysUtils, TypInfo;

type

  TFMLTokenType = (ttUnknown, ttTitle, ttTopic, ttText,
   ttBold, ttEndBold, ttItalic, ttEndItalic);

  TFMLTokenItem = record
    id: TFMLTokenType;
    Value: shortstring;
  end;

  TFMLTokens = array of TFMLTokenItem;

  { TFMLScanner }

  TFMLScanner = class
  private
    procedure AddToken(AToken: TFMLTokenType; AValue: string);
    function LerStringDeToken: string;
    function VerificarEOF: Boolean;
  public
    Tokens: TFMLTokens;
    FFileStream: TFileStream;
    procedure RunLex;
    procedure PrintTokenList;
  end;

const
  Set_Structural_Tokens = [ttTitle, ttTopic];

var
  FMLScanner: TFMLScanner;

implementation

const
  Set_Caracteres_ignorados = [' ', #10, #13];

{ TMaquinaLex }

procedure TFMLScanner.AddToken(AToken: TFMLTokenType; AValue: string);
begin
  SetLength(Tokens, Length(Tokens) + 1);
  Tokens[Length(Tokens) - 1].id := AToken;
  Tokens[Length(Tokens) - 1].Value := AValue;
end;

function TFMLScanner.LerStringDeToken: string;
var
  AChar: Char;
  IsTextToken: Boolean;
begin
  Result := '';

  // Pega o primeiro char, ignorando os espaços
  AChar := Char(FFileStream.ReadByte);
  while (AChar in Set_Caracteres_ignorados) and (not VerificarEOF) do AChar := Char(FFileStream.ReadByte);
  Result := AChar;
  if VerificarEOF then Exit;

  // Verifies the kind of token.
  // It can be either a special token if it starts with {
  // or a text token otherwise
  IsTextToken := (Result <> '{');

  // Agora pega os outros. Espaços e outros caracteres especiais separam os tokens
  // mas não no caso de strings literais, onde o separador é somente a aspas simples
  if IsTextToken then
  begin
    AChar := Char(FFileStream.ReadByte);
    while (AChar <> #10) and (AChar <> #13) and (not VerificarEOF) do
    begin
      Result := Result + AChar;
      AChar := Char(FFileStream.ReadByte);
    end;
    Result := Result + AChar;
  end
  // Other tokens are read until a space
  else
  begin
    AChar := Char(FFileStream.ReadByte);
    while (AChar <> ' ') and (not VerificarEOF) do
    begin
      Result := Result + AChar;
      AChar := Char(FFileStream.ReadByte);
    end;
    Result := Result + AChar;
  end;
end;

function TFMLScanner.VerificarEOF: Boolean;
begin
  Result := FFileStream.Position >= FFileStream.Size;
end;

procedure TFMLScanner.RunLex;
var
  TokenStr: string;
  IntValue, IntPos: Integer;
begin
  IntValue := 0;
  IntPos := 0;

//  if not Assigned(FFileStream) then Utilitarios().ExibirErro('TMaquinaLex: FFileStream nulo');

  while (not VerificarEOF) do
  begin
    TokenStr := LerStringDeToken;

    TokenStr := Trim(TokenStr);

    if TokenStr = '' then Continue; // Evita excesão ao acessar uma string vazia (nula)

    if TokenStr[1] <> '{' then AddToken(ttText, TokenStr)
    else if AnsiCompareText(TokenStr, '{title}') = 0 then AddToken(ttTitle, TokenStr)
    else if AnsiCompareText(TokenStr, '{topic}') = 0 then AddToken(ttTopic, TokenStr)
    else
    begin
    end;
  end;
end;

procedure TFMLScanner.PrintTokenList;
var
  i: Integer;
begin
  for i := 0 to Length(Tokens) - 1 do
  begin
    WriteLn('Token #', i, ' ',
     GetEnumName(TypeInfo(TFMLTokenType), integer(Tokens[i].id)),
     ' ', Tokens[i].Value
    );
  end;
end;

initialization

  FMLScanner := TFMLScanner.Create;

finalization

  FMLScanner.Free;

end.

