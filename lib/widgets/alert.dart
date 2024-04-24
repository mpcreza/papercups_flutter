// https://github.com/appdev/FlutterToast

// MIT License

// Copyright (c) 2018 YM

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:flutter/material.dart';
import 'dart:async';

class Alert {
  static const int lengthShort = 1;
  static const int lengthLong = 3;
  static const int bottom = 0;
  static const int center = 1;
  static const int top = 2;

  static const Color defaultBgColor = Colors.white;

  static void show(String msg, BuildContext context,
      {int duration = 1,
      int gravity = 0,
      Color backgroundColor = defaultBgColor,
      textStyle = const TextStyle(fontSize: 15, color: Colors.white),
      double backgroundRadius = 20,
      bool? rootNavigator,
      Border? border}) {
    ToastView.dismiss();
    ToastView.createView(msg, context, duration, gravity, backgroundColor,
        textStyle, backgroundRadius, border, rootNavigator);
  }
}

class ToastView {
  static final ToastView _singleton = ToastView._internal();

  factory ToastView() {
    return _singleton;
  }

  ToastView._internal();

  static OverlayState? overlayState;
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static void createView(
      String msg,
      BuildContext context,
      int? duration,
      int gravity,
      Color background,
      TextStyle? textStyle,
      double backgroundRadius,
      Border? border,
      bool? rootNavigator) async {
    overlayState = Overlay.of(context, rootOverlay: rootNavigator ?? false);

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) => ToastWidget(
          duration: Duration(seconds: duration ?? Alert.lengthShort),
          widget: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                child: Container(
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(backgroundRadius),
                    border: border,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Text(msg, softWrap: true, style: textStyle),
                )),
          ),
          gravity: gravity),
    );
    _isVisible = true;
    overlayState!.insert(_overlayEntry!);
    await Future.delayed(Duration(seconds: duration ?? Alert.lengthShort));
    dismiss();
  }

  static dismiss() async {
    if (!_isVisible) {
      return;
    }
    _isVisible = false;
    _overlayEntry?.remove();
  }
}

class ToastWidget extends StatefulWidget {
  const ToastWidget({
    Key? key,
    required this.widget,
    required this.gravity,
    required this.duration,
  }) : super(key: key);

  final Widget widget;
  final int gravity;
  final Duration duration;

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget> {
  double opacity = 0;
  bool timerset = false;

  @override
  Widget build(BuildContext context) {
    if (opacity == 0) {
      Timer(
          const Duration(
            milliseconds: 0,
          ), () {
        if (mounted & !timerset) {
          setState(() {
            opacity = 1;
            timerset = true;
          });
        }
      });
      Timer(Duration(milliseconds: widget.duration.inMilliseconds - 200), () {
        if (mounted) {
          setState(() {
            opacity = 0;
          });
        }
      });
    }
    return Positioned(
      top: widget.gravity == 2
          ? MediaQuery.of(context).viewInsets.top + 50
          : null,
      bottom: widget.gravity == 0
          ? MediaQuery.of(context).viewInsets.bottom + 50
          : null,
      child: AnimatedOpacity(
        opacity: opacity,
        curve: Curves.linear,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: Colors.transparent,
          child: widget.widget,
        ),
      ),
    );
  }
}
