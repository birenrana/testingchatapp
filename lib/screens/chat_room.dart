import 'dart:io';
import 'package:custom_chat/custom_chat.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

class ChatRoom extends StatefulWidget {
  final Map<String, dynamic> userMap;
  final String chatRoomId;

  const ChatRoom({super.key, required this.chatRoomId, required this.userMap});

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController message = TextEditingController();

  final TextEditingController editMessage = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool emojiShowing = false;
  File? imageFile;

  Future getImage() async {
    ImagePicker picker = ImagePicker();
    await picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {
    String fileName = const Uuid().v1();
    int status = 1;

    await _firestore
        .collection('chatroom')
        .doc(widget.chatRoomId)
        .collection('chats')
        .doc(fileName)
        .set({
      "sendby": _auth.currentUser!.displayName,
      "message": "",
      "type": "image",
      "time": FieldValue.serverTimestamp(),
    });

    var ref =
        FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");

    var uploadTask = await ref.putFile(imageFile!).catchError((error) async {
      await _firestore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(fileName)
          .delete();

      status = 0;
    });

    if (status == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();

      await _firestore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(fileName)
          .update({"message": imageUrl});

      print(imageUrl);
    }
  }

  // void onSendMessage() async {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection("user")
              .doc(widget.userMap['uid'])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.data != null) {
              return Column(
                children: [
                  Text(widget.userMap['name']),
                  Text(
                    snapshot.data!['status'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              );
            } else {
              return Container();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Expanded(
            child: Container(
              color: Colors.transparent,
              height: size.height * 0.8,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chatroom')
                    .doc(widget.chatRoomId)
                    .collection('chats')
                    .orderBy('time', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    return ListView.builder(
                      reverse: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        FlutterChat.seenChatList(
                            chatRoomId: widget.chatRoomId,
                            chatRoomCollectionName: 'chatroom',
                            chatsCollectionName: 'chats',
                            currentUserName: _auth.currentUser!.displayName!);
                        // updateChatList(
                        //     chatRoomId: widget.chatRoomId,
                        //     chatRoomCollectionName: 'chatroom',
                        //     chatsCollectionName: 'chats');

                        Map<String, dynamic> map = snapshot.data!.docs[index]
                            .data() as Map<String, dynamic>;
                        return messages(
                            size, map, context, snapshot.data!.docs[index].id);
                      },
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ),

          FlutterChat().messageField(
              // onPrefixIcon: () {
              //   setState(() {
              //     emojiShowing = !emojiShowing;
              //   });
              //   if (emojiShowing != false) {
              //     FocusScope.of(context).unfocus();
              //   }
              // },
              // isSuffixIconIsVisible: false,
              // suffixIcon: IconButton(
              //     onPressed: () {
              //       FlutterChat.getImage(
              //           senderName: _auth.currentUser!.displayName!,
              //           chatRoomId: widget.chatRoomId,
              //           chatRoomCollectionName: 'chatroom',
              //           chatsCollectionName: 'chats',
              //           type: 'image',
              //           time: FieldValue.serverTimestamp());
              //     },
              //     icon: const Icon(Icons.photo)
              //     // onPressed: () => getImage(),
              //     // icon: const Icon(Icons.photo),
              //     ),

              senderName: _auth.currentUser!.displayName!,
              chatRoomId: widget.chatRoomId,
              chatRoomCollectionName: 'chatroom',
              chatsCollectionName: 'chats',
              msgTextController: message,
              type: 'text',
              time: FieldValue.serverTimestamp(),
              // isSendButtonEnable: message.text.isNotEmpty,
              context: context),
          // Visibility(
          //     visible: emojiShowing,
          //     child: Expanded(
          //         child: FlutterChat().emojiPicker(
          //             msgTextController: message, context: context))),

          // Padding      (
          //   padding: const EdgeInsets.only(left: 28.0, right: 28.0),
          //   child: Container(
          //     color: Colors.transparent,
          //     alignment: Alignment.bottomCenter,
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Expanded(
          //           child: TextField(
          //               controller: message,
          //               decoration: InputDecoration(
          //                 contentPadding: const EdgeInsets.symmetric(
          //                     vertical: 8.0, horizontal: 20.0),
          //                 hintText: "Send Message",
          //                 hintStyle: const TextStyle(color: Colors.blueGrey),
          //                 fillColor: Colors.white,
          //                 filled: true,
          //                 border: OutlineInputBorder(
          //                   borderSide: const BorderSide(color: Colors.blue),
          //                   borderRadius: BorderRadius.circular(10),
          //                 ),
          //                 focusedBorder: OutlineInputBorder(
          //                   borderSide: const BorderSide(color: Colors.blue),
          //                   borderRadius: BorderRadius.circular(10),
          //                 ),
          //                 enabledBorder: OutlineInputBorder(
          //                   borderSide: const BorderSide(color: Colors.blue),
          //                   borderRadius: BorderRadius.circular(10),
          //                 ),
          //               )),
          //         ),
          //         const SizedBox(width: 5),
          //         FloatingActionButton(
          //           onPressed: () {
          //             FlutterChat.sendMessage(
          //                 senderName: _auth.currentUser!.displayName!,
          //                 chatRoomId: chatRoomId,
          //                 chatRoomCollectionName: 'chatroom',
          //                 chatsCollectionName: 'chats',
          //                 msgTextController: message,
          //                 type: 'text',
          //                 time: FieldValue.serverTimestamp());
          //           },
          //           child: const Icon(Icons.send),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget messages(
      Size size, Map<String, dynamic> map, BuildContext context, String id) {
    return map['type'] == "text"
        ? map['sendby'] == _auth.currentUser!.displayName
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                        onLongPress: () {
                          editMessage.text = map['message'];
                          // showDialog(
                          //     context: context,
                          //     builder: (context) {
                          //       return AlertDialog(
                          //         title: const Text("Delete Message"),
                          //         content: const Text(
                          //             "Are you sure you want to delete this message?"),
                          //         actions: [
                          //           TextButton(
                          //               onPressed: () {
                          //                 Navigator.pop(context);
                          //               },
                          //               child: const Text("Cancel")),
                          //           TextButton(
                          //               onPressed: () {
                          //                 FlutterChat.deleteMessage(
                          //                     chatRoomId: chatRoomId,
                          //                     chatRoomCollectionName: 'chatroom',
                          //                     chatsCollectionName: 'chats',
                          //                     messageId: id);
                          //                 Navigator.pop(context);
                          //               },
                          //               child: const Text("Delete")),
                          //         ],
                          //       );
                          //     });
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Form(
                                    key: formKey,
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: editMessage,
                                          // decoration: InputDecoration(
                                          //   hintText: message.text,
                                          // ),
                                          validator: (value) {
                                            if (value!.trim().isEmpty) {
                                              return 'Enter Name';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    ElevatedButton(
                                      onPressed: () {
                                        print(id);
                                        if (formKey.currentState!.validate()) {
                                          FlutterChat.updateMessage(
                                              chatRoomId: widget.chatRoomId,
                                              chatRoomCollectionName:
                                                  'chatroom',
                                              chatsCollectionName: 'chats',
                                              messageId: id,
                                              message: editMessage.text);
                                          Navigator.pop(context);
                                          editMessage.clear();
                                        }
                                      },
                                      child: const Text("Update"),
                                    ),
                                    ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel')),
                                    ElevatedButton(
                                        onPressed: () {
                                          if (formKey.currentState!
                                              .validate()) {
                                            FlutterChat.deleteMessage(
                                                chatRoomId: widget.chatRoomId,
                                                chatRoomCollectionName:
                                                    'chatroom',
                                                chatsCollectionName: 'chats',
                                                messageId: id);
                                            Navigator.pop(context);
                                            editMessage.clear();
                                          }
                                        },
                                        child: const Text('Delete')),
                                  ],
                                );
                              });
                        },
                        child: FlutterChat.rightChatBubble(
                            message: map['message'])),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          map['time'] != null
                              ? Text(DateFormat('hh:mm')
                                  .format(map['time'].toDate()))
                              : Container(),
                          const SizedBox(
                            width: 3,
                          ),
                          map['seen']
                              ? const Icon(
                                  Icons.done_all,
                                  color: Colors.blue,
                                  size: 18,
                                )
                              : const Icon(
                                  Icons.done,
                                  color: Colors.grey,
                                  size: 18,
                                )
                        ],
                      ),
                    )
                  ],
                )
                //RightChatBubble(message: map['message']),
                )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: FlutterChat.leftChatBubble(message: map['message']))
        /*Container(
            width: size.width,
            alignment: map['sendby'] == _auth.currentUser!.displayName
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.blue,
              ),
              child: Text(
                map['message'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          )*/
        : Container(
            // height: size.height / 2.5,
            // width: size.width /2,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            alignment: map['sendby'] == _auth.currentUser!.displayName
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: (map['type'] == "image")
                ? InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShowImage(
                          imageUrl: map['mediaUrl'],
                        ),
                      ),
                    ),
                    child: Container(
                      height: 250,
                      width: 210,
                      decoration: BoxDecoration(border: Border.all()),
                      //  alignment: map['message'] != "" ? null : Alignment.center,
                      child: map['mediaUrl'] != ""
                          ? Image.network(
                              map['mediaUrl'],
                              fit: BoxFit.cover,
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  )
                : videoFrame(map)
            // InkWell(
            //         onTap: () => Navigator.of(context).push(
            //           MaterialPageRoute(
            //             builder: (_) => ShowVideo(
            //               videoUrl: map['mediaUrl'],
            //             ),
            //           ),
            //         ),
            //         child: Container(
            //           height: size.height / 2.5,
            //           width: size.width / 2,
            //           decoration: BoxDecoration(border: Border.all()),
            //           alignment: map['message'] != "" ? null : Alignment.center,
            //           child: map['mediaUrl'] != ""
            //               ? Stack(
            //                 children: [
            //                   VideoPlayer(controller)
            //                   const Center(
            //                       child: Icon(Icons.play_arrow),
            //                     ),
            //                 ],
            //               )
            //               // Image.network(
            //               // map['mediaUrl'],
            //               // fit: BoxFit.cover,
            //               // )
            //               : const CircularProgressIndicator(),
            //         ),
            //       )
            );
  }

  // Future updateChatList(
  //     {required String chatRoomId,
  //     required String chatRoomCollectionName,
  //     required String chatsCollectionName}) async {
  //   try {
  //     var collection = FirebaseFirestore.instance
  //         .collection(chatRoomCollectionName)
  //         .doc(chatRoomId)
  //         .collection(chatsCollectionName);
  //     var querySnapshots = await collection.get();
  //
  //     for (var doc in querySnapshots.docs) {
  //       if (doc['sendby'] != _auth.currentUser!.displayName) {
  //         await FirebaseFirestore.instance
  //             .collection(chatRoomCollectionName)
  //             .doc(chatRoomId)
  //             .collection(chatsCollectionName)
  //             .doc(doc.id)
  //             .update({"seen": true});
  //       }
  //     }
  //     return true;
  //   } catch (e) {
  //     print("Exception: $e");
  //     return null;
  //   }
  // }
  // Widget videoFrame(size,context,map,url){
  //   VideoPlayerController _controller;
  //   _controller = VideoPlayerController.network( map['mediaUrl'])
  //     ..initialize().then((_) {
  //       setState(() {});  //when your thumbnail will show.
  //     });
  //   return InkWell(
  //     onTap: () => Navigator.of(context).push(
  //       MaterialPageRoute(
  //         builder: (_) => ShowVideo(
  //           videoUrl: map['mediaUrl'],
  //         ),
  //       ),
  //     ),
  //     child: Container(
  //       height: size.height / 2.5,
  //       width: size.width / 2,
  //       decoration: BoxDecoration(border: Border.all()),
  //       alignment: map['message'] != "" ? null : Alignment.center,
  //       child: map['mediaUrl'] != ""
  //           ? Stack(
  //         children: [
  //           VideoPlayer(_controller),
  //           const Center(
  //             child: Icon(Icons.play_arrow),
  //           ),
  //         ],
  //       )
  //       // Image.network(
  //       // map['mediaUrl'],
  //       // fit: BoxFit.cover,
  //       // )
  //           : const CircularProgressIndicator(),
  //     ),
  //   );
  // }

}

