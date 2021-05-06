import 'dart:async';
//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class FileTracker extends ChangeNotifier {
  List<String> fileList = [];

  void addFileToList(String filePath) {
    fileList.add(filePath);

    notifyListeners();
  }
}

class PlayerManager extends ChangeNotifier {
  List<FlutterSoundPlayer> _players = [];
  List<String> _correspondingFiles = [];

  List<String> get correspondingFiles => _correspondingFiles;

  List<FlutterSoundPlayer> get players => _players;

  void handleSelectionChange(
      bool isSelected, FlutterSoundPlayer player, String file) {
    if (isSelected) {
      _players.add(player);
      _correspondingFiles.add(file);
    } else if (!isSelected) {
      _players.remove(player);
      _correspondingFiles.remove(file);
    }
  }

  void playSelectedPlayers() {}
}

class Track extends StatefulWidget {
  final int _index;
  final String _filePath;

  Track(this._index, this._filePath);

  @override
  _TrackState createState() => _TrackState(_filePath);
}

class _TrackState extends State<Track> {
  FlutterSoundPlayer _myPlayer = FlutterSoundPlayer();
  bool _isSelected = false;
  bool _isPlaying = false;
  String _filePath;

  _TrackState(this._filePath);

  @override
  void initState() {
    _myPlayer.openAudioSession().then((value) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _myPlayer.closeAudioSession();
    _myPlayer = null;
    super.dispose();
  }

  void play() async {
    await _myPlayer.startPlayer(
        fromURI: _filePath,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
    _isPlaying = true;
  }

  Future<void> stopPlayer() async {
    if (_myPlayer != null) {
      await _myPlayer.stopPlayer();
    }
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _isSelected ? Colors.blue[200] : Colors.white70,
      shadowColor: Colors.grey,
      elevation: 2.0,
      margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: ListTile(
        leading: IconButton(
          icon: _isPlaying
              ? Icon(Icons.stop, color: Colors.red)
              : Icon(Icons.play_arrow, color: Colors.green),
          onPressed: () {
            if (!_isPlaying) {
              play();
            } else if (_isPlaying) {
              stopPlayer();
            }
          },
        ),
        selected: _isSelected,
        trailing: CircleAvatar(
          child: Text('${widget._index}'),
          backgroundColor: Colors.black38,
          foregroundColor: Colors.white,
          radius: 15,
        ),
        onTap: () {
          setState(() {
            _isSelected = !_isSelected;
          });
          Provider.of<PlayerManager>(context, listen: false)
              .handleSelectionChange(_isSelected, _myPlayer, _filePath);
        },
      ),
    );
  }
}

class TrackPool extends StatefulWidget {
  @override
  _TrackPoolState createState() => _TrackPoolState();
}

class _TrackPoolState extends State<TrackPool> {
  List<Track> trackList;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer<FileTracker>(
        builder: (context, fileTracker, child) {
          return ListView.builder(
            itemCount: fileTracker.fileList.length,
            itemBuilder: (context, index) {
              return Track(index + 1, fileTracker.fileList[index]);
            },
          );
        },
      ),
    );
  }
}

class Transport extends StatefulWidget {
  @override
  _TransportState createState() => _TransportState();
}

class _TransportState extends State<Transport> {
  FlutterSoundRecorder _myRecorder = FlutterSoundRecorder();
  FlutterSoundPlayer _myPlayer = FlutterSoundPlayer();
  int _trackIndex = 1;
  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _duration = new Duration(seconds: 0);
  double _decibels = 1;
  String _filePath;

  @override
  void initState() {
    _myRecorder.openAudioSession().then((value) {
      setState(() {});
    });
    _myRecorder.setSubscriptionDuration(Duration(milliseconds: 100));
    _myPlayer.openAudioSession().then((value) {
      setState(() {});
    });
    updateFilePath();
    super.initState();
  }

  void updateFilePath() {
    _filePath = 'testFile$_trackIndex.aac';
  }

  @override
  void dispose() {
    _myRecorder.closeAudioSession();
    _myRecorder = null;
    _myPlayer.closeAudioSession();
    _myPlayer = null;
    super.dispose();
  }

  Future<void> startRecording() async {
    await _myRecorder
        .startRecorder(
          toFile: _filePath,
          codec: Codec.aacADTS,
        )
        .then((value) => {
              _myRecorder.onProgress.listen((event) {
                setState(() {
                  _duration = event.duration;
                  _decibels = event.decibels;
                });
              })
            });
  }

  Future<void> _stopRecording() async {
    await _myRecorder.stopRecorder();
    setState(() {
      _isRecording = !_isRecording;
      _decibels = 0.01;
    });
    Provider.of<FileTracker>(context, listen: false).addFileToList(_filePath);
    _trackIndex++;
    updateFilePath();
  }

  void play(String filePath, FlutterSoundPlayer player) async {
    await player.startPlayer(
        fromURI: filePath, codec: Codec.aacADTS, whenFinished: () {
          print(filePath);
    });
  }

  Future<void> stopPlayer() async {
    if (_myPlayer != null) {
      await _myPlayer.stopPlayer();
    }
    _isPlaying = false;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              icon: _isRecording
                  ? Icon(
                      Icons.stop,
                      color: Colors.grey,
                    )
                  : Icon(Icons.fiber_manual_record, color: Colors.red),
              iconSize: 75,
              onPressed: () {
                if (!_isRecording) {
                  startRecording();
                  setState(() {
                    _isRecording = !_isRecording;
                  });
                } else if (_isRecording) {
                  _stopRecording();
                }
              },
            ),
            Consumer<PlayerManager>(builder: (context, playerManager, child) {
              return IconButton(
                icon: Icon(Icons.play_arrow, color: Colors.green),
                iconSize: 75,
                onPressed: () {
                  if (playerManager.players.isNotEmpty) {
                    for (var i = 0; i < playerManager.players.length; i++) {
                      play(playerManager.correspondingFiles[i],
                          playerManager.players[i]);
                    }
                  } else {
                    play(_filePath, _myPlayer);
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  }
                },
              );
            }),
          ]),
          Text('File name: $_filePath'),
          AnimatedContainer(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.blue,
            ),
            margin: EdgeInsets.all(10),
            width: 10 + (_decibels * 5),
            height: 10,
            duration: (Duration(milliseconds: 250)),
          ),
          Text(
              'Recording length: ${_duration.inSeconds}:${_duration.inMilliseconds.remainder(1000)}'),
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MultiProvider(providers: [
        ChangeNotifierProvider<FileTracker>(create: (_) => FileTracker()),
        ChangeNotifierProvider<PlayerManager>(create: (_) => PlayerManager()),
      ], child: RecordingPage(title: 'Multi-Track Recorder')),
    );
  }
}

class RecordingPage extends StatefulWidget {
  RecordingPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _RecordingPageState createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  @override
  void initState() {
    Permission.microphone.request();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          TrackPool(),
          Divider(
            color: Colors.black12,
            thickness: 3,
            indent: 10,
            endIndent: 10,
          ),
          Transport(),
        ],
      ),
    );
  }
}
