// This is a minimal example demonstrating a play/pause button and a seek bar.
// More advanced examples demonstrating other features can be found in the same
// directory as this example in the GitHub repository.

import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'common.dart';
import 'package:rxdart/rxdart.dart';
import 'package:path/path.dart' as Path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

List<Map<String, dynamic>> createMusicPiecesList(List<String> links) {
  return List.generate(
      links.length,
      (i) => {
            "link": links[i],
            "name":
                Uri.decodeComponent(Path.basenameWithoutExtension(links[i])),
            "correct": 0,
            "incorrect": 0
          });
}

List<int> divideIntoGroups(int length) {
  List<int> numbers = List.generate(length, (i) => i);
  numbers.shuffle();
  return numbers;
}

class LearningPlay extends StatefulWidget {
  final List<String> linkList;
  final String username;
  final String password;
  final String basicAuth;
  const LearningPlay(
      {Key? key,
      required this.linkList,
      required this.basicAuth,
      required this.username,
      required this.password})
      : super(key: key);

  @override
  LearningPlayState createState() => LearningPlayState();
}

class LearningPlayState extends State<LearningPlay>
    with WidgetsBindingObserver, TraceableClientMixin {
  final GlobalKey<State> _key = GlobalKey<State>();
  var _isRandomize = true;
  var _selectedIndex;
  final _player = AudioPlayer();
  late List<Map<String, dynamic>> musicPiecesList;
  late List<int> queue;
  var showControls = false;
  int queuePos = 0;
  bool okPressed = false;
  bool goalTracked = false;
  int totalcorrect=0;
  String uri1 = "https://library.licejus.lt";

  Future<void> play(BuildContext context) async {
    try {
      await _player.setAudioSource(AudioSource.uri(
          Uri.parse("${uri1}${musicPiecesList[queue[queuePos]]['link']}"),
          headers: {'Authorization': widget.basicAuth}));
    } catch (e) {
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
                          style:
                              TextStyle(color: Color(0xff8484f2), fontSize: 20),
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
                    play(context);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
    }
    await _player.load();
    if (_player.duration != null) {
      if (_player.duration!.inSeconds > 60) {
        if (_isRandomize) {
          _player.seek(Duration(
              seconds: Random().nextInt(_player.duration!.inSeconds - 60)));
        }
        int initialQueuePos = queuePos;

        Future.delayed(Duration(seconds: 60), () {
          if (queuePos == initialQueuePos) _player.stop();
        });
      }
    }

    _player.play();
  }

  void handleIncorrectGuess(List<int> queue, int piecePosition,
      List<Map<String, dynamic>> musicPiecesList) {
    setState(() {
      showControls = false;
    });

    // make the range it could appear in the next group +-3 (but limits 1-10)
    musicPiecesList[queue[piecePosition]]['incorrect']++;
    int rangeStart = piecePosition - 3 + 10;
    if (kDebugMode) {
      print(rangeStart);
    }
    if (rangeStart < (piecePosition / 10 + 1).toInt() * 10)
      rangeStart = (piecePosition / 10 + 1).toInt() * 10;
    if (kDebugMode) {
      print((piecePosition / 10 + 1).toInt() * 10);
    }
    if (kDebugMode) {
      print(rangeStart);
    }
    int rangeEnd = piecePosition + 3 + 10;
    if (kDebugMode) {
      print(rangeEnd);
    }
    if (rangeEnd > (piecePosition / 10 + 2).toInt() * 10)
      rangeEnd = (piecePosition / 10 + 2).toInt() * 10;
    if (kDebugMode) {
      print((piecePosition / 10 + 2).toInt() * 10);
    }
    if (kDebugMode) {
      print(rangeEnd);
    }
    if (rangeStart >= queue.length) {
      queue.add(queue[piecePosition]);
    } else if (rangeEnd >= queue.length) {
      queue.add(queue[piecePosition]);
    } else {
      int insertIndex = rangeStart + (Random().nextInt(rangeEnd - rangeStart));
      queue.insert(insertIndex, queue[piecePosition]);
      if (musicPiecesList[queue[piecePosition]]['incorrect'] == 1) {
        queue.add(queue[piecePosition]);
      }
    }
    setState(() {
      queuePos++;
    });
    _player.stop();
    if (kDebugMode) {
      print(queue);
    }
  }

  void showInfo(BuildContext context, bool barrierDismissible) {
    showDialog(
      barrierDismissible: barrierDismissible,
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text('Informacija'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        'Dabar grojamas ${(queuePos + 1).toString()} kūrinys iš ${(queue.length).toString()} eilėje.\n\nTestavimo veikimo principas:\nAtsitiktine tvarka leidžiami kūriniai, tikslas kuo daugiau jų atspėti. Atspėjus kūrinį pereinama prie kito, o neatspėjus parodomas teisingas atsakymas ir kūrinys vėl pridedamas prie eilės. Kūriniai grojami minutę.\n'),
                    Icon(
                      Icons.last_page_outlined,
                    ),
                    Text(
                        'Paspaudus šį mygtuką galima pasiklausyti kūrinį iš naujo arba kitos jo dalies\n'),
                    Icon(
                      Icons.start_rounded,
                    ),
                    Text(
                        'Paspaudus šį mygtuką kūriniai bus leidžiami nuo jų pradžios\n'),
                    Icon(
                      Icons.shuffle_rounded,
                    ),
                    Text(
                        'Paspaudus šį mygtuką kūrinių pradžia bus atsitiktinai parenkama')
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    okPressed = true;
                  },
                ),
              ],
            ));
  }

  @override
  void initState() {
    super.initState();
    ambiguate(WidgetsBinding.instance)!.addObserver(this);
    musicPiecesList = createMusicPiecesList(widget.linkList);
    queue = divideIntoGroups(widget.linkList.length);
    if (kDebugMode) {
      print(queue);
    }
    _init(context);
  }

  Future<void> _init(BuildContext context) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
    if (kDebugMode) {
      print("${uri1}${musicPiecesList[queuePos]['link']}");
    }
    final prefs = await SharedPreferences.getInstance();
    double infoLevel = prefs.getDouble('infoLevel') ?? 0;
    if (infoLevel < 2) {
      Future.delayed(Duration.zero, () {
        if (_key.currentContext != null) {
          showInfo(_key.currentContext!,false);
        }
        prefs.setDouble('infoLevel', 2);
      });
    } else
      okPressed = true;
    while (!okPressed) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    play(context);
    // Try to load audio from a source and catch any errors.

    // AAC example: https://dl.espressif.com/dl/audio/ff-16b-2c-44100hz.aac
    ///await _player.setAudioSource(AudioSource.uri(Uri.parse(
    ///    "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3")));
  }

  @override
  void dispose() {
    ambiguate(WidgetsBinding.instance)!.removeObserver(this);
    // Release decoders and buffers back to the operating system making them
    // available for other apps to use.
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
      _player.stop();
    }
  }

  /// Collects the data useful for displaying in a seek bar, using a handy
  /// feature of rx_dart to combine the 3 streams of interest into one.
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  Widget build(BuildContext context) {
    void handleCorrectGuess(List<int> queue, int piecePosition,
        List<Map<String, dynamic>> musicPiecesList) {
      setState(() {
        showControls = false;
      });
      musicPiecesList[queue[piecePosition]]['correct']++;
      if (queuePos < queue.length - 1) {
        setState(() {
          queuePos++;
        });
      } else {
        Navigator.of(context).pop();
      }
      totalcorrect++;
      if(totalcorrect>(musicPiecesList.length/3) && totalcorrect>=7 && !goalTracked){
        MatomoTracker.instance.trackGoal(1);
        goalTracked = true;
      }
    }

    return Scaffold(
        key: _key,
        appBar:
            AppBar(title: const Text("Pasirinkite kūrinį"), actions: <Widget>[
          IconButton(
            icon: _isRandomize
                ? Icon(Icons.start_rounded)
                : Icon(Icons.shuffle_rounded),
            onPressed: () {
              setState(() {
                _isRandomize = !_isRandomize;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.last_page_outlined),
            onPressed: () {
              setState(() {
                showControls = true;
              });
            },
          ),
          if (kDebugMode)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                handleCorrectGuess(queue, queuePos, musicPiecesList);
                play(context);
              },
            ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showInfo(context,true);
            },
          ),
        ]),
        body: ListView.builder(
          itemCount: musicPiecesList.length,
          itemBuilder: (context, index) {
            return RadioListTile(
              title: Text(musicPiecesList[index]["name"]),
              value: index,
              groupValue: _selectedIndex,
              onChanged: (value) async {
                setState(() {
                  _selectedIndex = value as int;
                });
                if (kDebugMode) print(_selectedIndex);
                //await _player.setAudioSource(AudioSource.uri(
                //    Uri.parse("${uri1}${widget.linkList[_selectedIndex]}"),
                //    headers: {'Authorization': basicAuth}));
                //setState(() {
                //  duration = 0 as Duration;
                //});
              },
            );
          },
        ),
        floatingActionButton: true
            ? FloatingActionButton(
                onPressed: _selectedIndex != null
                    ? () {
                        if (_selectedIndex == queue[queuePos]) {
                          handleCorrectGuess(queue, queuePos, musicPiecesList);
                          play(context);
                        } else {
                          handleIncorrectGuess(
                              queue, queuePos, musicPiecesList);
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Neteisingai'),
                                content: Text(
                                    'Teisingas atsakymas: ${musicPiecesList[queue[queuePos - 1]]["name"]}'),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('OK'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          ).then((_) => play(context));
                        }
                      }
                    : null,
                tooltip: 'Pasirinkti',
                elevation: 0.0,
                child: Icon(Icons.check_rounded),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomSheet: showControls
            ? Column(mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            "${(queuePos + 1).toString()}/${(queue.length).toString()}"),
                        if (kDebugMode)
                          Text(musicPiecesList[queue[queuePos]]['name']),
                        if (kDebugMode) Text(queue[queuePos].toString()),
                        // Display play/pause button and volume/speed sliders.
                        ControlButtons(_player),
                        // Display seek bar. Using StreamBuilder, this widget rebuilds
                        // each time the position, buffered position or duration changes.
                        StreamBuilder<PositionData>(
                          stream: _positionDataStream,
                          builder: (context, snapshot) {
                            final positionData = snapshot.data;
                            return SeekBar(
                              duration: positionData?.duration ?? Duration.zero,
                              position: positionData?.position ?? Duration.zero,
                              bufferedPosition:
                                  positionData?.bufferedPosition ??
                                      Duration.zero,
                              onChangeEnd: _player.seek,
                            );
                          },
                        ),
                      ],



              )
            : null);
  }

  @override
  String get traceName => 'Testing';
  @override
  String get traceTitle => "GabalAI";
}

/// Displays the play/pause button and volume/speed sliders.
class ControlButtons extends StatelessWidget {
  final AudioPlayer player;

  const ControlButtons(this.player, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Opens volume slider dialog
        IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: () {
            showSliderDialog(
              context: context,
              title: "Garsas",
              divisions: 10,
              min: 0.0,
              max: 1.0,
              value: player.volume,
              stream: player.volumeStream,
              onChanged: player.setVolume,
            );
          },
        ),

        /// This StreamBuilder rebuilds whenever the player state changes, which
        /// includes the playing/paused state and also the
        /// loading/buffering/ready state. Depending on the state we show the
        /// appropriate button or loading indicator.
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 64.0,
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64.0,
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 64.0,
                onPressed: () => player.seek(Duration.zero),
              );
            }
          },
        ),
        // Opens speed slider dialog
        StreamBuilder<double>(
          stream: player.speedStream,
          builder: (context, snapshot) => IconButton(
            icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              showSliderDialog(
                context: context,
                title: "Greitis",
                divisions: 15,
                min: 0.5,
                max: 2,
                value: player.speed,
                stream: player.speedStream,
                onChanged: player.setSpeed,
              );
            },
          ),
        ),
      ],
    );
  }
}
