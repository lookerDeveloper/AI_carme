const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const db = require('../database_mysql');
const { logUsage } = require('../middleware/auth');

router.post('/register', async (req, res) => {
  try {
    console.log(`📝 [${new Date().toLocaleString()}] 用户注册请求: ${req.body.username}`);
    
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({
        success: false,
        message: '用户名、邮箱和密码不能为空'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: '密码长度至少6位'
      });
    }

    const existingUser = await db.prepare(
      'SELECT id FROM users WHERE username = ? OR email = ?'
    ).get(username, email);

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: '用户名或邮箱已存在'
      });
    }

    const hashedPassword = bcrypt.hashSync(password, 10);
    const userId = uuidv4();

    await db.prepare(`
      INSERT INTO users (id, username, email, password)
      VALUES (?, ?, ?, ?)
    `).run(userId, username, email, hashedPassword);

    const token = jwt.sign(
      { id: userId, username, role: 'user' },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    await db.prepare('UPDATE users SET last_login_at = NOW() WHERE id = ?').run(userId);
    logUsage(userId, 'REGISTER', { method: 'email' });

    console.log(`✅ [${new Date().toLocaleString()}] 用户注册成功: ${username}`);

    res.json({
      success: true,
      message: '注册成功',
      data: {
        token,
        user: {
          id: userId,
          username,
          email,
          role: 'user'
        }
      }
    });
  } catch (error) {
    console.error('❌ 注册失败:', error);
    res.status(500).json({
      success: false,
      message: '服务器错误，请稍后重试'
    });
  }
});

router.post('/login', async (req, res) => {
  try {
    console.log(`🔑 [${new Date().toLocaleString()}] 用户登录请求`);
    
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: '用户名和密码不能为空'
      });
    }

    const user = await db.prepare(
      'SELECT * FROM users WHERE (username = ? OR email = ?) AND is_active = 1'
    ).get(username, username);

    if (!user || !bcrypt.compareSync(password, user.password)) {
      console.log(`⚠️ [${new Date().toLocaleString()}] 登录失败: ${username}`);
      return res.status(401).json({
        success: false,
        message: '用户名或密码错误'
      });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    await db.prepare(`
      UPDATE users 
      SET last_login_at = NOW(), usage_count = usage_count + 1 
      WHERE id = ?
    `).run(user.id);

    logUsage(user.id, 'LOGIN', { method: 'password' });

    console.log(`✅ [${new Date().toLocaleString()}] 用户登录成功: ${user.username} (${user.role})`);

    res.json({
      success: true,
      message: '登录成功',
      data: {
        token,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          role: user.role,
          avatar: user.avatar
        }
      }
    });
  } catch (error) {
    console.error('❌ 登录失败:', error);
    res.status(500).json({
      success: false,
      message: '服务器错误，请稍后重试'
    });
  }
});

router.get('/me', require('../middleware/auth').authenticateToken, async (req, res) => {
  try {
    const user = await db.prepare(`
      SELECT id, username, email, role, avatar, usage_count, last_login_at, created_at 
      FROM users WHERE id = ?
    `).get(req.user.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: '用户不存在'
      });
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('获取用户信息失败:', error);
    res.status(500).json({
      success: false,
      message: '服务器错误'
    });
  }
});

module.exports = router;
