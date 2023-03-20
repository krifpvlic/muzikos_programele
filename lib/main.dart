import 'dart:html' as Html;

import 'package:matomo_tracker/matomo_tracker.dart';
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
import 'addlicences.dart';

double ver = 0;
String uri1 = "https://library.licejus.lt";
late String basicAuth;
String githuburl = "https://github.com/krifpvlic/muzikos_programele";
String tsgurl = "https://gabalai.licejus.lt";
String windowsurl = "$tsgurl/gabalai_windows.zip";
String androidurl = "$tsgurl/gabalai.apk";
String testurl =
    "$uri1/menai/1_kursas/1_semestras/1.azijos%20taut%C5%B3%20muzika/03%20-%20Tibetas%20-%20Lam%C5%B3%20giedojimas.mp3";
String? _username;
String? _password;
bool isSkipped = false;
String gplver = "";
bool isSaved = false;
bool _isDarkMode = true;
int analyticsEnabled = 0;
late var decrypted;
late var listConverted;
//final plausible = Plausible("https://plausible.io", "gabalai.licejus.lt");

final GlobalKey<State> _key = GlobalKey<State>();
BuildContext? dabartinis;

void setAnalytics(int value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setInt('analytics', value);
  analyticsEnabled = value;
  if (value == 1) {
    /*if(kIsWeb){
      html.ScriptElement script = new html.ScriptElement();
      script.setAttribute('defer', '');
      script.setAttribute('data-domain', 'gabalai.licejus.lt');
      script.src = 'https://plausible.io/js/script.hash.js';
      html.document.head?.append(script);
    }
      else{
      plausible.enabled = true;}*/
    await MatomoTracker.instance.initialize(
      siteId: 1,
      url: 'https://gabalai.licejus.lt/matomo/matomo.php',
    );

    //html.window.localStorage['plausible_ignore']='false';
  }
}

