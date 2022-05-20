import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart' as p;

import 'receive.dart';

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
          leading: const Icon(Icons.cloud_upload_outlined),
          title: const Text("Choose images to send"),
        ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(
                child: const Text("Choose file(s)"),
                onPressed: () async {
                  FilePickerResult? result;
                  if (Platform.isIOS) {
                    result = await FilePicker.platform
                        .pickFiles(type: FileType.any, allowMultiple: true);
                  } else {
                    result = await FilePicker.platform
                        .pickFiles(type: FileType.any, allowMultiple: true);
                  }

                  if (result == null) {
                    return;
                  } else {
                    setState(() {
                      for (int i = 0; i < result!.count; i++) {
                        listFiles.add(result.files[i]);
                      }
                      print("path: " + listFiles[0].name);
                      print("extension: " + p.extension(listFiles[0].path!));
                    });
                  }
                },
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.grey[300])),
              ),
              if (Platform.isIOS)
                TextButton(
                  child: const Text("Choose image(s)"),
                  onPressed: () async {
                    FilePickerResult? result;
                    result = await FilePicker.platform
                        .pickFiles(type: FileType.media, allowMultiple: true);

                    if (result == null) {
                      return;
                    } else {
                      setState(() {
                        for (int i = 0; i < result!.count; i++) {
                          listFiles.add(result.files[i]);
                        }
                        print("path: " + listFiles[0].name);
                        print("extension: " + p.extension(listFiles[0].path!));
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
                      if (p.extension(listFiles[index].path!) == ".jpeg" ||
                          p.extension(listFiles[index].path!) == ".png" ||
                          p.extension(listFiles[index].path!) == ".gif" ||
                          p.extension(listFiles[index].path!) == ".jpg") {
                        return ListTile(
                          leading: Image.file(File(listFiles[index].path!)),
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Delete this file?"),
                                    actions: [
                                      TextButton(
                                        child: const Text("No"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text("Yes"),
                                        onPressed: () {
                                          setState(() {
                                            listFiles.removeAt(index);
                                          });

                                          Navigator.of(context).pop();
                                        },
                                      )
                                    ],
                                  );
                                });
                          },
                        );
                      } else {
                        return ListTile(
                          title: Text(listFiles[index].name),
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Delete this file?"),
                                    actions: [
                                      TextButton(
                                        child: const Text("No"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text("Yes"),
                                        onPressed: () {
                                          setState(() {
                                            listFiles.removeAt(index);
                                          });

                                          Navigator.of(context).pop();
                                        },
                                      )
                                    ],
                                  );
                                });
                          },
                        );
                      }
                    }),
              ),
              TextButton(
                child: const Text("Upload file(s)"),
                onPressed: () {
                  if (listFiles.isNotEmpty) {
                    startServer(listFiles[0].path!);
                    successDialog();
                  }
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

    server.listen((request) async {
      // Strip leading forward slash
      final uri = request.uri.path.substring(1);

      if (uri == "") {
        request.response.statusCode = 404;
        request.response.headers.set('Content-Type', 'text/html');
        for (int i = 0; i < listFiles.length; i++) {
          request.response.write('<a href="/$i">${listFiles[i].name}</a> <br>');
        }
        await request.response.close();
        return; // prob a bad idea
      }

      int? fileNum = int.tryParse(uri);
      if (fileNum == null) {
        request.response.statusCode = 400;
        request.response.write("File $uri does not exist.");
        await request.response.close();
        return;
      }
      final fileAtIndex = listFiles[fileNum];
      final actualFile = File(fileAtIndex.path!);
      request.response.headers
          .set("Content-Disposition", "filename=\"${fileAtIndex.name}\"");
      request.response.headers.contentLength = await actualFile.length();
      // Assume file is jpeg if there is no extension

      request.response.headers.contentType =
          ContentType("image", fileAtIndex.extension ?? "jpeg");

      // Better way to do it, read as stream
      var stream = actualFile.openRead();
      await stream.forEach((byte) {
        request.response.add(byte);
      });
      await request.response.flush();
      await request.response.close();
    });
    setState(() {
      if (server.serverHeader != null) {
        print("Server running on IP : " +
            server.address.toString() +
            " On Port : " +
            server.port.toString());
      }
    });
  }

  resetPage() {
    setState(() {});
  }

  failureDialog() {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text('Please select a file before uploading!'),
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
        });
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
        });
  }
}
