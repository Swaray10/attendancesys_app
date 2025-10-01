import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';

class CheckInListItem extends StatelessWidget {
  final CheckInResponse checkIn;

  const CheckInListItem({
    super.key,
    required this.checkIn,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = checkIn.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sm),
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: isPending ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isPending ? Colors.orange[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isPending ? Colors.orange[100] : Colors.green[100],
            child: Icon(
              isPending ? Icons.sync : Icons.check,
              color: isPending ? Colors.orange[700] : Colors.green[700],
            ),
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkIn.studentName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${checkIn.studentId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm:ss').format(checkIn.checkInTime),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (isPending) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SYNCING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
