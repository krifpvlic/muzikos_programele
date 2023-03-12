//docx rodymui gal naudoti mammoth.js
///tooltips, ctrl enter, search, ok enter, select only part,
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:muzikos_programele/Selection.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as enc;
import 'dart:convert';

String tsgurl = "https://acro.lt/musictest";
String ver = "0";
String uri1 = "https://library.licejus.lt";
late String basicAuth;
String githuburl = "https://github.com/krifpvlic/muzikos_programele";
String windowsurl = tsgurl + "/muzika_windows.zip";
String androidurl = tsgurl + "/muzika.apk";
String testurl =
    "${uri1}/menai/1_kursas/1_semestras/1.azijos%20taut%C5%B3%20muzika/03%20-%20Tibetas%20-%20Lam%C5%B3%20giedojimas.mp3";
String? _username;
String? _password;
String gplver = "";
bool isSaved = false;
late var decrypted;
late var listConverted;
Future<String> loadAsset() async {
  return rootBundle
      .loadString('assets/data/encrypted.file')
      .then((value) => value);
}

Future<String> loadGpl() async {
  return rootBundle
      .loadString('assets/data/gpl-3.0.txt')
      .then((value) => value);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //bandom ieškoti ar jau yra išsaugoti prisijungimai
  final prefs = await SharedPreferences.getInstance();
  _username = prefs.getString('username');
  _password = prefs.getString('password');
  if (_username != null) {
    isSaved = true;
    //nuorodų sąrašo failo iššifravimas, "authorization header" generavimas
    var key = _username! + ":" + _password! + "29806657059681125";
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    var bas64 = stringToBase64.encode(_username! + ":" + _password!);
    basicAuth = 'Basic ' + bas64;

    var encryptedFile = await loadAsset();
    final akey = enc.Key.fromUtf8(key);
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(akey));
    final encrypted = enc.Encrypted.fromBase64(encryptedFile);
    decrypted = encrypter.decrypt(encrypted, iv: iv);
    listConverted = json.decode(decrypted);
  }
  gplver = await loadGpl();
  runApp(MyApp());
}

bool _isDarkMode = true;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
        light: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.blue,
          accentColor: Colors.blueAccent,
          useMaterial3: true,
        ),
        dark: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          accentColor: Colors.blueAccent,
          useMaterial3: true,
        ),
        initial: AdaptiveThemeMode.dark,
        builder: (theme, darkTheme) => MaterialApp(
              title: 'GabalAI',
              //jeigu yra išsaugoti prisijungimo duomenys, einam tiesiai į HomePage
              home: !isSaved ? LoginPage() : HomePage(),
              theme: theme,
              darkTheme: darkTheme,
            ));
  }
}

