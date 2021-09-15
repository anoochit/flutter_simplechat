import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:simple_chat/models/appdata.dart';
import 'package:simple_chat/services/auth_service.dart';
import 'package:simple_chat/services/chat_service.dart';
import 'package:simple_chat/widgets/chat_widget.dart';
import 'package:simple_chat/widgets/error_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.peerId, required this.displayName}) : super(key: key);

  final String peerId;
  final String displayName;

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController textInputController = TextEditingController();

  late String messageId;

  @override
  Widget build(BuildContext context) {
    messageId = getMessageId(uid: (appData.userUid.toString()), peerId: widget.peerId);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            getavatar(displayName: widget.displayName),
            const SizedBox(width: 8.0),
            Text(widget.displayName),
          ],
        ),
        titleSpacing: 0.0,
      ),
      body: Column(
        children: [
          // list chat message
          Expanded(
            child: StreamBuilder(
              stream: firebaseFirestore.collection("messages").doc(messageId).collection(messageId).orderBy('timestamp', descending: true).snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                // has error
                if (snapshot.hasError) {
                  return const ErrorMessageWidget();
                }

                // has data
                if (snapshot.hasData) {
                  var messageDocs = snapshot.data!.docs;
                  return buildChatMessage(messageDocs);
                }

                return Container();
              },
            ),
          ),

          // toolbar
          chatToolbar(context)
        ],
      ),
    );
  }

  Column chatToolbar(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, thickness: 1),
        Row(
          children: [
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width - 48,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(30)),
              child: TextFormField(
                controller: textInputController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type your message here',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(FontAwesomeIcons.paperPlane),
              onPressed: () {
                // add function send message
                log(textInputController.text);
                if (textInputController.text.trim() != "") {
                  sendMessage(
                      messageId: messageId,
                      uid: (appData.userUid.toString()),
                      peerId: widget.peerId,
                      type: 0,
                      content: textInputController.text.trim(),
                      timestamp: DateTime.now().millisecondsSinceEpoch);
                  textInputController.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  // chat message
  ListView buildChatMessage(List<QueryDocumentSnapshot<Object?>> messageDocs) {
    return ListView.builder(
      reverse: true,
      itemCount: messageDocs.length,
      itemBuilder: (BuildContext context, int index) {
        bool isOwner = (appData.userUid.toString() == messageDocs[index]['uid']) ? true : false;
        return chatMessageItem(
          id: messageDocs[index].id,
          content: messageDocs[index]['content'],
          type: messageDocs[index]['type'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(messageDocs[index]['timestamp']),
          avatar: " ",
          displayName: widget.displayName,
          owner: isOwner,
        );
      },
    );
  }

  // message widget
  Widget chatMessageItem({required String id, required String content, required int type, required DateTime timestamp, required String avatar, required String displayName, required bool owner}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (type == 0) {
          // text
          return chatMessageItemText(owner, displayName, constraints, content, timestamp);
        } else if (type == 1) {
          // image
          return chatMessageItemImage(owner, displayName, content, timestamp);
        } else if (type == 2) {
          // sticker
          return chatMessageItemSticker(owner, displayName, content, timestamp);
        } else if (type == 3) {
          // audio
          return chatMessageItemAudio(owner, avatar, content, timestamp);
        } else if (type == 4) {
          // video
          return chatMessageItemVideo(owner, avatar, content, timestamp);
        } else {
          return const Text("not support message type");
        }
      },
    );
  }

  Container chatMessageItemVideo(bool owner, String avatar, String content, DateTime timestamp) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      alignment: (owner) ? Alignment.bottomRight : Alignment.bottomLeft,
      child: Row(
        children: [
          (!owner)
              ? Container(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    backgroundImage: AssetImage(avatar),
                  ),
                )
              : const Spacer(),
          Column(
            crossAxisAlignment: (owner) ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              InkWell(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Container(
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadiusDirectional.circular(10)),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.grey.withOpacity(0.8),
                            size: 50,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                onTap: () {
                  // play video
                  log("play video = " + content);
                },
              ),
              Text(
                timeago.format(timestamp),
                style: const TextStyle(fontSize: 10.0),
              )
            ],
          ),
        ],
      ),
    );
  }

  Container chatMessageItemAudio(bool owner, String avatar, String content, DateTime timestamp) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      alignment: (owner) ? Alignment.bottomRight : Alignment.bottomLeft,
      child: Row(
        children: [
          (!owner)
              ? Container(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    backgroundImage: AssetImage(avatar),
                  ),
                )
              : const Spacer(),
          Column(
            crossAxisAlignment: (owner) ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              InkWell(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Container(
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadiusDirectional.circular(10)),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Icon(
                            Icons.audiotrack,
                            color: Colors.grey.withOpacity(0.8),
                            size: 50,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                onTap: () {
                  // play audio
                  log("play audio = " + content);
                },
              ),
              Text(
                timeago.format(timestamp),
                style: const TextStyle(fontSize: 10.0),
              )
            ],
          ),
        ],
      ),
    );
  }

  Container chatMessageItemSticker(bool owner, String displayName, String content, DateTime timestamp) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      alignment: (owner) ? Alignment.bottomRight : Alignment.bottomLeft,
      child: Row(
        children: [
          (!owner)
              ? Container(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: getavatar(displayName: displayName),
                )
              : const Spacer(),
          Column(
            crossAxisAlignment: (owner) ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Image.asset(content),
              ),
              Text(
                timeago.format(timestamp),
                style: const TextStyle(fontSize: 10.0),
              )
            ],
          ),
        ],
      ),
    );
  }

  Container chatMessageItemImage(bool owner, String displayName, String content, DateTime timestamp) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      alignment: (owner) ? Alignment.bottomRight : Alignment.bottomLeft,
      child: Row(
        children: [
          (!owner)
              ? Container(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: getavatar(displayName: displayName),
                )
              : const Spacer(),
          Column(
            crossAxisAlignment: (owner) ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              InkWell(
                child: Container(
                  width: 200,
                  height: 200,
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  decoration: BoxDecoration(color: (owner) ? Colors.pink.shade200 : Colors.pink.shade50, borderRadius: BorderRadiusDirectional.circular(10)),
                  child: Image.asset(content, fit: BoxFit.cover),
                ),
                onTap: () {
                  // show image
                  log("show image = " + content);
                },
              ),
              Text(
                timeago.format(timestamp),
                style: const TextStyle(fontSize: 10.0),
              )
            ],
          ),
        ],
      ),
    );
  }

  Container chatMessageItemText(bool owner, String displayName, BoxConstraints constraints, String content, DateTime timestamp) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      alignment: (owner) ? Alignment.bottomRight : Alignment.bottomLeft,
      child: Row(
        children: [
          (!owner)
              ? Container(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: getavatar(displayName: displayName),
                )
              : const Spacer(),
          Column(
            crossAxisAlignment: (owner) ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                width: constraints.maxWidth * 0.6,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(color: (owner) ? Colors.pink.shade200 : Colors.pink.shade50, borderRadius: BorderRadiusDirectional.circular(10)),
                child: Text(content),
              ),
              Text(
                timeago.format(timestamp),
                style: const TextStyle(fontSize: 10.0),
              )
            ],
          ),
        ],
      ),
    );
  }
}
