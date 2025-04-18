/* 
 * This file is part of Stack Wallet.
 * 
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 * Generated by Cypher Stack on 2023-05-26
 *
 */

import 'dart:convert';
import 'dart:math';

import 'package:string_validator/string_validator.dart';

import '../db/hive/db.dart';
import '../utilities/logger.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import 'electrumx_client.dart';

class CachedElectrumXClient {
  final ElectrumXClient electrumXClient;

  static const minCacheConfirms = 30;

  CachedElectrumXClient({required this.electrumXClient});

  factory CachedElectrumXClient.from({
    required ElectrumXClient electrumXClient,
  }) =>
      CachedElectrumXClient(
        electrumXClient: electrumXClient,
      );

  Future<Map<String, dynamic>> getAnonymitySet({
    required String groupId,
    String blockhash = "",
    required CryptoCurrency cryptoCurrency,
  }) async {
    try {
      final box =
          await DB.instance.getAnonymitySetCacheBox(currency: cryptoCurrency);
      final cachedSet = box.get(groupId) as Map?;

      Map<String, dynamic> set;

      // null check to see if there is a cached set
      if (cachedSet == null) {
        set = {
          "setId": groupId,
          "blockHash": blockhash,
          "setHash": "",
          "coins": <dynamic>[],
        };
      } else {
        set = Map<String, dynamic>.from(cachedSet);
      }

      final newSet = await electrumXClient.getLelantusAnonymitySet(
        groupId: groupId,
        blockhash: set["blockHash"] as String,
      );

      // update set with new data
      if (newSet["setHash"] != "" && set["setHash"] != newSet["setHash"]) {
        set["setHash"] = !isHexadecimal(newSet["setHash"] as String)
            ? base64ToHex(newSet["setHash"] as String)
            : newSet["setHash"];
        set["blockHash"] = !isHexadecimal(newSet["blockHash"] as String)
            ? base64ToReverseHex(newSet["blockHash"] as String)
            : newSet["blockHash"];
        for (int i = (newSet["coins"] as List).length - 1; i >= 0; i--) {
          final dynamic newCoin = newSet["coins"][i];
          final List<dynamic> translatedCoin = [];
          translatedCoin.add(
            !isHexadecimal(newCoin[0] as String)
                ? base64ToHex(newCoin[0] as String)
                : newCoin[0],
          );
          translatedCoin.add(
            !isHexadecimal(newCoin[1] as String)
                ? base64ToReverseHex(newCoin[1] as String)
                : newCoin[1],
          );
          try {
            translatedCoin.add(
              !isHexadecimal(newCoin[2] as String)
                  ? base64ToHex(newCoin[2] as String)
                  : newCoin[2],
            );
          } catch (e) {
            translatedCoin.add(newCoin[2]);
          }
          translatedCoin.add(
            !isHexadecimal(newCoin[3] as String)
                ? base64ToReverseHex(newCoin[3] as String)
                : newCoin[3],
          );
          set["coins"].insert(0, translatedCoin);
        }
        // save set to db
        await box.put(groupId, set);
        Logging.instance.d(
          "Updated current anonymity set for ${cryptoCurrency.identifier} with group ID $groupId",
        );
      }

      return set;
    } catch (e, s) {
      Logging.instance.e(
        "Failed to process CachedElectrumX.getAnonymitySet(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  String base64ToHex(String source) =>
      base64Decode(LineSplitter.split(source).join())
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join();

  String base64ToReverseHex(String source) =>
      base64Decode(LineSplitter.split(source).join())
          .reversed
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join();

  /// Call electrumx getTransaction on a per coin basis, storing the result in local db if not already there.
  ///
  /// ElectrumX api only called if the tx does not exist in local db
  Future<Map<String, dynamic>> getTransaction({
    required String txHash,
    required CryptoCurrency cryptoCurrency,
    bool verbose = true,
  }) async {
    try {
      final box = await DB.instance.getTxCacheBox(currency: cryptoCurrency);

      final cachedTx = box.get(txHash) as Map?;
      if (cachedTx == null) {
        final Map<String, dynamic> result =
            await electrumXClient.getTransaction(
          txHash: txHash,
          verbose: verbose,
        );

        result.remove("hex");
        result.remove("lelantusData");
        result.remove("sparkData");

        if (result["confirmations"] != null &&
            result["confirmations"] as int > minCacheConfirms) {
          await box.put(txHash, result);
        }

        // Logging.instance.log("using fetched result");
        return result;
      } else {
        // Logging.instance.log("using cached result");
        return Map<String, dynamic>.from(cachedTx);
      }
    } catch (e, s) {
      Logging.instance.e(
        "Failed to process CachedElectrumX.getTransaction(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<List<String>> getUsedCoinSerials({
    required CryptoCurrency cryptoCurrency,
    int startNumber = 0,
  }) async {
    try {
      final box =
          await DB.instance.getUsedSerialsCacheBox(currency: cryptoCurrency);

      final _list = box.get("serials") as List?;

      final Set<String> cachedSerials =
          _list == null ? {} : List<String>.from(_list).toSet();

      startNumber = max(
        max(0, startNumber),
        cachedSerials.length - 100, // 100 being some arbitrary buffer
      );

      final serials = await electrumXClient.getLelantusUsedCoinSerials(
        startNumber: startNumber,
      );

      final newSerials = List<String>.from(serials["serials"] as List)
          .map((e) => !isHexadecimal(e) ? base64ToHex(e) : e)
          .toSet();

      // ensure we are getting some overlap so we know we are not missing any
      if (cachedSerials.isNotEmpty && newSerials.isNotEmpty) {
        assert(cachedSerials.intersection(newSerials).isNotEmpty);
      }

      cachedSerials.addAll(newSerials);

      final resultingList = cachedSerials.toList();

      await box.put(
        "serials",
        resultingList,
      );

      return resultingList;
    } catch (e, s) {
      Logging.instance.e(
        "Failed to process CachedElectrumX.getUsedCoinSerials(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Clear all cached transactions for the specified coin
  Future<void> clearSharedTransactionCache({
    required CryptoCurrency cryptoCurrency,
  }) async {
    await DB.instance.clearSharedTransactionCache(currency: cryptoCurrency);
    await DB.instance.closeAnonymitySetCacheBox(currency: cryptoCurrency);
  }
}
