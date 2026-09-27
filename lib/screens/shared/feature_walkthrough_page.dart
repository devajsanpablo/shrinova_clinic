import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../core/theme.dart';

/// Points at a real control and invokes its action after it is tapped.
class WalkthroughStep {
  const WalkthroughStep({
    required this.target,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final GlobalKey target;
  final String title;
  final String description;
  final FutureOr<void> Function() onTap;
}

/// Owns only coach overlays; never creates sample patients or visits.
class FeatureWalkthrough {
  FeatureWalkthrough({
    required this.context,
    required this.steps,
    required this.onEnd,
  });
  final BuildContext context;
  final List<WalkthroughStep> steps;
  final VoidCallback onEnd;
  static final Set<String> _seenThisSession = {};
  TutorialCoachMark? _coach;
  String? _preferenceKey;
  int _index = 0;
  bool _ended = false;
  bool _advancing = false;

  Future<void> showIfNeeded(String accountKey) async {
    // Offer the replacement interactive tour once to users of the old demo.
    _preferenceKey = 'feature_walkthrough_v2_$accountKey';
    if (_seenThisSession.contains(_preferenceKey)) return;
    try {
      if (await SharedPreferencesAsync().getBool(_preferenceKey!) == true) {
        return;
      }
    } catch (_) {
      // Storage failures must not block access to the workspace.
    }
    if (_ended || !context.mounted) return;
    await show();
  }

  Future<void> show() async {
    // Let page transitions and Reveal animations settle before measuring.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (_ended || !context.mounted) return;
    final targetContext = steps[_index].target.currentContext;
    if (targetContext == null) {
      _end(remember: false);
      return;
    }
    await Scrollable.ensureVisible(
      targetContext,
      alignment: .5,
      duration: const Duration(milliseconds: 200),
    );
    await WidgetsBinding.instance.endOfFrame;
    if (_ended || !context.mounted) return;
    final step = steps[_index];
    _coach = TutorialCoachMark(
      targets: [
        TargetFocus(
          keyTarget: step.target,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          enableTargetTab: true,
          enableOverlayTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
              ),
              padding: EdgeInsets.zero,
              builder: (overlayContext, controller) =>
                  _hint(overlayContext, step, controller.skip),
            ),
          ],
        ),
      ],
      useSafeArea: false,
      hideSkip: true,
      disableBackButton: true,
      pulseEnable: false,
      colorShadow: AppColors.ink,
      onFinish: () {
        // The package removes its back-blocking route after this callback.
        scheduleMicrotask(_advance);
      },
      onSkip: () {
        scheduleMicrotask(() => _end(remember: true));
        return true;
      },
    )..show(context: context);
  }

  Widget _hint(
    BuildContext overlayContext,
    WalkthroughStep step,
    VoidCallback skip,
  ) {
    final media = MediaQuery.of(overlayContext);
    final box = step.target.currentContext!.findRenderObject()! as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final above = position.dy - media.padding.top - 16;
    final below =
        media.size.height -
        media.padding.bottom -
        position.dy -
        box.size.height -
        16;
    final placeBelow = below >= above;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        placeBelow
            ? position.dy + box.size.height + 16
            : media.padding.top + 16,
        16,
        placeBelow
            ? media.padding.bottom + 16
            : media.size.height - position.dy + 16,
      ),
      child: Align(
        alignment: placeBelow ? Alignment.topCenter : Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP ${_index + 1} OF ${steps.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.title,
                    style: Theme.of(overlayContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(step.description),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.touch_app_outlined, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Tap the highlighted control to continue.'),
                      ),
                    ],
                  ),
                  TextButton(onPressed: skip, child: const Text('Skip tour')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _advance() async {
    if (_ended || _advancing || !context.mounted) return;
    _advancing = true;
    try {
      await steps[_index].onTap();
      if (_ended || !context.mounted) return;
      _index++;
      if (_index == steps.length) {
        _end(remember: true);
      } else {
        await show();
      }
    } catch (_) {
      _end(remember: false);
    } finally {
      _advancing = false;
    }
  }

  void _end({required bool remember}) {
    if (_ended) return;
    _ended = true;
    _coach?.removeOverlayEntry();
    if (remember && _preferenceKey != null) {
      _seenThisSession.add(_preferenceKey!);
      unawaited(_remember());
    }
    if (context.mounted) onEnd();
  }

  Future<void> _remember() async {
    try {
      await SharedPreferencesAsync().setBool(_preferenceKey!, true);
    } catch (_) {
      // The in-memory flag still prevents repeats during this app session.
    }
  }

  void dispose() {
    _ended = true;
    _coach?.removeOverlayEntry();
  }
}
