unit ZFHash;

{General Hash Unit: This unit defines the common types, functions, and
procedures. Via Hash descriptors and corresponding pointers, algorithms
can be searched by name or by ID. More important: all supported algorithms
can be used in the HMAC and KDF constructions.}


interface

(*************************************************************************

 DESCRIPTION     :  General hash unit: defines Algo IDs, digest types, etc

 REQUIREMENTS    :  TP5-7, D1-D7/D9-D10, FPC, VP

 EXTERNAL DATA   :  ---

 MEMORY USAGE    :  ---

 DISPLAY MODE    :  ---

 REFERENCES      :  ---

 Version  Date      Author      Modification
 -------  --------  -------     ------------------------------------------
 0.10     15.01.06  W.Ehrhardt  Initial version
 0.11     15.01.06  we          FindHash_by_ID, $ifdef DLL: stdcall
 0.12     16.01.06  we          FindHash_by_Name
 0.13     18.01.06  we          Descriptor fields HAlgNum, HSig
 0.14     22.01.06  we          Removed HSelfTest from descriptor
 0.14     31.01.06  we          RIPEMD-160, C_MinHash, C_MaxHash
 0.15     11.02.06  we          Fields: HDSize, HVersion, HPtrOID, HLenOID
 0.16     02.08.06  we          Packed arrays
 0.17     07.08.06  we          $ifdef BIT32: (const fname: shortstring...)
 0.18     07.08.06  we          C_HashVers = $00010002
 0.19     10.02.07  we          HashFile: no eof, XL and filemode via $ifdef
 0.20     18.02.07  we          MD4, C_HashVers = $00010003
 0.21     22.02.07  we          POID_Vec=^TOID_Vec, typed HPtrOID
 0.22     24.02.07  we          added some checks for HSig=C_HashSig
**************************************************************************)

(*-------------------------------------------------------------------------
 (C) Copyright 2006-2007 Wolfgang Ehrhardt

 This software is provided 'as-is', without any express or implied warranty.
 In no event will the authors be held liable for any damages arising from
 the use of this software.

 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:

 1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software in
    a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

 2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

 3. This notice may not be removed or altered from any source distribution.
----------------------------------------------------------------------------*)

{$i STD.INC}


type
  THashAlgorithm = (_MD4,_MD5,_RIPEMD160,_SHA1,_SHA224,_SHA256,_SHA384,_SHA512, _Whirlpool); {Supported hash algorithms}

const
  MaxBlockLen  = 128;        {Max. block length (buffer size), multiple of 4}
  MaxDigestLen = 64;         {Max. length of hash digest}
  MaxStateLen  = 16;         {Max. size of internal state}
  MaxOIDLen    = 9;          {Current max. OID length}
  C_HashSig    = $3D7A;      {Signature for Hash descriptor}
  C_HashVers   = $00010003;  {Version of Hash definitions}
  C_MinHash    = _MD4;       {Lowest  hash in THashAlgorithm}
  C_MaxHash    = _Whirlpool; {Highest hash in THashAlgorithm}

type
  THashState   = packed array[0..MaxStateLen-1] of longint;         {Internal state}
  THashBuffer  = packed array[0..MaxBlockLen-1] of byte;            {hash buffer block}
  THashDigest  = packed array[0..MaxDigestLen-1] of byte;           {hash digest}
  THashBuf32   = packed array[0..MaxBlockLen  div 4 -1] of longint; {type cast helper}
  THashDig32   = packed array[0..MaxDigestLen div 4 -1] of longint; {type cast helper}


type
  THashContext = packed record
                   Hash  : THashState;             {Working hash}
                   MLen  : packed array[0..3] of longint; {max 128 bit msg length}
                   Buffer: THashBuffer;            {Block buffer}
                   Index : integer;                {Index in buffer}
                 end;

type
  TMD4Digest    = packed array[0..15] of byte;  {MD4    digest   }
  TMD5Digest    = packed array[0..15] of byte;  {MD5    digest   }
  TRMD160Digest = packed array[0..19] of byte;  {RMD160 digest   }
  TSHA1Digest   = packed array[0..19] of byte;  {SHA1   digest   }
  TSHA224Digest = packed array[0..27] of byte;  {SHA224 digest   }
  TSHA256Digest = packed array[0..31] of byte;  {SHA256 digest   }
  TSHA384Digest = packed array[0..47] of byte;  {SHA384 digest   }
  TSHA512Digest = packed array[0..63] of byte;  {SHA512 digest   }
  TWhirlDigest  = packed array[0..63] of byte;  {Whirlpool digest}

