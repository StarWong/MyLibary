unit BTAES;

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

uses BTAESUTIL, BTAESBOX;

type
  TBTAES128 = class
  public
    // file
    procedure encrypt(f_key: string; var f_src: file; out f_dest: file);
      overload;
    procedure decrypt(f_key: string; var f_src: file; out f_dest: file);
      overload;
    // buffer  (restriction: length(f_buffer) mod 16 = 0 )
    procedure encrypt(f_key: string; var f_buffer: array of byte;
      out f_out: array of byte); overload;
    procedure decrypt(f_key: string; var f_buffer: array of byte;
      out f_out: array of byte); overload;
    // my functions
    function encryptFile(const f_key, originalFile: string;
      Out encodedFile: string): LongBool; overload;
    function decryptFile(const f_key, encodedFile: string;
      Out decodedFile: string): LongBool; overload;
    function encryptStr(const f_key, originalStr: string;
      Out encodedStr: String;encodeBase64:LongBool = False): LongBool; overload;
    function decryptstr(const f_key, encodedStr: String;
      Out decodedStr: string;decodeBase64:LongBool = False): LongBool; overload;
    // selftest
    procedure selfTest();
  strict private
    keyCounter: integer;
    state: array [0 .. 3, 0 .. 3] of byte;
    keyshedule128: array [0 .. 43, 0 .. 3] of byte;
    initialKey: array [0 .. 15] of byte;
    byteCounter: integer;
    procedure xorRoundKey();
    procedure subBytes();
    procedure invsubBytes();
    procedure shiftRows();
    procedure invshiftRows();
    procedure mixcolumns();
    procedure invMixColumns();
    procedure keyExpansion128(initialKey: array of byte);
    procedure getRCon(i: integer; out fo_word: array of byte);
    procedure subWord(f_in: array of byte; out f_out: array of byte);
    procedure convertKeyString(keyString: string; out f_out: array of byte);
    procedure fillState(var f_out: array of byte); overload;
    procedure fillState(var f_fin: file); overload;
    procedure encryptNextBlock(var f_out: array of byte); overload;
    procedure encryptNextBlock(var f_out: file); overload;
    procedure decryptNextBlock(var f_out: array of byte); overload;
    procedure decryptNextBlock(var f_out: file); overload;
    function FFMul(const a, b: byte): byte;
    procedure printstate();
    function CalcDecodedSize(const addr:PAnsiChar;const size:Cardinal): Cardinal;
  end;

var
  tempx: byte;
  tempy: byte;
  temp1: array [0 .. 3] of byte;
  temp2: array [0 .. 3, 0 .. 3] of byte;
  key1: array [0 .. 3] of byte;
  i1: integer;
  j1: integer;

implementation

uses
  Classes, EncdDecd,SysUtils;


procedure TBTAES128.printstate();
var
  i, j: integer;
begin
  writeln;
  for i := 0 to 3 do
    for j := 0 to 3 do
      write(HexToString(state[i, j]) + ' ');
end;

procedure TBTAES128.selfTest();
var
  data: array [0 .. 16] of byte;
  i: integer;
begin
  data[0] := byte($32);
  data[1] := byte($43);
  data[2] := byte($F6);
  data[3] := byte($A8);
  data[4] := byte($88);
  data[5] := byte($5A);
  data[6] := byte($30);
  data[7] := byte($8D);
  data[8] := byte($31);
  data[9] := byte($31);
  data[10] := byte($98);
  data[11] := byte($A2);
  data[12] := byte($E0);
  data[13] := byte($37);
  data[14] := byte($07);
  data[15] := byte($34);
  encrypt('2b7e151628aed2a6abf7158809cf4f3c', data, data);
  // after encrypt
  // 39 25 84 1d 02 dc 09 fb dc 11 85 97 19 6a 0b 32
  writeln;
  for i := 0 to 15 do
    write(HexToString(data[i]) + ' ');
  decrypt('2b7e151628aed2a6abf7158809cf4f3c', data, data);
  // after decrypt
  // 32 43 f6 a8 88 5a 30 8d 31 31 98 a2 e0 37 07 34
  writeln;
  for i := 0 to 15 do
    write(HexToString(data[i]) + ' ');
end;