void analyticsDialog() async {
  while (dabartinis == null) {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  if (dabartinis != null) {
    showDialog(
        context: dabartinis!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sutikimas'),
            content: SingleChildScrollView(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(children: [
                      const Text(
                          "Šioje programoje naudojama Matomo Analytics - duomenų privatumą užtikrinantis, atviro kodo svetainių ir programų analitikos įrankis. Paspaudus \"Sutinku\" įrankis bus įgalintas, o jo naudojimo galima atsisakyti paspaudus \"Nesutinku\".\n"),
                      InkWell(
                        child: const Text(
                          'Viešai prieinama analitikos versija',
                          style: TextStyle(color: Color(0xff8484f2)),
                        ),
                        onTap: () async {
                          if (await canLaunchUrlString(
                              "https://gabalai.licejus.lt/matomo/")) {
                            launchUrlString("https://gabalai.licejus.lt/matomo/");
                          }
                        },
                      ),
                      InkWell(
                        child: const Text(
                          'Matomo duomenų politika',
                          style: TextStyle(color: Color(0xff8484f2)),
                        ),
                        onTap: () async {
                          if (await canLaunchUrlString(
                              "https://matomo.org/privacy/")) {
                            launchUrlString("https://matomo.org/privacy/");
                          }
                        },
                      ),
                    ]))),
            actions: <Widget>[
              TextButton(
                child: const Text('Nesutinku'),
                onPressed: () {

                  MatomoTracker.instance.setOptOut(optout: true);
                  setAnalytics(0);
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Sutinku'),
                onPressed: () {

                  MatomoTracker.instance.setOptOut(optout: false);
                  setAnalytics(1);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
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

Future<String> loadVersion() async {
  return rootBundle
      .loadString('assets/data/newversion')
      .then((value) => value);
}

Future<String> loadStringFromWebFile() async {
  final response =
  await http.get(Uri.parse("$tsgurl/assets/assets/data/newversion"));
  if (response.statusCode == 200) {
    return response.body;
  } else {
    return "0";
  }
}

Future<String> loadChangelog() async {
  final response =
  await http.get(Uri.parse("$tsgurl/assets/assets/data/changelog.txt"));
  if (response.statusCode == 200) {
    return response.body;
  } else {
    return "Pakeitimų sąrašo gavimo klaida.";
  }
}

void checkUpdates(BuildContext context) async {
  if (!kIsWeb) {
  ver = double.parse(await loadVersion());
  final prefs = await SharedPreferences.getInstance();
  double skippedVersion=prefs.getDouble('skippedVersion') ?? 0;
  double newver = double.parse(await loadStringFromWebFile());
    if (ver < newver && newver != skippedVersion) {
      String changelog = await loadChangelog();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Prieinamas atnaujinimas'),
            content: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(changelog),
                      const Padding(
                        padding: EdgeInsets.all(10.0),
                      ),
                      ElevatedButton(
                        child: const Text('Parsisiųsti'),
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
                child: const Text('Praleisti šią versiją'),
                onPressed: () {
                  prefs.setDouble('skippedVersion', newver);
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Uždaryti'),
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



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  addLicences();

  final prefs = await SharedPreferences.getInstance();
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  if (savedThemeMode == AdaptiveThemeMode.light) {
    _isDarkMode = false;
  } else {
    _isDarkMode = true;
  }

  runApp(const MyApp());


  _username = prefs.getString('username');
  _password = prefs.getString('password');
  if (prefs.getBool('skipped') == true) isSkipped = true;
  if (_username != null) {
    isSaved = true;
    //nuorodų sąrašo failo iššifravimas, "authorization header" generavimas
    var key = "${_username!}:${_password!}29806657059681125";
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    var bas64 = stringToBase64.encode("${_username!}:${_password!}");
    basicAuth = 'Basic $bas64';

    var encryptedFile = await loadAsset();
    final akey = enc.Key.fromUtf8(key);
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(akey));
    final encrypted = enc.Encrypted.fromBase64(encryptedFile);
    decrypted = encrypter.decrypt(encrypted, iv: iv);
    listConverted = json.decode(decrypted);
  }

  if(Html.window.navigator.doNotTrack == '1') {
    setAnalytics(0);
  }
  else{
    analyticsEnabled = prefs.getInt('analytics') ?? -1;
    if (analyticsEnabled == -1) {
      MatomoTracker.instance.setOptOut(optout: true);
      analyticsDialog();
    } else if (analyticsEnabled == 1) {
      await MatomoTracker.instance.initialize(
        siteId: 1,
        url: 'https://gabalai.licejus.lt/matomo/matomo.php',
      );
    }}

  gplver = await loadGpl();

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
              home: !isSaved & !isSkipped ? const LoginPage() : const HomePage(),
              theme: theme,
              darkTheme: darkTheme,
            ));
  }
}

//prisijungimo puslapis
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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

  @override
  void initState() {
    super.initState();
    checkUpdates(context);
    dabartinis=context;
  }


  //kopijuota iš kito class... negerai
  List<Widget> mygtukai(BuildContext context) {
    return [
      if (!kIsWeb)
        Tooltip(
          message: "Nuoroda į web versiją",
          child: IconButton(
              icon: const Icon(Icons.link),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Web versija: $tsgurl'),
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
                            const Padding(
                              padding: EdgeInsets.all(5.0),
                            ),
                            ElevatedButton(
                              child: const Text('Eiti'),
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
                            child: const Text('OK'),
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
              icon: const Icon(Icons.android),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Android programa'),
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
                                const Padding(
                                  padding: EdgeInsets.all(5.0),
                                ),
                                ElevatedButton(
                                  child: const Text('Parsisiųsti'),
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
                            child: const Text('Uždaryti'),
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
              icon: const Icon(Icons.desktop_windows),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Windows programa'),
                        content: ElevatedButton(
                          child: const Text('Parsisiųsti'),
                          onPressed: () async {
                            if (await canLaunchUrlString(windowsurl)) {
                              launchUrlString(windowsurl,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('OK'),
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
              ? const Icon(Icons.brightness_3)
              : const Icon(Icons.brightness_5),
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
          icon: const Icon(Icons.bug_report_rounded),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Informacija'),
                  content: Text(
                      //'Licencija - GPL v3\nProgramos versija - $ver\nSukūrė Kristupas Lapinskas\n\nFunkcijų užklausos ir pranešimai apie trūkumus gali būti siunčiami GitHub arba kristupas.lapinskas@licejus.lt'),
                      'Licencija - GPL v3\nProgramos versija - beta 1.1 (nedaug testuota, stabili versija gabalai.licejus.lt/old)\nSukūrė Kristupas Lapinskas\n\nFunkcijų užklausos ir pranešimai apie trūkumus gali būti siunčiami GitHub arba kristupas.lapinskas@licejus.lt'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('GPL v3'),
                      onPressed: () {
                        {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('GPL v3'),
                                  content: SingleChildScrollView(
                                      child: Text(gplver)),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("OK"))
                                  ],
                                );
                              });
                        }
                      },
                    ),
                    TextButton(
                      child: const Text('Kitos licencijos'),
                      onPressed: () {
                        showLicensePage(
                            context: context,
                            applicationIcon:
                                const ImageIcon(AssetImage("assets/data/icon.png")),
                            applicationLegalese:
                                "dirbtinis intelektas programėlėje nenaudojamas",
                        );
                      },
                    ),
                    TextButton(
                      child: const Text('GitHub'),
                      onPressed: () async {
                        if (await canLaunchUrlString(githuburl)) {
                          launchUrlString(githuburl,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    TextButton(
                      child: const Text('OK'),
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
            title: const Text('Neteisingi prisijungimo duomenys'),
            content: kDebugMode
                ? const SingleChildScrollView(
                    child: Text(
                        "Jeigu nežinote library.licejus.lt prisijungimo duomenų, yra galimybė įkelti savo aplanką praleidžiant prisijungimą, paspaudžiant rodyklę viršuje."))
                : const SingleChildScrollView(
                    child: Text(
                        "Atkreipkite dėmesį, kad reikalingi ne asmeniniai, o library.licejus.lt prisijungimo duomenys.")),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
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
      var key = "${_username!}:${_password!}29806657059681125";
      Codec<String, String> stringToBase64 = utf8.fuse(base64);
      var bas64 = stringToBase64.encode("${_username!}:${_password!}");
      basicAuth = 'Basic $bas64';
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
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const HomePage(),
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
        key: _key.currentContext == null ? _key : null,
        appBar: AppBar(
            title: const Tooltip(
                message: "library.licejus.lt prisijungimas",
                child: Text('library.licejus.lt prisijungimas')),
            actions: kDebugMode
                ? mygtukai(context) +
                    <Widget>[
                      Tooltip(
                          message: "Praleisti",
                          child: IconButton(
                              icon:
                                  const Icon(Icons.subdirectory_arrow_right_rounded),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title:
                                            const Text('Ar tikrai norite praleisti?'),
                                        content: const SingleChildScrollView(
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
                                                      const HomePage(),
                                                ));
                                              },
                                              child: const Text("Suprantu")),
                                          TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text("Grįžti"))
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
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
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
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
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
                      child: const Text('Tęsti'),
                    ),
                    const Padding(padding: EdgeInsets.all(5.0)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: const Center(
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
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TraceableClientMixin {
  String? _selectedCourse;
  String? _selectedSemester;
  /*final event = plausible.event(
      name: 'homepage',
      page: 'homepage',
      props: {
        'app_version': ver.toString(),
        'app_platform': kIsWeb ? 'web' : Platform.isWindows ? 'windows' : Platform.isAndroid ? 'android' : 'unknown',
        'app_theme': _isDarkMode ? 'dark' : 'light',
        'app_debug': kDebugMode ? 'debug' : 'release',
      });*/

  //kopijuota tas pats į kitą state... negerai
  List<Widget> mygtukai(BuildContext context) {
    return [
      if (!kIsWeb)
        Tooltip(
          message: "Nuoroda į web versiją",
          child: IconButton(
              icon: const Icon(Icons.link),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Web versija: $tsgurl'),
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
                            const Padding(
                              padding: EdgeInsets.all(5.0),
                            ),
                            ElevatedButton(
                              child: const Text('Eiti'),
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
                            child: const Text('OK'),
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
              icon: const Icon(Icons.android),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Android programa'),
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
                                const Padding(
                                  padding: EdgeInsets.all(5.0),
                                ),
                                ElevatedButton(
                                  child: const Text('Parsisiųsti'),
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
                            child: const Text('Uždaryti'),
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
              icon: const Icon(Icons.desktop_windows),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Windows programa'),
                        content: ElevatedButton(
                          child: const Text('Parsisiųsti'),
                          onPressed: () async {
                            if (await canLaunchUrlString(windowsurl)) {
                              launchUrlString(windowsurl,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('OK'),
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
              ? const Icon(Icons.brightness_3)
              : const Icon(Icons.brightness_5),
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
          icon: const Icon(Icons.bug_report_rounded),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Informacija'),
                  content: Text(
                    //'Licencija - GPL v3\nProgramos versija - $ver\nSukūrė Kristupas Lapinskas\n\nFunkcijų užklausos ir pranešimai apie trūkumus gali būti siunčiami GitHub arba kristupas.lapinskas@licejus.lt'),
                      'Licencija - GPL v3\nProgramos versija - beta 1.1 (nedaug testuota, stabili versija gabalai.licejus.lt/old)\nSukūrė Kristupas Lapinskas\n\nFunkcijų užklausos ir pranešimai apie trūkumus gali būti siunčiami GitHub arba kristupas.lapinskas@licejus.lt'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('GPL v3'),
                      onPressed: () {
                        {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('GPL v3'),
                                  content: SingleChildScrollView(
                                      child: Text(gplver)),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("OK"))
                                  ],
                                );
                              });
                        }
                      },
                    ),
                    TextButton(
                      child: const Text('Kitos licencijos'),
                      onPressed: () {
                        showLicensePage(
                            context: context,
                            applicationIcon:
                                const ImageIcon(AssetImage("assets/data/icon.png")),
                            applicationLegalese:
                                "dirbtinis intelektas programėlėje nenaudojamas");
                      },
                    ),

                    TextButton(
                      child: const Text('GitHub'),
                      onPressed: () async {
                        if (await canLaunchUrlString(githuburl)) {
                          launchUrlString(githuburl,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    TextButton(
                      child: const Text('OK'),
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






  @override
  void initState() {
    super.initState();
    isSkipped ? null : loadlicejus();
    checkUpdates(context);
    _loadSelection();
    dabartinis=context;
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
      //šis dialogas naudojamas ir kitur, reikėtų jį perkelti į vieną funkciją (bet tai padarius kažkodėl kartojama funkcija nelaukiant mygtukų paspaudimo)
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Nepasiekiami muzikos failai'),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Text(
                      'Spauskite "Bandyti vėl" arba',
                      style: TextStyle(fontSize: 20),
                    ),
                    if (kIsWeb)
                      InkWell(
                        child: const Text(
                          'atidarykite library.licejus.lt, prisijunkite ir spauskite "Bandyti vėl"',
                          style: TextStyle(color: Color(0xff8484f2), fontSize: 20),
                        ),
                        onTap: () async {
                          if (await canLaunchUrlString(
                              "https://library.licejus.lt")) {
                            launchUrlString("https://library.licejus.lt");
                          }
                        },
                      ),
                    if (kIsWeb)
                      const Text(
                          "\nŠią spragą galima apeiti naudojant Android arba Windows programas, kurias galima parsisiųsti pagrindinio puslapio viršuje.\n\n"),
                    const Text("Kiti problemos sprendimo būdai:"),
                    const Text(
                        '1) Patikrinti, ar pasiekiamas interneto ryšys\n2) Pabandyti programą kitame tinkle/įrenginyje'),
                  ])),
              actions: <Widget>[
                TextButton(
                  child: const Text('Ignoruoti'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Bandyti vėl'),
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
        key: _key.currentContext == null ? _key : null,
        appBar: AppBar(
          leading: isSkipped
              ? Tooltip(
                  message: "Grįžti į prisijungimą",
                  child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ));
                      }))
              : null,
          title: const Tooltip(
              message: "(dirbtinis intelektas programėlėje nenaudojamas)",
              child: Text('GabalAI')),
          actions: mygtukai(context),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(0.0),
                child: Text('Sveiki!', style: TextStyle(fontSize: 24.0)),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(''),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: DropdownButton<String>(
                  hint: const Text('Pasirinkti kursą'),
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
                padding: const EdgeInsets.all(16.0),
                child: DropdownButton<String>(
                  hint: const Text('Pasirinkti pusmetį'),
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
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
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
                  child: const Text('Tęsti'),
                ),
              ),
            ],
          ),
        ));
  }
  @override
  String get traceName => 'Home';
  @override
  String get traceTitle => "GabalAI";
}
