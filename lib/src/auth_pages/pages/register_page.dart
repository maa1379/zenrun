import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/src/auth_pages/providers/auth_provider.dart';

import '../../../generated/assets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.inviteEmail});

  final String inviteEmail;
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final FocusNode _emailFocusNode;
  late final FocusNode _phoneFocusNode;
  late final FocusNode _cityFocusNode;
  late final FocusNode _stateFocusNode;
  late final FocusNode _ageFocusNode;
  late final FocusNode _heightFocusNode;
  late final FocusNode _weightFocusNode;
  late final FocusNode _exerciseHoursFocusNode;
  late final FocusNode _invitedEmailFocusNode;
  late final FocusNode _codeFocusNode;
  late final PhoneController _phoneController;

  @override
  void initState() {
    final authProvider = context.read<AuthProvider>();
    authProvider.clean();
    if (widget.inviteEmail.isNotEmpty) {
      authProvider.invitedEmail.text = widget.inviteEmail;
    }
    _emailFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _cityFocusNode = FocusNode();
    _stateFocusNode = FocusNode();
    _ageFocusNode = FocusNode();
    _heightFocusNode = FocusNode();
    _weightFocusNode = FocusNode();
    _exerciseHoursFocusNode = FocusNode();
    _invitedEmailFocusNode = FocusNode();
    _codeFocusNode = FocusNode();

    _phoneController = PhoneController(
      initialValue: PhoneNumber(isoCode: IsoCode.US, nsn: authProvider.phone.text),
    );
    _phoneController.addListener(() {
      authProvider.phone.text = "+${_phoneController.value.countryCode}${_phoneController.value.nsn}";
      authProvider.country.text = _phoneController.value.isoCode.name;
    });
    super.initState();
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _cityFocusNode.dispose();
    _stateFocusNode.dispose();
    _ageFocusNode.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    _exerciseHoursFocusNode.dispose();
    _invitedEmailFocusNode.dispose();
    _codeFocusNode.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm(AuthProvider provider) {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!provider.isSend) {
      if (_formKey.currentState?.validate() ?? false) {
        if (provider.email.text.isEmpty || provider.phone.text.isEmpty ||
            provider.city.text.isEmpty || provider.country.text.isEmpty ||
            provider.state.text.isEmpty || provider.age.text.isEmpty ||
            provider.height.text.isEmpty || provider.weight.text.isEmpty ||
            provider.exerciseHours.text.isEmpty || provider.gender == null) {
          ViewHelper.showErrorDialog(context, text: "Please complete all fields");
        } else {
          provider.register(context);
        }
      } else {
        ViewHelper.showErrorDialog(context, text: "Please fix the errors in the form");
      }
    } else {
      if (provider.code.text.isNotEmpty) {
        provider.verifySms(context);
      } else {
        ViewHelper.showErrorDialog(context, text: "Please enter the verification code");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50, // تم روشن
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  physics: const BouncingScrollPhysics(),
                  child: Consumer<AuthProvider>(
                    builder: (context, provider, child) {
                      return Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildHeader().animate().fadeIn().slideY(begin: -0.1, end: 0),
                            Gap(3.h),
                            _buildFormCard(provider).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                            Gap(4.h),
                            _buildSocialMediaSection().animate().fadeIn(delay: 400.ms),
                            Gap(4.h),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: IconButton(
              onPressed: () async {
                await launchUrl(Uri.parse(context.read<AuthProvider>().contactUs?.whatsapp ?? ""), mode: LaunchMode.externalApplication);
              },
              icon: Image.asset(Assets.imagesSupport, width: 24, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          "Create Account".toLn(),
          style: const TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        const Gap(8),
        Text(
          "Join ZenRun and start earning today",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFormCard(AuthProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Account Information"),
          _buildEmailTextField(provider),
          const Gap(15),
          _buildMobileTextField(provider),
          const Gap(15),
          _buildInvitedEmailTextField(provider),

          Gap(3.h),
          _sectionTitle("Location Details"),
          Row(
            children: [
              Expanded(child: _buildCityTextField(provider)),
              const Gap(15),
              Expanded(child: _buildStateTextField(provider)),
            ],
          ),

          Gap(3.h),
          _sectionTitle("Body Metrics"),
          _buildAgeField(provider),
          const Gap(15),
          Row(
            children: [
              Expanded(child: _buildHeightField(provider)),
              const Gap(15),
              Expanded(child: _buildWeightField(provider)),
            ],
          ),
          const Gap(15),
          _buildExerciseHoursField(provider),
          const Gap(15),
          _buildGenderDropdown(provider),

          if (provider.isSend) ...[
            Gap(3.h),
            _sectionTitle("Verification"),
            _buildCodeTextField(provider).animate().fadeIn(),
          ],

          Gap(4.h),
          _buildRegisterButton(provider),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toLn(),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildRegisterButton(AuthProvider provider) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: ColorsHelper.btn2,
        boxShadow: [
          BoxShadow(color: ColorsHelper.btn2.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _submitForm(provider),
          child: Center(
            child: Text(
              provider.isSend ? "Verify & Register" : "Register Now",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
      ),
    );
  }

  // --- TextField Builders ---

  Widget _buildEmailTextField(AuthProvider provider) {
    return TextFormField(
      focusNode: _emailFocusNode,
      controller: provider.email,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocusNode),
      onChanged: (v) { if (provider.isSend) { provider.isSend = false; provider.update(); } },
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      decoration: _inputDecoration(hint: "Email", icon: Icons.alternate_email),
    );
  }

  Widget _buildMobileTextField(AuthProvider provider) {
    return PhoneFormField(
      focusNode: _phoneFocusNode,
      controller: _phoneController,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => FocusScope.of(context).requestFocus(_cityFocusNode),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) => (v == null || v.nsn.isEmpty) ? "Invalid phone" : null,
      countrySelectorNavigator: const CountrySelectorNavigator.modalBottomSheet(),
      decoration: _inputDecoration(hint: "Mobile Number", icon: Icons.phone_android),
    );
  }

  Widget _buildCityTextField(AuthProvider provider) {
    return TextFormField(
      focusNode: _cityFocusNode,
      controller: provider.city,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_stateFocusNode),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      decoration: _inputDecoration(hint: "City", icon: Icons.location_city),
    );
  }

  Widget _buildStateTextField(AuthProvider provider) {
    return TextFormField(
      focusNode: _stateFocusNode,
      controller: provider.state,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_ageFocusNode),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      decoration: _inputDecoration(hint: "State", icon: Icons.map_outlined),
    );
  }

  Widget _buildAgeField(AuthProvider provider) {
    return TextFormField(
      focusNode: _ageFocusNode,
      controller: provider.age,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_heightFocusNode),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      decoration: _inputDecoration(hint: "Age", icon: Icons.cake_outlined),
    );
  }

  Widget _buildHeightField(AuthProvider provider) {
    return TextFormField(
      focusNode: _heightFocusNode,
      controller: provider.height,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_weightFocusNode),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      decoration: _inputDecoration(hint: "Height (cm)", icon: Icons.height),
    );
  }

  Widget _buildWeightField(AuthProvider provider) {
    return TextFormField(
      focusNode: _weightFocusNode,
      controller: provider.weight,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_exerciseHoursFocusNode),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      decoration: _inputDecoration(hint: "Weight (kg)", icon: Icons.monitor_weight_outlined),
    );
  }

  Widget _buildExerciseHoursField(AuthProvider provider) {
    return TextFormField(
      focusNode: _exerciseHoursFocusNode,
      controller: provider.exerciseHours,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_invitedEmailFocusNode),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      decoration: _inputDecoration(hint: "Exercise Hours/Week", icon: Icons.fitness_center),
    );
  }

  Widget _buildGenderDropdown(AuthProvider provider) {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration(hint: "Gender", icon: Icons.people_outline),
      items: ["Male", "Female"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      onChanged: (value) {
        provider.gender = value;
        provider.update();
      },
    );
  }

  Widget _buildInvitedEmailTextField(AuthProvider provider) {
    return TextFormField(
      focusNode: _invitedEmailFocusNode,
      controller: provider.invitedEmail,
      keyboardType: TextInputType.emailAddress,
      textInputAction: provider.isSend ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (provider.isSend) { FocusScope.of(context).requestFocus(_codeFocusNode); }
        else { _submitForm(provider); }
      },
      decoration: _inputDecoration(hint: "Invite Email (Optional)", icon: Icons.card_giftcard),
    );
  }

  Widget _buildCodeTextField(AuthProvider provider) {
    return TextFormField(
      focusNode: _codeFocusNode,
      controller: provider.code,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submitForm(provider),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      decoration: _inputDecoration(hint: "Verification Code", icon: Icons.lock_outline),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint.toLn(),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.blue.shade600, size: 22),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      errorStyle: const TextStyle(height: 0.8),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5), borderRadius: BorderRadius.circular(20)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue.shade400, width: 2), borderRadius: BorderRadius.circular(20)),
      errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent, width: 1), borderRadius: BorderRadius.circular(20)),
      focusedErrorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent, width: 2), borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSocialMediaSection() {
    final provider = context.read<AuthProvider>();
    return Column(
      children: [
        Text("Connect with us".toLn(), style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
        const Gap(15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(Assets.imagesYoutube, () async {
              await launchUrl(Uri.parse(provider.contactUs?.youtube ?? ""), mode: LaunchMode.externalApplication);
            }),
            const Gap(20),
            _socialButton(Assets.imagesInstagram, () async {
              await launchUrl(Uri.parse(provider.contactUs?.instagram ?? ""), mode: LaunchMode.externalApplication);
            }),
          ],
        ),
      ],
    );
  }

  Widget _socialButton(String asset, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Image.asset(asset, width: 24, height: 24),
      ),
    );
  }
}