import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'countdown_timer.dart';
import 'localization.dart';
import 'main.dart';

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
  bool _isExpanded = false;

  Future<bool> _confirmDismiss() async {
    final localizations = AppLocalizations.of(context)!;
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('deleteTimer')),
        content: Text(localizations.translate('deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              localizations.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Dismissible(
      key: Key(widget.timer.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 16)),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white, size: 30),
          ],
        ),
      ),
      confirmDismiss: (direction) => _confirmDismiss(),
      onDismissed: (direction) => widget.onDelete(),
      dismissThresholds: const {
        DismissDirection.endToStart: 0.4,
      },
      movementDuration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: widget.timer.color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: _isExpanded ? 220 : 180,
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
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(localizations.translate('edit')),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              localizations.translate('delete'),
                              style: const TextStyle(color: Colors.red),
                            ),
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
                    '${localizations.translate('target')}: ${DateFormat('MMM dd, yyyy - HH:mm').format(widget.timer.targetDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${localizations.translate('timezone')}: ${widget.timezone}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${localizations.translate('created')}: ${DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(int.parse(widget.timer.id)))}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                  const Spacer(),
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      final now = tz.TZDateTime.now(tz.getLocation(widget.timezone));
                      final target = tz.TZDateTime.from(widget.timer.targetDate, tz.getLocation(widget.timezone));
                      final difference = target.difference(now);

                      String timeLeft = '';
                      if (difference.isNegative) {
                        timeLeft = localizations.translate('eventPassed');
                      } else {
                        timeLeft = '${difference.inDays}d ${difference.inHours % 24}h ${difference.inMinutes % 60}m ${difference.inSeconds % 60}s';
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.translate('timeRemaining'),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
        ),
      ),
    );
  }
}