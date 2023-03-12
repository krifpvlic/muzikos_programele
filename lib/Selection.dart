import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DirectoryPage({required this.course, required this.semester, required this.listConverted});

  @override
  _DirectoryPageState createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  String? _selectedFolder;
  late var _linkListStr;
  late String _username;
  late String _password;
  late String basicAuth;
  @override
  void initState() {

    super.initState();
    ///_linkListStr = loadAsset();
  loadPrefs();
    _linkListStr=List<String>.from(listConverted['${widget.course}k${widget.semester}s']);
    /*print("asd2");
    LineSplitter ls = new LineSplitter();
    print("asd3");
    linkList = ls.convert(linkListStr);
    print("asd4");
    print(linkList);
    print("asd5");*/
    linkList=_linkListStr;
    linkList = linkList
        .where((filePath) =>
    filePath.endsWith('.mp3') ||
        filePath.endsWith('.wav') ||
        filePath.endsWith('.m4a') ||
        filePath.endsWith('.flac') ||
        filePath.endsWith('.aac'))
        .toList();
    _saveCurrentState();
  }

  void loadPrefs() async{
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username')!;
    _password = prefs.getString('password')!;
    basicAuth = prefs.getString('basicAuth')!;
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
    //return WillPopScope(
      //  onWillPop: () async => false,
        //child: Scaffold(
    return Scaffold(
          appBar: AppBar(
            //automaticallyImplyLeading: false,
            title: Text(
                "${widget.course} kurso ${widget.semester} pusmečio klausymas"),
            /*leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _deleteSavedPath();
          },
        ),*/
          ),
          /*body: FutureBuilder<List<String>> (
            future: linkList,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                ///List<String> linkList = LineSplitter().convert(snapshot.data!);
                List<String> linkList=listConverted['${widget.course}k${widget.semester}s'];
                linkList = linkList
                    .where((filePath) =>
                        filePath.endsWith('.mp3') ||
                        filePath.endsWith('.wav') ||
                        filePath.endsWith('.m4a') ||
                        filePath.endsWith('.flac') ||
                        filePath.endsWith('.aac'))
                    .toList();


                return */body: Center(
      //body:Center(
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
                              .map((link) =>
                                  link.split("/").sublist(4, 5).join("/"))
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
                            :() {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ListPlay(linkList: partLinkList,basicAuth:basicAuth,username:_username,password:_password)),

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
                              builder: (context) =>
                                  LearningPlay(linkList: partLinkList,basicAuth:basicAuth,username:_username,password:_password),
                            ),
                          );
                        },
                        child: Text("Testavimas"),
                      ),
                      SizedBox(height: 20),
                      /*ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  LearningPlay2(linkList: linkList),
                            ),
                          );
                        },
                        child: Text("Testing 2"),
                      ),*/
                    ],
                  ),
                )/*;
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else {
                return CircularProgressIndicator();
              }
            }
            )*/
    );}

}