class videoFrame extends StatefulWidget {
  Map? map;
  videoFrame(this.map, {Key? key}) : super(key: key);

  @override
  State<videoFrame> createState() => _videoFrameState();
}

class _videoFrameState extends State<videoFrame> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShowVideo(
            videoUrl: widget.map!['mediaUrl'],
          ),
        ),
      ),
      child: Container(
        height: 250,
        width: 210,
        decoration: BoxDecoration(
            border: Border.all(),
            image: widget.map!['thumbnailUrl'] != null
                ? DecorationImage(
                    image: NetworkImage(widget.map!['thumbnailUrl']),
                    fit: BoxFit.cover)
                : null),
        child: widget.map!['mediaUrl'] != ""
            ? Center(
                child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blueGrey.withOpacity(0.8),
                    child: const Icon(Icons.play_arrow)))
            // Image.network(
            // map['mediaUrl'],
            // fit: BoxFit.cover,
            // )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

Widget showEmojiPicker() {
  return EmojiPicker(
    config: const Config(
      columns: 7,
      buttonMode: ButtonMode.MATERIAL,
    ),
    onEmojiSelected: (emoji, category) {},
  );
}

class ShowImage extends StatelessWidget {
  final String imageUrl;

  const ShowImage({required this.imageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        color: Colors.black,
        child: Image.network(imageUrl),
      ),
    );
  }
}

