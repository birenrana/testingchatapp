import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_chat/custom_chat.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import 'add_members.dart';

class GroupInfo extends StatefulWidget {
  final String groupId, groupName;
  const GroupInfo({Key? key, required this.groupId, required this.groupName})
      : super(key: key);

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  List membersList = [];
  bool isLoading = true;
  String imagePath = '';

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController editGroupName = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    getGroupDetails();
    editGroupName.text = widget.groupName.toString();
  }

  Future getGroupDetails() async {
    await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .get()
        .then((chatMap) {
      membersList = chatMap['members'];
      imagePath = chatMap['groupImage'];
      print(membersList);
      isLoading = false;
      setState(() {});
    });
    print(await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId));
  }

  // Future removeMembers(int index) async {
  //   String uid = membersList[index]['uid'];
  //
  //   setState(() {
  //     isLoading = true;
  //     membersList.removeAt(index);
  //   });
  //
  //   await _firestore.collection('groups').doc(widget.groupId).update({
  //     "members": membersList,
  //   }).then((value) async {
  //     await _firestore
  //         .collection('user')
  //         .doc(uid)
  //         .collection('groups')
  //         .doc(widget.groupId)
  //         .delete();
  //
  //     setState(() {
  //       isLoading = false;
  //     });
  //   });
  // }
  Future removeMembers(int index) async {
    setState(() {
      isLoading = true;
    });
    FlutterChat.removeMembers(
        membersList: membersList,
        groupChatId: widget.groupId,
        index: index,
        groupChatRoomCollectionName: 'groups',
        groupUsersCollectionName: 'user');
    setState(() {
      isLoading = false;
    });
  }

  bool checkAdmin() {
    bool isAdmin = false;
    for (var element in membersList) {
      if (element['uid'] == _auth.currentUser!.uid &&
          element['isAdmin'] != null) {
        isAdmin = element['isAdmin'];
      }
    }
    return isAdmin;
  }

  void showDialogBox(int index) {
    if (checkAdmin()) {
      if (_auth.currentUser!.uid != membersList[index]['uid']) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: ListTile(
                  onTap: () => removeMembers(index),
                  title: const Text("Remove This Member"),
                ),
              );
            });
      }
    }
  }
  // Future onLeaveGroup() async {
  //   if (!checkAdmin()) {
  //     setState(() {
  //       isLoading = true;
  //     });
  //
  //     for (int i = 0; i < membersList.length; i++) {
  //       if (membersList[i]['uid'] == _auth.currentUser!.uid) {
  //         membersList.removeAt(i);
  //       }
  //     }
  //
  //     await _firestore.collection('groups').doc(widget.groupId).update({
  //       "members": membersList,
  //     });
  //
  //     await _firestore
  //         .collection('user')
  //         .doc(_auth.currentUser!.uid)
  //         .collection('groups')
  //         .doc(widget.groupId)
  //         .delete();
  //
  //     Navigator.of(context).pushAndRemoveUntil(
  //       MaterialPageRoute(builder: (_) => const HomeScreen()),
  //           (route) => false,
  //     );
  //   } else {
  //     print("Can't left group");
  //   }
  // }

  Future onLeaveGroup() async {
    if (!checkAdmin()) {
      setState(() {
        isLoading = true;
      });
      FlutterChat.onLeaveGroup(
              membersList: membersList,
              groupChatId: widget.groupId,
              groupChatRoomCollectionName: 'groups',
              groupUsersCollectionName: 'user')
          .then((value) => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              ));
    } else {
      if (kDebugMode) {
        print("Can't left group");
      }
    }
  }

  Future onDeleteGroup() async {
    setState(() {
      isLoading = true;
    });
    FlutterChat.onGroupDelete(
            membersList: membersList,
            groupChatId: widget.groupId,
            groupChatRoomCollectionName: 'groups',
            groupChatsCollectionName: 'chats',
            groupUsersCollectionName: 'user')
        .then((value) => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            ));
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        body: isLoading
            ? Container(
                height: size.height,
                width: size.width,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              )
            : StreamBuilder(
                stream: _firestore
                    .collection('groups')
                    .doc(widget.groupId)
                    .snapshots(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: BackButton()),
                          SizedBox(
                            height: size.height / 8,
                            width: size.width / 1.1,
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    GestureDetector(
                                        onTap: () {
                                          checkAdmin() == true
                                              ? showMenu(
                                                  context: context,
                                                  position: const RelativeRect
                                                      .fromLTRB(20, 20, 20, 20),
                                                  items: [
                                                      PopupMenuItem(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            FlutterChat.getGroupProfileImage(
                                                                    groupChatRoomId:
                                                                        widget
                                                                            .groupId,
                                                                    groupChatRoomCollectionName:
                                                                        'groups',
                                                                    type:
                                                                        "image",
                                                                    isCamera:
                                                                        true,
                                                                    time: FieldValue
                                                                        .serverTimestamp())
                                                                .then((value) =>
                                                                    setState(
                                                                        () {
                                                                      isLoading =
                                                                          false;
                                                                    }));
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: const Text(
                                                              "Photo From Camera"),
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            FlutterChat.getGroupProfileImage(
                                                                groupChatRoomId:
                                                                    widget
                                                                        .groupId,
                                                                groupChatRoomCollectionName:
                                                                    'groups',
                                                                type: "image",
                                                                isCamera: false,
                                                                time: FieldValue
                                                                    .serverTimestamp());
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: const Text(
                                                              "Photo From Gallery"),
                                                        ),
                                                      ),
                                                    ])
                                              : Container();
                                        },
                                        child: Container(
                                            height: size.height / 11,
                                            width: size.height / 11,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              // color: Colors.grey,
                                            ),
                                            child: snapshot.data!
                                                        .get('groupImage') ==
                                                    ''
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 50,
                                                    color: Colors.grey,
                                                  )
                                                // const CircularProgressIndicator(
                                                //     strokeWidth: 2,
                                                //     valueColor:
                                                //         AlwaysStoppedAnimation<
                                                //                 Color>(
                                                //             Colors.blue),
                                                //   )
                                                : ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            100),
                                                    child: Image.network(
                                                      snapshot.data!
                                                          .get('groupImage'),
                                                      fit: BoxFit.cover,
                                                      height: size.height / 11,
                                                      width: size.height / 11,
                                                    ),
                                                  )))
                                    // Positioned(
                                    //   bottom: 0,
                                    //   right: 0,
                                    //   child: GestureDetector(
                                    //     onTap: () {
                                    //       FlutterChat.updateUploadGroupProfileImage(
                                    //         groupChatRoomId: widget.groupId,
                                    //         groupChatRoomCollectionName: 'groups',
                                    //         mediaUrl: '',
                                    //       );
                                    //     },
                                    //     child: Container(
                                    //       height: size.height / 30,
                                    //       width: size.height / 30,
                                    //       decoration: const BoxDecoration(
                                    //         shape: BoxShape.circle,
                                    //         color: Colors.green,
                                    //       ),
                                    //       child: Icon(
                                    //         Icons.edit,
                                    //         size: size.width / 30,
                                    //         color: Colors.white,
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                                SizedBox(width: size.width / 20),
                                Expanded(
                                    child: Text(
                                  widget.groupName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: size.width / 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )),
                                checkAdmin() == true
                                    ? GestureDetector(
                                        onTap: () async {
                                          await showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: Form(
                                                    key: formKey,
                                                    child: Column(
                                                      children: [
                                                        TextFormField(
                                                          // initialValue: widget.groupName,
                                                          controller:
                                                              editGroupName,
                                                          // decoration: InputDecoration(
                                                          //   hintText: message.text,
                                                          // ),
                                                          validator: (value) {
                                                            if (value!
                                                                .trim()
                                                                .isEmpty) {
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
                                                        // print(widget.groupId);
                                                        if (formKey
                                                            .currentState!
                                                            .validate()) {
                                                          FlutterChat.onGroupChatUpdateName(
                                                              groupName:
                                                                  editGroupName
                                                                      .text,
                                                              groupUsersCollectionName:
                                                                  'user',
                                                              groupChatId: widget
                                                                  .groupId,
                                                              membersList:
                                                                  membersList,
                                                              groupChatRoomCollectionName:
                                                                  'groups');
                                                          Navigator.pop(
                                                              context);
                                                          Navigator.pop(
                                                              context);
                                                          Navigator.pop(
                                                              context);
                                                          Navigator.pop(
                                                              context);
                                                          // editGroupName.clear();
                                                        }
                                                      },
                                                      child:
                                                          const Text("Update"),
                                                    ),
                                                    ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: const Text(
                                                            'Cancel')),
                                                  ],
                                                );
                                              });
                                        },
                                        child: Icon(Icons.edit,
                                            size: size.width / 14,
                                            color: Colors.grey))
                                    : Container(),
                              ],
                            ),
                          ),
                          //
                          SizedBox(
                            height: size.height / 20,
                          ),
                          SizedBox(
                            width: size.width / 1.1,
                            child: Text(
                              "${membersList.length} Members",
                              style: TextStyle(
                                fontSize: size.width / 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: size.height / 20,
                          ),

                          // Members Name
                          checkAdmin()
                              ? ListTile(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AddMembersINGroup(
                                        groupChatId: widget.groupId,
                                        name: widget.groupName,
                                        membersList: membersList,
                                      ),
                                    ),
                                  ),
                                  leading: const Icon(
                                    Icons.add,
                                  ),
                                  title: Text(
                                    "Add Members",
                                    style: TextStyle(
                                      fontSize: size.width / 22,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                          Flexible(
                            child: ListView.builder(
                              itemCount: membersList.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return ListTile(
                                  onTap: () => showDialogBox(index),
                                  leading: const Icon(Icons.account_circle),
                                  title: Text(
                                    membersList[index]['name'],
                                    style: TextStyle(
                                      fontSize: size.width / 22,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(membersList[index]['email']),
                                  trailing:
                                      membersList[index]['isAdmin'] == true
                                          ? const Text("Admin")
                                          : const Text(""),
                                );
                              },
                            ),
                          ),
                          checkAdmin() == false
                              ? ListTile(
                                  onTap: onLeaveGroup,
                                  leading: const Icon(
                                    Icons.logout,
                                    color: Colors.redAccent,
                                  ),
                                  title: Text(
                                    "Leave Group",
                                    style: TextStyle(
                                      fontSize: size.width / 22,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                )
                              : Container(),
                          checkAdmin() == true
                              ? ListTile(
                                  onTap: onDeleteGroup,
                                  leading: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  title: Text(
                                    "Delete Group",
                                    style: TextStyle(
                                      fontSize: size.width / 22,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
      ),
    );
  }
}
