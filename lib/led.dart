// @dart = 2.9
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:untitled5/switch.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;
  const ChatPage({this.server});
  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.text,this.whom);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection connection;

  List<_Message> messages = <_Message>[];
  String _messageBuffer = '';

  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;
  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });
      connection.input.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  List<String> values;
  double _value = 90.0;
  @override
  Widget build(BuildContext context) {
    final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(_message.text.trim()),
            style: TextStyle(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
                color:
                    _message.whom == clientID ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();
    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting chat to ' + widget.server.name + '...')
              : isConnected
                  ? Text('Live chat with ' + widget.server.name)
                  : Text('Chat log with ' + widget.server.name))),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(height: 10),
            BatteryPercentage(battery()),
            SizedBox(height: 15),
            sensor("Current             ", current()),
            SizedBox(height: 5),
            sensor("Ultrasonic        ", ultrasonic()),
            SizedBox(height: 5),
            sensor("Servo Position", servo()),
            SizedBox(height: 15),
            LiteRollingSwitch(
              value: true,
              text: 'Water Pump',
              onChanged:(bool pos){
                if(pos)_sendMessage('2'); else _sendMessage('4');
              },
            ),
            SizedBox(height: 10),
            LiteRollingSwitch(
              value: true,
              text: 'Stirer Motor',
              onChanged:(bool pos){
                if(pos)_sendMessage('6'); else _sendMessage('8');
              },
            ),
            SizedBox(height: 10),
            LiteRollingSwitch(
              value: true,
              text: 'Solar Panel',
              onChanged:(bool pos){
                if(pos)_sendMessage('1'); else _sendMessage('3');
              },
            ),
            SizedBox(height: 15),
            Flexible(
              child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  controller: listScrollController,
                  children: list
              ),
            ),
            Row(
              children: <Widget>[
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16.0),
                    child: TextField(
                      style: const TextStyle(fontSize: 15.0),
                      controller: textEditingController,
                      decoration: InputDecoration.collapsed(
                        hintText: isConnecting
                            ? 'Wait until connected...'
                            : isConnected
                            ? 'Type your message...'
                            : 'Chat got disconnected',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      enabled: isConnected,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8.0),
                  child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: isConnected
                          ? () => _sendMessage(textEditingController.text)
                          : null),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String u = '0';
  String s = '0';
  String b = '0';
  String c = '0';

  String ultrasonic(){
    String x = '';
    if((messages.length != 0) && (messages.length != 1)){
      x = messages[messages.length - 1].text.trim();
      if(x[0] == 'U'){
        setState(() {
          if(x.length == 14) u = x[13];
          else if(x.length == 15) u = x[13]+x[14];
        });
      }
    }
    return u;
  }
  String current(){
    String x = '';
    if((messages.length != 0) && (messages.length != 1)){
      x = messages[messages.length - 1].text.trim();
      if(x[0] == 'C'){
        setState(() {
          c = x[10] + x[11] + x[12] + x[13];
        });
      }
    }
    return c;
  }
  String servo(){
    String x = '';
    if((messages.length != 0) && (messages.length != 1)){
      x = messages[messages.length - 1].text.trim();
      if(x[0] == 'S'){
        setState(() {
          if(x.length == 17) s = x[16];
          else if(x.length == 18) s = x[16]+x[17];
          else if(x.length == 19) s = x[16]+x[17]+x[18];
        });
      }
    }
    return s;
  }
  String battery(){
    String x = '';
    if((messages.length != 0) && (messages.length != 1)){
      x = messages[messages.length - 1].text.trim();
      if(x[0] == 'B'){
        setState(() {
          if(x.length == 18) b = x[17];
          else if(x.length == 19) b = x[17]+x[18];
        });
      }
    }
    return b;
  }

  Widget sensor(String s, r){
    return Row(
      children: <Widget>[
        SizedBox(width: 20),
        Container(
          height: 35,
          width: 170,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(s, style:TextStyle(fontSize: 20)),
            ],
          ),
        ),
        SizedBox(width: 40),
        Container(
          height: 35,
          width: 100,
          child: Text(r, style:TextStyle(fontSize: 20), textAlign: TextAlign.center),
          decoration: BoxDecoration(
              color: Color.fromRGBO(192, 255, 224, 1.0),
              border: Border.all(
                color: Colors.green,
                width: 3,
              )
          ),
        )
      ],
    );
  }
  Widget BatteryPercentage(String s){
    return Row(
      children: <Widget>[
        Container(
          height: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(width: 20),
                  Text("Battery Percentage : ", style: TextStyle(fontSize:26, fontWeight:FontWeight.bold)),
                  Text(s + " " + "%", style: TextStyle(color: Colors.green, fontSize:26, fontWeight:FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }
    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(backspacesCounter > 0 ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
              : _messageBuffer + dataString.substring(0, index),
            1
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }
  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text + "\r\n"));
        await connection.output.allSent;

        setState(() {
          messages.add(_Message( text, clientID,));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}