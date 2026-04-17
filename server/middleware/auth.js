const jwt = require('jsonwebtoken');
const db = require('../database_mysql');

async function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    console.log(`⚠️ [${new Date().toLocaleString()}] 未提供认证Token: ${req.method} ${req.path}`);
    return res.status(401).json({
      success: false,
      message: '未提供认证令牌'
    });
  }

  try {
    const user = await new Promise((resolve, reject) => {
      jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
        if (err) reject(err);
        else resolve(decoded);
      });
    });

    const dbUser = await db.prepare('SELECT * FROM users WHERE id = ?').get(user.id);
    
    if (!dbUser || !dbUser.is_active) {
      return res.status(403).json({
        success: false,
        message: '用户不存在或已被禁用'
      });
    }

    req.user = {
      id: dbUser.id,
      username: dbUser.username,
      email: dbUser.email,
      role: dbUser.role
    };

    console.log(`✅ [${new Date().toLocaleString()}] 用户认证成功: ${req.user.username} (${req.user.role})`);
    next();
  } catch (err) {
    console.log(`❌ [${new Date().toLocaleString()}] Token验证失败: ${err.message}`);
    return res.status(403).json({
      success: false,
      message: '令牌无效或已过期'
    });
  }
}

function requireAdmin(req, res, next) {
  if (req.user.role !== 'admin') {
    console.log(`🚫 [${new Date().toLocaleString()}] 非管理员访问受限接口: ${req.user.username}`);
    return res.status(403).json({
      success: false,
      message: '需要管理员权限'
    });
  }
  next();
}

async function logUsage(userId, action, details = {}) {
  try {
    const { v4: uuidv4 } = require('uuid');
    await db.prepare(`
      INSERT INTO usage_logs (id, user_id, action, details)
      VALUES (?, ?, ?, ?)
    `).run(
      uuidv4(),
      userId,
      action,
      JSON.stringify(details)
    );
  } catch (error) {
    console.error('记录使用日志失败:', error.message);
  }
}

module.exports = {
  authenticateToken,
  requireAdmin,
  logUsage
};
