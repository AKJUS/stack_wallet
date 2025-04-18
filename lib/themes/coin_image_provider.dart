/* 
 * This file is part of Stack Wallet.
 * 
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 * Generated by Cypher Stack on 2023-05-26
 *
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/isar/stack_theme.dart';
import 'theme_providers.dart';
import '../wallets/crypto_currency/crypto_currency.dart';

final coinImageProvider = Provider.family<String, CryptoCurrency>((ref, coin) {
  final assets = ref.watch(themeAssetsProvider);

  if (assets is ThemeAssets) {
    // just update your wallet or theme
    return assets.stackIcon;
  } else if (assets is ThemeAssetsV2) {
    return (assets).coinImages[coin.mainNetId]!;
  } else {
    return (assets as ThemeAssetsV3).coinImages[coin.mainNetId]!;
  }
});

final coinImageSecondaryProvider =
    Provider.family<String, CryptoCurrency>((ref, coin) {
  final assets = ref.watch(themeAssetsProvider);

  if (assets is ThemeAssets) {
    // just update your wallet or theme
    return assets.stackIcon;
  } else if (assets is ThemeAssetsV2) {
    return (assets).coinSecondaryImages[coin.mainNetId]!;
  } else {
    return (assets as ThemeAssetsV3).coinSecondaryImages[coin.mainNetId]!;
  }
});
