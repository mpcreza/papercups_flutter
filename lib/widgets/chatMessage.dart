import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:open_file/open_file.dart';
import 'package:papercups_flutter/utils/fileInteraction/downloadFile.dart';
import 'package:papercups_flutter/widgets/timeWidget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';

import '../utils/utils.dart';
import 'widgets.dart';

class ChatMessage extends StatefulWidget {
  const ChatMessage({
    Key? key,
    required this.msgs,
    required this.index,
    required this.props,
    required this.sending,
    required this.maxWidth,
    required this.locale,
    required this.timeagoLocale,
    required this.sendingText,
    required this.sentText,
    required this.textColor,
    this.onMessageBubbleTap,
  }) : super(key: key);

  final List<PapercupsMessage>? msgs;
  final int index;
  final Props props;
  final bool sending;
  final double maxWidth;
  final String locale;
  final timeagoLocale;
  final String sendingText;
  final String sentText;
  final Color textColor;
  final void Function(PapercupsMessage)? onMessageBubbleTap;

  @override
  _ChatMessageState createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  double opacity = 0;
  double maxWidth = 0;
  bool isTimeSentVisible = false;
  String? longDay;
  Timer? timer;

  @override
  void dispose() {
    if (timer != null) timer!.cancel();
    super.dispose();
  }

  @override
  void initState() {
    maxWidth = widget.maxWidth;
    super.initState();
  }

  Future<File?> _handleDownloadStream(Stream<StreamedResponse> resp,
      {required File file}) async {
    List<List<int>> chunks = [];
    int downloaded = 0;
    bool success = false;

    resp.listen((StreamedResponse r) {
      r.stream.listen((List<int> chunk) {
        // TODO: Internationlaize this
        Alert.show(
          "Downloading, ${downloaded / (r.contentLength ?? 1) * 100}% done",
          context,
          textStyle: Theme.of(context).textTheme.bodyText2,
          backgroundColor: Theme.of(context).bottomAppBarColor,
          gravity: Alert.bottom,
          duration: Alert.lengthLong,
        );

        chunks.add(chunk);
        downloaded += chunk.length;
      }, onDone: () async {
        // Alert.show(
        //   "location: ${dir}/$filename",
        //   context,
        //   textStyle: Theme.of(context).textTheme.bodyText2,
        //
        //   gravity: Alert.bottom,
        //   duration: Alert.lengthLong,
        // );

        final Uint8List bytes = Uint8List(r.contentLength ?? 0);
        int offset = 0;
        for (List<int> chunk in chunks) {
          bytes.setRange(offset, offset + chunk.length, chunk);
          offset += chunk.length;
        }
        await file.writeAsBytes(bytes);
        success = true;
        return;
      });
    });

    if (success) {
      return file;
    }
  }

