import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player with Ads',
      home: const VideoPlayerWithAdsScreen(),
    );
  }
}

class VideoPlayerWithAdsScreen extends StatefulWidget {
  const VideoPlayerWithAdsScreen({super.key});

  @override
  State<VideoPlayerWithAdsScreen> createState() => _VideoPlayerWithAdsScreenState();
}

class _VideoPlayerWithAdsScreenState extends State<VideoPlayerWithAdsScreen> {
  late BetterPlayerPlaylistController _playlistController;
  bool _isMidRollAdPlaying = false;

  // Video and ad URLs
  final String _mainContentUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  final String _preRollAdUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4";
  final String _postRollAdUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4";
  final List<Map<String, dynamic>> _midRollAds = [
    {"time": 15, "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4", "shown": false},
    {"time": 30, "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4", "shown": false},
  ];

  @override
  void initState() {
    super.initState();
    _setupPlaylist();
  }

  void _setupPlaylist() {
    final List<BetterPlayerDataSource> playlist = [
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        _preRollAdUrl,
        cacheConfiguration: const BetterPlayerCacheConfiguration(useCache: true),
      ),
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        _mainContentUrl,
        cacheConfiguration: const BetterPlayerCacheConfiguration(useCache: true),
      ),
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        _postRollAdUrl,
        cacheConfiguration: const BetterPlayerCacheConfiguration(useCache: true),
      ),
    ];

    _playlistController = BetterPlayerPlaylistController(
      playlist,
      betterPlayerConfiguration: const BetterPlayerConfiguration(
        autoPlay: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: true,
          enableSkips: false,
          enableProgressText: true,
        ),
      ),
      betterPlayerPlaylistConfiguration: const BetterPlayerPlaylistConfiguration(
        loopVideos: false,
      ),
    );

    // Setup mid-roll ads after controller is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMidRollAds();
    });
  }

  void _setupMidRollAds() {
    _playlistController.betterPlayerController?.addEventsListener((event) {
      if (_isMidRollAdPlaying) return;

      if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
        final currentPos = event.parameters!['progress'] ~/ 1000; // Current position in seconds

        for (final ad in _midRollAds) {
          if (currentPos >= ad["time"] && !ad["shown"]) {
            ad["shown"] = true;
            _playMidRollAd(ad["url"]);
            break; // Only trigger one ad at a time
          }
        }
      }
    });
  }

  void _playMidRollAd(String adUrl) {
    _isMidRollAdPlaying = true;
    _playlistController.betterPlayerController?.pause();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Advertisement"),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 200,
          child: BetterPlayer(
            controller: BetterPlayerController(
              const BetterPlayerConfiguration(
                autoPlay: true,
                controlsConfiguration: BetterPlayerControlsConfiguration(
                  showControls: true,
                  enableSkips: true,
                ),
              ),
              betterPlayerDataSource: BetterPlayerDataSource(
                BetterPlayerDataSourceType.network,
                adUrl,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _isMidRollAdPlaying = false;
              _playlistController.betterPlayerController?.play();
            },
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Player Demo")),
      body: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayerPlaylist(
                betterPlayerConfiguration: const BetterPlayerConfiguration(
                  autoPlay: true,
                  controlsConfiguration: BetterPlayerControlsConfiguration(
                    showControls: true,
                  ),
                ),
                betterPlayerPlaylistConfiguration: const BetterPlayerPlaylistConfiguration(
                  loopVideos: false,
                ),
                betterPlayerDataSourceList: [
                  BetterPlayerDataSource(
                    BetterPlayerDataSourceType.network,
                    _preRollAdUrl,
                  ),
                  BetterPlayerDataSource(
                    BetterPlayerDataSourceType.network,
                    _mainContentUrl,
                  ),
                  BetterPlayerDataSource(
                    BetterPlayerDataSourceType.network,
                    _postRollAdUrl,
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Pre-roll, mid-roll (at 15s and 30s), and post-roll ads are configured"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _playlistController.dispose();
    super.dispose();
  }
}