import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
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
import 'package:plausible_analytics/plausible_analytics.dart';
double ver = 0;
String uri1 = "https://library.licejus.lt";
late String basicAuth;
String githuburl = "https://github.com/krifpvlic/muzikos_programele";
String tsgurl = "https://gabalai.licejus.lt";
String windowsurl = tsgurl + "/gabalai_windows.zip";
String androidurl = tsgurl + "/gabalai.apk";
String testurl =
    "${uri1}/menai/1_kursas/1_semestras/1.azijos%20taut%C5%B3%20muzika/03%20-%20Tibetas%20-%20Lam%C5%B3%20giedojimas.mp3";
String? _username;
String? _password;
bool isSkipped = false;
String gplver = "";
bool isSaved = false;
bool _isDarkMode = true;
int analyticsEnabled = 0;
late var decrypted;
late var listConverted;
final plausible = Plausible("https://plausible.io", "gabalai.licejus.lt");
final GlobalKey<State> _key = GlobalKey<State>();

void setAnalytics(int value) async{
  final prefs = await SharedPreferences.getInstance();
  prefs.setInt('analytics', value);
  analyticsEnabled = value;
  if(value == 1) plausible.enabled = true;
}

void analyticsDialog() async{
    while (_key.currentContext == null) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    if (_key.currentContext != null) {
      print("b");
      showDialog(
          context: _key.currentContext!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Sutikimas'),
              content: SingleChildScrollView(

              child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Column(
                      children: [ Text(
                      "Šioje programoje naudojamas plausible.io - duomenų privatumą užtikrinantis, atviro kodo svetainių ir programų analitikos įrankis. Paspaudus \"Sutinku\" įrankis bus įgalintas, o jo naudojimo galima  atsisakyti paspaudus \"Nesutinku\".\n"),
                        InkWell(
                          child: Text(
                            'plausible.io duomenų politika',
                            style: TextStyle(color: Colors.blue),
                          ),
                          onTap: () async {
                            if (await canLaunchUrlString(
                                "https://plausible.io/data-policy")) {
                              launchUrlString("https://plausible.io/data-policy");
                            }
                          },
                        ),

                ]))),
              actions: <Widget>[
                TextButton(
                  child: Text('Nesutinku'),
                  onPressed: () {
                    setAnalytics(0);
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Sutinku'),
                  onPressed: () {
                    setAnalytics(1);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
    };
}

Future<void> _setSkipped(bool bool1) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool('skipped', bool1);
}

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
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  if(savedThemeMode==AdaptiveThemeMode.dark) _isDarkMode = true;
  else _isDarkMode = false;
  _username = prefs.getString('username');
  _password = prefs.getString('password');
  if (prefs.getBool('skipped') == true) isSkipped = true;
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
  analyticsEnabled = prefs.getInt('analytics') ?? -1;
  print(analyticsEnabled);
  if (analyticsEnabled == 0) plausible.enabled = false;
  else if (analyticsEnabled == -1) {
    plausible.enabled = false;
    analyticsDialog();
    print("a");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
        light: FlexThemeData.light(
          colors: const FlexSchemeColor(
            primary: Color(0xff8484f2),
            primaryContainer: Color(0xff8484f2),
            secondary: Color(0xff8484f2),
            secondaryContainer: Color(0xff8484f2),
            tertiary: Color(0xff006875),
            tertiaryContainer: Color(0xff95f0ff),
            appBarColor: Color(0xff8484f2),
            error: Color(0xffb00020),
          ),
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 9,
          subThemesData: const FlexSubThemesData(),
          keyColors: const FlexKeyColors(
            keepPrimary: true,
            keepPrimaryContainer: true,
            keepSecondaryContainer: true,
          ),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
          fontFamily: GoogleFonts.raleway().fontFamily,
        ),
        dark: FlexThemeData.dark(
          colors: const FlexSchemeColor(
            primary: Color(0xff8484f2),
            primaryContainer: Color(0xff8484f2),
            secondary: Color(0xff8484f2),
            secondaryContainer: Color(0xff8484f2),
            tertiary: Color(0xff006875),
            tertiaryContainer: Color(0xff95f0ff),
            appBarColor: Color(0xff8484f2),
            error: Color(0xffb00020),
          ),
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 15,
          appBarStyle: FlexAppBarStyle.background,
          subThemesData: const FlexSubThemesData(),
          keyColors: const FlexKeyColors(
            keepPrimary: true,
            keepTertiary: true,
            keepPrimaryContainer: true,
            keepSecondaryContainer: true,
          ),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
          fontFamily: GoogleFonts.raleway().fontFamily,
        ),
        initial: AdaptiveThemeMode.dark,
        builder: (theme, darkTheme) => MaterialApp(
              title: 'GabalAI',
              //jeigu yra išsaugoti prisijungimo duomenys, einam tiesiai į HomePage
              home: !isSaved & !isSkipped ? LoginPage() : HomePage(),
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

  //kopijuota iš kito class... negerai
  List<Widget> mygtukai(BuildContext context) {
    return [
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
                                      mode: LaunchMode.externalApplication);
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
                                    if (await canLaunchUrlString(androidurl)) {
                                      launchUrlString(androidurl,
                                          mode: LaunchMode.externalApplication);
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
          icon: Icon(Icons.bug_report_rounded),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Informacija'),
                  content: Text(
                      'Licencija - GPL v3\nProgramos versija - ${ver}\nSukūrė Kristupas Lapinskas\n\nFunkcijų užklausos ir pranešimai apie trūkumus gali būti siunčiami GitHub arba kristupas.lapinskas@licejus.lt'),
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
                                  content: SingleChildScrollView(
                                      child: Text(gplver)),
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
                            context: context,
                            applicationIcon:
                                ImageIcon(AssetImage("assets/data/icon.png")),
                            applicationLegalese:
                                "dirbtinis intelektas programėlėje nenaudojamas");
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
    ];
  }

  void failAuthDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Neteisingi prisijungimo duomenys'),
            content: kDebugMode
                ? SingleChildScrollView(
                    child: Text(
                        "Jeigu nežinote library.licejus.lt prisijungimo duomenų, yra galimybė įkelti savo aplanką praleidžiant prisijungimą, paspaudžiant rodyklę viršuje."))
                : SingleChildScrollView(
                    child: Text(
                        "Atkreipkite dėmesį, kad reikalingi ne asmeniniai, o library.licejus.lt prisijungimo duomenys.")),
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
          _setSkipped(false);
          isSkipped = false;
          //Navigator.of(context).pop();
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
        key: _key,
        appBar: AppBar(
            title: Tooltip(
                message: "library.licejus.lt prisijungimas",
                child: Text('library.licejus.lt prisijungimas')),
            actions: kDebugMode
                ? mygtukai(context) +
                    <Widget>[
                      Tooltip(
                          message: "Praleisti",
                          child: IconButton(
                              icon:
                                  Icon(Icons.subdirectory_arrow_right_rounded),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title:
                                            Text('Ar tikrai norite praleisti?'),
                                        content: SingleChildScrollView(
                                            child: Text(
                                                "Praleidus prisijungimą nebus pasiekiami library.licejus.lt kūriniai, juos reikės įkelti iš savo įrenginio. Vėlesnis grįžimas į prisijungimo langą galimas.")),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                _setSkipped(true);
                                                isSkipped = true;
                                                //Navigator.of(context).pop();
                                                Navigator.of(context)
                                                    .push(MaterialPageRoute(
                                                  builder: (context) =>
                                                      HomePage(),
                                                ));
                                              },
                                              child: Text("Suprantu")),
                                          TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text("Grįžti"))
                                        ],
                                      );
                                    });
                              }))
                    ]
                : mygtukai(context)),
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
                      child: Text('Tęsti'),
                    ),
                    Padding(padding: EdgeInsets.all(5.0)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Center(
                        child: kIsWeb
                            ? Text(
                                "Naršyklės versijoje šiuos prisijungimus reikės pakartotinai įvesti",
                                textAlign: TextAlign.center,
                              )
                            : null,
                      ),
                    ),
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
  final event = plausible.event(
      name: 'homepage',
      page: 'homepage',
      props: {
        'app_version': ver.toString(),
        'app_platform': kIsWeb ? 'web' : Platform.isWindows ? 'windows' : Platform.isAndroid ? 'android' : 'unknown',
        'app_theme': _isDarkMode ? 'dark' : 'light',
        'app_debug': kDebugMode ? 'debug' : 'release',
      });

  @override
  //kopijuota tas pats į kitą state... negerai
  List<Widget> mygtukai(BuildContext context) {
    return [
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
                                      mode: LaunchMode.externalApplication);
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
                                    if (await canLaunchUrlString(androidurl)) {
                                      launchUrlString(androidurl,
                                          mode: LaunchMode.externalApplication);
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
          icon: Icon(Icons.bug_report_rounded),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Informacija'),
                  content: Text(
                      'Licencija - GPL v3\nProgramos versija - ${ver}\nSukūrė Kristupas Lapinskas\n\nFunkcijų užklausos ir pranešimai apie trūkumus gali būti siunčiami GitHub arba kristupas.lapinskas@licejus.lt'),
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
                                  content: SingleChildScrollView(
                                      child: Text(gplver)),
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
                            context: context,
                            applicationIcon:
                                ImageIcon(AssetImage("assets/data/icon.png")),
                            applicationLegalese:
                                "dirbtinis intelektas programėlėje nenaudojamas");
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
    ];
  }

  Future<String> loadAsset() async {
    return rootBundle
        .loadString('assets/data/newversion')
        .then((value) => value);
  }

  Future<String> loadStringFromWebFile() async {
    final response =
        await http.get(Uri.parse(tsgurl + "/assets/assets/data/newversion"));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "0";
    }
  }

  Future<String> loadChangelog() async {
    final response =
        await http.get(Uri.parse(tsgurl + "/assets/assets/data/changelog.txt"));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "Pakeitimų sąrašo gavimo klaida.";
    }
  }

  void checkUpdates() async {
    ver = double.parse(await loadAsset());
    String changelog = await loadChangelog();
    if (!kIsWeb) {
      if (ver < double.parse(await loadStringFromWebFile())) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Prieinamas atnaujinimas'),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text(changelog),
                    Padding(
                      padding: EdgeInsets.all(10.0),
                    ),
                    ElevatedButton(
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
                  ])),
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
    isSkipped ? null : loadlicejus();
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
        key: _key,
        appBar: AppBar(
          leading: isSkipped
              ? Tooltip(
                  message: "Grįžti į prisijungimą",
                  child: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ));
                      }))
              : null,
          title: Tooltip(
              message: "(dirbtinis intelektas programėlėje nenaudojamas)",
              child: Text('GabalAI')),
          actions: mygtukai(context),
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
                padding: EdgeInsets.all(8.0),
                child: Text(''),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
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
                  onPressed: _selectedCourse == null ||
                          _selectedSemester == null ||
                          isSkipped
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
