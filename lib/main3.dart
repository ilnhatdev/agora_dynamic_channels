import 'package:flutter/material.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFECE5DD),
      ),
      home: const MyHomePage(title: 'Agora Chat Quickstart'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String appKey = "611053209#1230707";
  static const String userId = "nhat2";
  String token =
      "007eJxTYDB/OMfaw6BX6h/j0tAQR6ZFXNIqf398ZYh9cenP7viID8sUGAySTMxNjMxTU82NjU1MDM0TLQ3S0oyMkk1STY3NkwwsXq/zTW0IZGQo3VzAwsjAysAIhCC+CoOJuWWSaZqRga55apKhrqFhaqpukqWxia65sWlSioFRsmGSoRkAOO0m7g==";

  @override
  void initState() {
    super.initState();
    setupChatClient();
    setupListeners();
  }

  void setupChatClient() async {
    ChatOptions options = ChatOptions(
      appKey: appKey,
      autoLogin: false,
    );
    agoraChatClient = ChatClient.getInstance;
    await agoraChatClient.init(options);

    await ChatClient.getInstance.startCallback();
  }

  void setupListeners() {
    agoraChatClient.addConnectionEventHandler(
      "CONNECTION_HANDLER",
      ConnectionEventHandler(
          onConnected: onConnected,
          onDisconnected: onDisconnected,
          onTokenWillExpire: onTokenWillExpire,
          onTokenDidExpire: onTokenDidExpire),
    );

    agoraChatClient.chatManager.addEventHandler(
      "MESSAGE_HANDLER",
      ChatEventHandler(onMessagesReceived: onMessagesReceived),
    );
  }

  void onMessagesReceived(List<ChatMessage> messages) {
    for (var msg in messages) {
      if (msg.body.type == MessageType.TXT) {
        ChatTextMessageBody body = msg.body as ChatTextMessageBody;
        displayMessage(body.content, false);
        // showLog('${msg.body}');
        // showLog("Message from ${msg.from}");
      } else {
        // String msgType = msg.body.type.name;
        // showLog("Received $msgType message, from ${msg.from}");
      }
    }
  }

  void onTokenWillExpire() {}
  void onTokenDidExpire() {}
  void onDisconnected() {}
  void onConnected() {
    showLog("Connected");
  }

  void joinLeave() async {
    if (!isJoined) {
      try {
        await agoraChatClient.loginWithAgoraToken(userId, token);
        showLog("Logged in successfully as $userId");
        setState(() {
          isJoined = true;
        });
      } on ChatError catch (e) {
        if (e.code == 200) {
          setState(() {
            isJoined = true;
          });
        } else {
          showLog("Login failed, code: ${e.code}, desc: ${e.description}");
        }
      }
    } else {
      try {
        await agoraChatClient.logout(true);
        showLog("Logged out successfully");
        setState(() {
          isJoined = false;
        });
      } on ChatError catch (e) {
        showLog("Logout failed, code: ${e.code}, desc: ${e.description}");
      }
    }
  }

  void sendMessage() async {
    if (recipientId.isEmpty || messageContent.isEmpty) {
      showLog("Enter recipient user ID and type a message");
      return;
    }

    var msg = ChatMessage.createTxtSendMessage(
      targetId: recipientId,
      content: messageContent,
    );
    ChatClient.getInstance.chatManager.addMessageEvent(
      "UNIQUE_HANDLER_ID",
      ChatMessageEvent(
        onSuccess: (msgId, msg) {
          print("on message succeed");
        },
        onProgress: (msgId, progress) {
          print("on message progress");
        },
        onError: (msgId, msg, error) {
          print(
            "on message failed, code: ${error.code}, desc: ${error.description}",
          );
        },
      ),
    );
    ChatClient.getInstance.chatManager.removeMessageEvent("UNIQUE_HANDLER_ID");
    agoraChatClient.chatManager.sendMessage(msg);
    displayMessage(messageContent, true);
    messageBoxController.clear();
  }

  void displayMessage(String text, bool isSentMessage) {
    messageList.add(Row(children: [
      Expanded(
        child: Align(
          alignment:
              isSentMessage ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(10),
            margin: EdgeInsets.fromLTRB(
                (isSentMessage ? 50 : 0), 5, (isSentMessage ? 0 : 50), 5),
            decoration: BoxDecoration(
              color: isSentMessage
                  ? const Color(0xFFDCF8C6)
                  : const Color(0xFFFFFFFF),
            ),
            child: Text(text),
          ),
        ),
      ),
    ]));

    setState(() {
      scrollController.jumpTo(scrollController.position.maxScrollExtent + 50);
    });
  }

  late ChatClient agoraChatClient;
  bool isJoined = false;

  ScrollController scrollController = ScrollController();
  TextEditingController messageBoxController = TextEditingController();
  String messageContent = "", recipientId = "";
  final List<Widget> messageList = [];

  showLog(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  void dispose() {
    agoraChatClient.chatManager.removeEventHandler("MESSAGE_HANDLER");
    agoraChatClient.removeConnectionEventHandler("CONNECTION_HANDLER");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Enter recipient's userId",
                      ),
                      onChanged: (chatUserId) => recipientId = chatUserId,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: joinLeave,
                    child: Text(isJoined ? "Leave" : "Join"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemBuilder: (_, index) {
                  return messageList[index];
                },
                itemCount: messageList.length,
              ),
            ),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: messageBoxController,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Message",
                    ),
                    onChanged: (msg) {
                      messageContent = msg;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 50,
                height: 40,
                child: ElevatedButton(
                  onPressed: sendMessage,
                  child: const Text(">>"),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
