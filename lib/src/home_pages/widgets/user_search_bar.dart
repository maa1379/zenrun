// import 'package:flutter/material.dart';
// import 'package:flutter_typeahead/flutter_typeahead.dart';
// import 'package:sizer/sizer.dart';
//
// import '../../../core/widgets/Costance.dart';
// import '../../api_models_repo/models/profile_model.dart';
// import 'package:toln/toln.dart';
//
// class UserSearchBox extends StatelessWidget {
//   final List<ProfileModel> users;
//   final void Function(ProfileModel user)? onUserSelected;
//
//   const UserSearchBox({super.key, required this.users, this.onUserSelected});
//
//   @override
//   Widget build(BuildContext context) {
//     return TypeAheadField<ProfileModel>(
//       suggestionsCallback: (pattern) {
//         pattern = pattern.toLowerCase();
//         return users.where((user) {
//           return (user.name?.toLowerCase().contains(pattern) ?? false) ||
//               (user.family?.toLowerCase().contains(pattern) ?? false) ||
//               (user.username?.toLowerCase().contains(pattern) ?? false) ||
//               (user.email?.toLowerCase().contains(pattern) ?? false);
//         }).toList();
//       },
//       emptyBuilder: (context) => SizedBox(),
//       builder: (context, controller, focusNode) {
//         return
//       },
//       itemBuilder: (context, user) {
//         return ListTile(
//           dense: true,
//           leading: CircleAvatar(
//             onBackgroundImageError: (exception, stackTrace) =>
//                 SizedBox.shrink(),
//             backgroundImage: NetworkImage(user.image ?? ''),
//             child: (user.image == null || user.image == "")
//                 ? Icon(Icons.person)
//                 : null,
//           ),
//           title: Text('${user.name ?? ''} ${user.family ?? ''}'.toLn()),
//           subtitle: Text(user.username ?? user.email ?? ''),
//         );
//       },
//       onSelected: (user) {
//         if (onUserSelected != null) onUserSelected!(user);
//       },
//     );
//   }
// }
