// ignore_for_file: must_be_immutable

import 'package:demoapp/check_permission.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as Path;

import 'dir_path.dart';

class PlayerScreen extends StatefulWidget {
  String? url;
  String? name;
  String? disc;
  bool? fileExist;

  PlayerScreen(this.url, this.name, this.disc, this.fileExist, {super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  CancelToken cancelToken = CancelToken();

  VideoPlayerController? _controller;

  bool disc = false;
  double? size;

  bool isPermission = false;
  var checkAllPermission = CheckPermission();

  bool isDownloading = false;
  bool isDownloadingPaused = false;
  bool fileExists = false;
  double per = 0;

  late String filePath;
  String? fileName;
  var getPathFile = DirectoryPath();

  checkPermission() async {
    var permission = await checkAllPermission.permission();
    if (permission) {
      setState(() {
        isPermission = true;
      });
    }
  }

  void pauseDownload() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel("Download paused");
      setState(() {
        isDownloading = true;
        fileExists = false;
      });
    }
  }

  void resumeDownload() {
    cancelToken = CancelToken();
    downloadFile();
    setState(() {
      isDownloading = true;
      fileExists = false;
    });
  }

  void cancelDownload() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel("Download canceled");
      setState(() {
        isDownloading = false;
        fileExists = false;
      });
    }
  }

  downloadFile() async {
    var storePath = await getPathFile.getPath();
    filePath = "$storePath/$fileName";
    try {
      setState(() {
        isDownloading = true;
      });

      await Dio().download(widget.url ?? "", filePath,
          onReceiveProgress: (count, total) {
        setState(() {
          per = (count / total);
        });
      }, cancelToken: cancelToken);
      setState(() {
        isDownloading = false;
        fileExists = true;
      });
    } catch (e) {
      setState(() {
        isDownloading = false;
      });
    }
  }

  checkFileExist() async {
    var storePath = await getPathFile.getPath();
    filePath = "$storePath/$fileName";

    bool fileExistChecker = await File(filePath).exists();

    setState(() {
      fileExists = fileExistChecker;
    });

    String newUrl = widget.url!.replaceRange(0, 4, "https");

    if (fileExists == true) {
      _controller = VideoPlayerController.file(
        File(filePath),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    } else {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(newUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    }

    _controller?.setLooping(true);
    _controller?.initialize();
    _controller?.addListener(() {
      setState(() {});
    });
    _controller?.play();
  }

  Future<int> getRemoteVideoFileSize() async {
    try {
      final response;
      if (widget.fileExist ?? false) {
        var fSize = await File(widget.url ?? "").length();
        setState(() {
          size = fSize / 1024 / 1024;
        });
        return fSize;
      } else {
        response = await http.head(Uri.parse(widget.url ?? ""));
        if (response.statusCode == 200) {
          final contentLength = response.headers['content-length'];
          if (contentLength != null) {
            final fileSizeInBytes = int.tryParse(contentLength);

            setState(() {
              size = fileSizeInBytes! / 1024 / 1024;
            });

            return fileSizeInBytes ??
                -1; // Return file size or -1 if content-length is not a valid integer
          } else {
            return -1; // Content-length header not found
          }
        } else {
          return -1; // Error response from the server
        }
      }
    } catch (e) {
      print("Error: $e");
      return -1;
    }
  }

  @override
  void initState() {
    super.initState();
    checkPermission();
    getRemoteVideoFileSize();
    setState(() {
      fileName = Path.basename(widget.name ?? "");
    });

    String newUrl = widget.url!.replaceRange(0, 4, "https");

    if (widget.fileExist == true) {
      _controller = VideoPlayerController.file(
        File(widget.url ?? ""),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    } else {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(newUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    }

    _controller?.setLooping(true);
    _controller?.initialize();
    _controller?.addListener(() {
      setState(() {});
    });
    _controller?.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "MyPlayer",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 25),
              ),
              const SizedBox(
                height: 10,
              ),
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    VideoPlayer(
                      _controller!,
                    ),
                    VideoProgressIndicator(_controller!, allowScrubbing: true),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  _controller!.value.isPlaying
                      ? GestureDetector(
                          onTap: () {
                            _controller?.pause();
                          },
                          child: const Icon(
                            CupertinoIcons.pause_circle_fill,
                            size: 50,
                          ))
                      : GestureDetector(
                          onTap: () {
                            _controller?.play();
                          },
                          child: const Icon(
                            CupertinoIcons.play_circle_fill,
                            size: 50,
                          )),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    widget.name ?? "",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(
                height: 25,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (widget.fileExist == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("File is already downloaded.")));
                        } else {

                          downloadFile();
                        }
                      },
                      child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[350]),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              isDownloading != false
                                  ? const CircularProgressIndicator(
                                      color: Colors.black,
                                    )
                                  : const Icon(
                                      CupertinoIcons.arrow_down_circle_fill),
                              Text(
                                per == null
                                    ? ""
                                    : "${(per * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          )),
                    ),
                  ),
                  const SizedBox(
                    width: 25,
                  ),
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[350]),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.doc_circle_fill),
                          Text(
                            "${size?.toStringAsFixed(0)} MB",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              isDownloading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (isDownloadingPaused) {
                                setState(() {
                                  isDownloadingPaused = false;
                                });
                                resumeDownload();
                              } else {
                                setState(() {
                                  isDownloadingPaused = true;
                                });
                                pauseDownload();
                              }
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[350]),
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: isDownloadingPaused
                                      ? const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(CupertinoIcons
                                                .play_circle_fill),
                                            Text("resume Downloading"),
                                          ],
                                        )
                                      : const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(CupertinoIcons
                                                .pause_circle_fill),
                                            Text("Paused Downloading"),
                                          ],
                                        ),
                                )),
                          ),
                        ),
                        const SizedBox(
                          width: 25,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              cancelDownload();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Downloading cancel")));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[350]),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.close),
                                    Text("Downloading Cancelled "),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
              const SizedBox(
                height: 25,
              ),
              Container(
                decoration: const BoxDecoration(
                    color: CupertinoColors.systemGrey3,
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: disc
                          ? Text(widget.disc ?? "")
                          : Text(
                              widget.disc ?? "",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () {
                          if (disc) {
                            setState(() {
                              disc = false;
                            });
                          } else {
                            setState(() {
                              disc = true;
                            });
                          }
                        },
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.grey,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: disc
                                  ? const Text("Show Less",
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700))
                                  : const Text(
                                      "Show More",
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
