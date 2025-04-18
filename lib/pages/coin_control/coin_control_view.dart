/* 
 * This file is part of Stack Wallet.
 * 
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 * Generated by Cypher Stack on 2023-05-26
 *
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';
import 'package:tuple/tuple.dart';

import '../../db/isar/main_db.dart';
import '../../models/isar/models/isar_models.dart';
import '../../providers/global/wallets_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../wallets/wallet/impl/namecoin_wallet.dart';
import '../../wallets/wallet/wallet.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/coin_control_interface.dart';
import '../../widgets/animated_widgets/rotate_icon.dart';
import '../../widgets/app_bar_field.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/custom_buttons/dropdown_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/expandable2.dart';
import '../../widgets/icon_widgets/x_icon.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/toggle.dart';
import 'utxo_card.dart';
import 'utxo_details_view.dart';

enum CoinControlViewType {
  manage,
  use;
}

class CoinControlView extends ConsumerStatefulWidget {
  const CoinControlView({
    super.key,
    required this.walletId,
    required this.type,
    this.requestedTotal,
    this.selectedUTXOs,
  });

  static const routeName = "/coinControl";

  final String walletId;
  final CoinControlViewType type;
  final Amount? requestedTotal;
  final Set<UTXO>? selectedUTXOs;

  @override
  ConsumerState<CoinControlView> createState() => _CoinControlViewState();
}

class _CoinControlViewState extends ConsumerState<CoinControlView> {
  final searchController = TextEditingController();
  final searchFocus = FocusNode();

  bool _isSearching = false;
  bool _showBlocked = false;

  CCSortDescriptor _sort = CCSortDescriptor.age;

  Map<String, List<Id>>? _map;
  List<Id>? _list;

  final Set<UTXO> _selectedAvailable = {};
  final Set<UTXO> _selectedBlocked = {};

  Future<void> _refreshBalance() async {
    final coinControlInterface =
        ref.read(pWallets).getWallet(widget.walletId) as CoinControlInterface;
    await coinControlInterface.updateBalance();
  }

  bool _isConfirmed(UTXO utxo, int currentChainHeight, Wallet wallet) {
    if (wallet is NamecoinWallet) {
      return wallet.checkUtxoConfirmed(utxo, currentChainHeight);
    } else {
      return utxo.isConfirmed(
        currentChainHeight,
        wallet.cryptoCurrency.minConfirms,
        wallet.cryptoCurrency.minCoinbaseConfirms,
      );
    }
  }

  @override
  void initState() {
    if (widget.selectedUTXOs != null) {
      _selectedAvailable.addAll(widget.selectedUTXOs!);
    }
    searchController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        setState(() {});
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final minConfirms = ref
        .watch(pWallets)
        .getWallet(widget.walletId)
        .cryptoCurrency
        .minConfirms;

    final coin = ref.watch(pWalletCoin(widget.walletId));
    final currentHeight = ref.watch(pWalletChainHeight(widget.walletId));

    if (_sort == CCSortDescriptor.address && !_isSearching) {
      _list = null;
      _map = MainDB.instance.queryUTXOsGroupedByAddressSync(
        walletId: widget.walletId,
        filter: CCFilter.all,
        sort: _sort,
        searchTerm: "",
        cryptoCurrency: coin,
      );
    } else {
      _map = null;
      _list = MainDB.instance.queryUTXOsSync(
        walletId: widget.walletId,
        filter: _isSearching
            ? CCFilter.all
            : _showBlocked
                ? CCFilter.frozen
                : CCFilter.available,
        sort: _sort,
        searchTerm: _isSearching ? searchController.text : "",
        cryptoCurrency: coin,
      );
    }

    return WillPopScope(
      onWillPop: () async {
        unawaited(_refreshBalance());
        Navigator.of(context).pop(
          widget.type == CoinControlViewType.use ? _selectedAvailable : null,
        );
        return false;
      },
      child: Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: _isSearching
                ? null
                : widget.type == CoinControlViewType.use &&
                        _selectedAvailable.isNotEmpty
                    ? AppBarIconButton(
                        icon: XIcon(
                          width: 24,
                          height: 24,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .topNavIconPrimary,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedAvailable.clear();
                          });
                        },
                      )
                    : AppBarBackButton(
                        onPressed: () {
                          unawaited(_refreshBalance());
                          Navigator.of(context).pop(
                            widget.type == CoinControlViewType.use
                                ? _selectedAvailable
                                : null,
                          );
                        },
                      ),
            title: _isSearching
                ? AppBarSearchField(
                    controller: searchController,
                    focusNode: searchFocus,
                  )
                : Text(
                    "Coin control",
                    style: STextStyles.navBarTitle(context),
                  ),
            titleSpacing: 0,
            actions: _isSearching
                ? [
                    AspectRatio(
                      aspectRatio: 1,
                      child: AppBarIconButton(
                        size: 36,
                        icon: SvgPicture.asset(
                          Assets.svg.x,
                          width: 20,
                          height: 20,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .topNavIconPrimary,
                        ),
                        onPressed: () {
                          // show search
                          setState(() {
                            _isSearching = false;
                          });
                        },
                      ),
                    ),
                  ]
                : [
                    AspectRatio(
                      aspectRatio: 1,
                      child: AppBarIconButton(
                        size: 36,
                        icon: SvgPicture.asset(
                          Assets.svg.search,
                          width: 20,
                          height: 20,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .topNavIconPrimary,
                        ),
                        onPressed: () {
                          // show search
                          setState(() {
                            _isSearching = true;
                          });
                        },
                      ),
                    ),
                    AspectRatio(
                      aspectRatio: 1,
                      child: JDropdownIconButton(
                        mobileAppBar: true,
                        groupValue: _sort,
                        items: CCSortDescriptor.values.toSet(),
                        onSelectionChanged: (CCSortDescriptor? newValue) {
                          if (newValue != null && newValue != _sort) {
                            setState(() {
                              _sort = newValue;
                            });
                          }
                        },
                        displayPrefix: "Sort by",
                      ),
                    ),
                  ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        if (!_isSearching)
                          RoundedWhiteContainer(
                            child: Text(
                              "This option allows you to control, freeze, and utilize "
                              "outputs at your discretion. Tap the output circle to "
                              "select.",
                              style: STextStyles.w500_14(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textSubtitle1,
                              ),
                            ),
                          ),
                        if (!_isSearching)
                          const SizedBox(
                            height: 10,
                          ),
                        if (!(_isSearching || _map != null))
                          SizedBox(
                            height: 48,
                            child: Toggle(
                              key: UniqueKey(),
                              onColor: Theme.of(context)
                                  .extension<StackColors>()!
                                  .popupBG,
                              onText: "Available outputs",
                              offColor: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textFieldDefaultBG,
                              offText: "Frozen outputs",
                              isOn: _showBlocked,
                              onValueChanged: (value) {
                                setState(() {
                                  _showBlocked = value;
                                });
                              },
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                              ),
                            ),
                          ),
                        if (!_isSearching)
                          const SizedBox(
                            height: 10,
                          ),
                        if (_isSearching)
                          Expanded(
                            child: ListView.separated(
                              itemCount: _list!.length,
                              separatorBuilder: (context, _) => const SizedBox(
                                height: 10,
                              ),
                              itemBuilder: (context, index) {
                                final utxo = MainDB.instance.isar.utxos
                                    .where()
                                    .idEqualTo(_list![index])
                                    .findFirstSync()!;

                                final isSelected =
                                    _selectedBlocked.contains(utxo) ||
                                        _selectedAvailable.contains(utxo);

                                return UtxoCard(
                                  key: Key(
                                    "${utxo.walletId}_${utxo.id}_$isSelected",
                                  ),
                                  walletId: widget.walletId,
                                  utxo: utxo,
                                  canSelect: widget.type ==
                                          CoinControlViewType.manage ||
                                      (widget.type == CoinControlViewType.use &&
                                          !utxo.isBlocked &&
                                          _isConfirmed(
                                            utxo,
                                            currentHeight,
                                            ref.watch(
                                              pWallets.select(
                                                (s) => s
                                                    .getWallet(widget.walletId),
                                              ),
                                            ),
                                          )),
                                  initialSelectedState: isSelected,
                                  onSelectedChanged: (value) {
                                    if (value) {
                                      utxo.isBlocked
                                          ? _selectedBlocked.add(utxo)
                                          : _selectedAvailable.add(utxo);
                                    } else {
                                      utxo.isBlocked
                                          ? _selectedBlocked.remove(utxo)
                                          : _selectedAvailable.remove(utxo);
                                    }
                                    setState(() {});
                                  },
                                  onPressed: () async {
                                    final result =
                                        await Navigator.of(context).pushNamed(
                                      UtxoDetailsView.routeName,
                                      arguments: Tuple2(
                                        utxo.id,
                                        widget.walletId,
                                      ),
                                    );
                                    if (mounted && result == "refresh") {
                                      setState(() {});
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        if (!_isSearching)
                          _list != null
                              ? Expanded(
                                  child: ListView.separated(
                                    itemCount: _list!.length,
                                    separatorBuilder: (context, _) =>
                                        const SizedBox(
                                      height: 10,
                                    ),
                                    itemBuilder: (context, index) {
                                      final utxo = MainDB.instance.isar.utxos
                                          .where()
                                          .idEqualTo(_list![index])
                                          .findFirstSync()!;

                                      final isSelected = _showBlocked
                                          ? _selectedBlocked.contains(utxo)
                                          : _selectedAvailable.contains(utxo);

                                      return UtxoCard(
                                        key: Key(
                                          "${utxo.walletId}_${utxo.id}_$isSelected",
                                        ),
                                        walletId: widget.walletId,
                                        utxo: utxo,
                                        canSelect: widget.type ==
                                                CoinControlViewType.manage ||
                                            (widget.type ==
                                                    CoinControlViewType.use &&
                                                !_showBlocked &&
                                                _isConfirmed(
                                                  utxo,
                                                  currentHeight,
                                                  ref.watch(
                                                    pWallets.select(
                                                      (s) => s.getWallet(
                                                        widget.walletId,
                                                      ),
                                                    ),
                                                  ),
                                                )),
                                        initialSelectedState: isSelected,
                                        onSelectedChanged: (value) {
                                          if (value) {
                                            _showBlocked
                                                ? _selectedBlocked.add(utxo)
                                                : _selectedAvailable.add(utxo);
                                          } else {
                                            _showBlocked
                                                ? _selectedBlocked.remove(utxo)
                                                : _selectedAvailable
                                                    .remove(utxo);
                                          }
                                          setState(() {});
                                        },
                                        onPressed: () async {
                                          final result =
                                              await Navigator.of(context)
                                                  .pushNamed(
                                            UtxoDetailsView.routeName,
                                            arguments: Tuple2(
                                              utxo.id,
                                              widget.walletId,
                                            ),
                                          );
                                          if (mounted && result == "refresh") {
                                            setState(() {});
                                          }
                                        },
                                      );
                                    },
                                  ),
                                )
                              : Expanded(
                                  child: ListView.separated(
                                    itemCount: _map!.entries.length,
                                    separatorBuilder: (context, _) =>
                                        const SizedBox(
                                      height: 10,
                                    ),
                                    itemBuilder: (context, index) {
                                      final entry =
                                          _map!.entries.elementAt(index);
                                      final _controller =
                                          RotateIconController();

                                      return Expandable2(
                                        border: Theme.of(context)
                                            .extension<StackColors>()!
                                            .backgroundAppBar,
                                        background: Theme.of(context)
                                            .extension<StackColors>()!
                                            .popupBG,
                                        animationDurationMultiplier:
                                            0.2 * entry.value.length,
                                        onExpandWillChange: (state) {
                                          if (state ==
                                              Expandable2State.expanded) {
                                            _controller.forward?.call();
                                          } else {
                                            _controller.reverse?.call();
                                          }
                                        },
                                        header: RoundedContainer(
                                          padding: const EdgeInsets.all(14),
                                          color: Colors.transparent,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      entry.key,
                                                      style:
                                                          STextStyles.w600_14(
                                                        context,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 2,
                                                    ),
                                                    Text(
                                                      "${entry.value.length} "
                                                      "output${entry.value.length > 1 ? "s" : ""}",
                                                      style:
                                                          STextStyles.w500_12(
                                                        context,
                                                      ).copyWith(
                                                        color: Theme.of(context)
                                                            .extension<
                                                                StackColors>()!
                                                            .textSubtitle1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              RotateIcon(
                                                animationDurationMultiplier:
                                                    0.2 * entry.value.length,
                                                icon: SvgPicture.asset(
                                                  Assets.svg.chevronDown,
                                                  width: 14,
                                                  color: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .textSubtitle1,
                                                ),
                                                curve: Curves.easeInOut,
                                                controller: _controller,
                                              ),
                                            ],
                                          ),
                                        ),
                                        children: entry.value.map(
                                          (id) {
                                            final utxo = MainDB
                                                .instance.isar.utxos
                                                .where()
                                                .idEqualTo(id)
                                                .findFirstSync()!;

                                            final isSelected = _selectedBlocked
                                                    .contains(utxo) ||
                                                _selectedAvailable
                                                    .contains(utxo);

                                            return UtxoCard(
                                              key: Key(
                                                "${utxo.walletId}_${utxo.id}_$isSelected",
                                              ),
                                              walletId: widget.walletId,
                                              utxo: utxo,
                                              canSelect: widget.type ==
                                                      CoinControlViewType
                                                          .manage ||
                                                  (widget.type ==
                                                          CoinControlViewType
                                                              .use &&
                                                      !utxo.isBlocked &&
                                                      _isConfirmed(
                                                        utxo,
                                                        currentHeight,
                                                        ref.watch(
                                                          pWallets.select(
                                                            (s) => s.getWallet(
                                                              widget.walletId,
                                                            ),
                                                          ),
                                                        ),
                                                      )),
                                              initialSelectedState: isSelected,
                                              onSelectedChanged: (value) {
                                                if (value) {
                                                  utxo.isBlocked
                                                      ? _selectedBlocked
                                                          .add(utxo)
                                                      : _selectedAvailable
                                                          .add(utxo);
                                                } else {
                                                  utxo.isBlocked
                                                      ? _selectedBlocked
                                                          .remove(utxo)
                                                      : _selectedAvailable
                                                          .remove(utxo);
                                                }
                                                setState(() {});
                                              },
                                              onPressed: () async {
                                                final result =
                                                    await Navigator.of(context)
                                                        .pushNamed(
                                                  UtxoDetailsView.routeName,
                                                  arguments: Tuple2(
                                                    utxo.id,
                                                    widget.walletId,
                                                  ),
                                                );
                                                if (mounted &&
                                                    result == "refresh") {
                                                  setState(() {});
                                                }
                                              },
                                            );
                                          },
                                        ).toList(),
                                      );
                                    },
                                  ),
                                ),
                      ],
                    ),
                  ),
                ),
                if (((_showBlocked && _selectedBlocked.isNotEmpty) ||
                        (!_showBlocked && _selectedAvailable.isNotEmpty)) &&
                    widget.type == CoinControlViewType.manage)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .backgroundAppBar,
                      boxShadow: [
                        Theme.of(context)
                            .extension<StackColors>()!
                            .standardBoxShadow,
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SecondaryButton(
                        label: _showBlocked ? "Unfreeze" : "Freeze",
                        onPressed: () async {
                          if (_showBlocked) {
                            await MainDB.instance.putUTXOs(
                              _selectedBlocked
                                  .map(
                                    (e) => e.copyWith(
                                      isBlocked: false,
                                    ),
                                  )
                                  .toList(),
                            );
                            _selectedBlocked.clear();
                          } else {
                            await MainDB.instance.putUTXOs(
                              _selectedAvailable
                                  .map(
                                    (e) => e.copyWith(
                                      isBlocked: true,
                                    ),
                                  )
                                  .toList(),
                            );
                            _selectedAvailable.clear();
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                if (!_showBlocked && widget.type == CoinControlViewType.use)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .backgroundAppBar,
                      boxShadow: [
                        Theme.of(context)
                            .extension<StackColors>()!
                            .standardBoxShadow,
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          RoundedWhiteContainer(
                            padding: const EdgeInsets.all(0),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Selected amount",
                                        style: STextStyles.w600_14(context),
                                      ),
                                      Builder(
                                        builder: (context) {
                                          final int selectedSumInt =
                                              _selectedAvailable.isEmpty
                                                  ? 0
                                                  : _selectedAvailable
                                                      .map((e) => e.value)
                                                      .reduce(
                                                        (value, element) =>
                                                            value += element,
                                                      );
                                          final selectedSum =
                                              selectedSumInt.toAmountAsRaw(
                                            fractionDigits: coin.fractionDigits,
                                          );
                                          return SelectableText(
                                            ref
                                                .watch(pAmountFormatter(coin))
                                                .format(selectedSum),
                                            style: widget.requestedTotal == null
                                                ? STextStyles.w600_14(context)
                                                : STextStyles.w600_14(context)
                                                    .copyWith(
                                                    color: selectedSum >=
                                                            widget
                                                                .requestedTotal!
                                                        ? Theme.of(context)
                                                            .extension<
                                                                StackColors>()!
                                                            .accentColorGreen
                                                        : Theme.of(context)
                                                            .extension<
                                                                StackColors>()!
                                                            .accentColorRed,
                                                  ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.requestedTotal != null)
                                  Container(
                                    width: double.infinity,
                                    height: 1.5,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .backgroundAppBar,
                                  ),
                                if (widget.requestedTotal != null)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Amount to send",
                                          style: STextStyles.w600_14(context),
                                        ),
                                        SelectableText(
                                          ref
                                              .watch(pAmountFormatter(coin))
                                              .format(widget.requestedTotal!),
                                          style: STextStyles.w600_14(context),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          PrimaryButton(
                            label: "Use coins",
                            enabled: _selectedAvailable.isNotEmpty,
                            onPressed: () async {
                              if (searchFocus.hasFocus) {
                                searchFocus.unfocus();
                              }
                              Navigator.of(context).pop(
                                _selectedAvailable,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
