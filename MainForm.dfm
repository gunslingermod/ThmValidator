object Form1: TForm1
  Left = 554
  Top = 64
  Width = 338
  Height = 282
  Caption = 'THM Bump Path Validator'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  DesignSize = (
    322
    244)
  PixelsPerInch = 96
  TextHeight = 13
  object Log: TMemo
    Left = 8
    Top = 8
    Width = 313
    Height = 201
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object btn_validate: TButton
    Left = 8
    Top = 216
    Width = 105
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Validate THMs'
    TabOrder = 1
    OnClick = btn_validateClick
  end
  object check_autocorrect: TCheckBox
    Left = 216
    Top = 220
    Width = 97
    Height = 17
    Anchors = [akRight, akBottom]
    Caption = 'Autocorrection'
    TabOrder = 2
  end
  object opendialog: TOpenDialog
    Filter = 'THM files (*.thm)|*.thm'
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Left = 144
    Top = 216
  end
end