class ShowVideo extends StatefulWidget {
  final String videoUrl;

  const ShowVideo({required this.videoUrl, Key? key}) : super(key: key);

  @override
  State<ShowVideo> createState() => _ShowVideoState();
}

class _ShowVideoState extends State<ShowVideo> {
  late VideoPlayerController _controller;
  File? thumbnailData;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);

    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.initialize().then((_) => setState(() {}));
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Container(
          height: size.height,
          width: size.width,
          color: Colors.black,
          child: _controller.value.isInitialized
              ? Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    _ControlsOverlay(controller: _controller),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({Key? key, required this.controller})
      : super(key: key);

  static const List<Duration> _exampleCaptionOffsets = <Duration>[
    Duration(seconds: -10),
    Duration(seconds: -3),
    Duration(seconds: -1, milliseconds: -500),
    Duration(milliseconds: -250),
    Duration.zero,
    Duration(milliseconds: 250),
    Duration(seconds: 1, milliseconds: 500),
    Duration(seconds: 3),
    Duration(seconds: 10),
  ];
  static const List<double> _examplePlaybackRates = <double>[
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        // Align(
        //   alignment: Alignment.topLeft,
        //   child: PopupMenuButton<Duration>(
        //     initialValue: controller.value.captionOffset,
        //     tooltip: 'Caption Offset',
        //     onSelected: (Duration delay) {
        //       controller.setCaptionOffset(delay);
        //     },
        //     itemBuilder: (BuildContext context) {
        //       return <PopupMenuItem<Duration>>[
        //         for (final Duration offsetDuration in _exampleCaptionOffsets)
        //           PopupMenuItem<Duration>(
        //             value: offsetDuration,
        //             child: Text('${offsetDuration.inMilliseconds}ms'),
        //           )
        //       ];
        //     },
        //     child: Padding(
        //       padding: const EdgeInsets.symmetric(
        //         // Using less vertical padding as the text is also longer
        //         // horizontally, so it feels like it would need more spacing
        //         // horizontally (matching the aspect ratio of the video).
        //         vertical: 12,
        //         horizontal: 16,
        //       ),
        //       child: Text('${controller.value.captionOffset.inMilliseconds}ms'),
        //     ),
        //   ),
        // ),
        // Align(
        //   alignment: Alignment.topRight,
        //   child: PopupMenuButton<double>(
        //     initialValue: controller.value.playbackSpeed,
        //     tooltip: 'Playback speed',
        //     onSelected: (double speed) {
        //       controller.setPlaybackSpeed(speed);
        //     },
        //     itemBuilder: (BuildContext context) {
        //       return <PopupMenuItem<double>>[
        //         for (final double speed in _examplePlaybackRates)
        //           PopupMenuItem<double>(
        //             value: speed,
        //             child: Text('${speed}x'),
        //           )
        //       ];
        //     },
        //     child: Padding(
        //       padding: const EdgeInsets.symmetric(
        //         // Using less vertical padding as the text is also longer
        //         // horizontally, so it feels like it would need more spacing
        //         // horizontally (matching the aspect ratio of the video).
        //         vertical: 12,
        //         horizontal: 16,
        //       ),
        //       child: Text('${controller.value.playbackSpeed}x'),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
