object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'HTTPThreadPool-TestSuite'
  ClientHeight = 470
  ClientWidth = 635
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
    Top = 317
    Width = 635
    Height = 153
    Align = alBottom
    TabOrder = 0
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
      Caption = 'Concurrent workers'
    end
    object Label3: TLabel
      Left = 391
      Top = 51
      Width = 69
      Height = 13
      Caption = 'Spare workers'
    end
    object URLMemo: TMemo
      Left = 8
      Top = 24
      Width = 377
      Height = 121
      Lines.Strings = (
        'http://www.spiegel.de/'
        'http://www.spiegel.de/politik/'
        'http://www.spiegel.de/politik/deutschland/'
        'http://www.spiegel.de/politik/ausland/'
        'http://www.spiegel.de/wirtschaft/'
        'http://www.spiegel.de/wirtschaft/service/'
        'http://www.spiegel.de/wirtschaft/unternehmen/'
        'http://www.spiegel.de/wirtschaft/soziales/'
        'http://www.spiegel.de/panorama/'
        'http://www.spiegel.de/panorama/justiz/'
        'http://www.spiegel.de/panorama/leute/'
        'http://www.spiegel.de/panorama/gesellschaft/'
        'http://www.spiegel.de/sport/'
        'http://www.spiegel.de/sport/fussball/'
        'http://www.spiegel.de/sport/formel1/'
        'http://www.spiegel.de/sport/wintersport/'
        'http://www.spiegel.de/kultur/'
        'http://www.spiegel.de/kultur/kino/'
        'http://www.spiegel.de/kultur/musik/'
        'http://www.spiegel.de/kultur/tv/'
        'http://www.spiegel.de/kultur/literatur/'
        'http://www.spiegel.de/netzwelt/'
        'http://www.spiegel.de/netzwelt/netzpolitik/'
        'http://www.spiegel.de/netzwelt/web/'
        'http://www.spiegel.de/netzwelt/gadgets/'
        'http://www.spiegel.de/netzwelt/games/'
        'http://www.spiegel.de/wissenschaft/'
        'http://www.spiegel.de/wissenschaft/mensch/'
        'http://www.spiegel.de/wissenschaft/natur/'
        'http://www.spiegel.de/wissenschaft/technik/'
        'http://www.spiegel.de/wissenschaft/weltall/'
        'http://www.spiegel.de/wissenschaft/medizin/'
        'http://www.spiegel.de/unispiegel/'
        'http://www.spiegel.de/schulspiegel/'
        'http://www.spiegel.de/reise/'
        'http://www.spiegel.de/auto/')
      ScrollBars = ssBoth
      TabOrder = 0
    end
    object AddTasksButton: TButton
      Left = 527
      Top = 88
      Width = 98
      Height = 25
      Caption = 'Add tasks'
      TabOrder = 1
      OnClick = AddTasksButtonClick
    end
    object CancelTasksButton: TButton
      Left = 527
      Top = 119
      Width = 98
      Height = 25
      Caption = 'Cancel tasks'
      TabOrder = 2
      OnClick = CancelTasksButtonClick
    end
    object ConcurrentWorkersEdit: TJvSpinEdit
      Left = 391
      Top = 24
      Width = 121
      Height = 21
      CheckMinValue = True
      ButtonKind = bkClassic
      Value = 10.000000000000000000
      TabOrder = 3
      OnChange = ConcurrentWorkersEditChange
    end
    object SpareWorkersEdit: TJvSpinEdit
      Left = 391
      Top = 70
      Width = 121
      Height = 21
      CheckMinValue = True
      ButtonKind = bkClassic
      Value = 5.000000000000000000
      TabOrder = 4
      OnChange = SpareWorkersEditChange
    end
    object ProgressBar: TProgressBar
      Left = 391
      Top = 128
      Width = 121
      Height = 17
      TabOrder = 5
    end
  end
  object LogMemo: TMemo
    Left = 0
    Top = 0
    Width = 635
    Height = 317
    Align = alClient
    ScrollBars = ssVertical
    TabOrder = 1
  end
end
