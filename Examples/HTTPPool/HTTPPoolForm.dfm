object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'HTTPThreadPool-TestSuite'
  ClientHeight = 526
  ClientWidth = 632
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 373
    Width = 632
    Height = 153
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 317
    ExplicitWidth = 635
    DesignSize = (
      632
      153)
    object Label1: TLabel
      Left = 8
      Top = 6
      Width = 24
      Height = 13
      Caption = 'URLs'
    end
    object Label2: TLabel
      Left = 391
      Top = 6
      Width = 95
      Height = 13
      Anchors = [akTop, akRight]
      Caption = 'Concurrent workers'
    end
    object Label3: TLabel
      Left = 391
      Top = 51
      Width = 69
      Height = 13
      Anchors = [akTop, akRight]
      Caption = 'Spare workers'
    end
    object URLMemo: TMemo
      Left = 8
      Top = 24
      Width = 377
      Height = 121
      Anchors = [akLeft, akTop, akRight]
      Lines.Strings = (
        'https://www.tagesschau.de/'
        'https://www.tagesschau.de/inland/'
        'https://www.tagesschau.de/inland/innenpolitik/'
        'https://www.tagesschau.de/inland/gesellschaft/'
        'https://www.tagesschau.de/regional/'
        'https://www.tagesschau.de/inland/deutschlandtrend/'
        'https://www.tagesschau.de/wahl/'
        'https://www.tagesschau.de/ausland/'
        'https://www.tagesschau.de/ausland/europa/'
        'https://www.tagesschau.de/ausland/amerika/'
        'https://www.tagesschau.de/ausland/afrika/'
        'https://www.tagesschau.de/ausland/asien/'
        'https://www.tagesschau.de/ausland/ozeanien/'
        'https://www.tagesschau.de/wirtschaft/'
        'https://www.tagesschau.de/wirtschaft/boersenkurse/'
        'https://www.tagesschau.de/wirtschaft/finanzen/'
        'https://www.tagesschau.de/wirtschaft/unternehmen/'
        'https://www.tagesschau.de/wirtschaft/verbraucher/'
        'https://www.tagesschau.de/wirtschaft/technologie/'
        'https://www.tagesschau.de/wirtschaft/konjunktur/'
        'https://www.tagesschau.de/wirtschaft/weltwirtschaft/'
        'https://www.tagesschau.de/investigativ/'
        'https://www.tagesschau.de/faktenfinder/'
        'https://www.tagesschau.de/wetter/'
        'https://www.tagesschau.de/multimedia/'
        'https://www.tagesschau.de/multimedia/livestreams/'
        'https://www.tagesschau.de/100sekunden/'
        'https://www.tagesschau.de/multimedia/letzte_sendung/'
        'https://www.tagesschau.de/sendung/tagesschau/')
      ScrollBars = ssBoth
      TabOrder = 0
    end
    object AddTasksButton: TButton
      Left = 527
      Top = 88
      Width = 98
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Add tasks'
      TabOrder = 1
      OnClick = AddTasksButtonClick
    end
    object CancelTasksButton: TButton
      Left = 527
      Top = 119
      Width = 98
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Cancel tasks'
      TabOrder = 2
      OnClick = CancelTasksButtonClick
    end
    object ProgressBar: TProgressBar
      Left = 391
      Top = 128
      Width = 121
      Height = 17
      Anchors = [akTop, akRight]
      TabOrder = 3
    end
    object ConcurrentWorkersEdit: TSpinEdit
      Left = 391
      Top = 23
      Width = 121
      Height = 22
      Anchors = [akTop, akRight]
      MaxValue = 0
      MinValue = 0
      TabOrder = 4
      Value = 10
    end
    object SpareWorkersEdit: TSpinEdit
      Left = 391
      Top = 70
      Width = 121
      Height = 22
      Anchors = [akTop, akRight]
      MaxValue = 0
      MinValue = 0
      TabOrder = 5
      Value = 5
    end
  end
  object LogMemo: TMemo
    Left = 0
    Top = 0
    Width = 632
    Height = 373
    Align = alClient
    ScrollBars = ssVertical
    TabOrder = 1
    ExplicitWidth = 635
    ExplicitHeight = 317
  end
end
