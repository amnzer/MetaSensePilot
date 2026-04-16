import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
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
  bool _isImporting = false;
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
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
            OutlinedButton.icon(
              onPressed: _isImporting ? null : _importCsv,
              icon: const Icon(Icons.upload_file),
              label: Text(_isImporting ? 'Importing CSV…' : 'Upload CSV to Replace DB'),
              style: OutlinedButton.styleFrom(
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

  Future<void> _importCsv() async {
    setState(() {
      _isImporting = true;
      _statusMessage = 'Choose a CSV file…';
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isImporting = false;
          _statusMessage = 'CSV import canceled.';
        });
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Could not read selected CSV file bytes.');
      }

      final csvText = utf8.decode(bytes);
      final parsedRows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(csvText);

      if (parsedRows.length < 2) {
        throw Exception('CSV must include a header row and at least one data row.');
      }

      final headers = parsedRows.first
          .map((value) => value.toString().trim().toLowerCase())
          .toList();

      final headerIndex = <String, int>{};
      for (var i = 0; i < headers.length; i++) {
        headerIndex[headers[i]] = i;
      }

      int? readIndex(List<String> options, {bool required = true}) {
        for (final name in options) {
          final idx = headerIndex[name];
          if (idx != null) return idx;
        }
        if (!required) return null;
        throw Exception('Missing required CSV column. Expected one of: ${options.join(", ")}');
      }

      final tsMsIdx = readIndex(['timestamp_ms', 'timestamp'], required: false);
      final tsIsoIdx = readIndex(['timestamp_iso'], required: false);
      if (tsMsIdx == null && tsIsoIdx == null) {
        throw Exception(
          'CSV must include either timestamp_ms/timestamp or timestamp_iso.',
        );
      }

      final pageIdx = readIndex(['page'], required: false);
      final int sensor1Idx = readIndex(['sensor1'])!;
      final int sensor2Idx = readIndex(['sensor2'])!;
      final int sensor3Idx = readIndex(['sensor3'])!;
      final int sensor4Idx = readIndex(['sensor4'])!;

      int parseTimestamp(List<dynamic> row) {
        if (tsMsIdx != null && tsMsIdx < row.length) {
          final raw = row[tsMsIdx].toString().trim();
          final parsedInt = int.tryParse(raw);
          if (parsedInt != null) {
            // Accept both epoch seconds and epoch milliseconds.
            if (parsedInt > 0 && parsedInt < 1000000000000) {
              return parsedInt * 1000;
            }
            return parsedInt;
          }

          final parsedDouble = double.tryParse(raw);
          if (parsedDouble != null) {
            final rounded = parsedDouble.round();
            if (rounded > 0 && rounded < 1000000000000) {
              return rounded * 1000;
            }
            return rounded;
          }
        }

        if (tsIsoIdx != null && tsIsoIdx < row.length) {
          final raw = row[tsIsoIdx].toString().trim();
          final parsed = DateTime.tryParse(raw);
          if (parsed != null) return parsed.millisecondsSinceEpoch;
        }

        throw Exception('Could not parse timestamp from row.');
      }

      double? parseSensor(List<dynamic> row, int idx) {
        if (idx >= row.length) return null;
        final raw = row[idx].toString().trim();
        if (raw.isEmpty) return null;
        return double.tryParse(raw);
      }

      final dbRows = <Map<String, Object?>>[];
      for (var i = 1; i < parsedRows.length; i++) {
        final row = parsedRows[i];
        if (row.isEmpty) {
          continue;
        }

        final timestamp = parseTimestamp(row);
        final page = (pageIdx != null && pageIdx < row.length)
            ? int.tryParse(row[pageIdx].toString().trim()) ?? 0
            : 0;

        final sensor1 = parseSensor(row, sensor1Idx);
        final sensor2 = parseSensor(row, sensor2Idx);
        final sensor3 = parseSensor(row, sensor3Idx);
        final sensor4 = parseSensor(row, sensor4Idx);

        dbRows.add({
          'timestamp': timestamp,
          'page': page,
          'sensor1': sensor1,
          'sensor2': sensor2,
          'sensor3': sensor3,
          'sensor4': sensor4,
        });
      }

      if (dbRows.isEmpty) {
        throw Exception('No valid rows found to import.');
      }

      await DBUtils.replaceAllSensorData(dbRows);

      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _statusMessage =
            'Imported ${dbRows.length} rows. Pull-to-refresh Dashboard to see updates.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${dbRows.length} rows from CSV.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _statusMessage = 'Failed to import CSV: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import CSV: $e'),
          backgroundColor: AppTheme.criticalColor,
        ),
      );
    }
  }
}
