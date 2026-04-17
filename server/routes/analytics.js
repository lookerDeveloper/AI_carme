const express = require('express');
const router = express.Router();
const db = require('../database_mysql');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

router.get('/dashboard', authenticateToken, requireAdmin, async (req, res) => {
  try {
    console.log(`📊 [${new Date().toLocaleString()}] 获取管理面板统计数据`);
    
    const totalUsers = await db.prepare('SELECT COUNT(*) as count FROM users WHERE is_active = 1').get();
    const todayUsers = await db.prepare(`
      SELECT COUNT(*) as count FROM users 
      WHERE DATE(created_at) = CURDATE() AND is_active = 1
    `).get();

    const activeUsersToday = await db.prepare(`
      SELECT COUNT(DISTINCT user_id) as count 
      FROM usage_logs 
      WHERE DATE(created_at) = CURDATE()
    `).get();

    const totalTemplates = await db.prepare('SELECT COUNT(*) as count FROM templates WHERE is_active = 1').get();

    const recentLogins = await db.prepare(`
      SELECT u.username, u.role, u.last_login_at
      FROM users u
      WHERE u.is_active = 1 AND u.last_login_at IS NOT NULL
      ORDER BY u.last_login_at DESC
      LIMIT 10
    `).all();

    const actionStats = await db.prepare(`
      SELECT action, COUNT(*) as count
      FROM usage_logs
      WHERE DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
      GROUP BY action
      ORDER BY count DESC
    `).all();

    const dailyActiveUsers = await db.prepare(`
      SELECT DATE(created_at) as date, COUNT(DISTINCT user_id) as active_users
      FROM usage_logs
      WHERE DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
      GROUP BY DATE(created_at)
      ORDER BY date
    `).all();

    res.json({
      success: true,
      data: {
        overview: {
          totalUsers: totalUsers.count,
          newUsersToday: todayUsers.count,
          activeUsersToday: activeUsersToday.count || 0,
          totalTemplates: totalTemplates.count
        },
        recentLogins,
        actionStats,
        dailyActiveUsers
      }
    });
  } catch (error) {
    console.error('获取统计数据失败:', error);
    res.status(500).json({
      success: false,
      message: '获取统计数据失败'
    });
  }
});

router.get('/usage-trend', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { days = 30 } = req.query;
    
    const trendData = await db.prepare(`
      SELECT 
        DATE(created_at) as date,
        SUM(CASE WHEN action = 'LOGIN' THEN 1 ELSE 0 END) as logins,
        SUM(CASE WHEN action = 'UPLOAD_TEMPLATE' THEN 1 ELSE 0 END) as template_uploads,
        SUM(CASE WHEN action = 'UPLOAD_CUSTOM_TEMPLATE' THEN 1 ELSE 0 END) as custom_uploads,
        COUNT(DISTINCT user_id) as unique_users
      FROM usage_logs
      WHERE DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
      GROUP BY DATE(created_at)
      ORDER BY date
    `).all(parseInt(days));

    res.json({ success: true, data: trendData });
  } catch (error) {
    console.error('获取使用趋势失败:', error);
    res.status(500).json({ success: false, message: '获取数据失败' });
  }
});

router.get('/user/:userId', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const userActions = await db.prepare(`
      SELECT action, details, created_at
      FROM usage_logs
      WHERE user_id = ?
      ORDER BY created_at DESC
      LIMIT 100
    `).all(req.params.userId);

    const actionSummary = await db.prepare(`
      SELECT action, COUNT(*) as count
      FROM usage_logs
      WHERE user_id = ?
      GROUP BY action
      ORDER BY count DESC
    `).all(req.params.userId);

    res.json({
      success: true,
      data: {
        recentActions: userActions,
        summary: actionSummary
      }
    });
  } catch (error) {
    console.error('获取用户活动失败:', error);
    res.status(500).json({ success: false, message: '获取数据失败' });
  }
});

module.exports = router;
