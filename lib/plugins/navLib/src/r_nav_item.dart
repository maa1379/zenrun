part of '../r_nav_n_sheet.dart';

/// [BottomNavigationBarItem] (bottom navigation bar items) for [RNavNSheet]
class RNavItem {
  /// Icon when item is not selected
  final IconData? icon;

  /// Icon when item is  selected
  final IconData? activeIcon;

  /// Label of the item
  final String label;
  final Widget? image;
  final Widget? activeImage;
  const RNavItem({ this.icon,  required this.label, this.activeIcon,this.image, this.activeImage, });
}

class _RNavItem extends StatelessWidget {
  final IconData? icon;
  final Widget? image;
  final Widget? activeImage;
  final IconData? activeIcon;
  final String label;
  final EdgeInsets? padding;
  final bool selected;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Gradient? selectedItemGradient;
  final Gradient? unselectedItemGradient;
  final bool hide;
  final VoidCallback? onTap;

  const _RNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.image,
    this.activeImage,
    this.padding,
    this.selected = false,
    this.onTap,
    this.hide = false,
    this.activeIcon,
    this.selectedItemColor,
    this.selectedItemGradient,
    this.unselectedItemColor,
    this.unselectedItemGradient,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var color = selected
        ? ColorsHelper.btn2
        : unselectedItemColor ?? theme.hintColor;
    var gradient = selected
        ? selectedItemGradient ??
              LinearGradient(
                colors: [
                  theme.colorScheme.secondary,
                  theme.colorScheme.secondary.withOpacity(0.9),
                  theme.colorScheme.secondary.withOpacity(0.1),
                  theme.iconTheme.color!,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
        : unselectedItemGradient ??
              LinearGradient(
                colors: [theme.hintColor, theme.canvasColor, theme.hintColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              );

    var widget = Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: !selected && image is Image
              ? image
              : selected && activeImage is Image
              ? activeImage
              : Icon(
                  selected && activeIcon != null ? activeIcon : icon,
                  color: color,
                  size: selected ? 24 : 21,
                ),
        ),
        const SizedBox(height: 5),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: selected ? 18.sp : 15.sp,
          ),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.black, fontSize: 14.sp),
          ),
        ),
      ],
    );
    var shader = ShaderMask(
      shaderCallback: (Rect bounds) {
        return gradient.createShader(bounds);
      },
      blendMode: BlendMode.srcATop,
      child: widget,
    );
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 100),
        alignment: Alignment.center,
        child: SizedBox(
          height: hide ? 0.0 : null,
          child: InkResponse(
            onTap: onTap,
            child: selectedItemColor == null ? shader : widget,
          ),
        ),
      ),
    );
  }
}