procedure TBTAES128.encrypt(f_key: string; var f_src: file; out f_dest: file);
begin
  byteCounter := 0;
  convertKeyString(f_key, initialKey);
  keyExpansion128(initialKey);
  while (byteCounter < (FileSize(f_src) - 15)) do
  begin
    fillState(f_src);
    inc(byteCounter, 16);
    if byteCounter mod 100000 = 0 then
    begin
      write('.');
    end;
    encryptNextBlock(f_dest);
  end;
end;

procedure TBTAES128.decrypt(f_key: string; var f_src: file; out f_dest: file);
begin
  byteCounter := 0;
  convertKeyString(f_key, initialKey);
  keyExpansion128(initialKey);
  while (byteCounter < (FileSize(f_src) - 15)) do
  begin
    fillState(f_src);
    inc(byteCounter, 16);
    if byteCounter mod 100000 = 0 then
      write('.');
    decryptNextBlock(f_dest);
  end;
end;

procedure TBTAES128.encrypt(f_key: string; var f_buffer: array of byte;
  out f_out: array of byte);
begin
  byteCounter := 0;
  convertKeyString(f_key, initialKey);
  keyExpansion128(initialKey);
  while (byteCounter < (length(f_buffer) - 15)) do
  begin
    fillState(f_buffer);
    if byteCounter mod 100000 = 0 then
      write('.');
    encryptNextBlock(f_out);
  end;
end;

procedure TBTAES128.decrypt(f_key: string; var f_buffer: array of byte;
  out f_out: array of byte);
begin
  byteCounter := 0;
  convertKeyString(f_key, initialKey);
  keyExpansion128(initialKey);
  while (byteCounter < (length(f_buffer) - 15)) do
  begin
    fillState(f_buffer);
    if byteCounter mod 100000 = 0 then
      write('.');
    decryptNextBlock(f_out);
  end;
end;

procedure TBTAES128.fillState(var f_fin: file);
var
  i, j: integer;
begin
  for i := 0 to 3 do
    for j := 0 to 3 do
      state[i, j] := $00;
  BlockRead(f_fin, state, 16);
end;

procedure TBTAES128.fillState(var f_out: array of byte);
begin
  state[0, 0] := f_out[byteCounter];
  inc(byteCounter);
  state[0, 1] := f_out[byteCounter];
  inc(byteCounter);
  state[0, 2] := f_out[byteCounter];
  inc(byteCounter);
  state[0, 3] := f_out[byteCounter];
  inc(byteCounter);
  state[1, 0] := f_out[byteCounter];
  inc(byteCounter);
  state[1, 1] := f_out[byteCounter];
  inc(byteCounter);
  state[1, 2] := f_out[byteCounter];
  inc(byteCounter);
  state[1, 3] := f_out[byteCounter];
  inc(byteCounter);
  state[2, 0] := f_out[byteCounter];
  inc(byteCounter);
  state[2, 1] := f_out[byteCounter];
  inc(byteCounter);
  state[2, 2] := f_out[byteCounter];
  inc(byteCounter);
  state[2, 3] := f_out[byteCounter];
  inc(byteCounter);
  state[3, 0] := f_out[byteCounter];
  inc(byteCounter);
  state[3, 1] := f_out[byteCounter];
  inc(byteCounter);
  state[3, 2] := f_out[byteCounter];
  inc(byteCounter);
  state[3, 3] := f_out[byteCounter];
  inc(byteCounter);
end;


procedure TBTAES128.encryptNextBlock(var f_out: file);
begin
  keyCounter := 0;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  xorRoundKey;
  BlockWrite(f_out, state, 16);
end;

procedure TBTAES128.encryptNextBlock(var f_out: array of byte);
var
  i, j, k: integer;
begin
  keyCounter := 0;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  mixcolumns;
  xorRoundKey;
  subBytes;
  shiftRows;
  xorRoundKey;
  k := 0;
  for i := 0 to 3 do
  begin
    for j := 0 to 3 do
    begin
      f_out[byteCounter - 16 + k] := state[i, j];
      inc(k);
    end;
  end;
end;

procedure TBTAES128.decryptNextBlock(var f_out: file);
begin
  keyCounter := 40;
  xorRoundKey;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := 0;
  xorRoundKey;
  BlockWrite(f_out, state, 16);