type
  HashInitProc     = procedure(var Context: THashContext);
                      {-initialize context}
                      {$ifdef DLL} stdcall; {$endif}

  HashFinalProc    = procedure(var Context: THashContext; var Digest: THashDigest);
                      {-finalize calculation, clear context}
                      {$ifdef DLL} stdcall; {$endif}

  HashUpdateXLProc = procedure(var Context: THashContext; Msg: pointer; Len: longint);
                      {-update context with Msg data}
                      {$ifdef DLL} stdcall; {$endif}

type
  TOID_Vec  = packed array[1..MaxOIDLen] of longint; {OID vector}
  POID_Vec  = ^TOID_Vec;                             {ptr to OID vector}

type
  THashName = string[19];                      {Hash algo name type }
  PHashDesc = ^THashDesc;                      {Ptr to descriptor   }
  THashDesc = packed record
                HSig      : word;              {Signature=C_HashSig }
                HDSize    : word;              {sizeof(THashDesc)   }
                HDVersion : longint;           {THashDesc Version   }
                HBlockLen : word;              {Blocklength of hash }
                HDigestlen: word;              {Digestlength of hash}
                HInit     : HashInitProc;      {Init  procedure     }
                HFinal    : HashFinalProc;     {Final procedure     }
                HUpdateXL : HashUpdateXLProc;  {Update procedure    }
                HAlgNum   : longint;           {Algo ID, longint avoids problems with enum size/DLL}
                HName     : THashName;         {Name of hash algo   }
                HPtrOID   : POID_Vec;          {Pointer to OID vec  }
                HLenOID   : word;              {Length of OID vec   }
                HReserved : packed array[0..25] of byte;
              end;


procedure RegisterHash(AlgId: THashAlgorithm; PHash: PHashDesc);
  {-Register algorithm with AlgID and Hash descriptor PHash^}
  {$ifdef DLL} stdcall; {$endif}

function  FindHash_by_ID(AlgoID: THashAlgorithm): PHashDesc;
  {-Return PHashDesc of AlgoID, nil if not found/registered}
  {$ifdef DLL} stdcall; {$endif}

function  FindHash_by_Name(AlgoName: THashName): PHashDesc;
  {-Return PHashDesc of Algo with AlgoName, nil if not found/registered}
  {$ifdef DLL} stdcall; {$endif}


procedure HashFile({$ifndef BIT16} const fname: shortstring; {$else} fname: AnsiString; {$endif}
                   PHash: PHashDesc; var Digest: THashDigest; var buf;
                   bsize: {$ifdef WIN64}NativeInt{$else}word{$endif}; var Err: word);
  {-Calulate hash digest of file, buf: buffer with at least bsize bytes}
  {$ifdef DLL} stdcall; {$endif}

procedure HashUpdate(PHash: PHashDesc; var Context: THashContext; Msg: pointer; Len: word);
  {-update context with Msg data}
  {$ifdef DLL} stdcall; {$endif}

procedure HashFullXL(PHash: PHashDesc; var Digest: THashDigest; Msg: pointer; Len: longint);
  {-Calulate hash digest of Msg with init/update/final}
  {$ifdef DLL} stdcall; {$endif}

procedure HashFull(PHash: PHashDesc; var Digest: THashDigest; Msg: pointer; Len: word);
  {-Calulate hash digest of Msg with init/update/final}
  {$ifdef DLL} stdcall; {$endif}



implementation


var
  PHashVec : array[THashAlgorithm] of PHashDesc;
             {Hash descriptor pointers of all defined hash algorithms}

{---------------------------------------------------------------------------}
procedure RegisterHash(AlgId: THashAlgorithm; PHash: PHashDesc);
  {-Register algorithm with AlgID and Hash descriptor PHash^}
begin
  if (PHash<>nil) and
     (PHash^.HAlgNum=longint(AlgId)) and
     (PHash^.HSig=C_HashSig) and
     (PHash^.HDVersion=C_HashVers) and
     (PHash^.HDSize=sizeof(THashDesc)) then PHashVec[AlgId] := PHash;
end;


{---------------------------------------------------------------------------}
function FindHash_by_ID(AlgoID: THashAlgorithm): PHashDesc;
  {-Return PHashDesc of AlgoID, nil if not found/registered}
