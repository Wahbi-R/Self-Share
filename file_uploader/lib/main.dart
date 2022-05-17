import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:network_info_plus/network_info_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self Share',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Self Share'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<PlatformFile> listFiles = [];

  late HttpServer server;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Choose images to send"),
        ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(
                child: const Text("Choose file(s)"),
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(type: FileType.media);
                  if (result == null) {
                    return;
                  } else {
                    setState(() {
                      listFiles = result.files;
                    });
                  }
                },
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.grey[300])),
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: listFiles.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Image.file(File(listFiles[index].path!)),
                      );
                    }),
              ),
              TextButton(
                child: const Text("Upload file(s)"),
                onPressed: () {
                  startServer(listFiles[0].path!);
                  successDialog();
                },
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.grey[300])),
              )
            ]));
  }

  startServer(fileName) async {
    server = await HttpServer.bind('0.0.0.0', 8080);
    print("Server running on IP : " +
        server.address.toString() +
        " On Port : " +
        server.port.toString());
    var request =
        http.MultipartRequest("POST", Uri.parse('http://0.0.0.0:8080'));
    request.files.add(await http.MultipartFile.fromPath('picture', fileName));
    request.send().then((response) {
      if (response.statusCode == 200) print("Uploaded!");
    });

    await for (var req in server) {
      File currentFile = new File(fileName);
      currentFile.readAsBytes().then((raw) {
        req.response.headers.set('Content-Type', 'image/jpeg');
        req.response.headers.set('Content-Length', raw.length);
        req.response.add(raw);
        req.response.close();
      });
    }
    setState(() {
      print("Server running on IP : " +
          server.address.toString() +
          " On Port : " +
          server.port.toString());
    });
  }

  resetPage() {
    setState(() {});
  }

  successDialog() async {
    final info = NetworkInfo();
    var address = await info.getWifiIP();
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text('Your files are uploaded!'),
              content: Text('''Access them on $address:8080
Once you press ok, the image will no longer be accessable.'''),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    server.close();
                    listFiles.clear();
                    Navigator.pop(context);
                    resetPage();
                  },
                  child: const Text("OK"),
                )
              ],
            );
          });
        }
        // builder: (context) => AlertDialog(
        //       title: const Text('Your files are uploaded!'),
        //       content: Text('''Access them on $address:8080
        //       Once you press ok, the image will no longer be accessable.'''),
        //       actions: <Widget>[
        //         TextButton(
        //           onPressed: () {
        //             server.close();
        //             listFiles.clear();
        //             Navigator.pop(context);
        //           },
        //           child: const Text("OK"),
        //         )
        //       ],
        //     )
        );
  }
}

// startServer() async {
//   var server = await HttpServer.bind("localhost", 8080);
//   print(server.address);
//   await server.forEach((HttpRequest request) {
//     request.response.write('Hello, world!');
//     request.response.close();
//   });
// }
