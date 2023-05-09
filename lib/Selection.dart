import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:muzikos_programele/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'justaudio/listening.dart';
import 'justaudio/testing1.dart';

late List<String> linkList;
late List<String> partLinkList;

class DirectoryPage extends StatefulWidget {
  final String course;
  final String semester;
  final listConverted;
  final bool local;
  DirectoryPage(
      {required this.course,
      required this.semester,
      required this.listConverted,
      required this.local});

  @override
  _DirectoryPageState createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> with TraceableClientMixin{
  String? _selectedFolder;
  late var _linkListStr;
  late String _username;
  late String _password;
  late String basicAuth;
  @override
  void initState() {
    super.initState();
    loadPrefs();
    _linkListStr = List<String>.from(
        listConverted['${widget.course}k${widget.semester}s']);
    linkList = _linkListStr;
    linkList = linkList
        .where((filePath) =>
            filePath.endsWith('.mp3') ||
            filePath.endsWith('.wav') ||
            filePath.endsWith('.m4a') ||
            filePath.endsWith('.flac') ||
            filePath.endsWith('.aac'))
        .toList();
    //_saveCurrentState();
  }

  void showInfo(double infoLevel){
    //TODO: (jei reiks) info popup
    if(infoLevel < 1){
      saveInfoLevel(1);
    }
  }

  saveInfoLevel(double infoLevel) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('infoLevel', infoLevel);
  }

  void loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username')!;
    _password = prefs.getString('password')!;
    basicAuth = prefs.getString('basicAuth')!;
    double infoLevel = prefs.getDouble('infoLevel') ?? 0;
    if(infoLevel < 1) showInfo(infoLevel);
  }

  Future<String> loadAsset() async {
    return rootBundle
        .loadString('assets/data/${widget.course}k${widget.semester}s')
        .then((value) => value);
  }



  _saveCurrentState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('page', 'DirectoryPage');
  }

  _deleteSavedPath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('page');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: !widget.local ? Text(
              "${widget.course} kurso ${widget.semester} pusmečio klausymas") : Text("Pasirinktas aplankalas"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Pasirinkti aplanką"),
              SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedFolder,
                items: [
                  DropdownMenuItem<String>(
                    value: 'Visi',
                    child: Text("Visi"),
                  ),
                  ...linkList
                      .map((link) => link.split("/").sublist(4, 5).join("/"))
                      .where((path) => path != "")
                      .toSet()
                      .map((path) => DropdownMenuItem<String>(
                            value: path,
                            child: Text(Uri.decodeComponent(path)),
                          ))
                      .toList(),
                ],
                onChanged: (path) {
                  setState(() {
                    _selectedFolder = path!;
                  });
                  if (path == "Visi") {
                    partLinkList = linkList;
                  } else {
                    partLinkList = linkList
                        .where((filePath) => filePath.contains(path!))
                        .toList();
                  }
                },
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _selectedFolder == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => ListPlay(
                                  linkList: partLinkList,
                                  basicAuth: basicAuth,
                                  username: _username,
                                  password: _password,
                                  local: widget.local)),
                        );
                      },
                child: Text("Klausymas"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectedFolder == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LearningPlay(
                                linkList: partLinkList,
                                basicAuth: basicAuth,
                                username: _username,
                                password: _password),
                          ),
                        );
                      },
                child: Text("Testavimas"),
              ),
              SizedBox(height: 20),
            ],
          ),
        ));
  }
  @override
  String get traceName => 'Selection ${widget.course}k';
  @override
  String get traceTitle => "GabalAI";
}
