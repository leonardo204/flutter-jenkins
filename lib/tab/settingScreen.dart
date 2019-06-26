import 'package:flutter/material.dart';
import 'package:jenkins/util/jsonManager.dart';
import 'dart:convert';
import 'package:jenkins/util/sysInfo.dart';

class SettingScreen extends StatefulWidget {
  // static String addr = "http://10.70.0.39:8091";
  // static String username = "kocap";
  // static String password = "11dc2a34fe38a012ab68046eb47cb2275b";

  static String user_addr;
  static String user_id;
  static String user_password;

  @override
  _Setting createState() => _Setting();
}

class _Setting extends State<SettingScreen>  {

  SettingScreen instance = new SettingScreen();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); 

  String sysInfoFile = 'json/serverInfo.json';
  var sysInfo = new JsonManager();
  var finSysInfo;

  String temp = SettingScreen.user_addr;

  void _save() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      print('addr: ${SettingScreen.user_addr}');
      print('id: ${SettingScreen.user_id}');
      print('Password: ${SettingScreen.user_password}');

      // 저장한다. user.json에

      setState((){
      });
    }
  }

  void _reset() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      print('reset()');
      loadFiles().whenComplete(setParams);
      // remove user.json 
    }
  }

  void setParams() {
    SettingScreen.user_addr = finSysInfo.server_address;
    SettingScreen.user_id = finSysInfo.id;
    SettingScreen.user_password = finSysInfo.password;
        
    setState((){
    });
  }

  Future<bool> loadFiles() async {
    bool status = await sysInfo.loadJsonFile(sysInfoFile, true).then((status) {
      if (status) {
        var decodedSysInfo = json.decode(sysInfo.myJson);
        finSysInfo = SysInfo.fromJson(decodedSysInfo);
        SettingScreen.user_addr = finSysInfo.server_address;
        SettingScreen.user_id = finSysInfo.id;
        SettingScreen.user_password = finSysInfo.password;
      }
      print('|SETTING| load completed = (${status})');
      return status;
    });
  }

  final FocusNode _addressFocus = FocusNode();
  final FocusNode _idFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  Widget build(BuildContext context) {
    // print('addr: ${SettingScreen.user_addr}');
    // print('id: ${SettingScreen.user_id}');
    // print('Password: ${SettingScreen.user_password}');
    return new Scaffold(
        appBar: null,
        body: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  // address
                  new TextFormField(
                    controller: TextEditingController(text: SettingScreen.user_addr),
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.computer),
                      hintText: 'http://ip:port',
                      labelText: 'ADDRESS',
                    ),
                    onFieldSubmitted: (String value) {
                      print('input address: ${value}');
                    },
                    validator: (value) => value.isEmpty?"mandatory":null,
                    focusNode: _addressFocus,
                    onSaved: (String url) {
                      SettingScreen.user_addr = url;
                      _addressFocus.unfocus();
                    },
                  ),
                  // id
                  new TextFormField(
                    keyboardType: TextInputType.text,
                    controller: TextEditingController(text: SettingScreen.user_id),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.person),
                      hintText: 'id',
                      labelText: 'USERNAME',
                    ),
                    onFieldSubmitted: (String value) {
                      print('input id: ${value}');
                    },
                    validator: (value) => value.isEmpty?"mandatory":null,
                    focusNode: _idFocus,
                    onSaved: (String id) {
                      SettingScreen.user_id = id;
                      _idFocus.unfocus();
                    },
                  ),
                  // password
                  new TextFormField(
                    obscureText: true,
                    keyboardType: TextInputType.text,
                    controller: TextEditingController(text: SettingScreen.user_password),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.vpn_key),
                      hintText: 'password',
                      labelText: 'PASSWORD OR TOKEN',
                    ),
                    onFieldSubmitted: (String value) {
                      print('input password: ${value}');
                    },
                    validator: (value) => value.isEmpty?"mandatory":null,
                    focusNode: _passwordFocus,
                    onSaved: (String password) {
                      SettingScreen.user_password = password;
                      _passwordFocus.unfocus();
                    },
                  ),
                  // save
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget> [
                      new Container(
                        width: 100,
                        child: new RaisedButton(
                          child: new Text(
                            'Save',
                            style: new TextStyle(
                              color: Colors.white
                            ),
                          ),
                          onPressed: this._save,
                          color: Colors.blue,
                        ),
                        margin: new EdgeInsets.only(
                          left: 30,
                          top: 20.0,
                        ),
                      ),
                      new Container(
                        width: 100,
                        child: new RaisedButton(
                          child: new Text(
                            'Reset',
                            style: new TextStyle(
                              color: Colors.white
                            ),
                          ),
                          onPressed: this._reset,
                          color: Colors.blue,
                        ),
                        margin: new EdgeInsets.only(
                          left: 20,
                          top: 20.0,
                        ),
                      ),
                    ]
                  ),
                ],
              )
          )
        )
      );
  }
}