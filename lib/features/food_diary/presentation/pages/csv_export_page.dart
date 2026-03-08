import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/database_lib.dart';
import '../../../../core/themes/app_theme.dart';

@RoutePage()
class CsvExportPage extends StatefulWidget {
  const CsvExportPage({super.key});

  @override
  State<CsvExportPage> createState() => _CsvExportPageState();
}

class _CsvExportPageState extends State<CsvExportPage> {
  bool _isExporting = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Export (CSV)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.download,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Download all recorded data as a CSV file.',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The export includes every row from the local sensor data table:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• timestamp_iso\n'
                      '• timestamp_ms\n'
                      '• page\n'
                      '• sensor1\n'
                      '• sensor2\n'
                      '• sensor3\n'
                      '• sensor4',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportCsv,
              icon: const Icon(Icons.file_download),
              label: Text(_isExporting ? 'Preparing CSV…' : 'Download CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_statusMessage != null)
              Text(
                _statusMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            const Spacer(),
            Text(
              'Tip: after export, choose a destination app to save the CSV.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiaryColor,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    setState(() {
      _isExporting = true;
      _statusMessage = 'Gathering data…';
    });

    try {
      final rows = await DBUtils.getAllSensorData(orderDesc: false);

      if (rows.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isExporting = false;
          _statusMessage = 'No data found to export.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data available to export yet.'),
            backgroundColor: AppTheme.infoColor,
          ),
        );
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln(
        'timestamp_iso,timestamp_ms,page,sensor1,sensor2,sensor3,sensor4',
      );

      for (final row in rows) {
        final tsMillis = row['timestamp'] as int?;
        final timestamp = tsMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(tsMillis)
            : null;
        final timestampIso =
            timestamp != null ? DateFormat('yyyy-MM-ddTHH:mm:ss').format(timestamp) : '';

        String asValue(dynamic value) {
          if (value == null) return '';
          if (value is num) return value.toString();
          return value.toString();
        }

        final csvRow = [
          timestampIso,
          tsMillis?.toString() ?? '',
          asValue(row['page']),
          asValue(row['sensor1']),
          asValue(row['sensor2']),
          asValue(row['sensor3']),
          asValue(row['sensor4']),
        ].join(',');

        buffer.writeln(csvRow);
      }

      final csvString = buffer.toString();
      final bytes = Uint8List.fromList(utf8.encode(csvString));
      final fileName =
          'metasense_data_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';

      final xFile = XFile.fromData(
        bytes,
        mimeType: 'text/csv',
        name: fileName,
      );

      await Share.shareXFiles(
        [xFile],
        text: 'MetaSense sensor data CSV export',
      );

      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _statusMessage = 'CSV generated and share sheet opened.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _statusMessage = 'Failed to export CSV: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export CSV: $e'),
          backgroundColor: AppTheme.criticalColor,
        ),
      );
    }
  }
}