end;

procedure TBTAES128.decryptNextBlock(var f_out: array of byte);
var
  i, j, k: integer;
begin
  keyCounter := 40;
  xorRoundKey;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := keyCounter - 8;
  xorRoundKey;
  invMixColumns;
  invsubBytes;
  invshiftRows;
  keyCounter := 0;
  xorRoundKey;
  k := 0;
  for i := 0 to 3 do
  begin
    for j := 0 to 3 do
    begin
      f_out[byteCounter - 16 + k] := state[i, j];
      inc(k);
    end;
  end;
end;



function TBTAES128.CalcDecodedSize(const addr:PAnsiChar;const size:Cardinal): Cardinal;
begin
  if size = 0 then  Exit;
  if (size mod 4) <> 0 then Exit;
  Result:=(size shr 2)*3;
  if (addr + size -2)^ =AnsiChar($3D)
  then Dec(Result, 2)
  else if (addr + size -1)^ = AnsiChar($3D)
then Dec(Result);
end;


procedure TBTAES128.convertKeyString(keyString: string;
  out f_out: array of byte);
var
  i: integer;
begin
  for i := 0 to 15 do
  begin
    f_out[i] := hexToByte(copy(keyString, 1, 2));
    keyString := copy(keyString, 3, length(keyString));
  end;
end;

procedure TBTAES128.getRCon(i: integer; out fo_word: array of byte);
var
  i1: integer;
begin
  for i1 := 1 to 3 do
    fo_word[i1] := $00;
  if i < 9 then
  begin
    fo_word[0] := $01 shl (i - 1);
    Exit;
  end;
  if i = 9 then
  begin
    fo_word[0] := $1B;
    Exit;
  end;
  fo_word[0] := $36;
end;

procedure TBTAES128.subWord(f_in: array of byte; out f_out: array of byte);
var
  i: integer;
begin
  for i := 0 to 3 do
    f_out[i] := sBox[f_in[i]];
end;

procedure TBTAES128.keyExpansion128(initialKey: array of byte);
var
  i, j: integer;
  temp: array [0 .. 3] of byte;
  temp2: array [0 .. 3] of byte;
  temp3: array [0 .. 3] of byte;
  temp4: array [0 .. 3] of byte;
begin
  for i := 0 to 3 do
    for j := 0 to 3 do
      keyshedule128[i, j] := initialKey[4 * i + j];
  for i := 4 to 43 do
  begin
    for j := 0 to 3 do
      temp[j] := keyshedule128[i - 1, j];
    if i mod 4 = 0 then
    begin
      rotWord(temp, temp);
      subWord(temp, temp);
      getRCon(trunc(i / 4), temp2);
      xorWord(temp, temp2, temp);
    end;
    for j := 0 to 3 do
      temp3[j] := keyshedule128[i - 4, j];
    xorWord(temp3, temp, temp4);
    for j := 0 to 3 do
      keyshedule128[i, j] := temp4[j];
  end;
end;

procedure TBTAES128.xorRoundKey();
var
  key: array [0 .. 3] of byte absolute key1;
  temp: array [0 .. 3] of byte absolute temp1;
begin
  // get next key
  key[0] := keyshedule128[keyCounter, 0];
  key[1] := keyshedule128[keyCounter, 1];
  key[2] := keyshedule128[keyCounter, 2];
  key[3] := keyshedule128[keyCounter, 3];
  inc(keyCounter);
  // xor round key
  state[0, 0] := state[0, 0] xor key[0];
  state[0, 1] := state[0, 1] xor key[1];
  state[0, 2] := state[0, 2] xor key[2];
  state[0, 3] := state[0, 3] xor key[3];
  key[0] := keyshedule128[keyCounter, 0];
  key[1] := keyshedule128[keyCounter, 1];
  key[2] := keyshedule128[keyCounter, 2];
  key[3] := keyshedule128[keyCounter, 3];
  inc(keyCounter);
  state[1, 0] := state[1, 0] xor key[0];
  state[1, 1] := state[1, 1] xor key[1];
  state[1, 2] := state[1, 2] xor key[2];
  state[1, 3] := state[1, 3] xor key[3];
  key[0] := keyshedule128[keyCounter, 0];
  key[1] := keyshedule128[keyCounter, 1];
  key[2] := keyshedule128[keyCounter, 2];
  key[3] := keyshedule128[keyCounter, 3];
  inc(keyCounter);
  state[2, 0] := state[2, 0] xor key[0];
  state[2, 1] := state[2, 1] xor key[1];
  state[2, 2] := state[2, 2] xor key[2];
  state[2, 3] := state[2, 3] xor key[3];
  key[0] := keyshedule128[keyCounter, 0];
  key[1] := keyshedule128[keyCounter, 1];
  key[2] := keyshedule128[keyCounter, 2];
  key[3] := keyshedule128[keyCounter, 3];
  inc(keyCounter);
  state[3, 0] := state[3, 0] xor key[0];
  state[3, 1] := state[3, 1] xor key[1];
  state[3, 2] := state[3, 2] xor key[2];
  state[3, 3] := state[3, 3] xor key[3];
