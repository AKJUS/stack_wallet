/* 
 * This file is part of Stack Wallet.
 * 
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 * Generated by Cypher Stack on 2023-05-26
 *
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../themes/coin_image_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../widgets/animated_widgets/rotating_arrows.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/stack_dialog.dart';

class BuildingTransactionDialog extends ConsumerStatefulWidget {
  const BuildingTransactionDialog({
    super.key,
    required this.onCancel,
    required this.coin,
    required this.isSpark,
  });

  final VoidCallback onCancel;
  final CryptoCurrency coin;
  final bool isSpark;

  @override
  ConsumerState<BuildingTransactionDialog> createState() =>
      _RestoringDialogState();
}

class _RestoringDialogState extends ConsumerState<BuildingTransactionDialog> {
  late final VoidCallback onCancel;

  @override
  void initState() {
    onCancel = widget.onCancel;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = ref.watch(
      coinImageSecondaryProvider(
        widget.coin,
      ),
    );

    if (Util.isDesktop) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Generating transaction",
            style: STextStyles.desktopH3(context),
          ),
          if (widget.isSpark)
            const SizedBox(
              height: 16,
            ),
          if (widget.isSpark)
            Text(
              "This may take a few minutes...",
              style: STextStyles.desktopSubtitleH2(context),
            ),
          const SizedBox(
            height: 40,
          ),
          assetPath.endsWith(".gif")
              ? Image.file(
                  File(
                    assetPath,
                  ),
                )
              : const RotatingArrows(
                  width: 40,
                  height: 40,
                ),
          const SizedBox(
            height: 40,
          ),
          SecondaryButton(
            buttonHeight: ButtonHeight.l,
            label: "Cancel",
            onPressed: () {
              onCancel.call();
            },
          ),
        ],
      );
    } else {
      return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: assetPath.endsWith(".gif")
            ? StackDialogBase(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.file(
                      File(
                        assetPath,
                      ),
                    ),
                    Text(
                      "Generating transaction",
                      textAlign: TextAlign.center,
                      style: STextStyles.pageTitleH2(context),
                    ),
                    if (widget.isSpark)
                      const SizedBox(
                        height: 12,
                      ),
                    if (widget.isSpark)
                      Text(
                        "This may take a few minutes...",
                        textAlign: TextAlign.center,
                        style: STextStyles.w500_16(context),
                      ),
                    const SizedBox(
                      height: 32,
                    ),
                    Row(
                      children: [
                        const Spacer(),
                        Expanded(
                          child: TextButton(
                            style: Theme.of(context)
                                .extension<StackColors>()!
                                .getSecondaryEnabledButtonStyle(context),
                            child: Text(
                              "Cancel",
                              style: STextStyles.itemSubtitle12(context),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onCancel.call();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : StackDialog(
                title: "Generating transaction",
                message:
                    widget.isSpark ? "This may take a few minutes..." : null,
                icon: const RotatingArrows(
                  width: 24,
                  height: 24,
                ),
                rightButton: TextButton(
                  style: Theme.of(context)
                      .extension<StackColors>()!
                      .getSecondaryEnabledButtonStyle(context),
                  child: Text(
                    "Cancel",
                    style: STextStyles.itemSubtitle12(context),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCancel.call();
                  },
                ),
              ),
      );
    }
  }
}
