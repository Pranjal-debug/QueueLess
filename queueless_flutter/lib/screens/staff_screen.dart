import 'package:flutter/material.dart';
import 'package:queueless_client/queueless_client.dart';
import '../client.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<QueueTicket> _activeQueue = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queue = await client.queue.getActiveQueue();
      setState(() {
        _activeQueue = queue;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load queue. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _callNext() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ticket = await client.queue.callNext();
      if (ticket != null) {
        // Reload queue to get updated state
        await _loadQueue();
      } else {
        setState(() => _errorMessage = 'No waiting customers in the queue.');
        _isLoading = false;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to call next customer.';
        _isLoading = false;
      });
    }
  }

  Future<void> _completeTicket(int ticketId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await client.queue.completeTicket(ticketId);
      if (success) {
        await _loadQueue();
      } else {
        setState(() => _errorMessage = 'Failed to complete ticket.');
        _isLoading = false;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to complete ticket.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final servingTickets = _activeQueue
        .where((t) => t.status == 'serving')
        .toList();
    final waitingTickets = _activeQueue
        .where((t) => t.status == 'waiting')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadQueue,
            tooltip: 'Refresh Queue',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Container(
                color: Colors.red.shade100,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _errorMessage = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Call Next Action Area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _callNext,
                icon: const Icon(Icons.campaign),
                label: const Text('CALL NEXT CUSTOMER'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const Divider(),

            // Queue Lists
            Expanded(
              child: _isLoading && _activeQueue.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadQueue,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (servingTickets.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Currently Serving',
                              Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            ...servingTickets.map(
                              (t) => _buildTicketCard(t, true),
                            ),
                            const SizedBox(height: 24),
                          ],

                          _buildSectionHeader(
                            'Waiting in Line (${waitingTickets.length})',
                            Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          if (waitingTickets.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'The queue is empty',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...waitingTickets.map(
                              (t) => _buildTicketCard(t, false),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(QueueTicket ticket, bool isServing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isServing ? Colors.orange.shade300 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isServing
              ? Colors.orange.shade100
              : Colors.blue.shade50,
          foregroundColor: isServing
              ? Colors.orange.shade800
              : Colors.blue.shade800,
          radius: 24,
          child: Text(
            '#${ticket.ticketNumber}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        title: Text(
          ticket.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Joined: ${_formatTime(ticket.createdAt)}'
            '${isServing && ticket.calledAt != null ? '\nCalled: ${_formatTime(ticket.calledAt!)}' : ''}',
            style: TextStyle(color: Colors.grey[600], height: 1.4),
          ),
        ),
        trailing: isServing
            ? ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _completeTicket(ticket.id!),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 40),
                ),
              )
            : const Icon(Icons.hourglass_empty, color: Colors.grey),
        isThreeLine: isServing,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
