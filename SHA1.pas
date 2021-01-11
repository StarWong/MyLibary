unit SHA1;

interface

uses
   SysUtils,Dialogs;

// No range and overflow checking, do not remove!!!
{$R-}
{$Q-}

function GetSha1(Buffer: pointer; Size: INTEGER): AnsiString;

implementation
type
   TLogicalFunction = function(B, C, D: INTEGER): INTEGER;

   TLogicalFunctions = array[0..3] of TLogicalFunction;

   TMessageBlock = array[0..15] of INTEGER;

   PMessageBlocks = ^TMessageBlocks;

   TMessageBlocks = array[0..0] of TMessageBlock;

   TWorkArray = array[0..79] of INTEGER;

   PLocalByteArray = ^TLocalByteArray;

   TLocalByteArray = array[0..0] of BYTE;

var
   LogicalFunctions: TLogicalFunctions;



function GetSha1(Buffer: pointer; Size: INTEGER): AnsiString;
const
   K: array[0..3] of Uint64 = ($5A827999, $6ED9EBA1, $8F1BBCDC, $CA62C1D6);
var
   A, B, C, D, E: INTEGER;
   H0, H1, H2, H3, H4: Uint64;
   TEMP: INTEGER;
   i, t, Index: INTEGER;
   W: TWorkArray;
   ATemp: INTEGER;
   BlockCount, BlockRest: INTEGER;
   LocalBuffer: pointer;
   NewSize: INTEGER;
   SizeBytes: array[0..3] of BYTE absolute Size;
   ByteArray: PLocalByteArray absolute LocalBuffer;
   MessageBlocks: PMessageBlocks absolute LocalBuffer;
label
   ConvertLoop;
