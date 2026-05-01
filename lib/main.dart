import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const GnomeNoiseApp());

class GnomeNoiseApp extends StatelessWidget {
  const GnomeNoiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GNOME Noise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3584E4), // GNOME Blue
          brightness: Brightness.light,
        ),
        fontFamily: 'Cantarell',
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3584E4),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Cantarell',
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade800),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const NoiseHomePage(),
    );
  }
}

class Sound {
  final String id;
  final String name;
  final String icon;
  final String file;

  const Sound({required this.id, required this.name, required this.icon, required this.file});
}

class NoiseHomePage extends StatefulWidget {
  const NoiseHomePage({super.key});

  @override
  State<NoiseHomePage> createState() => _NoiseHomePageState();
}

class _NoiseHomePageState extends State<NoiseHomePage> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingSound;
  double _volume = 0.7;
  final Set<String> _activeSounds = {};
  bool _isLoading = false;

  static const List<Sound> _sounds = [
    Sound(id: 'rain', name: 'Rain', icon: '🌧️', file: 'rain.ogg'),
    Sound(id: 'storm', name: 'Storm', icon: '⛈️', file: 'storm.ogg'),
    Sound(id: 'waves', name: 'Waves', icon: '🌊', file: 'waves.ogg'),
    Sound(id: 'stream', name: 'Stream', icon: '💧', file: 'stream.ogg'),
    Sound(id: 'wind', name: 'Wind', icon: '💨', file: 'wind.ogg'),
    Sound(id: 'fireplace', name: 'Fireplace', icon: '🔥', file: 'fireplace.ogg'),
    Sound(id: 'birds', name: 'Birds', icon: '🐦', file: 'birds.ogg'),
    Sound(id: 'summer-night', name: 'Summer Night', icon: '🦗', file: 'summer-night.ogg'),
    Sound(id: 'white-noise', name: 'White Noise', icon: '📺', file: 'white-noise.ogg'),
    Sound(id: 'pink-noise', name: 'Pink Noise', icon: '🎀', file: 'pink-noise.ogg'),
    Sound(id: 'coffee-shop', name: 'Coffee Shop', icon: '☕', file: 'coffee-shop.ogg'),
    Sound(id: 'city', name: 'City', icon: '🏙️', file: 'city.ogg'),
    Sound(id: 'train', name: 'Train', icon: '🚂', file: 'train.ogg'),
    Sound(id: 'boat', name: 'Boat', icon: '⛵', file: 'boat.ogg'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _player.setVolume(_volume);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getDouble('volume') ?? 0.7;
      _player.setVolume(_volume);
    });
  }

  Future<void> _saveVolume() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volume', _volume);
  }

  Future<void> _toggleSound(Sound sound) async {
    setState(() => _isLoading = true);
    
    try {
      if (_activeSounds.contains(sound.id)) {
        await _stopSound(sound);
      } else {
        await _playSound(sound);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playSound(Sound sound) async {
    setState(() => _activeSounds.add(sound.id));
    
    final source = AudioSource.asset('assets/sounds/${sound.file}');
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: [
        source,
        source, // Loop
        source,
        source,
      ]),
    );
    await _player.play();
    setState(() => _playingSound = sound.id);
  }

  Future<void> _stopSound(Sound sound) async {
    _activeSounds.remove(sound.id);
    if (_playingSound == sound.id) {
      _playingSound = _activeSounds.isNotEmpty ? _activeSounds.first : null;
    }
  }

  Future<void> _setVolume(double value) async {
    setState(() => _volume = value);
    await _player.setVolume(value);
    await _saveVolume();
  }

  void _stopAll() {
    _player.stop();
    setState(() {
      _activeSounds.clear();
      _playingSound = null;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar.large(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('GNOME Noise', style: TextStyle(fontWeight: FontWeight.w600)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withOpacity(0.2),
                      colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (_activeSounds.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined),
                  tooltip: 'Stop All',
                  onPressed: _stopAll,
                ),
            ],
          ),
          
          // Volume Control
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.volume_down, color: colorScheme.primary),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          onChanged: _setVolume,
                          activeColor: colorScheme.primary,
                        ),
                      ),
                      Icon(Icons.volume_up, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 45,
                        child: Text(
                          '${(_volume * 100).round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Sound Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sound = _sounds[index];
                  final isActive = _activeSounds.contains(sound.id);
                  
                  return _SoundCard(
                    sound: sound,
                    isActive: isActive,
                    isLoading: _isLoading && _playingSound == sound.id,
                    onTap: () => _toggleSound(sound),
                    colorScheme: colorScheme,
                    isDark: isDark,
                  );
                },
                childCount: _sounds.length,
              ),
            ),
          ),
          
          // Footer
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Based on Blanket by Rafael Mardojai CM',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }
}

class _SoundCard extends StatelessWidget {
  final Sound sound;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;

  const _SoundCard({
    required this.sound,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isActive 
          ? colorScheme.primaryContainer 
          : (isDark ? Colors.grey.shade900 : Colors.grey.shade50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive 
                      ? colorScheme.primary 
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isActive ? Colors.white : colorScheme.primary,
                          ),
                        )
                      : Text(
                          sound.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                sound.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive 
                      ? colorScheme.onPrimaryContainer 
                      : (isDark ? Colors.white : Colors.black87),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Status indicator
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Playing',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