end;

procedure TBTAES128.shiftRows();
var
  temp1: byte absolute tempx;
  temp2: byte absolute tempy;
begin
  temp1 := state[0, 1];
  state[0, 1] := state[1, 1];
  state[1, 1] := state[2, 1];
  state[2, 1] := state[3, 1];
  state[3, 1] := temp1;
  temp1 := state[0, 2];
  temp2 := state[1, 2];
  state[0, 2] := state[2, 2];
  state[1, 2] := state[3, 2];
  state[2, 2] := temp1;
  state[3, 2] := temp2;
  temp1 := state[0, 3];
  state[0, 3] := state[3, 3];
  state[3, 3] := state[2, 3];
  state[2, 3] := state[1, 3];
  state[1, 3] := temp1;
end;

procedure TBTAES128.invshiftRows();
var
  temp1: byte absolute tempx;
  temp2: byte absolute tempy;
begin
  temp1 := state[0, 1];
  temp2 := state[2, 1];
  state[0, 1] := state[3, 1];
  state[2, 1] := state[1, 1];
  state[1, 1] := temp1;
  state[3, 1] := temp2;
  temp1 := state[3, 2];
  temp2 := state[0, 2];
  state[0, 2] := state[2, 2];
  state[3, 2] := state[1, 2];
  state[1, 2] := temp1;
  state[2, 2] := temp2;
  temp1 := state[0, 3];
  state[0, 3] := state[1, 3];
  state[1, 3] := state[2, 3];
  state[2, 3] := state[3, 3];
  state[3, 3] := temp1;
end;

procedure TBTAES128.subBytes();
begin
  state[0, 0] := sBox[state[0, 0]];
  state[0, 1] := sBox[state[0, 1]];
  state[0, 2] := sBox[state[0, 2]];
  state[0, 3] := sBox[state[0, 3]];
  state[1, 0] := sBox[state[1, 0]];
  state[1, 1] := sBox[state[1, 1]];
  state[1, 2] := sBox[state[1, 2]];
  state[1, 3] := sBox[state[1, 3]];
  state[2, 0] := sBox[state[2, 0]];
  state[2, 1] := sBox[state[2, 1]];
  state[2, 2] := sBox[state[2, 2]];
  state[2, 3] := sBox[state[2, 3]];
  state[3, 0] := sBox[state[3, 0]];
  state[3, 1] := sBox[state[3, 1]];
  state[3, 2] := sBox[state[3, 2]];
  state[3, 3] := sBox[state[3, 3]];
end;

procedure TBTAES128.invsubBytes();
begin
  state[0, 0] := sBoxinv[state[0, 0]];
  state[0, 1] := sBoxinv[state[0, 1]];
  state[0, 2] := sBoxinv[state[0, 2]];
  state[0, 3] := sBoxinv[state[0, 3]];
  state[1, 0] := sBoxinv[state[1, 0]];
  state[1, 1] := sBoxinv[state[1, 1]];
  state[1, 2] := sBoxinv[state[1, 2]];
  state[1, 3] := sBoxinv[state[1, 3]];
  state[2, 0] := sBoxinv[state[2, 0]];
  state[2, 1] := sBoxinv[state[2, 1]];
  state[2, 2] := sBoxinv[state[2, 2]];
  state[2, 3] := sBoxinv[state[2, 3]];
  state[3, 0] := sBoxinv[state[3, 0]];
  state[3, 1] := sBoxinv[state[3, 1]];
  state[3, 2] := sBoxinv[state[3, 2]];
  state[3, 3] := sBoxinv[state[3, 3]];