begin
   Result := '';
   H0 := $67452301;
   H1 := $EFCDAB89;
   H2 := $98BADCFE;
   H3 := $10325476;
   H4 := $C3D2E1F0;
      // Compute message block count
   asm
        XOR     EDX, EDX
        MOV     EAX, Size
        MOV     ECX, 64
        DIV     ECX
        MOV     BlockCount, EAX
        MOV     BlockRest, EDX
   end;
   if (64 - BlockRest) >= 9 then
   begin
      Inc(BlockCount);
   end
   else
   begin
      if BlockRest = 0 then
      begin
         Inc(BlockCount)
      end
      else
      begin
         Inc(BlockCount, 2)
      end;
   end;
      // Alloc memory for local buffer
   NewSize := BlockCount * 64;
   GetMem(LocalBuffer, NewSize);
      // Copy data into local buffer
   asm
        PUSH    EDI
        PUSH    ESI
        MOV     EDI, LocalBuffer
        MOV     ESI, Buffer
        MOV     ECX, Size
        SHR     ECX, 2
        CLD
        REP     movsd
        XOR     EDX, EDX
        MOV     EAX, Size
        MOV     ECX, 4
        DIV     ECX
        MOV     ECX, EDX
        REP     movsb
        POP     ESI
        POP     EDI
   end;
      // Fill last block
   ByteArray[Size] := $80;
   for i := Size + 1 to NewSize - 9 do
   begin
      ByteArray[i] := 0
   end;
   Size := Size * 8;
      // Upper 32 Bits of Size, because cannot handle 64 Bit integers
   ByteArray[NewSize - 8] := 0;
   ByteArray[NewSize - 7] := 0;
   ByteArray[NewSize - 6] := 0;
   ByteArray[NewSize - 5] := 0;
      // Lower 32 Bits of Size
   ByteArray[NewSize - 4] := SizeBytes[3];
   ByteArray[NewSize - 3] := SizeBytes[2];
   ByteArray[NewSize - 2] := SizeBytes[1];
   ByteArray[NewSize - 1] := SizeBytes[0];
      // Convert byte order in local buffer
   asm
        MOV     ECX, NewSize
        SHR     ECX, 2
        MOV     EDX, LocalBuffer
        ConvertLoop :
        MOV     EAX, [EDX]
        BSWAP   EAX
        MOV     [EDX], EAX
        ADD     EDX, 4
        DEC     ECX
        JNZ     ConvertLoop
   end;
      // Process all message blocks
   for i := 0 to BlockCount - 1 do
   begin
          // a. Divide M(i) into 16 words W(0), W(1), ... , W(15), where W(0) is the
          //    left-most word.
      for t := 0 to 15 do
      begin
         W[t] := MessageBlocks[i][t]
      end;
          // b. For t = 16 to 79 let W(t) = S^1(W(t-3) XOR W(t-8) XOR W(t-14) XOR W(t-16)).
      for t := 16 to 79 do
      begin
         ATemp := W[t - 3] xor W[t - 8] xor W[t - 14] xor W[t - 16];
         asm
        MOV     EAX, ATemp
        ROL     EAX, 1
        MOV     ATemp, EAX
         end;
         W[t] := ATemp;
      end;
          // c. Let A = H0, B = H1, C = H2, D = H3, E = H4.
      A := H0;
      B := H1;
      C := H2;
      D := H3;
      E := H4;
          // d. For t = 0 to 79 do
          //      TEMP = S^5(A) + f(t;B,C,D) + E + W(t) + K(t);
          //      E = D;  D = C;  C = S^30(B);  B = A; A = TEMP;
      for t := 0 to 79 do
      begin
         asm
        MOV     EAX, A
        ROL     EAX, 5
        MOV     ATemp, EAX
         end;
         Index := t div 20;
         TEMP := ATemp + LogicalFunctions[Index](B, C, D) + E + W[t] + K[Index];
         E := D;
         D := C;
         asm
        MOV     EAX, B
        ROL     EAX, 30
        MOV     C, EAX
         end;
         B := A;
         A := TEMP;
      end;
          // e. Let H0 = H0 + A, H1 = H1 + B, H2 = H2 + C, H3 = H3 + D,
          //    H4 = H4 + E.

      H0 := (H0 + A) and $FFFFFFFF;
      H1 := (H1 + B) and $FFFFFFFF;
      H2 := (H2 + C) and $FFFFFFFF;
      H3 := (H3 + D) and $FFFFFFFF;
      H4 := (H4 + E) and $FFFFFFFF;
   end;
   FreeMem(LocalBuffer);

   Result := IntToHex(H0, 8)  + IntToHex(H1, 8)  + IntToHex(H2, 8)  +
      IntToHex(H3, 8)  + IntToHex(H4, 8);

end;

function f0(B, C, D: INTEGER): INTEGER; assembler;
asm
      // Result:=(B AND C)  OR  ((NOT B) AND D);
        PUSH    EBX
        MOV     EBX, EAX
        AND     EAX, EDX
        NOT     EBX
        AND     EBX, ECX
        OR      EAX, EBX
        POP     EBX
end;

function f1(B, C, D: INTEGER): INTEGER; assembler;
asm
      // Result:=(B  XOR   C)   XOR   D;
        XOR     EAX, EDX
        XOR     EAX, ECX
end;

function f2(B, C, D: INTEGER): INTEGER; assembler;
asm
      // Result:=(B AND C)  OR  (B AND D)  OR  (C AND D);
        PUSH    EBX
        MOV     EBX, EAX
        AND     EAX, EDX
        AND     EBX, ECX
        OR      EAX, EBX
        AND     EDX, ECX
        OR      EAX, EDX
        POP     EBX
end;

function f3(B, C, D: INTEGER): INTEGER; assembler;
asm
      // Result:=(B   XOR   C)   XOR  D;
        XOR     EAX, EDX
        XOR     EAX, ECX
end;

initialization

  // Initialize logical functions array
   LogicalFunctions[0] := f0;
   LogicalFunctions[1] := f1;
   LogicalFunctions[2] := f2;
   LogicalFunctions[3] := f3;

end.
