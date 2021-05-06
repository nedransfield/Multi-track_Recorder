import 'package:flutter/material.dart';

class Track extends StatefulWidget {
  final int index;
  final ListTile tile = new ListTile();

  Track(this.index);

  @override
  _TrackState createState() => _TrackState();
}

class _TrackState extends State<Track> {
  bool _isEnabled = true;
  bool _isPlaying = false;

  void disable() {

  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white70,
      shadowColor: Colors.grey,
      elevation: 2.0,
      margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: ListTile(
        leading: IconButton(
          icon: _isPlaying
              ? Icon(Icons.stop, color: Colors.red)
              : Icon(Icons.play_arrow, color: Colors.green),
          onPressed: () {},

        ),
        trailing: Text('${widget.index}'),
        onTap: () {
          this._isEnabled = !_isEnabled;

        },),
    );
  }
}