end;

function TBTAES128.FFMul(const a, b: byte): byte;
begin
  if ((a <> 0) and (b <> 0)) then
    Result := FFPow[FFlog[a] + FFlog[b]]
  else
    Result := 0;
end;

procedure TBTAES128.mixcolumns();
var
  t: array [0 .. 3, 0 .. 3] of byte absolute temp2;
begin
  t[0, 0] := state[0, 0];
  t[0, 1] := state[0, 1];
  t[0, 2] := state[0, 2];
  t[0, 3] := state[0, 3];
  t[1, 0] := state[1, 0];
  t[1, 1] := state[1, 1];
  t[1, 2] := state[1, 2];
  t[1, 3] := state[1, 3];
  t[2, 0] := state[2, 0];
  t[2, 1] := state[2, 1];
  t[2, 2] := state[2, 2];
  t[2, 3] := state[2, 3];
  t[3, 0] := state[3, 0];
  t[3, 1] := state[3, 1];
  t[3, 2] := state[3, 2];
  t[3, 3] := state[3, 3];

  state[0, 0] := FFMul(a, t[0, 0]) xor FFMul(b, t[0, 1]) xor t[0, 2] xor t[0,
    3];
  state[0, 1] := FFMul(a, t[0, 1]) xor FFMul(b, t[0, 2]) xor t[0, 3] xor t[0,
    0];
  state[0, 2] := FFMul(a, t[0, 2]) xor FFMul(b, t[0, 3]) xor t[0, 0] xor t[0,
    1];
  state[0, 3] := FFMul(a, t[0, 3]) xor FFMul(b, t[0, 0]) xor t[0, 1] xor t[0,
    2];

  state[1, 0] := FFMul(a, t[1, 0]) xor FFMul(b, t[1, 1]) xor t[1, 2] xor t[1,
    3];
  state[1, 1] := FFMul(a, t[1, 1]) xor FFMul(b, t[1, 2]) xor t[1, 3] xor t[1,
    0];
  state[1, 2] := FFMul(a, t[1, 2]) xor FFMul(b, t[1, 3]) xor t[1, 0] xor t[1,
    1];
  state[1, 3] := FFMul(a, t[1, 3]) xor FFMul(b, t[1, 0]) xor t[1, 1] xor t[1,
    2];

  state[2, 0] := FFMul(a, t[2, 0]) xor FFMul(b, t[2, 1]) xor t[2, 2] xor t[2,
    3];
  state[2, 1] := FFMul(a, t[2, 1]) xor FFMul(b, t[2, 2]) xor t[2, 3] xor t[2,
    0];
  state[2, 2] := FFMul(a, t[2, 2]) xor FFMul(b, t[2, 3]) xor t[2, 0] xor t[2,
    1];
  state[2, 3] := FFMul(a, t[2, 3]) xor FFMul(b, t[2, 0]) xor t[2, 1] xor t[2,
    2];

  state[3, 0] := FFMul(a, t[3, 0]) xor FFMul(b, t[3, 1]) xor t[3, 2] xor t[3,
    3];
  state[3, 1] := FFMul(a, t[3, 1]) xor FFMul(b, t[3, 2]) xor t[3, 3] xor t[3,
    0];
  state[3, 2] := FFMul(a, t[3, 2]) xor FFMul(b, t[3, 3]) xor t[3, 0] xor t[3,
    1];
  state[3, 3] := FFMul(a, t[3, 3]) xor FFMul(b, t[3, 0]) xor t[3, 1] xor t[3,
    2];

end;

procedure TBTAES128.invMixColumns();
var
  t: array [0 .. 3, 0 .. 3] of byte absolute temp2;
