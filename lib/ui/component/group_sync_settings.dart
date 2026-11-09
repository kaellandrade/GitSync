import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/ui/component/auto_sync_settings.dart';
import 'package:GitSync/ui/component/scheduled_sync_settings.dart';
import 'package:GitSync/ui/component/quick_sync_settings.dart';
import 'package:flutter/material.dart';

class GroupSyncSettings extends StatelessWidget {
  const GroupSyncSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: repoManager.getStringList(StorageKey.repoman_repoNames),
      builder: (context, repoNamesSnapshot) {
        final hasMultipleRepos = (repoNamesSnapshot.data?.length ?? 1) > 1;
        return Column(
          children: [
            AutoSyncSettings(),
            SizedBox(height: spaceMD),
            ScheduledSyncSettings(),
            if (hasMultipleRepos) ...[
              SizedBox(height: spaceMD),
              QuickSyncSettings(),
            ],
          ],
        );
      },
    );
  }
}
