import 'dart:io';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

bool serverOpen = false;

class ReceivePage extends StatelessWidget {
  const ReceivePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              if (serverOpen == true) {
                //server.close();
              }
            },
            icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Second Route'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            startServer();
          },
          child: const Text('Open server'),
        ),
      ),
    );
  }
}

startServer() async {
  if (await Permission.contacts.request().isGranted) {
    // Either the permission was already granted before or the user just granted it.
  }

// You can request multiple permissions at once.
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.storage,
  ].request();
  Permission.storage.request();
  print(statuses[Permission.storage]);
  serverOpen = true;
  HttpServer server = await HttpServer.bind('0.0.0.0', 8080);
  print("Server running on IP : " +
      server.address.toString() +
      " On Port : " +
      server.port.toString());
  await for (HttpRequest request in server) {
    if (request.method == 'POST') {
      print("SOMETHING UPLOADED");
      grabFile();
    } else {
      request.response.headers.set('content-type', 'text/html');
      request.response.write('''<form action="/" method="post">
<input type="file"
       id="sendFile" name="sendFile"
       accept="image/png, image/jpeg">
       <input type="submit" value="Submit">
</form>
''');
      await request.response.close();
    }
  }
//   server.listen((request) async {
//     request.response.headers.set('content-type', 'text/html');
//     request.response.write('''<form action="/" method="post">
// <input type="file"
//        id="sendFile" name="sendFile"
//        accept="image/png, image/jpeg">
//        <input type="submit" value="Submit">
// </form>
// ''');
//     await request.response.close();
//   });
}

grabFile() async {
  Directory root = getExternalStorageDirectory() as Directory;
  print(root);

  String directoryPath = root.toString() + "/temp";
  final request2 =
      await HttpClient().getUrl(Uri.parse('http://192.168.2.160:8080/'));
  final response2 = await request2.close();
  File('$directoryPath/foo.jpeg').create(recursive: true).then(
      (value) => response2.pipe(File('$directoryPath/foo.jpeg').openWrite()));
}
