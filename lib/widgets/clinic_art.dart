import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Bundled vector illustrations: no remote image requests or layout shifts.
class ClinicArt extends StatelessWidget {
  const ClinicArt({super.key, this.records = false, this.height = 220});
  final bool records;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      records
          ? 'assets/illustrations/records.svg'
          : 'assets/illustrations/care-team.svg',
      height: height,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => SizedBox(height: height),
    ),
  );
}
