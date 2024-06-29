import 'package:flutter/material.dart';
import '../../../models/isar/ordinal.dart';
import '../ordinal_details_view.dart';
import '../../../pages_desktop_specific/ordinals/desktop_ordinal_details_view.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../widgets/rounded_white_container.dart';

class OrdinalCard extends StatelessWidget {
  const OrdinalCard({
    super.key,
    required this.walletId,
    required this.ordinal,
  });

  final String walletId;
  final Ordinal ordinal;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      radiusMultiplier: 2,
      onPressed: () {
        Navigator.of(context).pushNamed(
          Util.isDesktop
              ? DesktopOrdinalDetailsView.routeName
              : OrdinalDetailsView.routeName,
          arguments: (walletId: walletId, ordinal: ordinal),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: Image.network(
                ordinal.content, // Use the preview URL as the image source
                fit: BoxFit.cover,
                filterQuality:
                    FilterQuality.none, // Set the filter mode to nearest
              ),
            ),
          ),
          const Spacer(),
          Text(
            'INSC. ${ordinal.inscriptionNumber}', // infer from address associated with utxoTXID
            style: STextStyles.w500_12(context),
          ),
          // const Spacer(),
          // Text(
          //   "ID ${ordinal.inscriptionId}",
          //   style: STextStyles.w500_8(context),
          // ),
        ],
      ),
    );
  }
}
