import '../utils/localized_vehicle_text.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_design_system.dart' hide StatusChip;
import '../theme/app_tokens.dart';
import '../utils/bidi_text.dart';
import '../utils/western_digits.dart';
import '../widgets/ui/ui.dart';

class HistoryScreen extends StatefulWidget {
  final bool embedded;
  const HistoryScreen({super.key, this.embedded = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static String get baseUrl => ApiConfig.baseUrl;

  bool _isLoading = true;
  String? _errorText;
  List<dynamic> _items = [];
  String _selectedFilter = 'all';
  static const int _pageSize = 50;
  bool _hasMore = false;
  bool _loadingMore = false;

  static const List<String> _filters = ['all', 'high', 'medium', 'low'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/history?limit=$_pageSize'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final items = data is List ? data : (data['items'] ?? []);
        setState(() {
          _items = items;
          _hasMore = items.length >= _pageSize;
        });
      } else {
        setState(() => _errorText = 'server:${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorText = 'connection');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _items.isEmpty) return;
    final cursor = (_items.last as Map?)?['timestamp']?.toString();
    if (cursor == null) {
      setState(() => _hasMore = false);
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/history?limit=$_pageSize&before=${Uri.encodeQueryComponent(cursor)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final items = data is List ? data : (data['items'] ?? []);
        setState(() {
          _items = [..._items, ...items];
          _hasMore = items.length >= _pageSize;
        });
      } else if (mounted) {
        _showSnack(AppLocalizations.of(context).historyLoadFailed);
      }
    } catch (_) {
      if (mounted) _showSnack(AppLocalizations.of(context).historyConnectionFailed);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<dynamic> get _filteredItems {
    if (_selectedFilter == 'all') return _items;
    return _items.where((item) {
      final result = (item['result'] as Map?) ?? {};
      return _severityKey(result['severity']?.toString()) == _selectedFilter;
    }).toList();
  }

  String _severityKey(String? severity) => switch (severity) {
        'critical' || 'high' => 'high',
        'medium' => 'medium',
        'low' => 'low',
        _ => 'unknown',
      };

  String _severityLabel(String severity) {
    final l10n = AppLocalizations.of(context);
    return switch (severity) {
      'all' => l10n.historyFilterAll,
      'high' => l10n.severityHigh,
      'medium' => l10n.severityMedium,
      'low' => l10n.severityLow,
      _ => l10n.historyUnknownSeverity,
    };
  }

  Future<void> _deleteItem(String id) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.historyDeleteTitle),
        content: Text(l10n.historyDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/history/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() => _items.removeWhere((e) => e['id'].toString() == id));
      } else {
        _showSnack(l10n.historyDeleteFailed);
      }
    } catch (e) {
      _showSnack(l10n.historyConnectionFailed);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _severityColor(String? severity) {
    switch (severity) {
      case 'high':
        return Ui.dangerText;
      case 'medium':
        return Ui.warnText;
      case 'low':
        return Ui.okText;
      default:
        return Ui.textSecondary;
    }
  }

  IconData _severityIcon(String? severity) {
    switch (severity) {
      case 'high':
        return Icons.dangerous_outlined;
      case 'medium':
        return Icons.warning_amber_rounded;
      case 'low':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final localizations = MaterialLocalizations.of(context);
      final formattedDate = localizations.formatMediumDate(date);
      final formattedTime = localizations.formatTimeOfDay(
        TimeOfDay.fromDateTime(date),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
      return westernDigits('$formattedDate - $formattedTime');
    } catch (_) {
      return isoDate;
    }
  }

  void _showDetails(Map item) {
    final l10n = AppLocalizations.of(context);
    final result = (item['result'] as Map?) ?? {};
    final severity = _severityKey(result['severity']?.toString());
    final color = _severityColor(severity);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(_severityIcon(severity), color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result['possible_issue'] ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${l10n.historySeverityLabel}: ${_severityLabel(severity)}',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Text(result['explanation'] ?? '',
                    style: const TextStyle(fontSize: 14, height: 1.6)),
                if (result['recommendations'] != null) ...[
                  const SizedBox(height: 12),
                  Text(l10n.historyRecommendationsLabel,
                      style:
                           const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  ...List<String>.from(result['recommendations']).map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(r,
                                  style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  ),
                ],
                if (result['estimated_cost'] != null &&
                    result['estimated_cost'] != 'null') ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined,
                          size: 18, color: AppColors.steel),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            '${l10n.historyEstimatedCostLabel}: ${result['estimated_cost']}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.steel)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          final color =
              filter == 'all' ? Ui.primaryText : _severityColor(filter);
          return ChoiceChip(
            label: Text(_severityLabel(filter)),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedFilter = filter),
            selectedColor: color.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: isSelected ? color : Ui.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected ? color : Ui.border,
            ),
            backgroundColor: Colors.transparent,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    final noneAtAll = _items.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                  noneAtAll
                      ? Icons.history_rounded
                      : Icons.filter_alt_off_outlined,
                  size: 40,
                  color: AppColors.accent.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text(
              noneAtAll
                  ? l10n.historyEmpty
                  : '${l10n.historyNoFiltered} "${_severityLabel(_selectedFilter)}"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Ui.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Map item) {
    final l10n = AppLocalizations.of(context);
    final result = (item['result'] as Map?) ?? {};
    final severity = _severityKey(result['severity']?.toString());
    final color = _severityColor(severity);
    final id = item['id'].toString();
    final car = (item['car'] as Map?) ?? {};
    final carLabel = car.isNotEmpty
        ? '${l10n.carBrand((car['brand'] ?? '').toString())} ${l10n.localizedCarModel((car['model'] ?? '').toString(), Localizations.localeOf(context).languageCode)} - ${car['year'] ?? ''}'
        : null;

    final level = switch (severity) {
      'high' => StatusLevel.danger,
      'medium' => StatusLevel.warn,
      _ => StatusLevel.ok,
    };
    final title = bidiText(
        context, (result['possible_issue'] ?? l10n.historyUntitled).toString());
    return Padding(
      padding: const EdgeInsets.only(bottom: Ui.s12),
      child: AppCard(
        onTap: () => _showDetails(item),
        semanticLabel: title,
        padding: const EdgeInsets.fromLTRB(Ui.s16, Ui.s12, Ui.s8, Ui.s12),
        child: Row(
          children: [
            IconTile(_severityIcon(severity), size: 44, color: color),
            const SizedBox(width: Ui.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: Ui.body, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Ui.s4),
                  if (carLabel != null)
                    Text(
                      carLabel,
                      style: const TextStyle(
                          fontSize: Ui.secondary, color: Ui.textSecondary),
                    ),
                  Text(
                    _formatDate(item['timestamp'] as String?),
                    style: const TextStyle(
                        fontSize: Ui.secondary, color: Ui.textSecondary),
                  ),
                  const SizedBox(height: Ui.s8),
                  StatusChip(label: _severityLabel(severity), level: level),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.delete,
              constraints: const BoxConstraints(
                  minWidth: Ui.minTouch, minHeight: Ui.minTouch),
              icon: const Icon(Icons.delete_outline, color: Ui.textSecondary),
              onPressed: () => _deleteItem(id),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(AppLocalizations.of(context).historyPageTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              children: [
                if (!_isLoading && _errorText == null && _items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFilterBar(),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadHistory,
                    child: _isLoading
                        ? AppStateView(
                            icon: Icons.history_rounded,
                            title: AppLocalizations.of(context).historyLoading,
                            loading: true)
                        : _errorText != null
                            ? ListView(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 80),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: AppStateView(
                                          icon: Icons.cloud_off_outlined,
                                          title: l10n.historyLoadFailed,
                                          message: _errorText!.startsWith('server:') ? '${l10n.historyLoadFailed} (${_errorText!.substring(7)})' : l10n.historyConnectionFailed,
                                          actionLabel: l10n.historyRetry,
                                          onAction: _loadHistory,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : filtered.isEmpty
                                ? ListView(
                                    children: [_buildEmptyState()],
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: filtered.length + (_hasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index < filtered.length) {
                                        return _buildItemCard(filtered[index]);
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Center(
                                          child: _loadingMore
                                              ? const CircularProgressIndicator()
                                              : OutlinedButton(
                                                  onPressed: _loadMore,
                                                  child: Text(l10n.historyLoadMore),
                                                ),
                                        ),
                                      );
                                    },
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
