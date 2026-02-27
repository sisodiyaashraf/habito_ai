import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> shareIdentityCard(Widget shareWidget) async {
    final image = await screenshotController.captureFromWidget(
      shareWidget,
      delay: const Duration(milliseconds: 100),
    );

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = await File(
      '${directory.path}/neural_record.png',
    ).create();
    await imagePath.writeAsBytes(image);

    await Share.shareXFiles([
      XFile(imagePath.path),
    ], text: 'My Neural Record from 2099.');
  }
}
