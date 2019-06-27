import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:jenkins/util/custom_spinkit.dart';

class MonitorScreen extends StatefulWidget {
  @override
  _MonitorScreen createState() => _MonitorScreen();
}

class _MonitorScreen extends State<MonitorScreen> with TickerProviderStateMixin{

  RefreshController _controller;
  AnimationController _anicontroller,_scaleController;
  String msg;

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
  }

  void dispose() {
    super.dispose();
  }

  void _onRefresh() async {
    print('refresh');
    Future.delayed(const Duration(milliseconds: 500)).then((onValue) {
      _controller.refreshCompleted();
      setState(() {
      });
    });
  }

  void _onOffsetChange(bool up,double offset){
    if(up&&(_controller.headerStatus==RefreshStatus.idle||_controller.headerStatus==RefreshStatus.canRefresh)){
      // 80.0 is headerTriggerDistance default value
      _scaleController.value = offset/80.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new SmartRefresher(
        controller: _controller,
        onOffsetChange: _onOffsetChange,
        enablePullDown: true,
        enablePullUp: true,
        onRefresh: _onRefresh,
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
                        color: index.isEven ? Colors.red : Colors.green,
                      ),
                    );
                  },
                ),
                scale: _scaleController,
              ),
              alignment: Alignment.topCenter,
              color: Colors.white,
            );
          },
        ),
        child: new Center(
          child: new Padding(
            child: msg==null?new Text('ready'):new Text(msg),
            padding: EdgeInsets.all(20),
          ),
        ),
    );
  }
}