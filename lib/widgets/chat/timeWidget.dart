import 'package:flutter/material.dart';
import 'package:papercups_flutter/models/models.dart';

class TimeWidget extends StatelessWidget {
  const TimeWidget({
    Key? key,
    required this.userSent,
    required this.msg,
    required this.isVisible,
  }) : super(key: key);

  final bool userSent;
  final PapercupsMessage msg;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1 : 0,
      duration: Duration(milliseconds: 100),
      curve: Curves.easeIn,
      child: Padding(
        padding: EdgeInsets.only(bottom: 5.0, left: 4, right: 4),
        child: Text(
          TimeOfDay.fromDateTime(msg.createdAt!).format(context),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyText1!.color!.withAlpha(100),
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}