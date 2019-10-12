///ONE首页

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_one_app/api/api.dart';
import 'package:flutter_one_app/application/app.dart';
import 'package:flutter_one_app/entity/one_list_entity.dart';
import 'package:flutter_one_app/entity/one_page_item_entity.dart';
import 'package:flutter_one_app/events/one_tool_bar_list_event.dart';
import 'package:flutter_one_app/pages/one/one_page_item.dart';
import 'package:flutter_one_app/utils/date_utils.dart';
import 'package:flutter_one_app/utils/net_utils.dart';
import 'package:flutter_one_app/utils/refresh_utils.dart';
import 'package:flutter_one_app/widgets/loading_widget.dart';

class OnePage extends StatefulWidget {
  OnePage({Key key}) : super(key: key);

  @override
  _OnePageState createState() {
    return _OnePageState();
  }
}

class _OnePageState extends State<OnePage> with TickerProviderStateMixin {
  List<String> _oneList;
  List<OnePageItemData> _data = List();
  EasyRefreshController _controller = EasyRefreshController();
  static int _index = 0;
  static bool _isShowBody = true;

  Animation _animation;
  AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    initAnimation();
    getOneList();
  }

  void initAnimation() {
    _animationController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 200));
    _animation = new Tween(begin: 0.0, end: 0.5).animate(_animationController);
  }

  void changeOpacity(bool expand) {
    setState(() {
      if (expand) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void getOneList() {
    NetUtils.get(
      Api.idListUrl,
      success: (response) {
        setState(() {
          _oneList = OneListEntity.fromJson(json.decode(response)).data;
          _index = 0;
          _data.clear();
        });
        getData(_oneList[_index]);
      },
      fail: (exception) {},
    );
  }

  void getData(String id) {
    NetUtils.get(
      Api.getOneList(id),
      success: (response) {
        OnePageItemData onePageItemData =
            OnePageItemEntity.fromJson(json.decode(response)).data;
        if (onePageItemData != null) {
          setState(() {
            _data.add(onePageItemData);
            _index++;
          });
        }
      },
      fail: (exception) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        title: GestureDetector(
          child: Row(
            children: <Widget>[
              Text(DateUtil.formatDate(DateTime.now(), format: "dd"),
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 32.0,
                    letterSpacing: -0.5,
                  )),
              Padding(
                child: Text(
                    DateUtil.getMonth(true) + DateTime.now().year.toString(),
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                      letterSpacing: 0.5,
                    )),
                padding: EdgeInsets.fromLTRB(2.0, 12.0, 0, 0),
              ),
              Padding(
                child: RotationTransition(
                  turns: _animation,
                  child: Icon(
                    Icons.network_cell,
                    color: Colors.black,
                    size: 8.0,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(4.0, 16.0, 0, 0),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _isShowBody = !_isShowBody;
            });
            App.eventBus.fire(oneToolBarListEvent(!_isShowBody));
            changeOpacity(!_isShowBody);
          },
        ),
        actions: <Widget>[
          Padding(
            child: Text('地球·对流层 -273.15℃',
                style: TextStyle(color: Colors.black87, fontSize: 12.0)),
            padding: EdgeInsets.fromLTRB(0, 26.0, 5.0, 0),
          ),
        ],

        /// 阴影
        elevation: 0.5,
      ),
      body: _isShowBody
          ? (_oneList == null
              ? LoadingShimmerWidget()
              : Container(
                  color: Color(0xFFF4F4F4),
                  child: EasyRefresh.custom(
                    header: RefreshUtils.defaultHeader(),
                    footer: RefreshUtils.defaultFooter(),
                    controller: _controller,
                    slivers: <Widget>[
                      SliverToBoxAdapter(
                        child: Container(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return OnePageItem(_data[index]);
                            },
                            separatorBuilder: (context, index) {
                              return Divider(
                                height: 12.0,
                                color: Color(0xFFF4F4F4),
                              );
                            },
                            itemCount: _data.length,
                          ),
                        ),
                      ),
                    ],
                    onRefresh: () async {
                      getOneList();
                      _controller.resetLoadState();
                    },
                    onLoad: () async {
                      getData(_oneList[_index]);
                      _controller.finishLoad(
                          noMore: _index == _oneList.length - 1);
                    },
                  ),
                ))
          : Text("hello"),
    );
  }
}