  TimeOfDay senderTime = TimeOfDay.now();
  @override
  Widget build(BuildContext context) {
    if (opacity == 0)
      Timer(
          Duration(
            milliseconds: 0,
          ), () {
        if (mounted)
          setState(() {
            opacity = 1;
          });
      });
    var msg = widget.msgs![widget.index];

    bool userSent = true;
    if (msg.userId != null) userSent = false;

    var text = msg.body ?? "";
    if (msg.fileIds != null && msg.fileIds!.isNotEmpty) {
      if (text != "") {
        text += """

""";
      }
      text += "> " + msg.attachments!.first.fileName!;
    }
    var nextMsg = widget.msgs![min(widget.index + 1, widget.msgs!.length - 1)];
    var isLast = widget.index == widget.msgs!.length - 1;
    var isFirst = widget.index == 0;

    if (!isLast &&
        (nextMsg.sentAt!.day != msg.sentAt!.day) &&
        longDay == null) {
      try {
        longDay = DateFormat.yMMMMd(widget.locale).format(nextMsg.sentAt!);
      } catch (e) {
        print("ERROR: Error generating localized date!");
        longDay = "Loading...";
      }
    }
    if (userSent && isLast && widget.timeagoLocale != null) {
      timeago.setLocaleMessages(widget.locale, widget.timeagoLocale);
      timeago.setDefaultLocale(widget.locale);
    }
    if (isLast && userSent && timer == null)
      timer = Timer.periodic(Duration(minutes: 1), (timer) {
        if (mounted && timer.isActive) {
          setState(() {});
        }
      });
    if (!isLast && timer != null) timer!.cancel();
    return GestureDetector(
      onTap: () async {
        setState(() {
          isTimeSentVisible = true;
        });
        if (widget.onMessageBubbleTap != null)
          widget.onMessageBubbleTap!(msg);
        else if ((msg.fileIds?.isNotEmpty ?? false)) {
          if (kIsWeb) {
            String url = msg.attachments?.first.fileUrl ?? '';
            downloadFileWeb(url);
          } else if (Platform.isAndroid ||
              Platform.isIOS ||
              Platform.isLinux ||
              Platform.isMacOS ||
              Platform.isWindows) {
            String dir = (await getApplicationDocumentsDirectory()).path;
            File? file =
                File(dir + (msg.attachments?.first.fileName ?? "noName"));
            if (file.existsSync()) {
              OpenFile.open(file.absolute.path);
            }
            Stream<StreamedResponse> resp =
                await downloadFile(msg.attachments?.first.fileUrl ?? '');
            file = await _handleDownloadStream(
              resp,
              file: file,
            );
            if (file != null && file.existsSync()) {}
          }
        }
      },
      onLongPress: () {
        HapticFeedback.vibrate();
        print(text);
        final data = ClipboardData(text: text);
        Clipboard.setData(data);
        // TODO: Internationalize this
        Alert.show(
          "Text copied to clipboard",
          context,
          textStyle: Theme.of(context).textTheme.bodyText2,
          backgroundColor: Theme.of(context).bottomAppBarColor,
          gravity: Alert.bottom,
          duration: Alert.lengthLong,
        );
      },
      onTapUp: (_) {
        Timer(
            Duration(
              seconds: 10,
            ), () {
          if (mounted)
            setState(() {
              isTimeSentVisible = false;
            });
        });
      },
      child: AnimatedOpacity(
        curve: Curves.easeIn,
        duration: Duration(milliseconds: 300),
        opacity: opacity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  userSent ? MainAxisAlignment.end : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!userSent)
                  Padding(
                    padding: EdgeInsets.only(
                      right: 14,
                      left: 14,
                      top: (isFirst) ? 15 : 4,
                      bottom: 5,
                    ),
                    child: (widget.msgs!.length == 1 ||
                            nextMsg.userId != msg.userId ||
                            isLast)
                        ? Container(
                            decoration: BoxDecoration(
                              color: widget.props.primaryColor,
                              gradient: widget.props.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.transparent,
                              backgroundImage:
                                  (msg.user!.profilePhotoUrl != null)
                                      ? NetworkImage(msg.user!.profilePhotoUrl!)
                                      : null,
                              child: (msg.user!.profilePhotoUrl != null)
                                  ? null
                                  : (msg.user != null &&
                                          msg.user!.fullName == null)
                                      ? Text(
                                          msg.user!.email!
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                              color: widget.textColor),
                                        )
                                      : Text(
                                          msg.user!.fullName!
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                              color: widget.textColor),
                                        ),
                            ),
                          )
                        : SizedBox(
                            width: 32,
                          ),
                  ),
                if (userSent)
                  TimeWidget(
                    userSent: userSent,
                    msg: msg,
                    isVisible: isTimeSentVisible,
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: userSent
                        ? widget.props.primaryColor
                        : Theme.of(context).brightness == Brightness.light
                            ? brighten(Theme.of(context).disabledColor, 80)
                            : Color(0xff282828),
                    gradient: userSent ? widget.props.primaryGradient : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                  ),
                  margin: EdgeInsets.only(
                    top: (isFirst) ? 15 : 4,
                    bottom: 4,
                    right: userSent ? 18 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 14,
                  ),
                  child: MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet(
                        blockquote:
                            TextStyle(decoration: TextDecoration.underline),
                        p: TextStyle(
                          color: userSent
                              ? widget.textColor
                              : Theme.of(context).textTheme.bodyText1!.color,
                        ),
                        a: TextStyle(
                          color: userSent
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyText1!.color,
                        ),
                        blockquotePadding: EdgeInsets.only(bottom: 2),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1.5,
                              color: userSent
                                  ? widget.textColor
                                  : Theme.of(context)
                                          .textTheme
                                          .bodyText1!
                                          .color ??
                                      Colors.white,
                            ),
                          ),
                        )
                        // blockquotePadding: EdgeInsets.only(left: 14),
                        // blockquoteDecoration: BoxDecoration(
                        //     border: Border(
                        //   left: BorderSide(color: Colors.grey[300]!, width: 4),
                        // )),
                        ),
                  ),
                ),
                if (!userSent)
                  TimeWidget(
                    userSent: userSent,
                    msg: msg,
                    isVisible: isTimeSentVisible,
                  ),
              ],
            ),
            if (!userSent && ((nextMsg.userId != msg.userId) || (isLast)))
              Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 5, top: 4),
                  child: (msg.user!.fullName == null)
                      ? Text(
                          msg.user!.email!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .disabledColor
                                .withOpacity(0.5),
                            fontSize: 14,
                          ),
                        )
                      : Text(
                          msg.user!.fullName!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .disabledColor
                                .withOpacity(0.5),
                            fontSize: 14,
                          ),
                        )),
            if (userSent && isLast)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                  bottom: 4,
                  left: 18,
                  right: 18,
                ),
                child: Text(
                  widget.sending
                      ? widget.sendingText
                      : "${widget.sentText} ${timeago.format(msg.createdAt!)}",
                  textAlign: TextAlign.end,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            if (isLast || nextMsg.userId != msg.userId)
              SizedBox(
                height: 10,
              ),
            if (longDay != null)
              IgnorePointer(
                ignoring: true,
                child: Container(
                  margin: EdgeInsets.all(15),
                  width: double.infinity,
                  child: Text(
                    longDay!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
