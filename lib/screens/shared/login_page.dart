import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/staff/staff_auth_service.dart';
import '../../core/theme.dart';
import '../../core/app_state.dart';
import '../../widgets/clinic_art.dart';
import '../../widgets/motion.dart';
import '../../models/models.dart';
import 'app_shell.dart';

const _teal = Color(0xFF087F73);
const _forest = Color(0xFF103F3B);
const _mint = Color(0xFFEAF5F0);
const _muted = Color(0xFF647873);
const _border = Color(0xFFDCE7E1);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  UserRole role = UserRole.staff;
  bool obscure = true;
  bool signingIn = false;
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (signingIn) return;

    final enteredEmail = email.text.trim();
    final enteredPassword = password.text;
    final selectedRole = role;
    if (enteredEmail.isEmpty || enteredPassword.isEmpty) {
      _showMessage('Enter your email and password to continue.');
      return;
    }

    setState(() => signingIn = true);
    FocusScope.of(context).unfocus();
    try {
      final staffAuth = await StaffAuthService.initialize();
      await staffAuth.signIn(
        email: enteredEmail,
        password: enteredPassword,
        role: selectedRole,
      );
      if (!mounted) return;
      await AppStateScope.of(context).loadClinicData();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 420),
          pageBuilder: (_, animation, secondaryAnimation) =>
              AppShell(role: selectedRole),
          transitionsBuilder: (_, animation, secondaryAnimation, child) =>
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error.code));
    } on FirebaseException catch (error) {
      _showMessage(switch (error.code) {
        'permission-denied' => 'Patient record access was denied. Contact your clinic administrator to check your account access.',
        'app-not-found' || 'not-initialized' =>
          'Firebase setup is missing. Contact your app administrator.',
        _ => 'Unable to connect to Firebase (${error.code}). Please try again.',
      });
    } on PlatformException catch (error) {
      // Android reports missing generated Firebase resources as a platform error.
      final missingOptions =
          error.message?.contains(
            'Failed to load FirebaseOptions from resource',
          ) ??
          false;
      _showMessage(
        missingOptions
            ? 'Firebase setup is missing. Contact your app administrator.'
            : 'Unable to start sign-in (${error.code}). Restart the app and try again.',
      );
    } catch (_) {
      _showMessage('Unable to sign in right now. Please try again.');
    } finally {
      if (mounted) setState(() => signingIn = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _authErrorMessage(String code) => switch (code) {
    'invalid-email' => 'Enter a valid email address.',
    'workspace-access-denied' => 'This account does not have access to the selected workspace. Choose the correct role or contact your clinic administrator.',
    'invalid-credential' ||
    'user-not-found' ||
    'wrong-password' => 'The email or password is incorrect.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Try again later.',
    'network-request-failed' =>
      'Cannot connect. Check your internet connection and try again.',
    'operation-not-allowed' || 'configuration-not-found' =>
      'Email/password sign-in is not enabled. Contact your app administrator.',
    'invalid-api-key' || 'app-not-authorized' =>
      'Firebase configuration is invalid. Contact your app administrator.',
    _ => 'Unable to sign in ($code). Please try again.',
  };

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    // Scope the green palette to login, including Material focus/hover states.
    return Theme(
      data: base.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _teal,
          primary: _teal,
          onPrimary: Colors.white,
          secondary: _teal,
          surface: Colors.white,
          onSurface: _forest,
          surfaceTint: Colors.transparent,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: _teal,
          selectionColor: Color(0xFFBCE4D8),
          selectionHandleColor: _teal,
        ),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          fillColor: const Color(0xFFF8FAF8),
          prefixIconColor: _muted,
          suffixIconColor: _muted,
          labelStyle: base.inputDecorationTheme.labelStyle?.copyWith(
            color: _muted,
          ),
          floatingLabelStyle: const TextStyle(color: _teal),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _teal, width: 1.5),
          ),
        ),
      ),
      child: Builder(builder: _buildPage),
    );
  }

  Widget _buildPage(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 960;
    final tablet = width >= 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 0, 20),
                  child: _WelcomePanel(),
                ),
              ),
            Expanded(
              child: Center(
                child: _LoginViewport(
                  scrollable: !tablet,
                  maxWidth: 460,
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 40 : 20,
                    vertical: wide ? 36 : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!wide) ...[
                          const Reveal(child: _Brand()),
                          const SizedBox(height: 28),
                        ],
                        Reveal(
                          delay: 60,
                          child: Container(
                            padding: EdgeInsets.all(wide ? 32 : 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: _border),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x080D4339),
                                  blurRadius: 40,
                                  offset: Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: _Pill(
                                    icon: Icons.monitor_heart_outlined,
                                    label: 'YOUR CLINIC, CONNECTED',
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Welcome back',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontSize: wide ? 32 : 28,
                                        letterSpacing: -1.2,
                                        color: _forest,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'A fresh start to better care.\nChoose your workspace to continue.',
                                  style: TextStyle(color: _muted, height: 1.65),
                                ),
                                const SizedBox(height: 26),
                                Reveal(
                                  delay: 160,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final cards = [
                                        _RoleCard(
                                          title: 'Clinic Staff',
                                          subtitle: 'Organize visits',
                                          icon: Icons.badge_outlined,
                                          selected: role == UserRole.staff,
                                          onTap: () => setState(
                                            () => role = UserRole.staff,
                                          ),
                                        ),
                                        _RoleCard(
                                          title: 'Doctor',
                                          subtitle: 'Consult & care',
                                          icon: Icons.medical_services_outlined,
                                          selected: role == UserRole.doctor,
                                          onTap: () => setState(
                                            () => role = UserRole.doctor,
                                          ),
                                        ),
                                      ];
                                      if (constraints.maxWidth < 260 ||
                                          MediaQuery.textScalerOf(context)
                                                  .scale(14) >
                                              22) {
                                        return Column(
                                          children: [
                                            cards[0],
                                            const SizedBox(height: 10),
                                            cards[1],
                                          ],
                                        );
                                      }
                                      return Row(
                                        children: [
                                          Expanded(child: cards[0]),
                                          const SizedBox(width: 12),
                                          Expanded(child: cards[1]),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 26),
                                Reveal(
                                  delay: 240,
                                  child: AutofillGroup(
                                    child: Column(
                                      children: [
                                        TextField(
                                          controller: email,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.username,
                                          ],
                                          decoration: const InputDecoration(
                                            labelText: 'Email or employee ID',
                                            hintText: 'Email or employee ID',
                                            prefixIcon: Icon(
                                              Icons.alternate_email_rounded,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        TextField(
                                          controller: password,
                                          obscureText: obscure,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          onSubmitted: (_) => signIn(),
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            hintText: 'Password',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline_rounded,
                                              size: 20,
                                            ),
                                            suffixIcon: IconButton(
                                              tooltip: obscure
                                                  ? 'Show password'
                                                  : 'Hide password',
                                              onPressed: () => setState(
                                                () => obscure = !obscure,
                                              ),
                                              icon: Icon(
                                                obscure
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                          .visibility_off_outlined,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => showDialog<void>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Clinic account required',
                                        ),
                                        content: const Text(
                                          'Use your clinic email and password, then select the workspace assigned to your account. Contact your clinic administrator if you need access.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Got it'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: const Text('Need help signing in?'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Reveal(
                                  delay: 320,
                                  child: FilledButton(
                                    onPressed: signingIn ? null : signIn,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _teal,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: AnimatedSize(
                                      duration: _motionDuration(context),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: AnimatedSwitcher(
                                              duration: _motionDuration(
                                                context,
                                              ),
                                              child: Text(
                                                'Sign in as ${role == UserRole.staff ? 'Staff' : 'Doctor'}',
                                                key: ValueKey(role),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Divider(height: 1, color: _border),
                                const SizedBox(height: 20),
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 17,
                                      color: _muted,
                                    ),
                                    SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        'Staff and doctor access.\nPatient records are saved to the clinic database.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          height: 1.65,
                                          color: _muted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Thoughtfully connected. Patient by patient.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Duration _motionDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 240);

class _LoginViewport extends StatelessWidget {
  const _LoginViewport({
    required this.padding,
    required this.child,
    this.scrollable = false,
    this.maxWidth = double.infinity,
  });

  final EdgeInsets padding;
  final Widget child;
  final bool scrollable;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(padding: padding, child: child);
    }

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          // Keep all content visible on short windows and with the keyboard open.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: constraints.maxWidth.clamp(0, maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: light ? const Color(0xFFCEF3DD) : _teal,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          Icons.local_hospital_rounded,
          color: light ? _forest : Colors.white,
          size: 25,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shrinovva Homeophatic',
              style: TextStyle(
                fontFamily: AppTypography.heading,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: light ? Colors.white : _forest,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Patient care system',
              style: TextStyle(
                fontSize: 11,
                color: light ? const Color(0xFFB5D2C7) : _muted,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_forest, Color(0xFF176558)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth > 550 ? 48.0 : 32.0;
          return _LoginViewport(
            padding: EdgeInsets.all(padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - padding * 2).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Reveal(child: _Brand(light: true)),
                  const SizedBox(height: 40),
                  const Reveal(
                    delay: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MORE TIME FOR WHAT MATTERS',
                          style: TextStyle(
                            color: Color(0xFFB5E4C9),
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 18),
                        Text(
                          'A calmer day.\nMore connected\ncare.',
                          style: TextStyle(
                            fontFamily: AppTypography.heading,
                            color: Colors.white,
                            fontSize: 46,
                            height: 1.12,
                            letterSpacing: -1.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Bring your team, patient visits, and follow-ups\ntogether in one thoughtful workspace.',
                          style: TextStyle(
                            color: Color(0xFFCAE0D7),
                            height: 1.7,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Reveal(
                    delay: 220,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                      decoration: BoxDecoration(
                        color: _mint,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        children: [
                          ClinicArt(height: 230),
                          SizedBox(height: 10),
                          _Pill(
                            icon: Icons.favorite_outline_rounded,
                            label: 'A little more connected. A lot more care.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _Feature(
                        icon: Icons.people_outline_rounded,
                        label: 'Patient-first care',
                      ),
                      _Feature(
                        icon: Icons.hub_outlined,
                        label: 'One shared workspace',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _teal),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _teal,
              letterSpacing: .5,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: AnimatedContainer(
      duration: _motionDuration(context),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? _mint : Colors.white,
        border: Border.all(color: selected ? _teal : _border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: selected ? _teal : _muted, size: 23),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: _motionDuration(context),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        key: ValueKey(selected),
                        size: 18,
                        color: selected ? _teal : _border,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: _muted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: const Color(0xFFB5E4C9)),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFFCAE0D7)),
      ),
    ],
  );
}
