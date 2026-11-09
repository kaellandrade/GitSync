import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/ui/dialog/base_alert_dialog.dart';

class AiWandField extends ConsumerStatefulWidget {
  final Widget child;
  final Future<void> Function()? onPressed;
  final bool multiline;
  final bool enabled;

  const AiWandField({super.key, required this.child, this.onPressed, this.multiline = false, this.enabled = true});

  @override
  ConsumerState<AiWandField> createState() => _AiWandFieldState();
}

class _AiWandFieldState extends ConsumerState<AiWandField> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
