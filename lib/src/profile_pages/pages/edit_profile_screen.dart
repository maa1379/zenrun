import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/image_picker_helper.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/core/widgets/restart_widget.dart';

import '../../../generated/assets.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.canPop});

  final bool? canPop;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final PhoneController _phoneController;

  @override
  void initState() {
    ViewHelper.dismissLoading();
    Future.microtask(() {
      if(context.read<ProfileProvider>().profile?.usernameC.text.isEmpty == true){
        context.read<ProfileProvider>().validator = "Username must be at least 6 characters long";
        context.read<ProfileProvider>().update();
      }
    },);
    _phoneController = PhoneController(
      initialValue: PhoneNumber(
        isoCode: IsoCode.US,
        nsn: context.read<ProfileProvider>().profile?.phoneC.text ?? "",
      ),
    );
    _phoneController.addListener(() {
      context.read<ProfileProvider>().profile?.phoneC.text = "+${_phoneController.value.countryCode}${_phoneController.value.nsn}" ;
      context.read<ProfileProvider>().profile?.countryC.text = _phoneController.value.isoCode.name;
    });
    super.initState();
  }


  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.canPop != false,
      onPopInvokedWithResult: (didPop, result) {
        if (widget.canPop == false) {
          RestartAppWidget.restartApp(context);
        }
        // context.read<ProfileProvider>().loading = false;
      },
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          appBar: UiHelper.appBar("Edit Account"),
          backgroundColor: ColorsHelper.white,
          extendBodyBehindAppBar: true,
          body: Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              if (!provider.loading) {
                return UiHelper.showLoading();
              }
              return Container(
                height: 100.h,
                width: 100.w,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(Assets.imagesImg4),
                    fit: BoxFit.cover,
                    opacity: 0.8,
                  ),
                ),
                child: ListView(
                  children: [
                    Center(
                      child: SizedBox(
                        height: 18.h,
                        width: 37.w,
                        child: Stack(
                          children: [
                            (provider.profileImage != null)
                                ? CircleAvatar(
                                    backgroundImage: MemoryImage(
                                      provider.profileImage!.bytes,
                                    ),
                                    radius: 80,
                                  ).animate().fadeIn().shimmer()
                                : Positioned.fill(
                                    child:
                                        (provider.profile!.imageC.text.isEmpty)
                                        ? CircleAvatar(
                                            radius: 80,
                                            child: Icon(
                                              Icons.person,
                                              color: ColorsHelper.btn2,
                                              size: 50,
                                            ),
                                          ).animate().fadeIn().shimmer()
                                        : CircleAvatar(
                                            backgroundImage: FastCachedImageProvider(
                                              provider.profile!.imageC.text,
                                            ),
                                            radius: 80,
                                          ).animate().fadeIn().shimmer(),
                                  ),
                            Positioned.fill(
                              top: 10,
                              right: 10,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  height: 35,
                                  width: 35,
                                  decoration: BoxDecoration(
                                    color: ColorsHelper.blue.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: IconButton(
                                      onPressed: () {
                                        _showModal(
                                          () async {
                                            provider.profileImage =
                                                await ImagePickerHelper()
                                                    .selectCamera2();
                                            context.pop();
                                            provider.update();
                                          },
                                          () async {
                                            provider.profileImage =
                                                await ImagePickerHelper()
                                                    .selectGallery2();
                                            context.pop();
                                            provider.update();
                                          },
                                        );
                                      },
                                      icon: Icon(Icons.add, size: 15),
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Gap(15),
                    _buildEmailTextField(),
                    Gap(15),
                    _buildMobileTextField(),
                    Gap(15),
                    _buildCityTextField(),
                    Gap(15),
                    _buildStateTextField(),
                    Gap(15),
                    _buildStateNameField(),
                    Gap(15),
                    _buildStateFamilyField(),
                    Gap(15),
                    _buildUserNameFamilyField(),
                    Gap(15),
                    _buildBioTextField(),
                    Gap(5.h),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: UiHelper.buttonMain2(
                        () async {
                          if (provider.validator != null) {
                            ViewHelper.showErrorDialog(
                              context,
                              text: provider.validator,
                            );
                          } else {
                            await provider.setProfile(context);
                            RestartAppWidget.restartApp(context);
                          }
                        },
                        "Submit",
                        width: 80.w,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showModal(Function() onTap1, Function() onTap2) {
    showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SizedBox(
          height: 20.h,
          width: 100.w,
          child: ListView(
            children: [
              const Gap(25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: onTap1,
                    child: Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: ColorsHelper.btn2,
                          size: 30,
                        ),
                        Text(
                          "Camera".toLn(),
                          style: ThemeHelper.textStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onTap2,
                    child: Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_camera_back,
                          color: ColorsHelper.btn2,
                          size: 30,
                        ),
                        Text(
                          "Gallery".toLn(),
                          style: ThemeHelper.textStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmailTextField() {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 80.w,
        child: TextField(
          enabled: false,
          controller: context.read<ProfileProvider>().profile?.emailC,
          decoration: InputDecoration(
            isDense: true,
            hintText: "Email".toLn(),
            prefixIcon: Icon(Icons.person, color: Colors.grey),
            filled: true,
            fillColor: ColorsHelper.btn1.withOpacity(0.15),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xff969bff), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTextField() {
    return Center(
      child: SizedBox(
        width: 80.w,
        child: PhoneFormField(
          controller: _phoneController,
          textInputAction: TextInputAction.next,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => (value == null || value.nsn.isEmpty)
              ? "Please enter a valid phone number"
              : null,
          countrySelectorNavigator:
          const CountrySelectorNavigator.modalBottomSheet(),
          decoration: InputDecoration(
            hintText: "Mobile Number".toLn(),
            isDense: true,
            prefixIcon: Icon(Icons.phone, color: Colors.grey),
            filled: true,
            fillColor: ColorsHelper.btn1.withOpacity(0.15),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xff969bff), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          keyboardType: TextInputType.phone,
        ),
      ),
    );
  }

  Widget _buildCityTextField() {
    return Center(
      child: SizedBox(
        width: 80.w,
        child: TextField(
          controller: context.read<ProfileProvider>().profile?.cityC,
          decoration: InputDecoration(
              isDense: true,
            hintText: "City".toLn(),
            prefixIcon: Icon(Icons.pin_drop_outlined, color: Colors.grey),
            filled: true,
            fillColor: ColorsHelper.btn1.withOpacity(0.15),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xff969bff), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateTextField() {
    return Center(
      child: SizedBox(
        width: 80.w,
        child: TextField(
          controller: context.read<ProfileProvider>().profile?.stateC,
          decoration: InputDecoration(
              isDense: true,
            hintText: "State".toLn(),
            prefixIcon: Icon(Icons.pin_drop_outlined, color: Colors.grey),
            filled: true,
            fillColor: ColorsHelper.btn1.withOpacity(0.15),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xff969bff), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBioTextField() {
    return Center(
      child: SizedBox(
        width: 80.w,
        child: TextField(
          controller: context.read<ProfileProvider>().profile?.bioC,
          maxLines: 4,
          textAlign: TextAlign.start,
          decoration: InputDecoration(
              isDense: true,
            hintText: "Bio".toLn(),
            contentPadding: EdgeInsets.all(15),
            // prefixIcon: Icon(Icons.edit, color: Colors.grey),
            filled: true,
            fillColor: ColorsHelper.btn1.withOpacity(0.15),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xff969bff), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateNameField() {
    return Center(
      child: SizedBox(
        width: 80.w,
        child: TextField(
          controller: context.read<ProfileProvider>().profile?.nameC,
          decoration: InputDecoration(
              isDense: true,
            hintText: "Name".toLn(),
            prefixIcon: Icon(Icons.pin_drop_outlined, color: Colors.grey),
            filled: true,
            fillColor: ColorsHelper.btn1.withOpacity(0.15),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xff969bff), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateFamilyField() {
    return Center(
      child: SizedBox(
        width: 80.w,
        child: TextField(
          controller: context.read<ProfileProvider>().profile?.familyC,
          decoration: InputDecoration(
              isDense: true,
            hintText: "Family".toLn(),
            prefixIcon: Icon(Icons.pin_drop_outlined, color: Colors.grey),
            filled: true,
            fillColor: ColorsHelper.btn1.withOpacity(0.15),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xff969bff), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserNameFamilyField() {
    return Center(
      child: SizedBox(
        width: 80.w,
        child: Consumer<ProfileProvider>(
          builder: (context, provider, child) {
            return TextFormField(
              controller: provider.profile?.usernameC,
              onChanged: provider.onUsernameChanged,
              decoration: InputDecoration(
                  isDense: true,
                hintText: "Username".toLn(),
                prefixIcon: Icon(Icons.pin_drop_outlined, color: Colors.grey),
                filled: true,
                errorText: provider.validator,
                fillColor: ColorsHelper.btn1.withOpacity(0.15),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xff969bff), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
