import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:muzikos_programele/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'justaudio/listening.dart';
import 'justaudio/testing1.dart';
import 'package:path/path.dart' as p;

late List<String> linkList;
late List<String> partLinkList;
late List<String> modifiedLinkList;
late String linkListSelections;

//modifiedLinkList should be updated, saved according to the selected course, semester and folder

class ModifyListPage extends StatefulWidget {
  const ModifyListPage(
      {super.key,
      required this.title,
      required this.course,
      required this.semester,
      required this.selectionIndex,
      required this.username,
      required this.password});
  final String title;
  final String course;
  final String semester;
  final int selectionIndex;
  final String username;
  final String password;

  @override
  _ModifyListPageState createState() => _ModifyListPageState();
}

class _ModifyListPageState extends State<ModifyListPage>
// with TraceableClientMixin
{
  Set<int> _selectedIndexes =
      Set<int>.from(List.generate(partLinkList.length, (index) => index));
  String? _selectionIdentifier;
  bool _isLoading = true;
  late SharedPreferences prefs;
  @override
  void initState() {
    super.initState();
    _selectionIdentifier =
        "${widget.course}${widget.semester}${widget.selectionIndex}sel";
    handleSave();
    plausible.event(
      page: 'modify',
    );
  }

  //function to create modifiedLinkList
  List<String> createModifiedLinkList() {
    modifiedLinkList = [];
    for (int i = 0; i < partLinkList.length; i++) {
      if (_selectedIndexes.contains(i)) {
        modifiedLinkList.add(partLinkList[i]);
      }
    }
    return modifiedLinkList;
  }

  //function should convert _selectedIndexes to a string in the form of 0011010100111 where 1 is selected and 0 is not selected
  String convertSelections() {
    linkListSelections = "";
    for (int i = 0; i < partLinkList.length; i++) {
      if (_selectedIndexes.contains(i)) {
        linkListSelections += "1";
      } else {
        linkListSelections += "0";
      }
    }
    return linkListSelections;
  }

  Set<int> convertString() {
    _selectedIndexes =
        Set<int>.from(List.generate(partLinkList.length, (index) => index));
    for (int i = 0; i < partLinkList.length; i++) {
      if (linkListSelections[i] == "0") {
        _selectedIndexes.remove(i);
      }
    }
    return _selectedIndexes;
  }

  void handleSave() async {
    prefs = await SharedPreferences.getInstance();
    String? savedSelectionIdentifier = prefs.getString(_selectionIdentifier!);
    if (savedSelectionIdentifier != null) {
      linkListSelections = savedSelectionIdentifier;
      convertString();
    } else {
      convertSelections();
    }
    // print(_selectedIndexes);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            Container(
              margin: const EdgeInsets.only(
                  right: 22.0), // Adjust the spacing as needed
              child: Tooltip(
                message: _selectedIndexes.length != partLinkList.length
                    ? 'Pažymėti visus'
                    : 'Atžymėti visus',
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedIndexes.length != partLinkList.length) {
                        _selectedIndexes = Set<int>.from(List.generate(
                            partLinkList.length,
                            (index) => index)); //reset selection
                        convertSelections();
                        prefs.remove(_selectionIdentifier!);
                      } else {
                        _selectedIndexes = {};
                        prefs.setString(
                            _selectionIdentifier!, convertSelections());
                      }
                    });
                  },
                  icon: _selectedIndexes.length == partLinkList.length
                      ? const Icon(Icons.check_box_rounded)
                      : _selectedIndexes.isEmpty
                          ? const Icon(Icons.check_box_outline_blank_rounded)
                          : const Icon(Icons.indeterminate_check_box_rounded),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: partLinkList.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Text(Uri.decodeComponent(
                        p.basenameWithoutExtension(partLinkList[index]))),
                    value: _selectedIndexes.contains(index),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIndexes.add(index);
                          linkListSelections = linkListSelections.replaceRange(
                              index, index + 1, "1");
                        } else {
                          _selectedIndexes.remove(index);
                          linkListSelections = linkListSelections.replaceRange(
                              index, index + 1, "0");
                        }
                      });

                      prefs.setString(
                          _selectionIdentifier!, linkListSelections);
                    },
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed:
              //if set is not empty
              _selectedIndexes.isNotEmpty
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LearningPlay(
                              linkList: createModifiedLinkList(),
                              basicAuth: basicAuth,
                              username: widget.username,
                              password: widget.password),
                        ),
                      );
                    }
                  : null,
          child: const Icon(Icons.arrow_forward_rounded),
        ));
  }

  String get traceName => 'Modify';
  String get traceTitle => "GabalAI";
}

class DirectoryPage extends StatefulWidget {
  final String course;
  final String semester;
  final listConverted;
  final bool local;
  const DirectoryPage(
      {super.key,
      required this.course,
      required this.semester,
      required this.listConverted,
      required this.local});

  @override
  _DirectoryPageState createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage>
// with TraceableClientMixin
{
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
    plausible.event(
      page: '${widget.course}k',
    );
  }

  void showInfo(double infoLevel) {
    //TODO: (jei reiks) info popup
    if (infoLevel < 1) {
      saveInfoLevel(1);
    }
  }

  saveInfoLevel(double infoLevel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('infoLevel', infoLevel);
  }

  void loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username')!;
    _password = prefs.getString('password')!;
    basicAuth = prefs.getString('basicAuth')!;
    double infoLevel = prefs.getDouble('infoLevel') ?? 0;
    if (infoLevel < 1) showInfo(infoLevel);
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
          title: !widget.local
              ? Text(
                  "${widget.course} kurso ${widget.semester} pusmečio klausymas")
              : const Text("Pasirinktas aplankalas"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Pasirinkti aplanką"),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedFolder,
                items: [
                  const DropdownMenuItem<String>(
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
                          )),
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
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _selectedFolder == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => ListPlay(
                                  title: _selectedFolder == "Visi"
                                      ? "${widget.course} kurso ${widget.semester} pusmečio klausymas"
                                      : Uri.decodeComponent(_selectedFolder!),
                                  linkList: partLinkList,
                                  basicAuth: basicAuth,
                                  username: _username,
                                  password: _password,
                                  local: widget.local)),
                        );
                      },
                child: const Text("Klausymas"),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
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
                    child: const Text("Testavimas"),
                  ),
                  Expanded(
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Tooltip(
                            message: 'Modifikuoti kūrinių sąrašą',
                            child: IconButton(
                                onPressed: _selectedFolder == null
                                    ? null
                                    : () {
                                        Navigator.of(context)
                                            .push(MaterialPageRoute(
                                          builder: (context) => ModifyListPage(
                                            title:
                                                "Sąrašo modifikavimas (${_selectedFolder == "Visi" ? "${widget.course} kurso ${widget.semester} pusmečio" : Uri.decodeComponent(_selectedFolder!)})",
                                            course: widget.course,
                                            semester: widget.semester,
                                            selectionIndex: _selectedFolder ==
                                                    "Visi"
                                                ? -1
                                                : linkList
                                                    .indexOf(partLinkList[0]),
                                            username: _username,
                                            password: _password,
                                          ),
                                        ));
                                      },
                                icon: const Icon(Icons.edit_note)),
                          ))),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ));
  }

  // String get traceName => 'Selection ${widget.course}k';
  // String get traceTitle => "GabalAI";
}
