import 'package:flutter/material.dart';
import 'package:zenrun/core/widgets/Costance.dart';

class CustomDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String hintText;
    final bool enabled;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
    this.selectedItem,
    this.hintText = '',
    this.enabled = false,
  });


  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: selectedItem,
      decoration: InputDecoration(
        labelText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ColorsHelper.btn2, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ColorsHelper.btn2, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ColorsHelper.btn2, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true,
      items: items.map((T value) {
        return DropdownMenuItem<T>(
          enabled: enabled,
          value: value,
          child: Center(
            child: Text(
              itemLabel(value),
              style: TextStyle(color: Colors.black, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
