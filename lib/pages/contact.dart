import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:simple_chat/pages/chat.dart';
import 'package:simple_chat/services/auth_service.dart';
import 'package:simple_chat/services/chat_service.dart';
import 'package:simple_chat/widgets/chat_widget.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({Key? key}) : super(key: key);

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  @override
  Widget build(BuildContext context) {
    log("uid = " + appData.userUid.toString());
    return StreamBuilder(
      stream: firebaseFirestore.collection("users").where('uid', isNotEqualTo: (appData.userUid.toString())).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        // has error
        if (snapshot.hasError) {
          return const Center(
            child: Text("Something went wrong!"),
          );
        }

        // show users list except your own
        if (snapshot.hasData) {
          var docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                leading: getavatar(displayName: docs[index]['displayName']),
                title: Text(docs[index]['displayName']),
                trailing: SizedBox(
                  width: 60,
                  height: 62,
                  child: FutureBuilder(
                    future: addFriendButton(context: context, uid: (appData.userUid.toString()), peerId: docs[index]['uid'].toString(), displayName: docs[index]['displayName']),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data;
                      }
                      return Container();
                    },
                  ),
                ),
              );
            },
          );
        }

        // loading
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<Widget> addFriendButton({required BuildContext context, required String uid, required String peerId, required String displayName}) async {
    // check this uid is exist in messages
    String messageId = getMessageId(uid: uid, peerId: peerId);
    var doc = await firebaseFirestore.collection("messages").doc(messageId).get();
    log("find messageId = " + messageId + " result = " + doc.exists.toString());

    if (doc.exists == false) {
      return IconButton(
        icon: const Icon(FontAwesomeIcons.userPlus),
        onPressed: () {
          // add peerId to messages collection
          firebaseFirestore.collection("messages").doc(messageId).set({
            'uid': uid,
            'peerId': peerId,
          });
          // add peerId to friends collection
          firebaseFirestore.collection("friends").add({
            'uid': uid,
            'peerId': peerId,
          });
          // add uid to peer friends collection
          firebaseFirestore.collection("friends").add({
            'uid': peerId,
            'peerId': uid,
          });
          // log
          log("add " + peerId + "as friend");
          // setstate
          setState(() {});
        },
      );
    } else {
      return IconButton(
        icon: const Icon(FontAwesomeIcons.comment),
        onPressed: () {
          // goto chat page
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(peerId: peerId, displayName: displayName)));
        },
      );
    }
  }
}
