const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'ROOT',
  database: process.env.DB_NAME || 'aicam_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  charset: 'utf8mb4'
});

class Database {
  constructor() {
    this.pool = pool;
    this._initialized = false;
  }

  async init() {
    if (this._initialized) return;
    try {
      const conn = await this.pool.getConnection();
      await conn.ping();
      conn.release();
      console.log('✅ [MySQL] 数据库连接成功');
      this._initialized = true;
    } catch (error) {
      console.error('❌ [MySQL] 数据库连接失败:', error.message);
      throw error;
    }
  }

  prepare(sql) {
    return {
      get: async (...params) => {
        const [rows] = await this.pool.execute(sql, params);
        return rows[0] || null;
      },
      all: async (...params) => {
        const [rows] = await this.pool.execute(sql, params);
        return rows;
      },
      run: async (...params) => {
        const [result] = await this.pool.execute(sql, params);
        return {
          affectedRows: result.affectedRows,
          insertId: result.insertId,
          changes: result.affectedRows
        };
      }
    };
  }

  async query(sql, params = []) {
    const [rows] = await this.pool.execute(sql, params);
    return rows;
  }

  async close() {
    await this.pool.end();
  }
}

const db = new Database();

async function initDatabase() {
  await db.init();

  const adminExists = await db.prepare(
    "SELECT id FROM users WHERE username = 'admin'"
  ).get();
  
  if (!adminExists) {
    const hashedPassword = bcrypt.hashSync('admin123', 10);
    await db.prepare(`
      INSERT INTO users (id, username, email, password, role, is_active)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(uuidv4(), 'admin', 'admin@aicam.com', hashedPassword, 'admin', 1);
    console.log('✅ [初始化] 默认管理员账号已创建: admin / admin123');
  }

  const testExists = await db.prepare(
    "SELECT id FROM users WHERE username = 'test'"
  ).get();
  
  if (!testExists) {
    const hashedPassword = bcrypt.hashSync('test123', 10);
    await db.prepare(`
      INSERT INTO users (id, username, email, password, role, is_active)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(uuidv4(), 'test', 'test@aicam.com', hashedPassword, 'user', 1);
    console.log('✅ [初始化] 测试用户账号已创建: test / test123');
  }
}

module.exports = db;
module.exports.initDatabase = initDatabase;
