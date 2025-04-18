/* 
 * This file is part of Stack Wallet.
 * 
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 * Generated by Cypher Stack on 2023-05-26
 *
 */

import 'package:dart_numerics/dart_numerics.dart';
import 'package:hive/hive.dart';

part '../type_adaptors/utxo_model.g.dart';

// @HiveType(typeId: 6)
class UtxoData {
  // @HiveField(0)
  final String totalUserCurrency;
  // @HiveField(1)
  final int satoshiBalance;
  // @HiveField(2)
  final dynamic bitcoinBalance;
  // @HiveField(3)
  List<UtxoObject> unspentOutputArray;
  // @HiveField(4)
  final int satoshiBalanceUnconfirmed;

  UtxoData({
    required this.totalUserCurrency,
    required this.satoshiBalance,
    this.bitcoinBalance,
    required this.unspentOutputArray,
    required this.satoshiBalanceUnconfirmed,
  });

  factory UtxoData.fromJson(Map<String, dynamic> json) {
    final outputList = json['outputArray'] as List;
    final List<UtxoObject> utxoList = outputList
        .map((output) => UtxoObject.fromJson(output as Map<String, dynamic>))
        .toList();
    final String totalUserCurr = json['total_user_currency'] as String? ?? "";
    // TODO: this is not coin agnostic
    final String totalBtc = json['total_btc'] as String? ?? "";
    final int unconfirmed = json['unconfirmed'] as int? ?? 0;

    return UtxoData(
      totalUserCurrency: totalUserCurr,
      satoshiBalance: json['total_sats'] as int,
      bitcoinBalance: totalBtc,
      unspentOutputArray: utxoList,
      satoshiBalanceUnconfirmed: unconfirmed,
    );
  }

  @override
  String toString() {
    return "{totalUserCurrency: $totalUserCurrency, satoshiBalance: $satoshiBalance, bitcoinBalance: $bitcoinBalance, unspentOutputArray: $unspentOutputArray}";
  }
}

// @HiveType(typeId: 7)
class UtxoObject {
  // @HiveField(0)
  final String txid;
  // @HiveField(1)
  final int vout;
  // @HiveField(2)
  final Status status;
  // @HiveField(3)
  final int value;
  // @HiveField(4)
  final String fiatWorth;
  // @HiveField(5)
  String txName;
  // @HiveField(6)
  bool blocked;
  // @HiveField(7)
  bool isCoinbase;

  UtxoObject({
    required this.txid,
    required this.vout,
    required this.status,
    required this.value,
    required this.fiatWorth,
    required this.txName,
    required this.blocked,
    required this.isCoinbase,
  });

  factory UtxoObject.fromJson(Map<String, dynamic> json) {
    return UtxoObject(
      txName: '----',
      txid: json['txid'] as String? ?? "",
      vout: json['vout'] as int? ?? -1,
      status: Status.fromJson(json['status'] as Map<String, dynamic>),
      value: json['value'] as int? ?? 0,
      fiatWorth: json['fiatWorth'] as String? ?? "",
      blocked: false,
      isCoinbase: json["is_coinbase"] as bool? ?? false,
    );
  }

  @override
  String toString() {
    final String utxo =
        "{txid: $txid, vout: $vout, value: $value, fiat: $fiatWorth, blocked: $blocked, status: $status, is_coinbase: $isCoinbase}";

    return utxo;
  }
}

// @HiveType(typeId: 8)
class Status {
  // @HiveField(0)
  final bool confirmed;
  // @HiveField(1)
  final String blockHash;
  // @HiveField(2)
  final int blockHeight;
  // @HiveField(3)
  final int blockTime;
  // @HiveField(4)
  final int confirmations;

  Status({
    required this.confirmed,
    required this.blockHash,
    required this.blockHeight,
    required this.blockTime,
    required this.confirmations,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      confirmed: json['confirmed'] as bool? ?? false,
      blockHash: json['block_hash'] as String? ?? "",
      blockHeight: json['block_height'] is int
          ? json['block_height'] as int
          : int64MaxValue,
      blockTime: json['block_time'] as int? ?? 0,
      confirmations: json["confirmations"] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return "{confirmed: $confirmed, blockHash: $blockHash, blockHeight: $blockHeight, blockTime: $blockTime, confirmations: $confirmations}";
  }
}