begin
  t[0, 0] := state[0, 0];
  t[0, 1] := state[0, 1];
  t[0, 2] := state[0, 2];
  t[0, 3] := state[0, 3];
  t[1, 0] := state[1, 0];
  t[1, 1] := state[1, 1];
  t[1, 2] := state[1, 2];
  t[1, 3] := state[1, 3];
  t[2, 0] := state[2, 0];
  t[2, 1] := state[2, 1];
  t[2, 2] := state[2, 2];
  t[2, 3] := state[2, 3];
  t[3, 0] := state[3, 0];
  t[3, 1] := state[3, 1];
  t[3, 2] := state[3, 2];
  t[3, 3] := state[3, 3];

  state[0, 0] := FFMul(c, t[0, 0]) xor FFMul(d, t[0, 1]) xor FFMul(e, t[0, 2])
    xor FFMul(f, t[0, 3]);
  state[0, 1] := FFMul(c, t[0, 1]) xor FFMul(d, t[0, 2]) xor FFMul(e, t[0, 3])
    xor FFMul(f, t[0, 0]);
  state[0, 2] := FFMul(c, t[0, 2]) xor FFMul(d, t[0, 3]) xor FFMul(e, t[0, 0])
    xor FFMul(f, t[0, 1]);
  state[0, 3] := FFMul(c, t[0, 3]) xor FFMul(d, t[0, 0]) xor FFMul(e, t[0, 1])
    xor FFMul(f, t[0, 2]);

  state[1, 0] := FFMul(c, t[1, 0]) xor FFMul(d, t[1, 1]) xor FFMul(e, t[1, 2])
    xor FFMul(f, t[1, 3]);
  state[1, 1] := FFMul(c, t[1, 1]) xor FFMul(d, t[1, 2]) xor FFMul(e, t[1, 3])
    xor FFMul(f, t[1, 0]);
  state[1, 2] := FFMul(c, t[1, 2]) xor FFMul(d, t[1, 3]) xor FFMul(e, t[1, 0])
    xor FFMul(f, t[1, 1]);
  state[1, 3] := FFMul(c, t[1, 3]) xor FFMul(d, t[1, 0]) xor FFMul(e, t[1, 1])
    xor FFMul(f, t[1, 2]);

  state[2, 0] := FFMul(c, t[2, 0]) xor FFMul(d, t[2, 1]) xor FFMul(e, t[2, 2])
    xor FFMul(f, t[2, 3]);
  state[2, 1] := FFMul(c, t[2, 1]) xor FFMul(d, t[2, 2]) xor FFMul(e, t[2, 3])
    xor FFMul(f, t[2, 0]);
  state[2, 2] := FFMul(c, t[2, 2]) xor FFMul(d, t[2, 3]) xor FFMul(e, t[2, 0])
    xor FFMul(f, t[2, 1]);
  state[2, 3] := FFMul(c, t[2, 3]) xor FFMul(d, t[2, 0]) xor FFMul(e, t[2, 1])
    xor FFMul(f, t[2, 2]);

  state[3, 0] := FFMul(c, t[3, 0]) xor FFMul(d, t[3, 1]) xor FFMul(e, t[3, 2])
    xor FFMul(f, t[3, 3]);
  state[3, 1] := FFMul(c, t[3, 1]) xor FFMul(d, t[3, 2]) xor FFMul(e, t[3, 3])
    xor FFMul(f, t[3, 0]);
  state[3, 2] := FFMul(c, t[3, 2]) xor FFMul(d, t[3, 3]) xor FFMul(e, t[3, 0])
    xor FFMul(f, t[3, 1]);
  state[3, 3] := FFMul(c, t[3, 3]) xor FFMul(d, t[3, 0]) xor FFMul(e, t[3, 1])
    xor FFMul(f, t[3, 2]);

end;

function TBTAES128.decryptFile(const f_key, encodedFile: string;
  out decodedFile: string): LongBool;
var
  f: TMemoryStream;
  decoder: TBTAES128;
  ret: Cardinal;
  cache: array of byte;
  vaildSize: UInt64;
