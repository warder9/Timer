import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'about.dart';
import 'localization.dart';
import 'timer_card.dart';
import 'countdown_timer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  await AppLocalizations.load(const Locale('en'));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countdown Timer',
      theme: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ru', ''),
        Locale('kk', ''),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('kk');
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('kk');
      },
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/about': (context) => AboutPage(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CountdownTimer> timers = [];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _selectedDateTime;
  Color _selectedColor = Colors.blue;
  String _selectedTimezone = 'UTC';
  List<String> timezones = [];
  bool _showCompletedTimers = true;
  bool _showHelpText = true;

  @override
  void initState() {
    super.initState();
    _loadTimers();
    timezones = tz.timeZoneDatabase.locations.keys.toList();
    timezones.sort();
  }

  Future<void> _loadTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final timersJson = prefs.getStringList('timers') ?? [];
    setState(() {
      timers = timersJson.map((json) => CountdownTimer.fromJson(jsonDecode(json))).toList();
      _selectedTimezone = prefs.getString('timezone') ?? 'UTC';
    });
  }

  Future<void> _saveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'timers',
      timers.map((timer) => jsonEncode(timer.toJson())).toList(),
    );
    await prefs.setString('timezone', _selectedTimezone);
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: localizations.translate('selectDate'),
      cancelText: localizations.translate('cancel'),
      confirmText: localizations.translate('select'),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
      helpText: localizations.translate('selectTime'),
      cancelText: localizations.translate('cancel'),
      confirmText: localizations.translate('select'),
    );

    if (time != null) {
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _addOrUpdateTimer({CountdownTimer? existingTimer}) async {
    final localizations = AppLocalizations.of(context)!;
    bool isEditing = existingTimer != null;

    if (isEditing) {
      _titleController.text = existingTimer!.title;
      _selectedDateTime = existingTimer.targetDate;
      _selectedColor = existingTimer.color;
    } else {
      _titleController.clear();
      _selectedDateTime = null;
      _selectedColor = Colors.blue;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing
            ? localizations.translate('editTimer')
            : localizations.translate('addTimer')),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: localizations.translate('eventName'),
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? localizations.translate('enterName')
                      : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    _selectedDateTime == null
                        ? localizations.translate('selectDateTime')
                        : DateFormat('MMM dd, yyyy - HH:mm').format(_selectedDateTime!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDateTime(context),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Color>(
                  value: _selectedColor,
                  items: [
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.teal,
                  ].map((color) => DropdownMenuItem(
                    value: color,
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: color),
                        const SizedBox(width: 8),
                        Text(
                          color.toString().split('.')[1].capitalize(),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  onChanged: (color) => setState(() => _selectedColor = color!),
                  decoration: InputDecoration(
                    labelText: localizations.translate('color'),
                  ),
                  dropdownColor: Theme.of(context).cardColor,
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate() && _selectedDateTime != null) {
                final newTimer = CountdownTimer(
                  id: isEditing ? existingTimer!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                  title: _titleController.text,
                  targetDate: _selectedDateTime!,
                  color: _selectedColor,
                );

                setState(() {
                  if (isEditing) {
                    final index = timers.indexWhere((t) => t.id == existingTimer!.id);
                    timers[index] = newTimer;
                  } else {
                    timers.add(newTimer);
                  }
                  _saveTimers();
                });
                Navigator.pop(context);
              }
            },
            child: Text(isEditing
                ? localizations.translate('update')
                : localizations.translate('add')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTimer(String id) async {
    setState(() {
      timers.removeWhere((timer) => timer.id == id);
    });
    await _saveTimers();
  }

  Future<void> _showTimezoneDialog() async {
    final localizations = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('selectTimezone')),
        backgroundColor: Theme.of(context).cardColor,
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: timezones.length,
            itemBuilder: (context, index) {
              final tz = timezones[index];
              return ListTile(
                title: Text(
                  tz,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                trailing: _selectedTimezone == tz
                    ? Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                )
                    : null,
                onTap: () {
                  setState(() {
                    _selectedTimezone = tz;
                    _saveTimers();
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('appTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addOrUpdateTimer(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'timezone') {
                _showTimezoneDialog();
              } else if (value == 'about') {
                Navigator.pushNamed(context, '/about');
              } else if (value == 'toggle_completed') {
                setState(() {
                  _showCompletedTimers = !_showCompletedTimers;
                });
              } else if (value == 'toggle_help') {
                setState(() {
                  _showHelpText = !_showHelpText;
                });
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'timezone',
                child: Text(localizations.translate('changeTimezone')),
              ),
              PopupMenuItem<String>(
                value: 'toggle_completed',
                child: Text(_showCompletedTimers
                    ? localizations.translate('hideCompleted')
                    : localizations.translate('showCompleted')),
              ),
              PopupMenuItem<String>(
                value: 'toggle_help',
                child: Text(_showHelpText
                    ? localizations.translate('hideHelp')
                    : localizations.translate('showHelp')),
              ),
              PopupMenuItem<String>(
                value: 'about',
                child: Text(localizations.translate('about')),
              ),
            ],
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final filteredTimers = _showCompletedTimers
              ? timers
              : timers.where((timer) {
            final now = tz.TZDateTime.now(tz.getLocation(_selectedTimezone));
            final target = tz.TZDateTime.from(timer.targetDate, tz.getLocation(_selectedTimezone));
            return !target.difference(now).isNegative;
          }).toList();

          if (filteredTimers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onDoubleTap: () {
                      setState(() {
                        _showHelpText = !_showHelpText;
                      });
                    },
                    child: Icon(
                      Icons.timer,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('noTimers'),
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _addOrUpdateTimer(),
                    child: Text(localizations.translate('addFirstTimer')),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeaderSection(context)),
                if (_showHelpText)
                  SliverToBoxAdapter(
                    child: GestureDetector(
                      onLongPress: () {
                        setState(() {
                          _showHelpText = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                localizations.translate('trackDates'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (orientation == Orientation.portrait)
                  SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => TimerCard(
                        timer: filteredTimers[index],
                        timezone: _selectedTimezone,
                        onEdit: () => _addOrUpdateTimer(existingTimer: filteredTimers[index]),
                        onDelete: () => _deleteTimer(filteredTimers[index].id),
                      ),
                      childCount: filteredTimers.length,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => TimerCard(
                        timer: filteredTimers[index],
                        timezone: _selectedTimezone,
                        onEdit: () => _addOrUpdateTimer(existingTimer: filteredTimers[index]),
                        onDelete: () => _deleteTimer(filteredTimers[index].id),
                      ),
                      childCount: filteredTimers.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateTimer(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('upcomingEvents'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${localizations.translate('timezone')}: $_selectedTimezone',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('currentTime'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      final now = tz.TZDateTime.now(tz.getLocation(_selectedTimezone));
                      return Text(
                        DateFormat('MMM dd, yyyy - HH:mm:ss').format(now),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}