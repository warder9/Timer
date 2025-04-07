import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'about.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countdown Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/about': (context) => const AboutPage(),
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
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
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
        title: Text(isEditing ? 'Edit Timer' : 'Add New Timer'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Event Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    _selectedDateTime == null
                        ? 'Select Date & Time'
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
                        Text(color.toString().split('.')[1]),
                      ],
                    ),
                  )).toList(),
                  onChanged: (color) => setState(() => _selectedColor = color!),
                  decoration: const InputDecoration(labelText: 'Color'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTimer(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timer?'),
        content: const Text('Are you sure you want to delete this timer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        timers.removeWhere((timer) => timer.id == id);
        _saveTimers();
      });
    }
  }

  Future<void> _showTimezoneDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Timezone'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: timezones.length,
            itemBuilder: (context, index) {
              final tz = timezones[index];
              return ListTile(
                title: Text(tz),
                trailing: _selectedTimezone == tz ? const Icon(Icons.check) : null,
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Countdown Timer'),
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
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'timezone',
                child: Text('Change Timezone'),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Text('About'),
              ),
            ],
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (timers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No timers yet!', style: TextStyle(fontSize: 18)),
                  TextButton(
                    onPressed: () => _addOrUpdateTimer(),
                    child: const Text('Add your first timer'),
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
                if (orientation == Orientation.portrait)
                  SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9, // Adjusted to prevent overflow
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => TimerCard(
                        timer: timers[index],
                        timezone: _selectedTimezone,
                        onEdit: () => _addOrUpdateTimer(existingTimer: timers[index]),
                        onDelete: () => _deleteTimer(timers[index].id),
                      ),
                      childCount: timers.length,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TimerCard(
                          timer: timers[index],
                          timezone: _selectedTimezone,
                          onEdit: () => _addOrUpdateTimer(existingTimer: timers[index]),
                          onDelete: () => _deleteTimer(timers[index].id),
                        ),
                      ),
                      childCount: timers.length,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Events',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Timezone: $_selectedTimezone',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your important dates',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),
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
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Time',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      final now = tz.TZDateTime.now(tz.getLocation(_selectedTimezone));
                      return Text(
                        DateFormat('MMM dd, yyyy - HH:mm:ss').format(now),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
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

class TimerCard extends StatefulWidget {
  final CountdownTimer timer;
  final String timezone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TimerCard({
    super.key,
    required this.timer,
    required this.timezone,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: widget.timer.color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 180, // Fixed height to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      widget.timer.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.timer.color,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: widget.timer.color),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') widget.onEdit();
                      if (value == 'delete') widget.onDelete();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Target: ${DateFormat('MMM dd, yyyy - HH:mm').format(widget.timer.targetDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Timezone: ${widget.timezone}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  final now = tz.TZDateTime.now(tz.getLocation(widget.timezone));
                  final target = tz.TZDateTime.from(widget.timer.targetDate, tz.getLocation(widget.timezone));
                  final difference = target.difference(now);
                  
                  String timeLeft = '';
                  if (difference.isNegative) {
                    timeLeft = 'Event passed';
                  } else {
                    timeLeft = '${difference.inDays}d ${difference.inHours % 24}h ${difference.inMinutes % 60}m ${difference.inSeconds % 60}s';
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time remaining',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeLeft,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.timer.color,
                            ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CountdownTimer {
  final String id;
  final String title;
  final DateTime targetDate;
  final Color color;

  CountdownTimer({
    required this.id,
    required this.title,
    required this.targetDate,
    required this.color,
  });

  factory CountdownTimer.fromJson(Map<String, dynamic> json) {
    return CountdownTimer(
      id: json['id'],
      title: json['title'],
      targetDate: DateTime.parse(json['targetDate']),
      color: Color(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetDate': targetDate.toIso8601String(),
      'color': color.value,
    };
  }
}
