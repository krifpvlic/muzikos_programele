import 'dart:html';

import 'package:flutter/material.dart';
import 'package:file_system_access_api/file_system_access_api.dart';
import 'package:just_audio/just_audio.dart';

class MyCustomSource extends StreamAudioSource {
  final List<int> bytes;
  MyCustomSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}


class FolderSelect extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _FolderSelectState();

}

class _FolderSelectState extends State<FolderSelect>{

  @override
  void initState() {
    super.initState();
    if (!FileSystemAccess.supported) {
      print("NOT SUPPORTED!!!!");
      //TODO: implement unsupported popup
    }
  }

  Future<void> pickDirectory() async {
    try{
    FileSystemDirectoryHandle directory = await window.showDirectoryPicker(mode: PermissionMode.readwrite);

    // Iterable values might differ between calls depending on directory's content.
    await for (FileSystemHandle handle in directory.values) {
      if (handle.kind == FileSystemKind.file) {
        print("<file name='${handle.name}' />");
      } else if (handle.kind == FileSystemKind.directory) {
        print("<directory name='${handle.name}/' />");
        // You can create, move and delete files/directories. See example/ for more on this.
      }
    }
  } on AbortError {
  print("User dismissed dialog or picked a directory deemed too sensitive or dangerous.");
}
}






  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Tooltip(
        message: "Vietinio aplanko pasirinkimas",
        child: Text('Vietinio aplanko pasirinkimas')),),
    body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(onPressed: pickDirectory, icon: Icon(Icons.drive_folder_upload_outlined))
        ],
    ),


    );
  }
}

