program BTAES128;
{$APPTYPE CONSOLE}

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

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  BTAES in 'BTAES.pas',
  BTAESUtil in 'BTAESUtil.pas',
  BTAESBox in 'BTAESBox.pas';

var
  inFile: file;
  outFile: file;
  TempFileMode: Byte;
  Mode: byte;
  BTAES128Instance: TBTAES128;
begin
  if (ParamStr(1) = '') or
    (ParamStr(2) = '') or
    (ParamStr(3) = '') or
    (ParamStr(4) = '') then begin
    writeln('error: not enougth parameters');
    exit;
  end;
  if ParamStr(1) = 'e' then
    mode := 0
  else if ParamStr(1) = 'd' then
    mode := 1
  else begin
    writeln('error: selected mode is not supported');
    exit;
  end;
  writeln;
  writeln('BTAES v0.3');
  writeln('----------');
  Assign(infile, paramstr(3));
  TempFileMode := FileMode;
  FileMode := $0000; // openread mode
  reset(infile, 1);
  FileMode := TempFileMode;
  Assign(outfile, paramstr(4));
  TempFileMode := FileMode;
  FileMode := $0001; // openwrite mode
  rewrite(outfile, 1);
  FileMode := TempFileMode;
  BTAES128Instance := TBTAES128.Create;
  BTAES128Instance.selfTest;
  writeln;
  // encrypting
  if mode = 0 then begin
    write('encrypting');
    BTAES128Instance.encrypt(ParamStr(2), inFile, outFile);
  end;
  if mode = 1 then begin
    write('decrypting');
    BTAES128Instance.decrypt(ParamStr(2), infile, outFile);
  end;
  writeln;
  writeln;
  write('finished ');
  write(FileSize(infile));
  write(' bytes');
  writeln;
  writeln;
  closefile(infile);
  closefile(outFile);
  BTAES128Instance.Destroy;
end.

