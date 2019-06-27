import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

void main() {
  runApp(MyApp());
}

/////////////////////////////////////////////////////////////////////////
//
//                        sharedpreference
//
/////////////////////////////////////////////////////////////////////////

_backup(List<TaskItem> data) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  preferences.setInt('LOW', TaskItem.globalLow);
  preferences.setInt('HIGH', TaskItem.globalHigh);
  preferences.setDouble('AV', TaskItem.globalAv);
  var datalist = [];
  for (var item in data) {
    debugPrint('아이템?$item');
    datalist += [json.encode(item.toJson()).toString()];
  }
  debugPrint('띠용?$datalist');
  preferences.setStringList('DATA', datalist.cast<String>());
}

_getData() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  TaskItem.globalLow = preferences.getInt('LOW');
  TaskItem.globalHigh = preferences.getInt('HIGH');
  TaskItem.globalAv = preferences.getDouble('AV');

  List items = json.decode(preferences.getStringList("DATA").toString());
  List<TaskItem> result = [];
  for (var item in items) {
    // result.add(TaskItem(circleColor: item['circleColor'],name: item['name'],id: item['id'],date: item['date']));
    result.add(TaskItem.fromJson((item)));
  }
  return result;
}
/////////////////////////////////////////////////////////////////////////
//
//                        리스트 아이템
//
/////////////////////////////////////////////////////////////////////////

class CircleColor {
  static List<Color> colorList=[
    Colors.indigo,
    Colors.green,
    Colors.grey,
  ];
  Color getMax() => colorList[0];
  Color getMin() => colorList[1];
  Color getNormal() => colorList[2];

  int getCheck(int value) {
    if (value <= TaskItem.globalLow) {
      return 0;
    } else if (value >= TaskItem.globalHigh) {
      return 1;
    }
    return 2;
  }
}

class TaskItem {
  static int globalLow = 0; // 최저
  static int globalHigh = 0; // 최대
  static double globalAv = 0; // 평균
  int id; // 고유 번호?
  int circleColor; // 동그라미 색상
  String name; // 큐브 카운트
  String date; // 작성 시간

  TaskItem({this.name, this.date, this.circleColor}); // 생성자
  toJson() {
    // json 형식으로 반환! {}
    return {
      'name': name,
      'date': date,
      'circleColor': circleColor,
    };
  }

  factory TaskItem.fromJson(Map json) {
    return new TaskItem(
        // json 형식을 받아서 객체 반환
        name: json['name'],
        date: json['date'],
        circleColor: json['circleColor']);
  }
}

/////////////////////////////////////////////////////////////////////////
//
//                        메인 페이지
//
/////////////////////////////////////////////////////////////////////////
// stfl << 한번에 생기게하는 약어
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // 처음 초기화할 때
    SystemChrome.setEnabledSystemUIOverlays([]); // 네비, 상단바 제거
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CUBE',
      home: TutorialHome(),
      debugShowCheckedModeBanner: false, // 우 상단의 디버그 표시 제거
    );
  }
}
//

//

class TutorialHome extends StatefulWidget {
  @override
  _TutorialHomeState createState() => _TutorialHomeState();
}

class _TutorialHomeState extends State<TutorialHome> {
  List<TaskItem> items = []; // 할 일들의 집합(리스트)
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _getData().then((value) {
      // sharedpreference 에서 값 가져오고
      setState(() {
        // 상태 변경~
        items = value;
        // debugPrint('얍얍?${items}');
      });
    });

    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  void reload() {
    int sum = 0;
    int low = (items.isEmpty) ? 10000000 : int.parse(items[0].name), high = 0;
    double av = 0;
    if (!items.isEmpty) {
      for (TaskItem item in items) {
        int tmp = int.parse(item.name);
        sum += tmp;
        if (low >= tmp) {
          low = tmp;
        } else if (high <= tmp) {
          high = tmp;
        }
      }
      av = sum / items.length;
      int pos = av.toString().indexOf('.');
      TaskItem.globalAv = double.parse(av.toString().substring(0, pos + 2));
      TaskItem.globalHigh = high;
      TaskItem.globalLow = low;

      for (var i = 0; i < items.length; i++) {
        items[i].circleColor = CircleColor().getCheck(int.parse(items[i].name));
      }
    } else {
      TaskItem.globalAv = 0;
      TaskItem.globalHigh = 0;
      TaskItem.globalLow = 0;
    }
  }