//prisijungimo puslapis
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? _username;
  String? _password;
  bool _usernameValid = false;
  bool _passwordValid = false;

  void failAuthDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Neteisingi prisijungimo duomenys'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  //funkcija paspaudus continue
  Future<void> _handleContinuePress() async {
    if (_formKey.currentState != null) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
      }
    }

    setState(() {
      _usernameValid = _usernameController.text.isNotEmpty;
      _passwordValid = _passwordController.text.isNotEmpty;
    });
    if (_usernameValid && _passwordValid) {
      var key = _username! + ":" + _password! + "29806657059681125";
      Codec<String, String> stringToBase64 = utf8.fuse(base64);
      var bas64 = stringToBase64.encode(_username! + ":" + _password!);
      basicAuth = 'Basic ' + bas64;
      var encryptedFile = await loadAsset();
      final akey = enc.Key.fromUtf8(key);
      final iv = enc.IV.fromLength(16);
      try {
        final encrypter = enc.Encrypter(enc.AES(akey));
        final encrypted = enc.Encrypted.fromBase64(encryptedFile);
        decrypted = encrypter.decrypt(encrypted, iv: iv);
        if (decrypted[0] != "{") {
          failAuthDialog();
        } else {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('username', _username!);
          prefs.setString('password', _password!);
          prefs.setString('basicAuth', basicAuth);
          listConverted = json.decode(decrypted);
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => HomePage(),
          ));
        }
      } catch (err) {
        failAuthDialog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Prisijungimas prie library.licejus.lt')),
        body: Center(
            child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Prisijungimo vardas',
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Įveskite prisijungimo vardą';
                            }
                            return null;
                          },
                          onSaved: (value) => _username = value ?? '',
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Slaptažodis',
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Įveskite slaptažodį';
                            }
                            return null;
                          },
                          onSaved: (value) => _password = value ?? '',
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _handleContinuePress,
                      child: Text('Continue'),
                    ),
                    Padding(padding: EdgeInsets.all(5.0)),
                    Text(
                        "Naršyklės versijoje šiuos prisijungimus reikės pakartotinai įvesti"),
                  ],
                ))));
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedCourse;
  String? _selectedSemester;

  @override
  Future<String> loadAsset() async {
    return rootBundle
        .loadString('assets/data/newversion')
        .then((value) => value);
  }

  Future<String> loadStringFromWebFile() async {
    final response = await http.get(
        Uri.parse("https://acro.lt/musictest/assets/assets/data/newversion"));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load file');
    }
  }

  void checkUpdates() async {
    ver = await loadAsset();
    if (!kIsWeb) {
      if (ver != await loadStringFromWebFile()) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Prieinamas atnaujinimas'),
              content: ElevatedButton(
                child: Text('Parsisiųsti'),
                onPressed: () async {
                  if (Platform.isAndroid) {
                    if (await canLaunchUrlString(androidurl)) {
                      launchUrlString(androidurl,
                          mode: LaunchMode.externalApplication);
                    }
                  } else if (Platform.isWindows) {
                    if (await canLaunchUrlString(windowsurl)) {
                      launchUrlString(windowsurl,
                          mode: LaunchMode.externalApplication);
                    }
                  }
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Ignoruoti'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  void initState() {
    super.initState();
    loadlicejus();
    checkUpdates();
    _loadSelection();
  }

  Future<void> loadlicejus() async {
    final tempplayer = AudioPlayer();
    tempplayer.playbackEventStream
        .listen((event) {}, onError: (Object e, StackTrace stackTrace) {});
    /*await tempplayer.setAudioSource(AudioSource.uri(
        Uri.parse(
            testurl),
        headers: {'Authorization': basicAuth}));*/
    try {
      // AAC example: https://dl.espressif.com/dl/audio/ff-16b-2c-44100hz.aac
      await tempplayer.setAudioSource(AudioSource.uri(Uri.parse(testurl),
          headers: {'Authorization': basicAuth}));
    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Nepasiekiami muzikos failai'),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text(
                      'Spauskite "Bandyti vėl" arba',
                      style: TextStyle(fontSize: 20),
                    ),
                    if (kIsWeb)
                      InkWell(
                        child: Text(
                          'Atidarykite library.licejus.lt, prisijunkite ir spauskite "Bandyti vėl"',
                          style: TextStyle(color: Colors.blue, fontSize: 18),
                        ),
                        onTap: () async {
                          if (await canLaunchUrlString(
                              "https://library.licejus.lt")) {
                            launchUrlString("https://library.licejus.lt");
                          }
                        },
                      ),
                    if (kIsWeb)
                      Text(
                          "\nŠią spragą galima apeiti naudojant Android arba Windows programas, kurias galima parsisiųsti pagrindinio puslapio viršuje.\n\n"),
                    Text("Kiti problemos sprendimo būdai:"),
                    Text(
                        '1) Patikrinti, ar pasiekiamas interneto ryšys\n2) Pabandyti programą kitame tinkle/įrenginyje'),
                  ])),
              actions: <Widget>[
                TextButton(
                  child: Text('Ignoruoti'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Bandyti vėl'),
                  onPressed: () {
                    loadlicejus();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
    }

    tempplayer.dispose();
  }

  Future<void> _loadSelection() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCourse = prefs.getString('course');
      _selectedSemester = prefs.getString('semester');
    });
  }

  Future<void> _saveSelection() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('course', _selectedCourse!);
    prefs.setString('semester', _selectedSemester!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Tooltip(
        message: "(dirbtinis intelektas programėlėje nenaudojamas)",
        child:Text('GabalAI')),
          actions: <Widget>[
            if (!kIsWeb)
              Tooltip(
                message: "Nuoroda į web versiją",
                child: IconButton(
                    icon: Icon(Icons.link),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Web versija: ${tsgurl}'),
                              content: SingleChildScrollView(
                                  child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Container(
                                        color: Colors.white,
                                        child: QrImage(
                                          data: tsgurl,
                                          version: QrVersions.auto,
                                          size: 200,
                                        ),
                                      )),
                                  Padding(
                                    padding: EdgeInsets.all(5.0),
                                  ),
                                  ElevatedButton(
                                    child: Text('Eiti'),
                                    onPressed: () async {
                                      if (await canLaunchUrlString(tsgurl)) {
                                        launchUrlString(tsgurl,
                                            mode:
                                                LaunchMode.externalApplication);
                                      }
                                    },
                                  ),
                                ],
                              )),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          });
                    }),
              ),
            if (kIsWeb || Platform.isWindows)
              Tooltip(
                message: 'Android versijos parsisiuntimas',
                child: IconButton(
                    icon: Icon(Icons.android),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Android programa'),
                              content: SingleChildScrollView(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                          width: 200,
                                          height: 200,
                                          child: Container(
                                            color: Colors.white,
                                            child: QrImage(
                                              data: androidurl,
                                              version: QrVersions.auto,
                                              size: 200,
                                            ),
                                          )),
                                      Padding(
                                        padding: EdgeInsets.all(5.0),
                                      ),
                                      ElevatedButton(
                                        child: Text('Parsisiųsti'),
                                        onPressed: () async {
                                          if (await canLaunchUrlString(
                                              androidurl)) {
                                            launchUrlString(androidurl,
                                                mode: LaunchMode
                                                    .externalApplication);
                                          }
                                        },
                                      ),
                                    ]),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Uždaryti'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          });
                    }),
              ),
            if (kIsWeb || Platform.isAndroid)
              Tooltip(
                message: "Windows versijos parsisiuntimas",
                child: IconButton(
                    icon: Icon(Icons.desktop_windows),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Windows programa'),
                              content: ElevatedButton(
                                child: Text('Parsisiųsti'),
                                onPressed: () async {
                                  if (await canLaunchUrlString(windowsurl)) {
                                    launchUrlString(windowsurl,
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          });
                    }),
              ),
            Tooltip(
              message: "Šviesaus/tamsaus UI keitimas",
              child: IconButton(
                icon: !_isDarkMode
                    ? Icon(Icons.brightness_3)
                    : Icon(Icons.brightness_5),
                onPressed: () {
                  setState(() {
                    _isDarkMode = !_isDarkMode;
                    if (_isDarkMode) {
                      AdaptiveTheme.of(context).setDark();
                    } else {
                      AdaptiveTheme.of(context).setLight();
                    }
                  });
                },
              ),
            ),
            Tooltip(
              message: "Informacija",
              child: IconButton(
                icon: Icon(Icons.file_open_outlined),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Informacija'),
                        content: Text(
                            'Licencija - GPL v3\nProgramos versija - ${ver}\nSukūrė Kristupas Lapinskas'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('GPL v3'),
                            onPressed: () {
                              {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('GPL v3'),
                                        content: SingleChildScrollView(child:Text(gplver)),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text("OK"))
                                        ],
                                      );
                                    });
                              }
                            },
                          ),
                          TextButton(
                            child: Text('Kitos licencijos'),
                            onPressed: () {
                              showLicensePage(
                                  context: context, applicationLegalese: "dirbtinis intelektas programėlėje nenaudojamas");
                            },
                          ),
                          TextButton(
                            child: Text('GitHub'),
                            onPressed: () async {
                              if (await canLaunchUrlString(githuburl)) {
                                launchUrlString(githuburl,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                          TextButton(
                            child: Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(0.0),
                child: Text('Sveiki!', style: TextStyle(fontSize: 24.0)),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(''),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: DropdownButton<String>(
                  hint: Text('Pasirinkti kursą'),
                  value: _selectedCourse,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCourse = newValue!;
                    });
                  },
                  items: <String>[
                    '1 kursas',
                    '2 kursas',
                    '3 kursas',
                    '4 kursas'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: DropdownButton<String>(
                  hint: Text('Pasirinkti pusmetį'),
                  value: _selectedSemester,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSemester = newValue!;
                    });
                  },
                  items: <String>['1 pusmetis', '2 pusmetis']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: ElevatedButton(
                  child: Text('Tęsti'),
                  onPressed:
                      _selectedCourse == null || _selectedSemester == null
                          ? null
                          : () {
                              // perform action here
                              _saveSelection();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => DirectoryPage(
                                    course: _selectedCourse!
                                        .replaceAll(RegExp(r'[^0-9]'), ''),
                                    semester: _selectedSemester!
                                        .replaceAll(RegExp(r'[^0-9]'), ''),
                                    listConverted: listConverted,
                                  ),
                                ),
                              );
                            },
                ),
              ),
            ],
          ),
        ));
  }
}
