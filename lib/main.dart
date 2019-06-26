import 'package:flutter/material.dart';

import 'package:jenkins/tab/buildScreen.dart';
import 'package:jenkins/tab/settingScreen.dart';
import 'package:jenkins/tab/monitorScreen.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Jenkins',
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DefaultTabController(
        length: 3,
        child: new Scaffold(
          appBar: new AppBar(
            title: new Text("KOCAP Jenkins"),
          ),
          body: TabBarView(
            children: <Widget>[
              new Container(
                child: BuildScreen(),
                color: Colors.white,
              ),
              new Container(
                child: MonitorScreen(),
                color: Colors.white
              ),
              new Container(
                child: SettingScreen(),
                color: Colors.white
              )
            ],
          ),
          bottomNavigationBar: new TabBar(
            isScrollable: false,
            tabs: <Widget>[
              Tab(
                icon: new Icon(Icons.build),
                text: "build",
              ),
              Tab(
                icon: new Icon(Icons.view_agenda),
                text: "monitor",
              ),
              Tab(
                icon: new Icon(Icons.settings_applications),
                text: "setting",
              )
            ],
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.black,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorPadding: EdgeInsets.all(5.0),
            indicatorColor: Colors.red,
          ),

        )
      )
    );
  }
}
