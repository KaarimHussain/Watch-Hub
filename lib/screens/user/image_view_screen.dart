import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart';

class ImageViewScreen extends StatefulWidget {
  const ImageViewScreen({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.title = 'Image View',
  });

  final String imageUrl;
  final String? heroTag;
  final String title;

  @override
  State<ImageViewScreen> createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends State<ImageViewScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Pre-load image
    final imageProvider = MemoryImage(base64Decode(widget.imageUrl));
    imageProvider
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener(
            (info, _) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onError: (exception, stackTrace) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              }
            },
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDarkMode ? Brightness.light : Brightness.dark,
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onPressed: () {
                _animationController.reverse().then((_) {
                  Navigator.of(context).pop();
                });
              },
            ),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              // Background pattern
              if (!_isLoading && !_hasError)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black : Colors.grey[100],
                      backgroundBlendMode: BlendMode.multiply,
                    ),
                  ),
                ),

              // Main content
              Center(
                child:
                    _hasError
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_rounded,
                              size: 80,
                              color: theme.colorScheme.error.withOpacity(0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _hasError = false;
                                });
                                // Re-trigger image loading
                                final imageProvider = MemoryImage(
                                  base64Decode(widget.imageUrl),
                                );
                                imageProvider.resolve(
                                  const ImageConfiguration(),
                                );
                              },
                            ),
                          ],
                        )
                        : _isLoading
                        ? const CircularProgressIndicator()
                        : Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Hero(
                            tag:
                                widget.heroTag ??
                                'image-view-${widget.imageUrl.hashCode}',
                            child: PhotoView(
                              imageProvider: MemoryImage(
                                base64Decode(widget.imageUrl),
                              ),
                              minScale: PhotoViewComputedScale.contained,
                              maxScale: PhotoViewComputedScale.covered * 2,
                              backgroundDecoration: BoxDecoration(
                                color: Colors.transparent,
                              ),
                              loadingBuilder:
                                  (context, event) => Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          event == null
                                              ? 0
                                              : event.cumulativeBytesLoaded /
                                                  (event.expectedTotalBytes ??
                                                      1),
                                    ),
                                  ),
                            ),
                          ),
                        ),
              ),

              // Zoom hint
              if (!_isLoading && !_hasError)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _animationController.value,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.zoom_out_map,
                              size: 18,
                              color: theme.colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pinch to zoom',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
