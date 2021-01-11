unit SysExtraFunc;
interface
type
  TEXEVersionData = record
    CompanyName,
    FileDescription,
    FileVersion,
    InternalName,
    LegalCopyright,
    LegalTrademarks,
    OriginalFileName,
    ProductName,
    ProductVersion,
    Comments,
    PrivateBuild,
    SpecialBuild: string;
  end;

function GetEXEVersionDataW(const FileName: UnicodeString;var verInfo:TEXEVersionData):LongBool;

implementation
uses
Windows,SysUtils;

function GetEXEVersionDataW(const FileName: UnicodeString;var verInfo:TEXEVersionData):LongBool;
type
  PLandCodepage = ^TLandCodepage;
  TLandCodepage = record
    wLanguage,
    wCodePage: word;
  end;
var
  dummy,len: cardinal;
  buf:array of Byte;
  pntr: Pointer;
  lang: UnicodeString;
begin
  Result:=False;
  len := GetFileVersionInfoSizeW(PwideChar(FileName), dummy);
  if len = 0 then
    Exit;
    buf:=nil;
  try
    SetLength(buf,len);
    if not GetFileVersionInfoW(PwideChar(FileName), 0, len, buf) then
      exit;

    if not VerQueryValueW(buf, '\VarFileInfo\Translation\', pntr, len) then
      exit;

    lang := Format('%.4x%.4x', [PLandCodepage(pntr)^.wLanguage, PLandCodepage(pntr)^.wCodePage]);

    if VerQueryValueW(buf, PwideChar('\StringFileInfo\' + lang + '\CompanyName'), pntr, len){ and (@len <> nil)} then
      verInfo.CompanyName := PwideChar(pntr);
    if VerQueryValueW(buf, PwideChar('\StringFileInfo\' + lang + '\FileDescription'), pntr, len){ and (@len <> nil)} then
      verInfo.FileDescription := PwideChar(pntr);
    if VerQueryValueW(buf, PwideChar('\StringFileInfo\' + lang + '\FileVersion'), pntr, len){ and (@len <> nil)} then
      verInfo.FileVersion := PwideChar(pntr);
    if VerQueryValueW(buf, PwideChar('\StringFileInfo\' + lang + '\InternalName'), pntr, len){ and (@len <> nil)} then
      verInfo.InternalName := PwideChar(pntr);
    if VerQueryValueW(buf, PwideChar('\StringFileInfo\' + lang + '\LegalCopyright'), pntr, len){ and (@len <> nil)} then
      verInfo.LegalCopyright := PwideChar(pntr);
    if VerQueryValueW(buf, PwideChar('\StringFileInfo\' + lang + '\LegalTrademarks'), pntr, len){ and (@len <> nil)} then
      verInfo.LegalTrademarks := PwideChar(pntr);
    if VerQueryValueW(buf, PwideChar('\StringFileInfo\' + lang + '\OriginalFileName'), pntr, len){ and (@len <> nil)} then
      verInfo.OriginalFileName := PwideChar(pntr);
    if VerQueryValueW(buf, PwideChar('\StringFileInfo\' + lang + '\ProductName'), pntr, len){ and (@len <> nil)} then
      verInfo.ProductName := PwideChar(pntr);
    if VerQueryValueW(buf, PwideChar('\StringFileInfo\' + lang + '\ProductVersion'), pntr, len){ and (@len <> nil)} then
      verInfo.ProductVersion := PwideChar(pntr);
    if VerQueryValueW(buf, PwideChar('\StringFileInfo\' + lang + '\Comments'), pntr, len){ and (@len <> nil)} then
      verInfo.Comments := PwideChar(pntr);
    if VerQueryValueW(buf, PwideChar('\StringFileInfo\' + lang + '\PrivateBuild'), pntr, len){ and (@len <> nil)} then
      verInfo.PrivateBuild := PwideChar(pntr);
    if VerQueryValueW(buf, PwideChar('\StringFileInfo\' + lang + '\SpecialBuild'), pntr, len){ and (@len <> nil)} then
      verInfo.SpecialBuild := PwideChar(pntr);
      Result:=True;
  finally
   IF buf <> nil then SetLength(buf,0);
  end;
end;

end.
