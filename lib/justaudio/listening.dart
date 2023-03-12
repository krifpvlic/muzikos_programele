// This is a minimal example demonstrating a play/pause button and a seek bar.
// More advanced examples demonstrating other features can be found in the same
// directory as this example in the GitHub repository.

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'common.dart';
import 'package:rxdart/rxdart.dart';
import 'package:path/path.dart' as p;

String uri1 = "https://library.licejus.lt";

class ListPlay extends StatefulWidget {
  final List<String> linkList;
  final String username;
  final String password;
  final String basicAuth;
  const ListPlay({Key? key, required this.linkList,required this.basicAuth,required this.username,required this.password}) : super(key: key);

  @override
  ListPlayState createState() => ListPlayState();
}

class ListPlayState extends State<ListPlay> with WidgetsBindingObserver {
  final _player = AudioPlayer();
  int _selectedIndex = -1;
  @override
  void initState() {
    super.initState();
    ambiguate(WidgetsBinding.instance)!.addObserver(this);

    _init();
  }

  Future<void> _init() async {
    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
    // Try to load audio from a source and catch any errors.
    ///gal reiketu
    /*try {
      // AAC example: https://dl.espressif.com/dl/audio/ff-16b-2c-44100hz.aac
      await _player.setAudioSource(AudioSource.uri(Uri.parse(
          "${uri1}/menai/1_kursas/1_semestras/1.azijos%20taut%C5%B3%20muzika/01%20-%20Indija%20-%20Raga%20instrumentiam%20ansambliui.mp3"),headers: {'Authorization': basicAuth}));
    } catch (e) {
      print("Error loading audio source: $e");
    }*/
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
    return Scaffold(
      appBar: AppBar(
        title: Text("${Uri.decodeComponent(widget.linkList[0].split("/").sublist(4, 5).join("/"))}"),
      ),

      body:
          //Column(children:[
          ListView.builder(
        itemCount: widget.linkList.length,
        itemBuilder: (context, index) {
          return RadioListTile(
            title: Text(Uri.decodeComponent(
                p.basenameWithoutExtension(widget.linkList[index]))),
            value: index,
            groupValue: _selectedIndex,
            onChanged: (value) async {
              setState(() {
                _selectedIndex = value as int;
              });
              await _player.setAudioSource(AudioSource.uri(
                  Uri.parse("${uri1}${widget.linkList[_selectedIndex]}"),
                  headers: {'Authorization': widget.basicAuth}));
              //setState(() {
              //  duration = 0 as Duration;
              //});
            },
          );
        },
      ),
      //],
      //),
      /*///perkopijuosim logika is appbar
          floatingActionButton: true
              ? FloatingActionButton(
            onPressed: () {/*
              if (player.playing) {
                player.pause();
              } else {
                player.play();
              }*/
            },
            tooltip: 'Play',
            elevation: 0.0,
            child: Icon(
              //isPlaying ? Icons.pause : Icons.play_arrow,
                Icons.play_arrow
            ),
          )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          */
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        BottomAppBar(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                        positionData?.bufferedPosition ?? Duration.zero,
                    onChangeEnd: _player.seek,
                  );
                },
              ),
            ],
          ),
        ),
      ]),
    );
  }
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
