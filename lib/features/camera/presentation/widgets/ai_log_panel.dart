import 'package:flutter/material.dart';
import '../../../../core/utils/app_logger.dart';

class AiLogPanel extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onClose;

  const AiLogPanel({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.onClose,
  });

  @override
  State<AiLogPanel> createState() => _AiLogPanelState();
}

class _AiLogPanelState extends State<AiLogPanel> {
  final ScrollController _scrollController = ScrollController();
  List<String> _logs = [];
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    AppLogger.addListener(_onLogUpdate);
    _refreshLogs();
  }

  void _onLogUpdate(List<String> allLogs) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _logs = allLogs.where((log) => log.contains('[AI]')).toList();
          });
        }
      });
    }
  }

  void _refreshLogs() {
    final recentLogs = AppLogger.getRecentLogs(count: 100);
    setState(() {
      _logs = recentLogs.where((log) => log.contains('[AI]')).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isExpanded) {
      return Positioned(
        bottom: 120,
        right: 16,
        child: FloatingActionButton.small(
          onPressed: widget.onToggle,
          backgroundColor: Colors.blue,
          child: Badge(
            label: Text('${_logs.length}', style: TextStyle(fontSize: 10)),
            isLabelVisible: _logs.isNotEmpty,
            child: Icon(Icons.terminal, size: 20),
          ),
        ),
      );
    }

    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFF1A1A2E),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildLogList()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF0F3460),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.terminal, color: Colors.lightBlueAccent, size: 18),
          SizedBox(width: 8),
          Text(
            'AI 日志面板',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          IconButton(
            onPressed: _refreshLogs,
            icon: Icon(Icons.refresh, color: Colors.white70, size: 18),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            tooltip: '刷新',
          ),
          SizedBox(width: 12),
          IconButton(
            onPressed: widget.onToggle,
            icon: Icon(Icons.minimize, color: Colors.white70, size: 18),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            tooltip: '最小化',
          ),
          SizedBox(width: 12),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(Icons.close, color: Colors.white70, size: 18),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.white38, size: 32),
            SizedBox(height: 8),
            Text(
              '暂无日志',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            Text(
              '开启日志开关后运行AI分析',
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoScroll && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(8),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return _buildLogItem(log);
      },
    );
  }

  Widget _buildLogItem(String log) {
    Color textColor = Colors.white70;
    IconData? icon;

    if (log.contains('[AI请求开始]')) {
      textColor = Color(0xFF4CAF50);
      icon = Icons.upload;
    } else if (log.contains('[AI响应返回]')) {
      textColor = Color(0xFF2196F3);
      icon = Icons.download;
    } else if (log.contains('[AI]') && log.contains('评分')) {
      textColor = Color(0xFFFFEB3B);
      icon = Icons.star;
    } else if (log.contains('Error') || log.contains('失败')) {
      textColor = Color(0xFFF44336);
      icon = Icons.error;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              _formatLog(log),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: textColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLog(String log) {
    log = log.replaceAll(RegExp(r'\[.*?\]\s*'), '');
    if (log.length > 150) {
      log = log.substring(0, 150) + '...';
    }
    return log;
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF0F3460).withOpacity(0.5),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Text(
            '${_logs.length} 条日志',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
          Spacer(),
          Row(
            children: [
              Text('自动滚动', style: TextStyle(color: Colors.white38, fontSize: 10)),
              SizedBox(width: 4),
              Switch(
                value: _autoScroll,
                onChanged: (v) => setState(() => _autoScroll = v),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          SizedBox(width: 8),
          IconButton(
            onPressed: () {
              AppLogger.clearLogFiles();
              setState(() => _logs.clear());
            },
            icon: Icon(Icons.delete_outline, color: Colors.white38, size: 16),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            tooltip: '清空日志',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.removeListener(_onLogUpdate);
    _scrollController.dispose();
    super.dispose();
  }
}
