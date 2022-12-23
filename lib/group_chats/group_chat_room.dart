import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_chat/custom_chat.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'group_info.dart';

class GroupChatRoom extends StatelessWidget {
  final String groupChatId, groupName;
  GroupChatRoom({Key? key, required this.groupChatId, required this.groupName})
      : super(key: key);

  final TextEditingController _message = TextEditingController();
  final TextEditingController editMessage = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String currentUserName = "User1";

  List<Map<String, dynamic>> dummyChatList = [
    {
      "message": "User1 created this Group",
      "type": "notify",
    },
    {
      "message": "Hello this is user 1",
      "sendBy": "User1",
      "type": "text",
    },
    {
      "message": "Hello this is user 2",
      "sendBy": "User2",
      "type": "text",
    },
    {
      "message": "Hello this is user 3",
      "sendBy": "User3",
      "type": "text",
    },
    {
      "message": "Hello this is user 4",
      "sendBy": "User4",
      "type": "text",
    },
    {
      "message": "Hello this is user 5",
      "sendBy": "User5",
      "type": "text",
    },
    {
      "message": "user1 added User6",
      "type": "notify",
    },
  ];

  void onSendMessage() async {
    if (_message.text.isNotEmpty) {
      Map<String, dynamic> chatData = {
        "sendBy": _auth.currentUser!.displayName,
        "message": _message.text,
        "type": "text",
        "time": FieldValue.serverTimestamp(),
      };

      _message.clear();

      await _firestore
          .collection('groups')
          .doc(groupChatId)
          .collection('chats')
          .add(chatData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(groupName),
        actions: [
          IconButton(
              onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupInfo(
                        groupName: groupName,
                        groupId: groupChatId,
                      ),
                    ),
                  ),
              icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SizedBox(
              height: size.height / 1.27,
              width: size.width,
              // child: ListView.builder(
              //   itemCount: dummyChatList.length,
              //   itemBuilder: (context, index) {
              //     return messageTile(size, dummyChatList[index]);
              //   },
              // ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('groups')
                    .doc(groupChatId)
                    .collection('chats')
                    .orderBy('time')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        FlutterChat.groupChatSeenChatList(
                            groupChatRoomId: groupChatId,
                            groupChatRoomCollectionName: 'groups',
                            groupChatsCollectionName: 'chats',
                            currentUserName: _auth.currentUser!.displayName!);
                        Map<String, dynamic> chatMap =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        return messageTile(size, context, chatMap,
                            snapshot.data!.docs[index].id);
                      },
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ),
          FlutterChat().groupMessageField(
              context: context,
              msgTextController: _message,
              senderName: _auth.currentUser!.displayName!,
              groupChatRoomId: groupChatId,
              type: 'text',
              time: FieldValue.serverTimestamp(),
              groupChatRoomCollectionName: 'groups',
              groupChatsCollectionName: 'chats',
              uid: _auth.currentUser!.uid),
        ],
      ),
    );
  }

  // Widget messageTile(Size size, Map<String, dynamic> chatMap) {
  //   return Container(
  //       width: size.width,
  //       alignment: chatMap['sendBy'] == currentUserName
  //           ? Alignment.centerRight
  //           : Alignment.centerLeft,
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
  //         margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(15),
  //           color: Colors.blue,
  //         ),
  //         child: Text(
  //           chatMap['message'],
  //           style: const TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.w500,
  //             color: Colors.white,
  //           ),
  //         ),
  //       ));
  // }
  Widget messageTile(Size size, BuildContext context, chatMap, String id) {
    return Builder(builder: (_) {
      if (chatMap['type'] == "text") {
        return chatMap['sendBy'] == _auth.currentUser!.displayName
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                        onLongPress: () {
                          editMessage.text = chatMap['message'];
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
                                          FlutterChat.groupMessageUpdate(
                                              groupChatId: groupChatId,
                                              groupChatRoomCollectionName:
                                                  'groups',
                                              groupChatsCollectionName: 'chats',
                                              messageId: id,
                                              message: editMessage.text);
                                          Navigator.pop(context);
                                          // editMessage.clear();
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
                                            FlutterChat.groupMessageDelete(
                                                groupChatId: groupChatId,
                                                groupChatRoomCollectionName:
                                                    'groups',
                                                groupChatsCollectionName:
                                                    'chats',
                                                messageId: id);
                                            Navigator.pop(context);
                                            // editMessage.clear();
                                          }
                                        },
                                        child: const Text('Delete')),
                                  ],
                                );
                              });
                        },
                        child: FlutterChat.groupRightChatBubble(
                            uid: _auth.currentUser!.uid,
                            messageId: chatMap['uid'],
                            message: chatMap['message'],
                            userDetailsMap: chatMap,
                            isStatusAvailable: false,
                            bubbleType: GroupRightBubbleType.type1)),
                  ],
                ))
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: FlutterChat.groupLeftChatBubble(
                    message: chatMap['message'],
                    userDetailsMap: chatMap,
                    isStatusAvailable: false,
                    bubbleType: GroupLeftBubbleType.type1));
      } else if (chatMap['type'] == "image") {
        return Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            alignment: chatMap['sendBy'] == _auth.currentUser!.displayName
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShowImage(
                    imageUrl: chatMap['mediaUrl'],
                  ),
                ),
              ),
              child: Container(
                height: 250,
                width: 210,
                decoration: BoxDecoration(border: Border.all()),
                //  alignment: map['message'] != "" ? null : Alignment.center,
                child: chatMap['mediaUrl'] != ""
                    ? Image.network(
                        chatMap['mediaUrl'],
                        fit: BoxFit.cover,
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ));
      } else if (chatMap['type'] == "notify") {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.black38,
          ),
          child: Center(
            child: Text(
              chatMap['message'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      } else if (chatMap['type'] == "video") {
        return Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            alignment: chatMap['sendBy'] == _auth.currentUser!.displayName
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: InkWell(
                onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShowImage(
                          imageUrl: chatMap['mediaUrl'],
                        ),
                      ),
                    ),
                child: videoFrame(chatMap)));
      } else {
        return const SizedBox();
      }
    });
  }
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
      ],
    );
  }
}
