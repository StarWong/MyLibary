unit BTAESUtil;

(* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *  Copyright (C) 2005 Martin Offenwanger                                    *
 *  Mail: coder@dsplayer.de                                                  *
 *  Web:  http://www.dsplayer.de                                             *
 *                                                                           *
 *  This Program is free software; you can redistribute it and/or modify     *
 *  it under the terms of the GNU General Public License as published by     *
 *  the Free Software Foundation; either version 2, or (at your option)      *
 *  any later version.                                                       *
 *                                                                           *
 *  This Program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the             *
 *  GNU General Public License for more details.                             *
 *                                                                           *
 *  You should have received a copy of the GNU General Public License        *
 *  along with GNU Make; see the file COPYING.  If not, write to             *
 *  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.    *
 *  http://www.gnu.org/copyleft/gpl.html                                     *
 *                                                                           *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
{
@author(Martin Offenwanger: coder@dsplayer.de)
@created(Jan 01, 2005)
@lastmod(Apr 06, 2005)
}

interface

procedure xorWord(a, b: array of byte; out f_out: array of byte);
procedure setWord(a, b, c, d: byte; out fo_word: array of byte);
procedure rotWord(f_in: array of byte; out f_out: array of byte);
procedure StringToBytes(var text: string; out Bytes: array of byte);
function BytesToString(var Bytes: array of byte): string;
function hexToBit(a: char): byte;
function hexToByte(y: string): byte;
function hexChar(x: byte): char;
function hexToString(a: byte): string;

implementation

procedure xorWord(a, b: array of byte; out f_out: array of byte);
var i: integer;
begin
  for i := 0 to sizeof(a) - 1 do
    f_out[i] := a[i] xor b[i];
end;

procedure setWord(a, b, c, d: byte; out fo_word: array of byte);
begin
  fo_word[0] := a;
  fo_word[1] := b;
  fo_word[2] := c;
  fo_word[3] := d;
end;

procedure rotWord(f_in: array of byte; out f_out: array of byte);
begin
  f_out[0] := f_in[1];
  f_out[1] := f_in[2];
  f_out[2] := f_in[3];
  f_out[3] := f_in[0];
end;

procedure StringToBytes(var text: string; out Bytes: array of byte);
var
  a, len: integer;
begin
  len := Length(Text);
  if Length(Bytes) < len then len := Length(Bytes);
  for a := 0 to len - 1 do begin
    Bytes[a] := byte(Text[a + 1]);
  end;
end;

function BytesToString(var Bytes: array of byte): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to length(Bytes) - 1 do
    Result := Result + char(Bytes[i]);

end;

function hexToBit(a: char): byte;
begin
  Result := byte($FF);
  case a of
    '0': Result := $00;
    '1': Result := $01;
    '2': Result := $02;
    '3': Result := $03;
    '4': Result := $04;
    '5': Result := $05;
    '6': Result := $06;
    '7': Result := $07;
    '8': Result := $08;
    '9': Result := $09;
    'a': Result := $0A;
    'b': Result := $0B;
    'c': Result := $0C;
    'd': Result := $0D;
    'e': Result := $0E;
    'f': Result := $0F;
  end;
end;

function hexToByte(y: string): byte;
var
  a, b: char;
  lout: byte;
begin
  a := PChar(y)[0];
  b := PChar(y)[1];
  lout := $00;
  lout := hexToBit(a);
  lout := lout shl 4;
  lout := lout xor hexToBit(b);
  Result := lout;
end;

function hexChar(x: byte): char;
begin
  case x of
    0: Result := '0';
    1: Result := '1';
    2: Result := '2';
    3: Result := '3';
    4: Result := '4';
    5: Result := '5';
    6: Result := '6';
    7: Result := '7';
    8: Result := '8';
    9: Result := '9';
    10: Result := 'a';
    11: Result := 'b';
    12: Result := 'c';
    13: Result := 'd';
    14: Result := 'e';
    15: Result := 'f';
  end;
end;

function hexToString(a: byte): string;
var
  x, y: byte;
begin
  x := a;
  if x < 0 then begin
    x := x shr 4;
    x := x xor $F0;
  end else
    x := x shr 4;
  y := a shl 4;
  if y < 0 then begin
    y := y shr 4;
    y := y xor $F0;
  end else
    y := y shr 4;
  Result := hexchar(x) + hexchar(y);
end;

end.