begin
  Result := False;
  f := TMemoryStream.Create;
  decoder := TBTAES128.Create;
  try
    f.LoadFromFile(encodedFile);
    if f.Size = 0 then
      Exit;
    ret := f.Size mod 16;
    if ret <> 0 then
      Exit;
    SetLength(cache, f.Size);
    f.Position := 0;
    f.ReadBuffer(cache[0], f.Size);
    decoder.decrypt(f_key, cache, cache);
    vaildSize := PUInt64(@cache[f.Size - 8])^;
    if vaildSize = 0 then
      Exit;
    f.SetSize(vaildSize);
    f.Position := 0;
    f.WriteBuffer(cache[0], vaildSize);
    SetLength(cache, 0);
    f.SaveToFile(decodedFile);
    Result := True;
  finally
    f.Free;
    decoder.Free;
  end;

end;

function TBTAES128.encryptFile(const f_key, originalFile: string;
  out encodedFile: string): LongBool;
var
  f: TMemoryStream;
  encoder: TBTAES128;
  ret: Cardinal;
  cache: array of byte;
  alignedSize: UInt64;
begin
  Result := False;
  f := TMemoryStream.Create;
  encoder := TBTAES128.Create;
  try
    f.LoadFromFile(originalFile);
    if f.Size = 0 then
      Exit;

    ret := (f.Size + 8) mod 16;
    if ret = 0 then
      alignedSize := f.Size + 8
    else
      alignedSize := f.Size + 8 + 16 - ret;
    SetLength(cache, alignedSize);
    f.Position := 0;
    f.ReadBuffer(cache[0], f.Size);
    PUInt64(@cache[alignedSize - 8])^ := f.Size;
    encoder.encrypt(f_key, cache, cache);
    f.Position := 0;
    f.WriteBuffer(cache[0], alignedSize);
    SetLength(cache, 0);
    f.SaveToFile(encodedFile);
  finally
    f.Free;
    encoder.Free;
  end;

end;


function TBTAES128.encryptStr(const f_key, originalStr: string;
  Out encodedStr: String;encodeBase64:LongBool = False): LongBool;
var
  strSrc: string;
  strDst: String;
  strSize: Integer;
  encoder: TBTAES128;
  ret: Cardinal;
  cache: array of byte;
  alignedSize: Integer;
begin
  Result := False;
  if originalStr = '' then
    Exit;
  strSrc := originalStr;
    encoder := TBTAES128.Create;
  try
    strSize := length(strSrc) * 2;// do not include NUL
    ret := strSize mod 16;
    if ret = 0 then
      alignedSize := strSize + 16
    else
    alignedSize := strSize + 16 - ret;
    SetLength(cache, alignedSize);   //make sure , size of cache is multi times with 16 bytes
    Move(strSrc[1], cache[0], strSize);
    FillChar(cache[strSize], 16 - ret, 16 - ret);
    encoder.encrypt(f_key, cache, cache);
    if encodeBase64 then
    begin
     strDst:=EncdDecd.EncodeBase64(@cache[0],alignedSize);
    end
    else
    SetString(strDst,PWideChar(@cache[0]),alignedSize shr 1);

    encodedStr := strDst;
    Result := True;
  finally
    SetLength(cache, 0);
    encoder.Free;
  end;

end;

function TBTAES128.decryptStr(const f_key, encodedStr: String;
  Out decodedStr: string;decodeBase64:LongBool = False): LongBool;
var
  str_base64E: AnsiString;
  str_Src_AES: String;
  strDst: String;
  strSize: Integer;
  decoder: TBTAES128;
  cache:TBytes;
  alignedSize: Integer;
begin
  Result := False;
  if encodedStr = '' then
    Exit;

  decoder := TBTAES128.Create;
  try
    str_base64E := encodedStr;
    if decodeBase64 then
    begin
     cache:=EncdDecd.DecodeBase64(str_base64E);
    alignedSize := Length(cache);
    if (alignedSize mod 16) <> 0 then Exit;
    end
    else
    begin
       str_Src_AES:=encodedStr;
       alignedSize:= Length(str_Src_AES)*2;
       if (alignedSize mod 16) <> 0 then Exit;
       SetLength(cache,alignedSize);
       Move(str_Src_AES[1],cache[0],alignedSize);
    end;
    decoder.decrypt(f_key, cache, cache);
    strSize := cache[alignedSize - 1];
    strSize := alignedSize - strSize;
    SetString(strDst, PWideChar(@cache[0]), strSize shr 1);
    decodedStr := strDst;
    Result := True;
  finally
    SetLength(cache, 0);
    decoder.Free;
  end;

end;

end.
