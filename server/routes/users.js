const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const db = require('../database_mysql');
const { authenticateToken, requireAdmin, logUsage } = require('../middleware/auth');

router.get('/', authenticateToken, requireAdmin, async (req, res) => {
  try {
    console.log(`📋 [${new Date().toLocaleString()}] 管理员查询用户列表`);
    
    const { page = 1, limit = 20, search = '', role = '' } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = '1=1';
    const params = [];

    if (search) {
      whereClause += ' AND (username LIKE ? OR email LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }

    if (role) {
      whereClause += ' AND role = ?';
      params.push(role);
    }

    const users = await db.prepare(`
      SELECT id, username, email, role, avatar, is_active, usage_count, last_login_at, created_at
      FROM users 
      WHERE ${whereClause}
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `).all(...params, parseInt(limit), offset);

    const totalResult = await db.prepare(`
      SELECT COUNT(*) as count FROM users WHERE ${whereClause}
    `).get(...params);

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: totalResult.count,
          totalPages: Math.ceil(totalResult.count / limit)
        }
      }
    });
  } catch (error) {
    console.error('获取用户列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取用户列表失败'
    });
  }
});

router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const user = await db.prepare(`
      SELECT id, username, email, role, avatar, usage_count, last_login_at, created_at
      FROM users WHERE id = ?
    `).get(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: '用户不存在'
      });
    }

    if (req.user.role !== 'admin' && req.user.id !== req.params.id) {
      return res.status(403).json({
        success: false,
        message: '无权查看此用户信息'
      });
    }

    res.json({ success: true, data: user });
  } catch (error) {
    console.error('获取用户详情失败:', error);
    res.status(500).json({
      success: false,
      message: '服务器错误'
    });
  }
});

router.put('/:id/toggle-status', authenticateToken, requireAdmin, async (req, res) => {
  try {
    console.log(`🔄 [${new Date().toLocaleString()}] 管理员切换用户状态: ${req.params.id}`);
    
    const user = await db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: '用户不存在'
      });
    }

    if (user.role === 'admin') {
      return res.status(400).json({
        success: false,
        message: '不能禁用管理员账号'
      });
    }

    const newStatus = user.is_active ? 0 : 1;
    await db.prepare('UPDATE users SET is_active = ?, updated_at = NOW() WHERE id = ?')
      .run(newStatus, req.params.id);

    logUsage(req.user.id, 'TOGGLE_USER_STATUS', { targetUserId: req.params.id, newStatus });

    res.json({
      success: true,
      message: newStatus ? '用户已启用' : '用户已禁用',
      data: { isActive: !!newStatus }
    });
  } catch (error) {
    console.error('切换用户状态失败:', error);
    res.status(500).json({
      success: false,
      message: '操作失败'
    });
  }
});

module.exports = router;
