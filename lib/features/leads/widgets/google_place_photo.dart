import 'package:flutter/material.dart';

import '../../../core/services/app_config_service.dart';

class GooglePlacePhoto extends StatelessWidget {
  final List<String> photoReferences;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  const GooglePlacePhoto({
    super.key,
    required this.photoReferences,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (photoReferences.isEmpty) {
      return _PhotoPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }

    return FutureBuilder<String>(
      future: AppConfigService.getGoogleMapsApiKey(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _PhotoLoadingShimmer(
            width: width,
            height: height,
            borderRadius: borderRadius,
          );
        }

        final photoUrl = Uri.https('maps.googleapis.com', '/maps/api/place/photo', {
          'maxwidth': '1200',
          'photo_reference': photoReferences.first,
          'key': snapshot.data!,
        }).toString();

        final image = Image.network(
          photoUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _PhotoLoadingShimmer(
              width: width,
              height: height,
              borderRadius: borderRadius,
            );
          },
          errorBuilder: (_, __, ___) => _PhotoPlaceholder(
            width: width,
            height: height,
            borderRadius: borderRadius,
          ),
        );

        if (borderRadius == null) {
          return image;
        }

        return ClipRRect(
          borderRadius: borderRadius!,
          child: image,
        );
      },
    );
  }
}

class _PhotoLoadingShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const _PhotoLoadingShimmer({
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<_PhotoLoadingShimmer> createState() => _PhotoLoadingShimmerState();
}

class _PhotoLoadingShimmerState extends State<_PhotoLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final start = -1.2 + (_controller.value * 2.4);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(start, 0),
              end: Alignment(start + 1.2, 0),
              colors: const [
                Color(0xFFECECE7),
                Color(0xFFF8F8F4),
                Color(0xFFE9E9E3),
              ],
            ),
          ),
        );
      },
    );

    if (widget.borderRadius == null) {
      return child;
    }

    return ClipRRect(
      borderRadius: widget.borderRadius!,
      child: child,
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const _PhotoPlaceholder({
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F1EE),
      alignment: Alignment.center,
      child: const Icon(
        Icons.storefront_rounded,
        color: Color(0xFFB0B0AA),
        size: 34,
      ),
    );

    if (borderRadius == null) {
      return child;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }
}
