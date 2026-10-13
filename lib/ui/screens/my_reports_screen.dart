import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/incident_models.dart';
import '../components/guide_tour.dart';
import '../theme/dinig_theme.dart';
import '../view_models/dinig_view_model.dart';

class MyReportsScreen extends StatelessWidget {
  final DinigViewModel viewModel;
  final void Function(IncidentReport)? onSelectReport;

  const MyReportsScreen({
    super.key,
    required this.viewModel,
    this.onSelectReport,
  });

  @override
  Widget build(BuildContext context) {
    final reports = viewModel.reports;
    final filter = viewModel.reportFilter;

    final filtered = reports.where((r) {
      if (filter == ReportFilter.emergency) return r.isEmergency;
      if (filter == ReportFilter.safetyCheck) return !r.isEmergency;
      return true;
    }).toList();

    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Log'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            key: GuideKeys.reports,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: ReportFilter.values.map((f) {
                final isSelected = filter == f;
                return FilterChip(
                  label: Text(f.label),
                  selected: isSelected,
                  selectedColor: DinigColors.lightBlue,
                  checkmarkColor: DinigColors.primaryBlue,
                  labelStyle: TextStyle(
                    color: isSelected
                      ? DinigColors.primaryBlue
                      : DinigColors.textSecondary,
                    fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => viewModel.setReportFilter(f),
                );
              }).toList(),
            ),
          ),

          // Reports List
          Expanded(
            child: filtered.isEmpty
              ? Center(
                  child: Text(
                    reports.isEmpty
                        ? 'No reports from this phone number yet.'
                        : 'No incident reports found.',
                    style: const TextStyle(color: DinigColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onSelectReport?.call(item),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.id,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: DinigColors.darkNavy,
                                    ),
                                  ),
                                  _buildStatusBadge(item.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 14,
                                      color: DinigColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.locationAddress,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: DinigColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateFormat.format(item.timestamp),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: DinigColors.textSecondary,
                                    ),
                                  ),
                                  const Row(
                                    children: [
                                      Text(
                                        'View Details',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: DinigColors.primaryBlue,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 14,
                                        color: DinigColors.primaryBlue,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(IncidentStatus status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = DinigColors.textSecondary;

    switch (status) {
      case IncidentStatus.detected:
      case IncidentStatus.pendingCancel:
        bg = const Color(0xFFFEF3C7);
        fg = DinigColors.statusAmber;
        break;
      case IncidentStatus.submitted:
      case IncidentStatus.received:
      case IncidentStatus.acknowledged:
        bg = DinigColors.lightBlue;
        fg = DinigColors.primaryBlue;
        break;
      case IncidentStatus.responding:
        bg = const Color(0xFFFEE2E2);
        fg = DinigColors.emergencyRed;
        break;
      case IncidentStatus.resolved:
        bg = const Color(0xFFDCFCE7);
        fg = DinigColors.statusGreen;
        break;
      case IncidentStatus.canceled:
      case IncidentStatus.falseAlarm:
        bg = const Color(0xFFF1F5F9);
        fg = DinigColors.textSecondary;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
