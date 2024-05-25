import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'my_app_state.dart';

class UnexpectedPositionError extends Error {
  final String message;
  UnexpectedPositionError(this.message);

  @override
  String toString() => message;
}

class PreflopPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppState>(builder: (context, state, child) {
      List<String> positions = ['BB', 'SB', 'BTN', 'CO', 'HJ', 'LJ', 'UTG'];

      if (state.participants == 8) {
        positions.insert(6, 'UTG+1');
      } else if (state.participants == 9) {
        positions.insertAll(6, ['UTG+2', 'UTG+1']);
      } else {
        positions = positions.sublist(0, state.participants);
      }

      return Column(children: [
        Text('Small Blind: ${state.smallBlind}'),
        Text('Big Blind: ${state.bigBlind}'),
        Text('Ante: ${state.ante}'),
        Text('${state.participants} handed'),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RadioAction(
              positions: positions,
              bigBlindAmount: state.bigBlind,
            )
          ],
        ),
        ElevatedButton(
          onPressed: () {
            // blindページへ遷移
            state.updateSelectedIndex('participants');
          },
          child: Text('Blindに戻る'),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // TO BE IMPLEMENTED
          },
          child: Text('アクションを最初から登録し直す'),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            state.updateSelectedIndex('flop');
          },
          child: Text('Flopを入力'),
        ),
      ]);
    });
  }
}

class RadioAction extends StatefulWidget {
  final List<String> positions;
  final int bigBlindAmount;

  RadioAction({required this.positions, required this.bigBlindAmount});

  @override
  _RadioActionState createState() => _RadioActionState();
}

class _RadioActionState extends State<RadioAction> {
  late List<String> _positions;
  late int _bigBlindAmount;

  String? _utgSelectedAction = null;
  String? _utg1SelectedAction = null;
  String? _utg2SelectedAction = null;
  String? _ljSelectedAction = null;
  String? _hjSelectedAction = null;
  String? _coSelectedAction = null;
  String? _btnSelectedAction = null;
  String? _sbSelectedAction = null;
  String? _bbSelectedAction = null;

  int? _utgRaisedAmount = null;
  int? _utg1RaisedAmount = null;
  int? _utg2RaisedAmount = null;
  int? _ljRaisedAmount = null;
  int? _hjRaisedAmount = null;
  int? _coRaisedAmount = null;
  int? _btnRaisedAmount = null;
  int? _sbRaisedAmount = null;
  int? _bbRaisedAmount = null;

  int _currentTargetPosition = 0;
  int _round = 1;

  int _callAmount = 0;

