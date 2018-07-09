object trmSocketForm: TtrmSocketForm
  Left = 447
  Top = 207
  AutoScroll = False
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'TSS Admin'
  ClientHeight = 455
  ClientWidth = 502
  Color = clBtnFace
  Constraints.MinHeight = 415
  Constraints.MinWidth = 510
  ParentFont = True
  OldCreateOrder = True
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object mainPanel: TPanel
    Left = 0
    Top = 0
    Width = 502
    Height = 455
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 0
    object Pages: TPageControl
      Left = 1
      Top = 1
      Width = 500
      Height = 453
      ActivePage = PropPage
      Align = alClient
      TabOrder = 0
      OnChange = PagesChange
      object PropPage: TTabSheet
        Caption = 'Settings'
        object gbSrvSett: TGroupBox
          Left = 0
          Top = 33
          Width = 492
          Height = 142
          Align = alTop
          Caption = 'Server settings'
          TabOrder = 0
          object gbSocket: TGroupBox
            Left = 122
            Top = 0
            Width = 370
            Height = 70
            Anchors = [akLeft, akTop, akRight]
            Caption = 'Socket'
            TabOrder = 1
            object llistenport: TLabel
              Left = 8
              Top = 20
              Width = 68
              Height = 13
              Alignment = taRightJustify
              Caption = '&Listen on Port:'
            end
            object linactivetimeout: TLabel
              Left = 7
              Top = 44
              Width = 82
              Height = 13
              Alignment = taRightJustify
              Caption = '&Inactive Timeout:'
            end
            object ApplyButton: TButton
              Tag = -1
              Left = 180
              Top = 36
              Width = 75
              Height = 24
              Action = ApplyAction
              Anchors = [akLeft, akBottom]
              TabOrder = 0
            end
            object PortNo: TRxSpinEdit
              Left = 91
              Top = 13
              Width = 84
              Height = 21
              MaxValue = 65535
              MinValue = 1
              Value = 1
              MaxLength = 5
              TabOrder = 1
              OnExit = IntegerExit
            end
            object Timeout: TRxSpinEdit
              Left = 91
              Top = 39
              Width = 85
              Height = 21
              MaxValue = 2880
              MaxLength = 4
              TabOrder = 2
              OnExit = IntegerExit
            end
          end
          object gbSystem: TGroupBox
            Left = 122
            Top = 61
            Width = 370
            Height = 81
            Anchors = [akLeft, akTop, akRight]
            Caption = 'System'
            TabOrder = 2
            object cbRegisteredOnly: TCheckBox
              Left = 8
              Top = 16
              Width = 149
              Height = 17
              Action = RegisteredAction
              State = cbChecked
              TabOrder = 0
            end
            object gbCPUAffinity: TGroupBox
              Left = 0
              Top = 36
              Width = 370
              Height = 45
              Caption = 'CPU Affinity'
              TabOrder = 1
              object cbCPU0: TCheckBox
                Tag = 1
                Left = 8
                Top = 15
                Width = 65
                Height = 17
                Caption = 'CPU 0'
                TabOrder = 0
              end
              object cbCPU1: TCheckBox
                Tag = 2
                Left = 78
                Top = 15
                Width = 65
                Height = 17
                Caption = 'CPU 1'
                Enabled = False
                TabOrder = 1
              end
              object btnApplyAffinity: TButton
                Tag = -1
                Left = 180
                Top = 13
                Width = 75
                Height = 24
                Anchors = [akLeft, akBottom]
                Caption = 'Apply'
                Enabled = False
                TabOrder = 2
                OnClick = btnApplyAffinityClick
              end
            end
          end
          object gbPorts: TGroupBox
            Left = 0
            Top = 0
            Width = 124
            Height = 142
            Caption = 'Ports'
            TabOrder = 0
            object pnlPorts: TPanel
              Left = 2
              Top = 13
              Width = 53
              Height = 127
              BevelOuter = bvLowered
              TabOrder = 0
              object PortList: TListBox
                Left = 1
                Top = 1
                Width = 51
                Height = 125
                Align = alClient
                BorderStyle = bsNone
                ItemHeight = 13
                TabOrder = 0
                OnClick = PortListClick
              end
            end
            object btnPortAdd: TButton
              Left = 59
              Top = 22
              Width = 57
              Height = 23
              Action = AddPortAction
              TabOrder = 1
            end
            object btnPortRemove: TButton
              Left = 59
              Top = 50
              Width = 57
              Height = 23
              Action = RemovePortAction
              TabOrder = 2
            end
          end
        end
        object pnlConnect: TPanel
          Left = 0
          Top = 0
          Width = 492
          Height = 33
          Align = alTop
          BevelInner = bvRaised
          BevelOuter = bvLowered
          TabOrder = 1
          object btConnect: TToolbarButton97
            Left = 196
            Top = 5
            Width = 23
            Height = 23
            Action = ConnectedAction
            AllowAllUp = True
            GroupIndex = 2
            Glyph.Data = {
              86040000424D8604000000000000760000002800000064000000140000000100
              0400000000001004000000000000000000001000000000000000000000000000
              8000008000000080800080000000800080008080000080808000C0C0C0000000
              FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
              8888888888888888888888888888888888888888888888888888888888888888
              8888888888888888888888880000888888888888888888888888888888888888
              8888888888888888888888888888888888888888888888888888888888888888
              0000888088888888888888888888888888888888888888888888888888888888
              8888888888888888888888888888888888888888000088080888888888888888
              8880888888888888888888808888888888888888888088888888888888888880
              8888888888888888000088808000008888888888880808888888888888888808
              0888888888888888880808888888888888888808088888888888888800008888
              0076660888888888888080000088888888888880800000888888888888808000
              008888888888888080000088888888880000888880BBB7608888888888880076
              6608888888888888007666088888888888880076660888888888888800766608
              88888888000088880BBB766088888888888880BBB76088888888888880BBB760
              88888888888880BBB76088888888888880BBB76088888888000088880BB7BB08
              8888888888880BBB76600888888888880BBB76600888888888880BBB76600888
              888888880BBB76600888888800008888087BB0880088888888880BB7BB066088
              888888880BB7BB066088888888880BB7BB066088888888880BB7BB0660888888
              00008888808B08806608888888880F7BB0BB7608888888880F7BB0BB76088888
              88880F7BB0BB7608888888880F7BB0BB76088888000088888800880BB7608888
              888880FB0BB766088888888880FB0BB766088888888880FB0BB7660888888888
              80FB0BB76608888800008888888880BB7660888888888800BB7BB60888888888
              8800BB7BB608888888888800BB7BB608888888888800BB7BB608888800008888
              88880BB7BB60888888888880F7BBB708888888888880F7BBB708888888888880
              F7BBB708888888888880F7BBB7088888000088888888087BBB70888888888888
              0FBB70088888888888880FBB70088888888888880FBB70088888888888880FBB
              70088888000088888888808BB700888888888888800700808888888888888007
              0080888888888888800700808888888888888007008088880000888888888800
              7008088888888888888888080888888888888888880808888888888888888808
              0888888888888888880808880000888888888888888080888888888888888880
              8888888888888888888088888888888888888880888888888888888888808888
              0000888888888888888888888888888888888888888888888888888888888888
              8888888888888888888888888888888888888888000088888888888888888888
              8888888888888888888888888888888888888888888888888888888888888888
              88888888888888880000}
            ModalResult = 6
            NumGlyphs = 5
            ParentShowHint = False
            ShowBorderWhenInactive = True
            ShowHint = True
          end
          object meCCIP: TMaskEdit
            Left = 6
            Top = 6
            Width = 186
            Height = 21
            TabOrder = 0
            OnKeyPress = meCCIPKeyPress
          end
        end
      end
      object StatPage: TTabSheet
        Caption = 'Connections'
        object UserStatus: TStatusBar
          Left = 0
          Top = 406
          Width = 492
          Height = 19
          Action = UpdateStatusAction
          Panels = <>
          SimplePanel = True
        end
        object pnlConnectBtns: TPanel
          Left = 0
          Top = 0
          Width = 492
          Height = 23
          Align = alTop
          BevelOuter = bvLowered
          TabOrder = 1
          object sbDisconnect: TButton
            Left = 1
            Top = 1
            Width = 80
            Height = 21
            Hint = 'Disconnect'
            Action = DisconnectAction
            Caption = 'Disconnect'
            ParentShowHint = False
            ShowHint = True
            TabOrder = 0
          end
          object sbRefresh: TButton
            Left = 199
            Top = 1
            Width = 80
            Height = 21
            Hint = 'Refresh (Ctrl+R)'
            Action = RefreshAction
            Anchors = [akLeft, akTop, akBottom]
            ParentShowHint = False
            ShowHint = True
            TabOrder = 2
          end
          object pnlShowHostName: TPanel
            Left = 80
            Top = 1
            Width = 119
            Height = 21
            BevelInner = bvLowered
            BevelOuter = bvSpace
            TabOrder = 1
            object cbShowHostName: TCheckBox
              Left = 4
              Top = 2
              Width = 110
              Height = 17
              Action = ShowHostAction
              TabOrder = 0
            end
          end
          object pnlAcceptStop: TPanel
            Left = 455
            Top = 1
            Width = 36
            Height = 21
            Align = alRight
            TabOrder = 3
            object btnAcceptStop: TToolbarButton97
              Left = 0
              Top = 0
              Width = 36
              Height = 21
              Action = AcceptAction
              AllowAllUp = True
              GroupIndex = 2
              Glyph.Data = {
                86040000424D8604000000000000760000002800000064000000140000000100
                0400000000001004000000000000000000001000000000000000000000000000
                8000008000000080800080000000800080008080000080808000C0C0C0000000
                FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
                8888888888888888888888888888888888888888888888888888888888888888
                8888888888888888888888880000888888888888888888888888888888888888
                8888888888888888888888888888888888888888888888888888888888888888
                0000888888888888888888888888888888888888888888888888888888888888
                8888888888888888888888888888888888888888000088888888888888888888
                8888888888888888888888888888888888888888888888888888888888888888
                8888888888888888000088877777788777777888888777777887777778888887
                7888888888888888888078888888888888888880777778807777788800008887
                7777788777777888888777777887777778888887777888888888888888802778
                8888888888888880977778809777788800008887777778877777788888877777
                7887777778888887777778888888888888802227788888888888888099997880
                9999788800008887777778877777788888877777788777777888888777777777
                8888888888802222277788888888888099997880999978880000888777777887
                7777788888877777788777777888888777777777778888888880222222277788
                8888888099997880999978880000888777777887777778888887777778877777
                7888888777777777777778888880222222227777788888809999788099997888
                0000888777777887777778888887777778877777788888877777777777777888
                8880222222222700088888809999788099997888000088877777788777777888
                8887777778877777788888877777777777888888888022222222008888888880
                9999788099997888000088877777788777777888888777777887777778888887
                7777777788888888888022222000888888888880999978809999788800008887
                7777788777777888888777777887777778888887777778888888888888802220
                0888888888888880999978809999788800008887777778877777788888877777
                7887777778888887777888888888888888802008888888888888888099997880
                9999788800008887777778877777788888877777788777777888888778888888
                8888888888800888888888888888888000000880000008880000888888888888
                8888888888888888888888888888888888888888888888888888888888888888
                8888888888888888888888880000888888888888888888888888888888888888
                8888888888888888888888888888888888888888888888888888888888888888
                0000888888888888888888888888888888888888888888888888888888888888
                8888888888888888888888888888888888888888000088888888888888888888
                8888888888888888888888888888888888888888888888888888888888888888
                88888888888888880000}
              NumGlyphs = 5
              OldDisabledStyle = True
              ParentShowHint = False
              ShowBorderWhenInactive = True
              ShowHint = True
            end
          end
        end
        object pnlConnections: TPanel
          Left = 0
          Top = 23
          Width = 492
          Height = 383
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pnlConnectList: TPanel
            Left = 0
            Top = 0
            Width = 394
            Height = 383
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object ConnectionList: TListView
              Left = 0
              Top = 0
              Width = 394
              Height = 383
              Align = alClient
              Columns = <
                item
                  Caption = 'Port'
                  Width = 32
                end
                item
                  Caption = 'IP Address'
                  Width = 90
                end
                item
                  AutoSize = True
                  Caption = 'Host'
                end
                item
                  Caption = 'Connected'
                  Width = 120
                end
                item
                  Caption = 'Last Activity'
                  Width = 120
                end>
              FlatScrollBars = True
              HideSelection = False
              MultiSelect = True
              ReadOnly = True
              RowSelect = True
              ShowWorkAreas = True
              TabOrder = 0
              ViewStyle = vsReport
              OnColumnClick = ConnectionListColumnClick
              OnCompare = ConnectionListCompare
            end
          end
          object pnlPermit: TPanel
            Left = 394
            Top = 0
            Width = 98
            Height = 383
            Align = alRight
            BevelOuter = bvNone
            TabOrder = 1
            TabStop = True
            object pnlNewIP: TPanel
              Left = 0
              Top = 0
              Width = 98
              Height = 58
              Align = alTop
              BevelInner = bvLowered
              BevelOuter = bvNone
              TabOrder = 0
              object meNewIP: TMaskEdit
                Left = 0
                Top = 19
                Width = 98
                Height = 21
                TabOrder = 0
                OnKeyPress = meNewIPKeyPress
              end
              object btnPermAdd: TButton
                Left = 1
                Top = 39
                Width = 48
                Height = 18
                Action = AddPermitAction
                TabOrder = 1
              end
              object btnPermRem: TButton
                Left = 48
                Top = 39
                Width = 48
                Height = 18
                Action = RemovePermitAction
                TabOrder = 2
              end
              object pnlPermHead: TPanel
                Left = 1
                Top = 1
                Width = 96
                Height = 19
                Align = alTop
                Caption = 'Permittions'
                TabOrder = 3
              end
            end
            object pnlPermitIP: TPanel
              Left = 0
              Top = 58
              Width = 98
              Height = 325
              Align = alClient
              BevelOuter = bvNone
              Caption = 'pnlPermitIP'
              TabOrder = 1
              object lvPermit: TListView
                Left = 0
                Top = 0
                Width = 98
                Height = 325
                Align = alClient
                Columns = <
                  item
                    AutoSize = True
                    Caption = 'IP Address'
                  end>
                FlatScrollBars = True
                HideSelection = False
                MultiSelect = True
                ReadOnly = True
                RowSelect = True
                ShowWorkAreas = True
                TabOrder = 0
                ViewStyle = vsReport
                OnColumnClick = lvPermitColumnClick
                OnCompare = lvPermitCompare
              end
            end
          end
        end
      end
    end
  end
  object mainActionList: TActionList
    Left = 70
    Top = 394
    object DisconnectAction: TAction
      ShortCut = 16430
      OnExecute = DisconnectActionExecute
      OnUpdate = DisconnectActionUpdate
    end
    object ShowHostAction: TAction
      Caption = 'Show Host Name'
      OnExecute = ShowHostActionExecute
    end
    object AddPortAction: TAction
      Caption = 'Add'
      OnExecute = AddPortActionExecute
      OnUpdate = AddPortActionUpdate
    end
    object RemovePortAction: TAction
      Caption = 'Remove'
      OnExecute = RemovePortActionExecute
      OnUpdate = RemovePortActionUpdate
    end
    object RegisteredAction: TAction
      Caption = 'Registered Objects Only'
      Checked = True
      OnExecute = RegisteredActionExecute
    end
    object ApplyAction: TAction
      Caption = 'Apply'
      OnExecute = ApplyActionExecute
      OnUpdate = ApplyActionUpdate
    end
    object GetConnectionsAction: TAction
      OnExecute = GetConnectionsActionExecute
    end
    object UpdateStatusAction: TAction
      Caption = 'UpdateStatusAction'
      OnUpdate = UpdateStatusActionUpdate
    end
    object ConnectedAction: TAction
      ShortCut = 49219
      OnExecute = ConnectedActionExecute
      OnUpdate = ConnectedActionUpdate
    end
    object DoubleRefreshAction: TAction
      ShortCut = 16466
      Visible = False
      OnExecute = RefreshActionExecute
    end
    object RefreshAction: TAction
      Caption = 'Refresh'
      Hint = 'Refresh'
      ShortCut = 116
      OnExecute = RefreshActionExecute
    end
    object AcceptAction: TAction
      ShortCut = 49235
      OnExecute = AcceptActionExecute
      OnUpdate = AcceptActionUpdate
    end
    object SelectAllAction: TAction
      ShortCut = 16449
      Visible = False
      OnExecute = SelectAllActionExecute
    end
    object RemovePermitAction: TAction
      Caption = 'Del'
      ShortCut = 46
      OnExecute = RemovePermitActionExecute
      OnUpdate = RemovePermitActionUpdate
    end
    object AddPermitAction: TAction
      Caption = 'Add'
      OnExecute = AddPermitActionExecute
      OnUpdate = AddPermitActionUpdate
    end
    object ParseIP_ConnectAction: TAction
      Caption = 'ParseIP_ConnectAction'
      OnExecute = ParseIP_ConnectActionExecute
    end
  end
  object ccGeneral: TControlConnection
    OnNotifyClientFromServer = ccGeneralNotifyClientFromServer
    Left = 25
    Top = 394
  end
  object mainFormStorage: TFormPlacement
    Left = 117
    Top = 394
  end
end
