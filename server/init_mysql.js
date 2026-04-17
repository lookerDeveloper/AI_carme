const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

async function init() {
  console.log('正在连接MySQL...');
  const conn = await mysql.createConnection({
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'root'
  });
  console.log('MySQL连接成功!');

  await conn.query('CREATE DATABASE IF NOT EXISTS aicam_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
  console.log('数据库 aicam_db 已就绪');
  await conn.query('USE aicam_db');

  await conn.query(`DROP TABLE IF EXISTS usage_logs`);
  await conn.query(`DROP TABLE IF EXISTS user_templates`);
  await conn.query(`DROP TABLE IF EXISTS templates`);
  await conn.query(`DROP TABLE IF EXISTS users`);
  console.log('旧表已清理');

  await conn.query(`
    CREATE TABLE users (
      id VARCHAR(36) NOT NULL,
      username VARCHAR(50) NOT NULL,
      email VARCHAR(100) NOT NULL,
      password VARCHAR(255) NOT NULL,
      role ENUM('admin','user') DEFAULT 'user',
      avatar VARCHAR(500) DEFAULT NULL,
      is_active TINYINT(1) DEFAULT 1,
      usage_count INT DEFAULT 0,
      last_login_at DATETIME DEFAULT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      UNIQUE KEY uk_username (username),
      UNIQUE KEY uk_email (email)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  `);
  console.log('users 表创建完成');

  await conn.query(`
    CREATE TABLE templates (
      id VARCHAR(36) NOT NULL,
      name VARCHAR(100) NOT NULL,
      category VARCHAR(30) NOT NULL,
      thumbnail_url VARCHAR(500) NOT NULL,
      tags JSON DEFAULT NULL,
      composition_rules JSON DEFAULT NULL,
      camera_params JSON DEFAULT NULL,
      uploaded_by VARCHAR(36) NOT NULL,
      is_active TINYINT(1) DEFAULT 1,
      usage_count INT DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      KEY idx_category (category),
      KEY idx_uploaded_by (uploaded_by)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  `);
  console.log('templates 表创建完成');

  await conn.query(`
    CREATE TABLE user_templates (
      id VARCHAR(36) NOT NULL,
      user_id VARCHAR(36) NOT NULL,
      custom_name VARCHAR(100) DEFAULT '自定义参考图',
      image_url VARCHAR(500) NOT NULL,
      category VARCHAR(30) DEFAULT 'custom',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      KEY idx_user_id (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  `);
  console.log('user_templates 表创建完成');

  await conn.query(`
    CREATE TABLE usage_logs (
      id VARCHAR(36) NOT NULL,
      user_id VARCHAR(36) NOT NULL,
      action VARCHAR(50) NOT NULL,
      details JSON DEFAULT NULL,
      ip_address VARCHAR(45) DEFAULT NULL,
      user_agent VARCHAR(500) DEFAULT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      KEY idx_user_id (user_id),
      KEY idx_action (action),
      KEY idx_created_at (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  `);
  console.log('usage_logs 表创建完成');

  const adminPwd = bcrypt.hashSync('admin123', 10);
  await conn.query(
    'INSERT INTO users (id, username, email, password, role, is_active) VALUES (?, ?, ?, ?, ?, ?)',
    [uuidv4(), 'admin', 'admin@aicam.com', adminPwd, 'admin', 1]
  );
  console.log('管理员账号: admin / admin123');

  const testPwd = bcrypt.hashSync('test123', 10);
  await conn.query(
    'INSERT INTO users (id, username, email, password, role, is_active) VALUES (?, ?, ?, ?, ?, ?)',
    [uuidv4(), 'test', 'test@aicam.com', testPwd, 'user', 1]
  );
  console.log('测试账号: test / test123');

  const [tables] = await conn.query('SHOW TABLES FROM aicam_db');
  console.log('\n=== MySQL数据库初始化全部完成! ===');
  console.log('已创建表:', tables.map(t => Object.values(t)[0]).join(', '));

  await conn.end();
}

init().catch(e => {
  console.error('初始化失败:', e.message);
  process.exit(1);
});
