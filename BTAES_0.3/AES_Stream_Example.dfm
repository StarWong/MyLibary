object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Stream_Test: AES128 + Base64'
  ClientHeight = 336
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 120
    Top = 32
    Width = 489
    Height = 13
    AutoSize = False
  end
  object SpeedButton1: TSpeedButton
    Left = 144
    Top = 88
    Width = 66
    Height = 57
    Caption = #21152#23494#23383#31526#20018
    OnClick = SpeedButton1Click
  end
  object SpeedButton2: TSpeedButton
    Left = 144
    Top = 208
    Width = 66
    Height = 57
    Caption = #35299#23494#23383#31526#20018
    OnClick = SpeedButton2Click
  end
  object Button1: TButton
    Left = 32
    Top = 24
    Width = 75
    Height = 25
    Caption = #35835#20837
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 32
    Top = 160
    Width = 75
    Height = 25
    Caption = #21152#23494
    TabOrder = 1
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 32
    Top = 240
    Width = 75
    Height = 25
    Caption = #35299#23494
    TabOrder = 2
    OnClick = Button3Click
  end
  object eMemo2: TMemo
    Left = 224
    Top = 72
    Width = 385
    Height = 89
    TabOrder = 3
  end
  object dMemo1: TMemo
    Left = 224
    Top = 192
    Width = 385
    Height = 89
    TabOrder = 4
  end
  object FileOpenDialog1: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 64
    Top = 56
  end
end
