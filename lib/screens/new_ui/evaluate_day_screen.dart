import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../theme/dark_diary_theme.dart';
import '../../services/place_history_service.dart';

class EvaluateDayScreen extends StatefulWidget {
  static const routeName = '/evaluate-day';
  const EvaluateDayScreen({Key? key}) : super(key: key);

  @override
  State<EvaluateDayScreen> createState() => _EvaluateDayScreenState();
}

class _EvaluateDayScreenState extends State<EvaluateDayScreen> {
  late String _date;
  late String _time;
  int _rating = 5;
  late String _ratingDesc;
  late TextEditingController _reasonCtrl;
  late TextEditingController _placeCtrl;
  List<String> _history = [];

  static const _ratingLabels = <int, String>{
    1: 'Very bad day',
    5: 'Neutral: no strong feelings',
    10: 'Great day!',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateFormat('dd-MM-yyyy').format(now);
    _time = DateFormat('HH:mm').format(now);
    _reasonCtrl = TextEditingController();
    _placeCtrl = TextEditingController();
    _ratingDesc = _ratingLabels[5]!;
    _loadHistory();
    _autoFillLocation();
  }

  Future<void> _loadHistory() async {
    _history = await PlaceHistoryService.loadHistory();
    if (_history.length > 3) _history = _history.take(3).toList();
    setState(() {});
  }

  Future<void> _autoFillLocation() async {
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        final city = marks.first.locality ?? '';
        if (city.isNotEmpty && mounted) {
          _placeCtrl.text = city;
        }
      }
    } catch (_) {
      // ignore errors
    }
  }

  String get _emoji {
    if (_rating <= 3) return '😖';
    if (_rating <= 7) return '😐';
    return '😄';
  }

  Color get _trackColor {
    const start = Color(0xFFFF4B4B);
    const end = Color(0xFF4CAF50);
    final t = _rating / 10.0;
    return Color.lerp(start, end, t)!;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
    );
    if (pickedDate != null) {
      _date = DateFormat('dd-MM-yyyy').format(pickedDate);
    }
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (pickedTime != null) {
      _time = pickedTime.format(context);
    }
    setState(() {});
  }

  void _copyDateTime() {
    final txt = '$_date $_time';
    Clipboard.setData(ClipboardData(text: txt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Date/time copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = DarkDiaryTheme.theme;
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: DarkDiaryTheme.background,
        appBar: AppBar(
          title: const Text('Дневник'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DarkDiaryTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text('📅 $_date  $_time'),
                      const Spacer(),
                      TextButton(
                        onPressed: _copyDateTime,
                        child: const Text('Копировать'),
                      ),
                      TextButton(
                        onPressed: _pickDateTime,
                        child: const Text('Редактировать'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Autocomplete<String>(
                  optionsBuilder: (text) {
                    if (text.text.isEmpty) return _history;
                    return _history.where((p) =>
                        p.toLowerCase().contains(text.text.toLowerCase()));
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    _placeCtrl = controller;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        filled: true,
                        hintText: 'Где ты сегодня был?',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    );
                  },
                  onSelected: (v) async {
                    await PlaceHistoryService.addPlace(v);
                  },
                ),
                const SizedBox(height: 24),
                Text('1/3', style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                Card(
                  elevation: 3,
                  color: DarkDiaryTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Насколько хорошим был твой день?',
                            style: theme.textTheme.headlineSmall),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _trackColor,
                            thumbColor: _trackColor,
                            overlayColor: _trackColor.withOpacity(0.2),
                            thumbShape: _EmojiThumb(emoji: _emoji),
                          ),
                          child: Slider(
                            value: _rating.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            onChanged: (v) => setState(() {
                              _rating = v.round();
                              _ratingDesc = _ratingLabels[_rating] ?? _ratingDesc;
                            }),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_ratingDesc, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonCtrl,
                  minLines: 4,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Опиши причину (необязательно)',
                    border: UnderlineInputBorder(),
                  ),
                ),
                const Spacer(),
                SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {},
                      child: const Text('Далее: Состояние'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiThumb extends SliderComponentShape {
  final String emoji;
  const _EmojiThumb({required this.emoji});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(40, 40);

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final canvas = context.canvas;
    final text = TextSpan(text: emoji, style: const TextStyle(fontSize: 24));
    final tp = TextPainter(
      text: text,
      textDirection: textDirection,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }
}