import 'dart:convert';
import 'dart:io';
import 'package:demoapp/ApiServices.dart';
import 'package:demoapp/playerScreen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'check_permission.dart';
import 'dir_path.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool disc = false;
  double? size;

  bool isPermission = false;
  var checkAllPermission = CheckPermission();

  bool isDownloading = false;
  bool fileExists = false;
  double per = 0;

  late String filePath;
  var getPathFile = DirectoryPath();
  @override
  void initState() {
    super.initState();
  }

   Future<bool> checkFileExist(String name) async {

    var storePath = await getPathFile.getPath();
    filePath = "$storePath/$name";

    bool fileExistChecker = await File(filePath).exists();

    setState(() {
      fileExists = fileExistChecker;
    });

    return fileExists;

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder(
            future: ApiServices().fetchData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}',style: const TextStyle(fontSize: 18),));
              } else {
                return ListView.builder(
                  itemCount: snapshot.data?["categories"][0]["videos"].length,
                  itemBuilder: (context, index) {
                    final item =
                        snapshot.data?["categories"][0]["videos"][index];
                    final image = snapshot.data?["categories"][0]["videos"]
                        [index]['thumb'];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          checkFileExist(item['title']).then((value) {
                            if(value) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerScreen(
                                      filePath, item['title'],item['description'],value),
                                ),
                              );
                            }else{
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerScreen(
                                      item["sources"][0], item['title'],item['description'],value),
                                ),
                              );
                            }
                          });


                        },
                        child: Column(
                          children: [
                            Card(
                                child: Image.network(
                                    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/$image")),
                            Row(
                              children: [
                                Text(
                                  item['title'],
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                          // Add more widgets to display other data fields
                        ),
                      ),
                    );
                  },
                );
              }
            }),
      ),
    );
  }
}
