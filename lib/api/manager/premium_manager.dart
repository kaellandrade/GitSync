import 'dart:async';
import 'dart:convert';
import 'package:GitSync/api/helper.dart';
import 'package:GitSync/api/logger.dart';
import 'package:GitSync/api/manager/settings_manager.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/global.dart';
import 'package:flutter/foundation.dart';

enum GhSponsorCheck { sponsor, notSponsor, notLinked, tokenRejected, unreachable }

class PremiumManager {
  final ValueNotifier<bool?> hasPremiumNotifier = ValueNotifier(true);

  Future<void> init() async {
    await repoManager.setBool(StorageKey.repoman_hasGHSponsorPremium, true);
    hasPremiumNotifier.value = true;
  }

  Future<bool> _readPremiumStatus() async {
    return true;
  }

  Future<GhSponsorCheck> updateGitHubSponsorPremium() async {
    await _setGhSponsorPremium(true);
    return GhSponsorCheck.sponsor;
  }

  Future<void> _setGhSponsorPremium(bool value) async {
    await repoManager.setBool(StorageKey.repoman_hasGHSponsorPremium, true);
    hasPremiumNotifier.value = true;
  }

  Future<bool> cullNonPremium() async {
    return false;
  }

  void dispose() async {
    hasPremiumNotifier.dispose();
  }
}
