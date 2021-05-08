object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 444
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
  object LogMemo: TMemo
    Left = 0
    Top = 0
    Width = 480
    Height = 444
    Align = alClient
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 480
    Top = 0
    Width = 155
    Height = 444
    Align = alRight
    TabOrder = 1
    object PageControl1: TPageControl
      Left = 1
      Top = 1
      Width = 153
      Height = 442
      ActivePage = TabSheet1
      Align = alClient
      TabOrder = 0
      object TabSheet1: TTabSheet
        Caption = 'Prime task'
        DesignSize = (
          145
          414)
        object Label2: TLabel
          Left = 3
          Top = 3
          Width = 86
          Height = 13
          Caption = 'Start with number'
        end
        object Label3: TLabel
          Left = 3
          Top = 56
          Width = 80
          Height = 13
          Caption = 'Range for a task'
        end
        object Label4: TLabel
          Left = 3
          Top = 112
          Width = 70
          Height = 13
          Caption = 'Count of tasks'
        end
        object Label1: TLabel
          Left = 3
          Top = 184
          Width = 95
          Height = 13
          Caption = 'Concurrent workers'
        end
        object Label5: TLabel
          Left = 3
          Top = 240
          Width = 69
          Height = 13
          Caption = 'Spare workers'
        end
        object StartNumberEdit: TEdit
          Left = 3
          Top = 22
          Width = 121
          Height = 21
          NumbersOnly = True
          TabOrder = 0
          Text = '0'
        end
        object TaskRangeEdit: TEdit
          Left = 3
          Top = 75
          Width = 121
          Height = 21
          NumbersOnly = True
          TabOrder = 1
          Text = '10000'
        end
        object ConcurrentWorkersEdit: TEdit
          Left = 3
          Top = 203
          Width = 121
          Height = 21
          NumbersOnly = True
          TabOrder = 3
          Text = '2'
          OnChange = ConcurrentWorkersEditChange
        end
        object TaskCountEdit: TEdit
          Left = 3
          Top = 131
          Width = 121
          Height = 21
          NumbersOnly = True
          TabOrder = 2
          Text = '100'
        end
        object AddPrimeTasksButton: TButton
          Left = 1
          Top = 315
          Width = 137
          Height = 25
          Anchors = [akLeft, akBottom]
          Caption = 'Add tasks'
          TabOrder = 5
          OnClick = AddPrimeTasksButtonClick
        end
        object TerminatePrimeManagerButton: TButton
          Left = 1
          Top = 386
          Width = 139
          Height = 25
          Anchors = [akLeft, akBottom]
          Caption = 'Terminate TPrimeManager'
          TabOrder = 6
          OnClick = TerminatePrimeManagerButtonClick
        end
        object SpareWorkersEdit: TEdit
          Left = 3
          Top = 261
          Width = 121
          Height = 21
          NumbersOnly = True
          TabOrder = 4
          Text = '0'
          OnChange = SpareWorkersEditChange
        end
        object CancelTasksButton: TButton
          Left = 1
          Top = 346
          Width = 137
          Height = 25
          Anchors = [akLeft, akBottom]
          Caption = 'Cancel tasks'
          TabOrder = 7
          OnClick = CancelTasksButtonClick
        end
        object PrimeProgressBar: TProgressBar
          Left = 3
          Top = 288
          Width = 126
          Height = 17
          TabOrder = 8
        end
      end
    end
  end
end
