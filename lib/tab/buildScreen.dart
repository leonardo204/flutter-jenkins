import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:jenkins/jsonProxy.dart';
import 'package:jenkins/util/jsonManager.dart';
import 'package:jenkins/tab/settingScreen.dart';
import 'package:jenkins/util/custom_spinkit.dart';
import 'package:web_socket_channel/io.dart';

class BuildScreen extends StatefulWidget {

  static bool bNetStatus = false;

  @override
  _BuildScreen createState() => _BuildScreen();
}

class _BuildScreen extends State<BuildScreen> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  SettingScreen setting = new SettingScreen();

  List<String> _sites = <String>[
    '',
    'TBROAD',
    'CJ',
    'JEJU',
    'HCN_XCAS',
    'DLIVE'
  ];
  String _site = '';

  List<String> _stbs = <String>[''];
  String _stb = '';
  List<String> newBoxes = new List<String>();

  List<String> _targets = <String>[
    '',
    'all',
    'nolog',
    'cd',
    'java',
    'log',
    'core',
    'java_usb',
    'log_usb'
  ];
  String _target = '';

  bool bSetBox = false;

  String defaultParamFile = 'json/defaultParam.json';
  var defaultParam = new JsonManager();
  var decodedDefaultInfo;

  static bool bLaunched = false;
  static bool _loadingActive = true;

  Color m_color;

  RefreshController _controller;
  AnimationController _anicontroller,_scaleController;
  IOWebSocketChannel channel;
  String gitCommit;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = new RefreshController(initialRefresh:false);
    _scaleController = AnimationController(value: 0.0,vsync: this,upperBound: 1.0);
    _anicontroller = AnimationController(vsync: this, duration: Duration(milliseconds: 2000));
    _controller.headerMode.addListener((){
      if(_controller.headerStatus == RefreshStatus.idle){
        _scaleController.value=0.0;
        _anicontroller.reset();
      }
      else if(_controller.headerStatus == RefreshStatus.refreshing){
        _anicontroller.repeat();
      }
    });
    _loadingActive = true;

    channel = IOWebSocketChannel.connect("ws://10.70.0.39:1337");
    print('channel: $channel');
    listen();
  }

  void listen() {
    if (channel != null) {
      channel.stream.listen((data) {
        print('recv: $data');
        setState((){gitCommit = data;});
      });
    } else {
      print("can't connect server");
    }
  }

  void dispose() {
    if (channel != null) channel.sink.close();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return new SmartRefresher(
        controller: _controller,
        onOffsetChange: _onOffsetChange,
        enablePullDown: true,
        enablePullUp: false,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        header: CustomHeader(
          refreshStyle: RefreshStyle.Behind,
          builder: (c,m){
            return Container(
              child: ScaleTransition(
                child: SpinKitFadingCircle(
                  size: 30.0,
                  animationController: _anicontroller,
                  itemBuilder: (_, int index) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white//.isEven ? Colors.red : Colors.green,
                      ),
                    );
                  },
                ),
                scale: _scaleController,
              ),
              alignment: Alignment.topCenter,
              color: Colors.lightBlue,
            );
          },
        ),
        child: _loadingActive ? loadingProgress() : _mainForm(),
    );
  }

  void _onRefresh() async {
    init();
    print('refresh start');

    await checkNetwork(false).then((s) {

      if (channel == null) {
        channel = IOWebSocketChannel.connect("ws://10.70.0.39:1337");
        listen();
      }
      setState(() {
        if(BuildScreen.bNetStatus) m_color = Colors.blue;
        else m_color = Colors.grey;
      });

      _controller.refreshCompleted();
      print('refresh finished');
    });
  }

  void _onLoading() {
    _controller.loadNoData();
  }

  void _onOffsetChange(bool up,double offset){
    if(up&&(_controller.headerStatus==RefreshStatus.idle||_controller.headerStatus==RefreshStatus.canRefresh)){
      // 80.0 is headerTriggerDistance default value
      _scaleController.value = offset/80.0;
    }
  }


  Future<void> runRemoteBuild() async {
    // param
    var param = decodedDefaultInfo['parameter'];
    defaultParam.setTarget(param);

    defaultParam.setValue("CHOOSE_STB", _stb);
    defaultParam.setValue("CHOOSE_TARGET", _target);

    // url
    String url = SettingScreen.user_addr + "/job/";
    url += _site + "/build?token=";
    url += _site + "_BUILD_TOKEN";
    url += "&json=" + json.encode(decodedDefaultInfo);

    print('final url: ${url}');

    // send request as POST

    //to authorization
    String username = SettingScreen.user_id;
    String password = SettingScreen.user_password;
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
    print('basicAuth=${basicAuth}');

    // send post request and print response
    var response = await http.post(
      url,
      headers: {'authorization': basicAuth},
    ).then((response) {
      print('resCode=${response.statusCode}');
      print('${response.body}');
    });
  }

  void dumpResult() {
    print('');
    print(" - DEFAULT CONFIG START DUMP -");
    print(decodedDefaultInfo['parameter']);
    print(" - END DUMP -");
    print('');
  }

  Future<bool> loadFiles() async {
    String myJson = await rootBundle.loadString(defaultParamFile);
    defaultParam.setJson(myJson);
    decodedDefaultInfo = json.decode(defaultParam.myJson);
    dumpResult();
    return true;
  }

  void _runJenkinsBuild() async {
    print(' - select option -');
    print('* site   : ${_site}');
    print('* stb    : ${_stb}');
    print("* target : ${_target}");

    if (await loadFiles() && bSetBox) {
      runRemoteBuild();
      setState(() {
        _site = '';
        _stb = '';
        _target = '';
        newBoxes.clear();
        bSetBox = false;
      });
      String title = "Successed";
      String body = "\n\nremote build call is completed!";
      _showDialog(title, body);
    } else {
      print('build failed');
    }
  }


  Future<void> _getStbLists(String site) async {
    print('select $site');

    if(channel != null) channel.sink.add(site);

    if (BuildScreen.bNetStatus) {
      JsonProxy jp = new JsonProxy();
      jp.getStbList(site).then((List l) => setStbs(l));
    } else {
      setStbs(null);
    }
  }

  void setStbs(List l) {
    _loadingActive = false;
    if (l != null && l[0] == '-1') {
      print("can't get stblists (invalid url)");
      String title = "Failed";
      String body = "\n\nCan't get stblists. \n\nCheck URL or Accounts are valid.";
      _showDialog(title, body);
    } else if (l != null) {
      newBoxes.clear();
      for (var n in l) {
        print('add box - ${n}');
        newBoxes.add(n);
      }
      bSetBox = true;
    } else {
      print("can't get stblists (network error)");
      String title = "Failed";
      String body = "\n\nCan't get stblists. \n\nCheck network is avaliable.";
      _showDialog(title, body);
    }

    if (bSetBox) {
      setState(() {
        _stb = newBoxes[0];
      });
    }
  }

  void _showDialog(String title, String body) {
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text(title),
          content: new Text(body),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _site = '';
                  _stb = '';
                  _target = '';
                  gitCommit = null;
                  newBoxes.clear();
                  bSetBox = false;
                  _loadingActive = false;
                });
              }
            )
          ],
        );
      }
    );
  }


  void doRunOrAlert(int statusCode) {
    if (statusCode == 200 || statusCode == 201) {
      print('check network ok');
      if (_site == '' && _stb == '' && _target == '') {
        String title = "Note";
        String body = "\n\nNetwork is avaliable!";
        _showDialog(title, body);
      } else if (bSetBox && _target != '') {
        _runJenkinsBuild();
      } else {
        String title = "Failed";
        String body = "\n\nCheck every items are selected";
        _showDialog(title, body);
      }
    } else {
      print('check network=${statusCode}');
      String title = "Failed";
      String body = "\n\nNetwork is unreachable \n\nor Something error";
      _showDialog(title, body);
    }
  }

  Future<void> checkNetwork(bool bSendResult) async {
    String url = SettingScreen.user_addr;
    String username = SettingScreen.user_id;
    String password = SettingScreen.user_password;
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    print('|CHECKNETWORK| url(${url}) -  id(${username})  alert(${bSendResult})');

    if (url == null || url.indexOf('http') != 0){
      print('|CHECKNETWORK| invalid url(${url})');
      _loadingActive = false;
      if (bSendResult) doRunOrAlert(500);
      return;
    }

    // send post request and print response
    try {
    var response = await http.post(
        url,
        headers: {'authorization': basicAuth},
      ).then((response) {
        print('|CHECKNETWORK| response.statusCode=${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          BuildScreen.bNetStatus = true;
        } else {
          BuildScreen.bNetStatus = false;
        }

        if (bSendResult) doRunOrAlert(response.statusCode);

      }).timeout(const Duration(seconds: 3));
    } on TimeoutException catch (e){
      String title = "Failed";
      String body = "\n\nRequest timeout.";
      if (bSendResult) _showDialog(title, body);
      BuildScreen.bNetStatus = false;
      _loadingActive = false;
      print('request timeout: ${e.toString()}');
    } on SocketException catch (e){
      String title = "Failed";
      String body = "\n\nNetwork is unreachable.";
      if (bSendResult) _showDialog(title, body);
      BuildScreen.bNetStatus = false;
      _loadingActive = false;
      print('|CHECKNETWORK| socket error: ${e.toString()}');
    } catch (e) {
      String title = "Failed";
      String body = "\n\nUnexpected error.";
      if (bSendResult) _showDialog(title, body);
      BuildScreen.bNetStatus = false;
      _loadingActive = false;
      print('error: ${e.toString()}');
    }
  }

  void setColor() async {
    print('setColor() called');
    await checkNetwork(false).then((s) {
      print('setColor(${BuildScreen.bNetStatus})');
      if(BuildScreen.bNetStatus)
        m_color = Colors.blue;
      else
        m_color = Colors.grey;

      setState(() {
        _loadingActive = false;
      });
    });

  }

  void loadSettings() async {
    print('loadSettings(launched: ${bLaunched})');
    if (bLaunched == false) {
      Future<Null> status = await setting.createState().loadFiles().then((status) {
        print('|loadSettings| status=${status}');
        //if (status != null && status == true) {
          String url = SettingScreen.user_addr;
          String username = SettingScreen.user_id;
          print('|WIDGET| url(${url}) -  id(${username}) loading completed');

          // 최초 앱 실행 시 1회만 팝업을 띄우지 않도록 한다.
          if (bLaunched==false) {
            bLaunched = true;
          }

          if (m_color == null) setColor();
        //}
      });
    } else {
      if (m_color == null) {
        setColor();
        setState(() {
          _loadingActive = true;
        });
      }
    }
  }

  void init() {
    setState( () {
      _site = '';
      _stb = '';
      _target = '';
      newBoxes.clear();
      bSetBox = false;
      _loadingActive = false;
      gitCommit = null;
      channel = null;
    });
  }

  Form loadingProgress() {
    loadSettings();

    return new Form (
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: <Widget>[
                      getSiteForm2(),
                      getStbForm2(),
                      getTargetForm2(),
                      new Padding(
                        padding: const EdgeInsets.only(left: 0.0, top: 50.0, bottom: 100.0),
                        child: CircularProgressIndicator()
                      ),
                    ],
                  )
                )
              );
  }

  FormField getTargetForm() {
    return new FormField(
      builder: (FormFieldState state) {
        return InputDecorator(
          decoration: InputDecoration(
            icon: const Icon(Icons.tv),
            labelText: 'CHOOSE_TARGET',
          ),
          isEmpty: _target == '',
          child: new DropdownButtonHideUnderline(
            child: new DropdownButton(
              value: _target,
              isDense: true,
              onChanged: (String newValue) {
                setState(() {
                  _target = newValue;
                  state.didChange(newValue);
                });
              },
              items: _targets.map((String value) {
                return new DropdownMenuItem(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  FormField getTargetForm2() {
    return new FormField(
      builder: (FormFieldState state) {
        return InputDecorator(
          decoration: InputDecoration(
            icon: const Icon(Icons.tv),
            labelText: 'CHOOSE_TARGET',
          ),
          isEmpty: _target == '',
          child: new DropdownButtonHideUnderline(
            child: new DropdownButton(
              value: _target,
              isDense: true,
              onChanged: (String newValue) {
              },
              items: _targets.map((String value) {
                return new DropdownMenuItem(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  FormField getSiteForm() {
    return new FormField(
      builder: (FormFieldState state) {
        return InputDecorator(
          decoration: InputDecoration(
            icon: const Icon(Icons.local_atm),
            labelText: 'CHOOSE_SITE',
          ),
          isEmpty: _site == '',
          child: new DropdownButtonHideUnderline(
            child: new DropdownButton(
              value: _site,
              isDense: true,
              onChanged: (String newValue) {
                setState(() {
                  _site = newValue;
                  _getStbLists(_site);
                  _loadingActive = true;
                  state.didChange(newValue);
                });
              },
              items: _sites.map((String value) {
                return new DropdownMenuItem(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  FormField getSiteForm2() {
    return new FormField(
      builder: (FormFieldState state) {
        return InputDecorator(
          decoration: InputDecoration(
            icon: const Icon(Icons.local_atm),
            labelText: 'CHOOSE_SITE',
          ),
          isEmpty: _site == '',
          child: new DropdownButtonHideUnderline(
            child: new DropdownButton(
              value: _site,
              isDense: true,
              onChanged: (String newValue) {
              },
              items: _sites.map((String value) {
                return new DropdownMenuItem(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  FormField getStbForm2() {

    return new FormField(
      builder: (FormFieldState state) {
        return InputDecorator(
          decoration: InputDecoration(
            icon: const Icon(Icons.check_box),
            labelText: 'CHOOSE_STB',
          ),
          isEmpty: _stb == '',
          child: new DropdownButtonHideUnderline(
            child: new DropdownButton(
              value: _stb,
              isDense: true,
              onChanged: (String newValue) {
              },
              items: null,
            ),
          ),
        );
      },
    );
  }

  FormField getStbForm() {
    List<String> boxes = new List<String>();
    if (bSetBox) {
      boxes = newBoxes.toList();
    } else {
      boxes = _stbs.toList();
    }

    return new FormField(
      builder: (FormFieldState state) {
        return InputDecorator(
          decoration: InputDecoration(
            icon: const Icon(Icons.check_box),
            labelText: 'CHOOSE_STB',
          ),
          isEmpty: _stb == '',
          child: new DropdownButtonHideUnderline(
            child: new DropdownButton(
              value: _stb,
              isDense: true,
              onChanged: (String newValue) {
                setState(() {
                  _stb = newValue;
                  state.didChange(newValue);
                });
              },
              items: boxes.map((String value) {
                return new DropdownMenuItem(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget getGitHash(){
    return gitCommit==null?new Container():new Text(
      gitCommit,
      style: new TextStyle(
        color: Colors.black,
        fontSize: 10
      ),
    );
  }

  Form _mainForm() {
    loadSettings();

    return new Form (
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: <Widget>[
                      getSiteForm(),
                      getGitHash(),
                      getStbForm(),
                      getTargetForm(),
                      new Container(
                        width: 150,
                        height: 200,
                        padding: const EdgeInsets.only(
                            left: 0.0, top: 50.0, bottom: 100.0),
                        child: new RaisedButton(
                            child: new Text(
                              'Run Build',
                              style: new TextStyle(
                                color: Colors.white
                              ),
                            ),
                            onPressed: () {
                              print('onPressed() called');
                              checkNetwork(true);
                              setState( (){
                                _loadingActive = true;
                              });
                            },
                            color: m_color,
                          ),
                      )
                    ],
                  )
                )
              );
  }


}