  _getPageData(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPage()),
    ).then((da) {
      debugPrint('ddd:$da');
      if (da != null && da != '')
        setState(() {
          items.add(TaskItem(
            name: da,
            date: DateTime.now().toString().substring(0, 19), // 시간을 초까지 나타냄
            circleColor: CircleColor().getCheck(int.parse(da)), // 색상 랜덤 부여
          ));
          reload();
          _backup(items);
        });
    });
  }

  void removeItem(int index) {
    setState(() {
      SystemChrome.setEnabledSystemUIOverlays([]);
      debugPrint('위치 :::: $index');
      items.removeAt(index);
      reload();
      _backup(items);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // 늘림
        children: <Widget>[
          //( 상단의 ToDo )
          Container(
              margin: EdgeInsets.fromLTRB(24, 52, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 할 일 텍스트
                  Text('CUBE',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      )),
                  // 밑 줄
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 16, 0, 0),
                    color: Colors.black54,
                    width: double.infinity, // match parent와 같은 효과
                    height: 1, // 여기서는 두께
                  )
                ],
              )),
          Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Text(
                        '최소 횟수',
                        style: TextStyle(fontSize: 24),
                      ),
                      Text(TaskItem.globalLow.toString(),
                          style: TextStyle(
                              fontSize: 48, color: CircleColor().getMin())),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Text(
                        '평균 횟수',
                        style: TextStyle(fontSize: 24),
                      ),
                      Text(
                          TaskItem.globalAv.toString().substring(
                              0, TaskItem.globalAv.toString().indexOf('.') + 2),
                          style: TextStyle(
                              fontSize: 48, color: CircleColor().getNormal())),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Text(
                        '최대 횟수',
                        style: TextStyle(fontSize: 24),
                      ),
                      Text(TaskItem.globalHigh.toString(),
                          style: TextStyle(
                              fontSize: 48, color: CircleColor().getMax())),
                    ],
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.fromLTRB(24, 16, 24, 24),
                color: Colors.black54,
                width: double.infinity, // match parent와 같은 효과
                height: 1, // 여기서는 두께
              )
            ],
          ),
          // 할 일들의 리스트
          Expanded(
              child: CustomScrollView(
            slivers: <Widget>[
              SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200.0,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  childAspectRatio: 3.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return Dismissible(
                      resizeDuration: Duration(milliseconds: 300),
                      direction: (index % 2 == 0)
                          ? DismissDirection.endToStart
                          : DismissDirection.startToEnd,
                      key: Key(items[index].date.toString()),
                      onDismissed: (direction) {
                        removeItem(index);
                      },
                      background: Container(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                        color: Colors.red,
                        child: Row(
                          mainAxisAlignment: (index % 2 == 0)
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              Icons.check,
                              color: Colors.white,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              '삭제',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      child: InkWell(
                        // 터치 리플 효과
                        onTap: () {},
                        onLongPress: () {},
                        child: Container(
                            padding: EdgeInsets.fromLTRB(24, 8, 0, 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              // 동그라미 아이콘 + 텍스트 column
                              children: <Widget>[
                                Container(
                                  // 동그라미 아이콘
                                  width: 8,
                                  height: 48,
                                  margin: EdgeInsets.fromLTRB(0, 0, 16, 0),
                                  decoration: BoxDecoration(
                                    //
                                    color: CircleColor.colorList[CircleColor().getCheck(int.parse(
                                        items[index]
                                            .name))], // 밖에 color 있으면 오류!!
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    // 할일 text + 날짜
                                    children: <Widget>[
                                      Container(
                                        margin: EdgeInsets.fromLTRB(0, 0, 0, 8),
                                        child: Text(
                                          // row -> column
                                          items[index].name,
                                          overflow: TextOverflow.fade,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24),
                                        ),
                                      ),
                                      Text(items[index].date,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300,
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            )),
                      ),
                    );
                  },
                  childCount: items.length,
                ),
              )
            ],
          )),
          Container(
            // 할 일 추가 버튼
            margin: EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Hero(
              // 같은 tag 끼리의 변화 애니메이션  A -> B 로 점차 변화함.
              tag: "splash",
              child: Material(
                borderRadius: BorderRadius.all(Radius.circular(32)),
                color: Colors.blue,
                child: InkWell(
                  // 터치 리플 효과
                  onTap: () {
                    _getPageData(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // 플러스 아이콘
                        Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                        // 텍스트와 아이콘 띄어 놓기 위함
                        SizedBox(
                          width: 8,
                        ),
                        // 버튼의 텍스트
                        Text(
                          "횟수 입력",
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

/////////////////////////////////////////////////////////////////////////
//
//                        할 일 추가 페이지
//
/////////////////////////////////////////////////////////////////////////

class AddPage extends StatefulWidget {
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  // TextEditingController controller;
  String tmpStr = '';
  bool ch = false;
  @override
  void initState() {
    // 초기화
    // SystemChrome.setEnabledSystemUIOverlays([]);
    // controller = TextEditingController();
    ch = false;
    super.initState();
  }

  void change() {
    setState(() {
      ch = (tmpStr.length > 0);
      // ch = (controller.text.length > 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          // fab 플로팅 버튼
          onPressed: () {
            // widget.action(tmpStr); // 텍스트
            Navigator.pop(context, tmpStr); // 띄어놓은 창 끄기
            SystemChannels.textInput.invokeMethod('TextInput.hide'); // 키보드 숨기기
          },
          backgroundColor: Colors.white,
          child: Icon(
            (ch) ? Icons.add : Icons.close, // save 버튼
            color: (ch) ? Colors.blue : Colors.red,
          ),
        ),
        body: Stack(
          // 스택형식으로 쌓음
          children: [
            Hero(
              // 변화하는 애니메이션을 위함
              tag: "splash",
              child: Material(
                color: Colors.blue,
                child: SizedBox(
                    // 미디어 쿼리로 화면 크기를 가져옴 (전체화면 )
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height),
              ),
            ),
            Column(
              children: <Widget>[
                Container(
                  child: Row(
                    children: <Widget>[
                      Container(
                          // 뒤로 가기 버튼
                          width: 60,
                          child: RaisedButton(
                            color: Colors.transparent, // 기본 색상 투명
                            elevation: 0, // 기본 높이 0
                            highlightElevation: 0, // 눌렀을때 높이 0
                            highlightColor: Colors.transparent, // 눌렀을때 높이 0
                            onPressed: () {
                              Navigator.pop(context, tmpStr);
                              // Navigator.of(context).pop(tmpStr);
                            }, // 팝업 닫기
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                            ),
                          )),
                      Text(
                        "횟수 추가",
                        style: TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  margin: EdgeInsets.fromLTRB(0, 60, 0, 40),
                ),
                Container(
                  // 텍스트 입력 란
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: TextField(
                    onChanged: (text) {
                      tmpStr = text;
                      change();
                    }, // 있을때 + 없을때 x 아이콘!!!
                    autofocus: true,
                    onSubmitted: (text) {
                      // widget.action(text); // 텍스트
                      Navigator.pop(context, tmpStr);
                      // Navigator.of(context).pop(tmpStr); // 띄어놓은 창 끄기
                    },
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "숫자 입력",
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    // controller: controller,
                    cursorColor: Theme.of(context).accentColor,
                    style: TextStyle(
                        color: Colors.black,
                        backgroundColor: Colors.white,
                        fontSize: 20),
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '큐브 횟수\n분석하는 앱....\n\n\n',
                        style: TextStyle(
                          color: Color.fromARGB(255, 240, 240, 233),
                          fontSize: 40,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        'made by hy5jj',
                        style: TextStyle(
                          color: Color.fromARGB(255, 200, 200, 182),
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ));
  }
}

///////////////////////////
