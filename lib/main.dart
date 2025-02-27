import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'dart:async';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    
    return MaterialApp(
      title: 'Battery Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Replace the textDirection with builder
      builder: (context, child) {
        return Directionality(
          textDirection: lang.isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: const BatteryMonitorPage(),
    );
  }
}

class BatteryMonitorPage extends StatefulWidget {
  const BatteryMonitorPage({super.key});

  @override
  State<BatteryMonitorPage> createState() => _BatteryMonitorPageState();
}

class _BatteryMonitorPageState extends State<BatteryMonitorPage> {
  // Add S22 specific constants
  static const int BATTERY_CAPACITY = 3700; // mAh
  static const int FAST_CHARGING_RATE = 25000; // 25W
  static const double AVG_DISCHARGE_RATE = 370.0; // ~10% per hour under normal use

  final Battery _battery = Battery();
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  late Stream<BatteryState> _batteryStateStream;
  Timer? _batteryCheckTimer;
  int? _minutesRemaining;
  List<int> _recentLevels = [];
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _getBatteryLevel();
    _batteryStateStream = _battery.onBatteryStateChanged;
    _batteryStateStream.listen((BatteryState state) {
      setState(() {
        _batteryState = state;
        _recentLevels.clear(); // Clear history when state changes
      });
    });

    _batteryCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _getBatteryLevel();
      _calculateTimeRemaining();
    });
  }

  @override
  void dispose() {
    _batteryCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _getBatteryLevel() async {
    final level = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = level;
    });
  }

  void _calculateTimeRemaining() {
    if (_recentLevels.length < 2) {
      _recentLevels.add(_batteryLevel);
      return;
    }

    final now = DateTime.now();
    final duration = now.difference(_lastUpdate).inMinutes;
    if (duration == 0) return;

    final levelChange = _batteryLevel - _recentLevels.last;
    final ratePerMinute = levelChange / duration;

    if (ratePerMinute == 0) {
      setState(() => _minutesRemaining = null);
      return;
    }

    int remaining;
    if (_batteryState == BatteryState.charging) {
      remaining = ((100 - _batteryLevel) / ratePerMinute).round();
    } else {
      remaining = (_batteryLevel / -ratePerMinute).round();
    }

    setState(() {
      _minutesRemaining = remaining.abs();
      _recentLevels = [_recentLevels.last, _batteryLevel];
      _lastUpdate = now;
    });
  }

  String _getTimeEstimate() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    
    if (_batteryState == BatteryState.charging) {
      if (_batteryLevel < 50) {
        return '${lang.translate('minutesTo50', [(25 - (_batteryLevel / 2)).round()])}\n'
            '${lang.translate('minutesToFull', [70 - _batteryLevel])}';
      } else {
        return lang.translate('minutesToFull', [70 - _batteryLevel]);
      }
    } else if (_batteryState == BatteryState.discharging) {
      double hoursRemaining = (_batteryLevel / 100.0) * (BATTERY_CAPACITY / AVG_DISCHARGE_RATE);
      int hours = hoursRemaining.floor();
      int minutes = ((hoursRemaining - hours) * 60).round();
      return lang.translate('aboutTimeRemaining', [hours, minutes]);
    }
    return '';
  }

  Color _getBatteryColor() {
    if (_batteryLevel <= 20) return Colors.red;
    if (_batteryLevel <= 50) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('appTitle')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String code) {
              lang.setLanguage(code);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'en',
                child: Text('English'),
              ),
              const PopupMenuItem(
                value: 'de',
                child: Text('Deutsch'),
              ),
              const PopupMenuItem(
                value: 'es',
                child: Text('Español'),
              ),
              const PopupMenuItem(
                value: 'ar',
                child: Text('العربية'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getBatteryColor(),
                  width: 10,
                ),
              ),
              child: Center(
                child: Text(
                  '$_batteryLevel%',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Add progress bar
            Container(
              width: 300,
              height: 25,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: _batteryLevel / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_getBatteryColor()),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _batteryState == BatteryState.charging
                  ? lang.translate('charging')
                  : lang.translate('discharging'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              _getTimeEstimate(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_minutesRemaining != null && _minutesRemaining! > 0) 
              Text(
                lang.translate('timeRemaining', [
                  _minutesRemaining! ~/ 60,
                  _minutesRemaining! % 60,
                ]),
                style: Theme.of(context).textTheme.titleMedium,
              ),
          ],
        ),
      ),
    );
  }
}