import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const LiquidGlassApp());
}

class LiquidGlassApp extends StatelessWidget {
  const LiquidGlassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
        fontFamily: '.SF Pro Display',
      ),
      home: const MainShellScreen(),
    );
  }
}

class MediaItem {
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;

  const MediaItem({
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.secondaryColor,
    this.icon = CupertinoIcons.photo_fill,
  });
}

const List<MediaItem> kFeaturedPresets = [
  MediaItem(
    title: 'Camera Roll',
    subtitle: 'Device Storage',
    primaryColor: Color(0xFFD9822B),
    secondaryColor: Color(0xFF4A2511),
  ),
  MediaItem(
    title: 'Screenshots',
    subtitle: 'Captured UI',
    primaryColor: Color(0xFFE040FB),
    secondaryColor: Color(0xFF311B92),
  ),
  MediaItem(
    title: 'Downloads',
    subtitle: 'Local Files',
    primaryColor: Color(0xFF00E5FF),
    secondaryColor: Color(0xFF1A237E),
  ),
];

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;
  MediaItem _activeItem = kFeaturedPresets[0];
  bool _isPlaying = true;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              HomeTabView(onSelect: (item) => setState(() => _activeItem = item)),
              const ExploreTabView(),
              const LocalGalleryTabView(),
            ],
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: math.max(bottomPadding, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingGlassMiniPlayer(
                  item: _activeItem,
                  isPlaying: _isPlaying,
                  onTogglePlay: () => setState(() => _isPlaying = !_isPlaying),
                ),
                const SizedBox(height: 10),
                LiquidGlassNavDock(
                  selectedIndex: _selectedIndex,
                  accentColor: _activeItem.primaryColor,
                  onTabChanged: (index) => setState(() => _selectedIndex = index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// LIQUID GLASS CORE ENGINE
class LiquidGlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color tintColor;
  final Color? ambientGlowColor;
  final EdgeInsetsGeometry padding;

  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 36,
    this.tintColor = const Color(0x381C1C22),
    this.ambientGlowColor,
    this.padding = EdgeInsets.zero,
  });

  static final ImageFilter _filter = ImageFilter.compose(
    outer: ImageFilter.ColorFilter(
      const ColorFilter.matrix(<double>[
        1.43, -0.35, -0.08, 0, 8,
        -0.15, 1.50, -0.08, 0, 8,
        -0.15, -0.35, 1.77, 0, 8,
        0, 0, 0, 1, 0,
      ]),
    ),
    inner: ImageFilter.blur(sigmaX: 28, sigmaY: 28, tileMode: TileMode.mirror),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: _filter,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tintColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withAlpha(40), width: 1.15),
            gradient: ambientGlowColor != null
                ? RadialGradient(
                    center: const Alignment(-0.8, 0),
                    radius: 1.3,
                    colors: [
                      ambientGlowColor!.withAlpha(80),
                      Colors.transparent,
                    ],
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

class FloatingGlassMiniPlayer extends StatelessWidget {
  final MediaItem item;
  final bool isPlaying;
  final VoidCallback onTogglePlay;

  const FloatingGlassMiniPlayer({
    super.key,
    required this.item,
    required this.isPlaying,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: 32,
      ambientGlowColor: item.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              gradient: LinearGradient(colors: [item.primaryColor, item.secondaryColor]),
            ),
            child: Icon(item.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                Text(item.subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          IconButton(
            onPressed: onTogglePlay,
            icon: Icon(isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class LiquidGlassNavDock extends StatelessWidget {
  final int selectedIndex;
  final Color accentColor;
  final ValueChanged<int> onTabChanged;

  const LiquidGlassNavDock({
    super.key,
    required this.selectedIndex,
    required this.accentColor,
    required this.onTabChanged,
  });

  static const _tabs = [
    (icon: CupertinoIcons.house_fill, label: 'Home'),
    (icon: CupertinoIcons.square_grid_2x2_fill, label: 'Explore'),
    (icon: CupertinoIcons.folder_fill, label: 'Files & Media'),
  ];

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: 40,
      tintColor: const Color(0x4016161C),
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        height: 60,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = selectedIndex == index;
            final tab = _tabs[index];
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTabChanged(index);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: isSelected ? accentColor.withAlpha(90) : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tab.icon, size: 20, color: isSelected ? Colors.white : Colors.white60),
                      const SizedBox(height: 2),
                      Text(tab.label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : Colors.white60)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class HomeTabView extends StatelessWidget {
  final ValueChanged<MediaItem> onSelect;
  const HomeTabView({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 180),
      children: [
        const Text('Overview', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 20),
        ...kFeaturedPresets.map((preset) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => onSelect(preset),
            tileColor: Colors.white.withAlpha(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: Icon(preset.icon, color: preset.primaryColor),
            title: Text(preset.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Text(preset.subtitle, style: const TextStyle(color: Colors.white60)),
          ),
        )),
      ],
    );
  }
}

class ExploreTabView extends StatelessWidget {
  const ExploreTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Explore Media & Tags', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 16)),
    );
  }
}

// REAL LOCAL DEVICE GALLERY TAB (Scans actual photos from phone storage)
class LocalGalleryTabView extends StatefulWidget {
  const LocalGalleryTabView({super.key});

  @override
  State<LocalGalleryTabView> createState() => _LocalGalleryTabViewState();
}

class _LocalGalleryTabViewState extends State<LocalGalleryTabView> {
  List<AssetEntity> _mediaList = [];
  bool _isLoading = true;
  String _status = 'Requesting storage permission...';

  @override
  void initState() {
    super.initState();
    _fetchDeviceMedia();
  }

  Future<void> _fetchDeviceMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth || ps == PermissionState.limited) {
      setState(() => _status = 'Scanning local storage...');
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );
      if (albums.isNotEmpty) {
        List<AssetEntity> media = await albums[0].getAssetListRange(start: 0, end: 100);
        setState(() {
          _mediaList = media;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _isLoading = false;
        _status = 'No media found.';
      });
    } else {
      setState(() {
        _isLoading = false;
        _status = 'Storage permission denied. Enable in phone settings.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 16),
              child: const Text('Local Files', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(child: Text(_status, style: const TextStyle(color: Colors.white60))),
            )
          else if (_mediaList.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text(_status, style: const TextStyle(color: Colors.white60))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 180),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _mediaList.length,
                itemBuilder: (context, index) {
                  return FutureBuilder(
                    future: _mediaList[index].thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(snapshot.data as List<int>, fit: BoxFit.cover),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
