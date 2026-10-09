import 'package:flutter/material.dart';
import 'package:queueless_client/queueless_client.dart';
import '../client.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  QueueStatus? _currentStatus;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinQueue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await client.queue.joinQueue(name);
      setState(() {
        _currentStatus = status;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to join queue. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshStatus() async {
    if (_currentStatus?.ticket.id == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await client.queue.getTicketStatus(
        _currentStatus!.ticket.id!,
      );
      setState(() {
        if (status != null) {
          _currentStatus = status;
        } else {
          _currentStatus = null; // Ticket no longer exists
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to refresh status.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Queue'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _currentStatus == null
                ? _buildJoinForm()
                : _buildStatusView(),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.people_alt_outlined, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Join the Queue',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your name to get your ticket and wait for your turn.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              enabled: !_isLoading,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _joinQueue(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _joinQueue,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Get Ticket'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView() {
    final ticket = _currentStatus!.ticket;
    final isServing = ticket.status == 'serving';
    final isCompleted = ticket.status == 'completed';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isCompleted) {
      statusColor = Colors.green;
      statusText = 'Completed';
      statusIcon = Icons.check_circle_outline;
    } else if (isServing) {
      statusColor = Colors.orange;
      statusText = 'It\'s your turn!';
      statusIcon = Icons.notifications_active_outlined;
    } else {
      statusColor = Colors.blue;
      statusText = 'Waiting';
      statusIcon = Icons.access_time;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(statusIcon, size: 64, color: statusColor),
                const SizedBox(height: 24),
                Text(
                  'Ticket #${ticket.ticketNumber}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hi, ${ticket.customerName}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    statusText.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (!isCompleted && !isServing) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Position',
                        '#${_currentStatus!.position}',
                      ),
                      _buildStatItem(
                        'Waiting',
                        '${_currentStatus!.totalWaiting}',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        if (!isCompleted)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _refreshStatus,
            icon: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Refresh Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        if (isCompleted)
          TextButton(
            onPressed: () {
              setState(() {
                _currentStatus = null;
                _nameController.clear();
              });
            },
            child: const Text('Join Again'),
          ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