var
  p: PHashDesc;
  A: longint;
begin
  A := longint(AlgoID);
  FindHash_by_ID := nil;
  if (A>=ord(C_MinHash)) and (A<=ord(C_MaxHash)) then begin
    p := PHashVec[AlgoID];
    if (p<>nil) and (p^.HSig=C_HashSig) and (p^.HAlgNum=A) then FindHash_by_ID := p;
  end;
end;


{---------------------------------------------------------------------------}
function  FindHash_by_Name(AlgoName: THashName): PHashDesc;
  {-Return PHashDesc of Algo with AlgoName, nil if not found/registered}
var
  algo : THashAlgorithm;
  phash: PHashDesc;

  function StrUpcase(s: AnsiString): AnsiString;
    {-Upcase for strings}
  var
    i: integer;
  begin
    for i:=1 to length(s) do s[i] := upcase(s[i]);
    StrUpcase := s;
  end;

begin
  AlgoName := StrUpcase(Algoname);
  FindHash_by_Name := nil;
  for algo := C_MinHash to C_MaxHash do begin
    phash := PHashVec[algo];
    if (phash<>nil) and (AlgoName=StrUpcase(phash^.HName))
      and (phash^.HSig=C_HashSig) and (phash^.HAlgNum=longint(algo))
    then begin
      FindHash_by_Name := phash;
      exit;
    end;
  end;
end;


{---------------------------------------------------------------------------}
procedure HashUpdate(PHash: PHashDesc; var Context: THashContext; Msg: pointer; Len: word);
  {-update context with Msg data}
begin
  if PHash<>nil then with PHash^ do begin
    if HSig=C_HashSig then HUpdateXL(Context, Msg, Len);
  end;
end;


{---------------------------------------------------------------------------}
procedure HashFullXL(PHash: PHashDesc; var Digest: THashDigest; Msg: pointer; Len: longint);
  {-Calulate hash digest of Msg with init/update/final}
var
  Context: THashContext;
begin
  if PHash<>nil then with PHash^ do begin
    if HSig=C_HashSig then begin
      HInit(Context);
      HUpdateXL(Context, Msg, Len);
      HFinal(Context, Digest);
    end;
  end;
end;


{---------------------------------------------------------------------------}
procedure HashFull(PHash: PHashDesc; var Digest: THashDigest; Msg: pointer; Len: word);
  {-Calulate hash digest of Msg with init/update/final}
begin
  {test PHash<>nil in HashFullXL}
  HashFullXL(PHash, Digest, Msg, Len);
end;


{$i-} {Force I-}
{---------------------------------------------------------------------------}
procedure HashFile({$ifndef BIT16} const fname: shortstring; {$else} fname: AnsiString; {$endif}
                   PHash: PHashDesc; var Digest: THashDigest; var buf;
                   bsize: {$ifdef WIN64}NativeInt{$else}word{$endif}; var Err: word);
  {-Calulate hash digest of file, buf: buffer with at least bsize bytes}
var
  {$ifdef VirtualPascal}
    fms: word;
  {$else}
    fms: byte;
  {$endif}
  {$ifdef WIN32}
    L: longint;
  {$else}
    {$ifdef WIN64}
    L: Integer;
    {$else}
    L: word;
    {$endif}
  {$endif}
var
  Context: THashContext;
  f: file;
begin
  if (PHash=nil) or (Phash^.HSig<>C_HashSig) then begin
    Err := 204; {Invalid pointer}
    exit;
  end;
  fms := FileMode;
  {$ifdef VirtualPascal}
    FileMode := $40; {open_access_ReadOnly or open_share_DenyNone;}
  {$else}
    FileMode := 0;
  {$endif}
  system.assign(f, string(fname));
  system.reset(f,1);
  Err := IOResult;
  FileMode := fms;
  if Err<>0 then exit;
  with PHash^ do begin
    HInit(Context);
    L := bsize;
    while (Err=0) and (L=bsize) do begin
      system.blockread(f,buf,bsize,L);
      Err := IOResult;
      HUpdateXL(Context, @buf, L);
    end;
    system.close(f);
    if IOResult=0 then {};
    HFinal(Context, Digest);
  end;
end;


begin
  {Paranoia: initialize all descriptor pointers to nil (should}
  {be done by compiler/linker because array is in global data)}
  fillchar(PHashVec,sizeof(PHashVec),0);
end.