  @override
  void initState() {
    super.initState();
    _positions = widget.positions;
    _bigBlindAmount = widget.bigBlindAmount;
    _currentTargetPosition = _positions.length - 1;
    _callAmount = _bigBlindAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppState>(builder: (context, state, children) {
      String? getActionStateFromCurrentTargetPosition({index: int}) {
        switch (_positions[index]) {
          case 'BB':
            return _bbSelectedAction;
          case 'SB':
            return _sbSelectedAction;
          case 'BTN':
            return _btnSelectedAction;
          case 'CO':
            return _coSelectedAction;
          case 'HJ':
            return _hjSelectedAction;
          case 'LJ':
            return _ljSelectedAction;
          case 'UTG+2':
            return _utg2SelectedAction;
          case 'UTG+1':
            return _utg1SelectedAction;
          case 'UTG':
            return _utgSelectedAction;
          default:
            throw UnexpectedPositionError(
                'unexpected position name is detected: ${_positions[_currentTargetPosition]}');
        }
      }

      int? getRaisedAmountFromIndex(int index) {
        switch (_positions[_positions.length - index - 1]) {
          case 'BB':
            return _bbRaisedAmount;
          case 'SB':
            return _sbRaisedAmount;
          case 'BTN':
            return _btnRaisedAmount;
          case 'CO':
            return _coRaisedAmount;
          case 'HJ':
            return _hjRaisedAmount;
          case 'LJ':
            return _ljRaisedAmount;
          case 'UTG+2':
            return _utg2RaisedAmount;
          case 'UTG+1':
            return _utg1RaisedAmount;
          case 'UTG':
            return _utgRaisedAmount;
          default:
            throw UnexpectedPositionError(
                'unexpected position name is detected: ${_positions[_currentTargetPosition]}');
        }
      }

      bool isRemainingAction() {
        // RaiseAmountに一つでもnullがあればまだactionしてない人がいる
        List<int?> amounts = [
          _bbRaisedAmount,
          _sbRaisedAmount,
          _btnRaisedAmount,
          _coRaisedAmount,
          _hjRaisedAmount,
          _ljRaisedAmount,
          _utg2RaisedAmount,
          _utg1RaisedAmount,
          _utgRaisedAmount
        ];

        List<int?> actual_players_amoounts =
            amounts.sublist(0, _positions.length);

        var null_action_is_included =
            actual_players_amoounts.any((element) => element == null);

        if (null_action_is_included) {
          return true;
        }

        // RaiseAmountにnullがなく、0ではない人のamountがすべて等しければこのroundは終了している
        List<int?> raised_or_called_players_amounts = [];
        raised_or_called_players_amounts =
            actual_players_amoounts.where((e) => e != 0).toList();
        var all_active_player_raised_same_amount =
            raised_or_called_players_amounts.every(
                (element) => element == raised_or_called_players_amounts[0]);

        // 全員の金額が揃っているなら、Actionは残っていない
        return !all_active_player_raised_same_amount;
      }

      void _handleRadioValueChange({String? value}) {
        String position = _positions[_currentTargetPosition];

        setState(() {
          switch (position) {
            case 'BB':
              _bbSelectedAction = value;
              if (value == 'call') {
                _bbRaisedAmount = _callAmount;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _bbSelectedAction,
                    amount: _bbRaisedAmount);
              } else if (value == 'fold') {
                _bbRaisedAmount = 0;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _bbSelectedAction,
                    amount: _bbRaisedAmount);
              }
              break;
            case 'SB':
              _sbSelectedAction = value;
              if (value == 'call') {
                _sbRaisedAmount = _callAmount;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _sbSelectedAction,
                    amount: _sbRaisedAmount);
              } else if (value == 'fold') {
                _sbRaisedAmount = 0;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _sbSelectedAction,
                    amount: _sbRaisedAmount);
              }
              break;
            case 'BTN':
              _btnSelectedAction = value;
              if (value == 'call') {
                _btnRaisedAmount = _callAmount;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _btnSelectedAction,
                    amount: _btnRaisedAmount);
              } else if (value == 'fold') {
                _btnRaisedAmount = 0;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _btnSelectedAction,
                    amount: _btnRaisedAmount);
              }
              break;
            case 'CO':
              _coSelectedAction = value;
              if (value == 'call') {
                _coRaisedAmount = _callAmount;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _coSelectedAction,
                    amount: _coRaisedAmount);
              } else if (value == 'fold') {
                _coRaisedAmount = 0;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _coSelectedAction,
                    amount: _coRaisedAmount);
              }
              break;
            case 'HJ':
              _hjSelectedAction = value;
              if (value == 'call') {
                _hjRaisedAmount = _callAmount;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _hjSelectedAction,
                    amount: _hjRaisedAmount);
              } else if (value == 'fold') {
                _hjRaisedAmount = 0;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _hjSelectedAction,
                    amount: _hjRaisedAmount);
              }
              break;
            case 'LJ':
              _ljSelectedAction = value;
              if (value == 'call') {
                _ljRaisedAmount = _callAmount;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _ljSelectedAction,
                    amount: _ljRaisedAmount);
              } else if (value == 'fold') {
                _ljRaisedAmount = 0;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _ljSelectedAction,
                    amount: _ljRaisedAmount);
              }
              break;
            case 'UTG+2':
              _utg2SelectedAction = value;
              if (value == 'call') {
                _utg2RaisedAmount = _callAmount;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _utg2SelectedAction,
                    amount: _utg2RaisedAmount);
              } else if (value == 'fold') {
                _utg2RaisedAmount = 0;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _utg2SelectedAction,
                    amount: _utg2RaisedAmount);
              }
              break;
            case 'UTG+1':
              _utg1SelectedAction = value;
              if (value == 'call') {
                _utg1RaisedAmount = _callAmount;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _utg1SelectedAction,
                    amount: _utg1RaisedAmount);
              } else if (value == 'fold') {
                _utg1RaisedAmount = 0;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _utg1SelectedAction,
                    amount: _utg1RaisedAmount);
              }
              break;
            case 'UTG':
              _utgSelectedAction = value;
              if (value == 'call') {
                _utgRaisedAmount = _callAmount;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _utgSelectedAction,
                    amount: _utgRaisedAmount);
              } else if (value == 'fold') {
                _utgRaisedAmount = 0;
                state.updatePreflop(
                    round: _round,
                    position: position,
                    action: _utgSelectedAction,
                    amount: _utgRaisedAmount);
              }
              break;
            default:
              throw UnexpectedPositionError(
                  'unexpected position name is detected: $position');
          }

          for (var i = 0; i < state.preflop.length; i++) {
            print("round: ${state.preflop[i].round}");
            print("position: ${state.preflop[i].position}");
            print("action: ${state.preflop[i].action}");
            print("amount: ${state.preflop[i].amount}");
            print("currentTargetPosition: $_currentTargetPosition");
          }

          if (!isRemainingAction()) {
            // flop pageへ
            state.updateSelectedIndex('flop');
          }

          if (value != 'raise') {
            if (_currentTargetPosition > 0) {
              _currentTargetPosition -= 1;
            } else if (_currentTargetPosition == 0) {
              _currentTargetPosition = _positions.length - 1;
              _round += 1;
            }
          }
        });
      }

      void _handleRaisedAmountChange({required int amount}) {
        String position = _positions[_currentTargetPosition];

        setState(() {
          switch (position) {
            case 'BB':
              _bbRaisedAmount = amount;
              state.updatePreflop(
                  round: _round,
                  position: position,
                  action: _bbSelectedAction,
                  amount: _bbRaisedAmount);

              break;
            case 'SB':
              _sbRaisedAmount = amount;
              state.updatePreflop(
                  round: _round,
                  position: position,
                  action: _sbSelectedAction,
                  amount: _sbRaisedAmount);

              break;
            case 'BTN':
              _btnRaisedAmount = amount;
              state.updatePreflop(
                  round: _round,
                  position: position,
                  action: _btnSelectedAction,
                  amount: _btnRaisedAmount);

              break;
            case 'CO':
              _coRaisedAmount = amount;
              state.updatePreflop(
                  round: _round,
                  position: position,
                  action: _coSelectedAction,
                  amount: _coRaisedAmount);

              break;
            case 'HJ':
              _hjRaisedAmount = amount;
              state.updatePreflop(
                  round: _round,
                  position: position,
                  action: _hjSelectedAction,
                  amount: _hjRaisedAmount);

              break;
            case 'LJ':
              _ljRaisedAmount = amount;
              state.updatePreflop(
                  round: _round,
                  position: position,
                  action: _ljSelectedAction,
                  amount: _ljRaisedAmount);

              break;
            case 'UTG+2':
              _utg2RaisedAmount = amount;
              state.updatePreflop(
                  round: _round,
                  position: position,
                  action: _utg2SelectedAction,
                  amount: _utg2RaisedAmount);

              break;
            case 'UTG+1':
              _utg1RaisedAmount = amount;
              state.updatePreflop(
                  round: _round,
                  position: position,
                  action: _utg1SelectedAction,
                  amount: _utg1RaisedAmount);

              break;
            case 'UTG':
              _utgRaisedAmount = amount;
              state.updatePreflop(
                  round: _round,
                  position: position,
                  action: _utgSelectedAction,
                  amount: _utgRaisedAmount);

              break;
            default:
              throw UnexpectedPositionError(
                  'unexpected position name is detected: $position');
          }

          _callAmount = amount;

          for (var i = 0; i < state.preflop.length; i++) {
            print("round: ${state.preflop[i].round}");
            print("position: ${state.preflop[i].position}");
            print("action: ${state.preflop[i].action}");
            print("amount: ${state.preflop[i].amount}");
            print("currentTargetPosition: $_currentTargetPosition");
          }

          if (!isRemainingAction()) {
            // flop pageへ
            state.updateSelectedIndex('flop');
          }

          if (_currentTargetPosition > 0) {
            _currentTargetPosition -= 1;
          } else if (_currentTargetPosition == 0) {
            _currentTargetPosition = _positions.length - 1;
            _round += 1;
          }
        });
      }

      List<Widget> _widgets =
          List<Widget>.generate(state.preflop.length, (int index) {
        return Column(
          children: [
            Row(
              children: [
                Text(state.preflop[index].position),
                Expanded(
                  child: ListTile(
                    title: Text('Raise'),
                    leading: Radio<String>(
                      value: 'raise',
                      groupValue: state.preflop[index].action,
                      onChanged: (value) {},
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text('Call'),
                    leading: Radio<String>(
                      value: 'call',
                      groupValue: state.preflop[index].action,
                      onChanged: (value) {},
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text('Fold'),
                    leading: Radio<String>(
                      value: 'fold',
                      groupValue: state.preflop[index].action,
                      onChanged: (value) {},
                    ),
                  ),
                )
              ],
            ),
            state.preflop[index].action == 'raise'
                ? Text("amount: ${state.preflop[index].amount}")
                : Container()
          ],
        );
      });

      _widgets.add(Column(
        children: [
          Row(
            children: [
              Text(_positions[_currentTargetPosition]),
              Expanded(
                child: ListTile(
                  title: Text('Raise'),
                  leading: Radio<String>(
                      value: 'raise',
                      groupValue: getActionStateFromCurrentTargetPosition(
                          index: _currentTargetPosition),
                      onChanged: (value) {
                        _handleRadioValueChange(value: value);
                      }),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text('Call'),
                  leading: Radio<String>(
                      value: 'call',
                      groupValue: getActionStateFromCurrentTargetPosition(
                          index: _currentTargetPosition),
                      onChanged: (value) {
                        _handleRadioValueChange(value: value);
                      }),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text('Fold'),
                  leading: Radio<String>(
                      value: 'fold',
                      groupValue: getActionStateFromCurrentTargetPosition(
                          index: _currentTargetPosition),
                      onChanged: (value) {
                        _handleRadioValueChange(value: value);
                      }),
                ),
              ),
            ],
          ),
          getActionStateFromCurrentTargetPosition(
                      index: _currentTargetPosition) ==
                  'raise'
              ? RaisedAmountInputField(handler: _handleRaisedAmountChange)
              : Container()
        ],
      ));
      return Column(children: _widgets);
    });
  }
}

class RaisedAmountInputField extends StatefulWidget {
  final void Function({required int amount}) handler;

  RaisedAmountInputField({required this.handler});

  @override
  _RaisedAmountInputFieldState createState() => _RaisedAmountInputFieldState();
}

class _RaisedAmountInputFieldState extends State<RaisedAmountInputField> {
  final TextEditingController _controller = TextEditingController();
  late void Function({required int amount}) _handler;

  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _handler = widget.handler;
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        try {
          int amount = int.parse(_controller.text);
          _handler(amount: amount);
        } on FormatException {
          print("FormatException: ${_controller.text} が数字じゃない");
        }
      }
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller, // コントローラをTextFieldにセット
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly
      ],
      decoration: InputDecoration(
        labelText: 'raise額を入力',
        border: OutlineInputBorder(),
      ),
      focusNode: focusNode,
    );
  }
}
