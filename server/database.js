const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const DB_DIR = path.join(__dirname, 'data');
const DB_FILE = path.join(DB_DIR, 'aicam.json');

function ensureDir() {
  if (!fs.existsSync(DB_DIR)) {
    fs.mkdirSync(DB_DIR, { recursive: true });
  }
}

function readDb() {
  ensureDir();
  if (!fs.existsSync(DB_FILE)) {
    return getDefaultDb();
  }
  try {
    const content = fs.readFileSync(DB_FILE, 'utf8');
    return JSON.parse(content);
  } catch (e) {
    console.error('读取数据库失败:', e);
    return getDefaultDb();
  }
}

function writeDb(data) {
  ensureDir();
  fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf8');
}

function getDefaultDb() {
  return {
    users: [],
    templates: [],
    userTemplates: [],
    usageLogs: []
  };
}

function initDefaultUsers() {
  const db = readDb();
  
  const adminExists = db.users.some(u => u.role === 'admin');
  if (!adminExists) {
    const hashedPassword = bcrypt.hashSync('admin123', 10);
    db.users.push({
      id: uuidv4(),
      username: 'admin',
      email: 'admin@aicam.com',
      password: hashedPassword,
      role: 'admin',
      avatar: null,
      is_active: 1,
      usage_count: 0,
      last_login_at: null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });
    console.log('✅ [初始化] 默认管理员账号已创建: admin / admin123');
  }

  const testExists = db.users.some(u => u.username === 'test');
  if (!testExists) {
    const hashedPassword = bcrypt.hashSync('test123', 10);
    db.users.push({
      id: uuidv4(),
      username: 'test',
      email: 'test@aicam.com',
      password: hashedPassword,
      role: 'user',
      avatar: null,
      is_active: 1,
      usage_count: 0,
      last_login_at: null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });
    console.log('✅ [初始化] 测试用户账号已创建: test / test123');
  }

  writeDb(db);
}

const db = {
  prepare: (sql) => {
    return {
      get: (...params) => executeQuery(sql, 'get', params),
      all: (...params) => executeQuery(sql, 'all', params),
      run: (...params) => executeQuery(sql, 'run', params)
    };
  }
};

function executeQuery(sql, type, params) {
  const database = readDb();
  const normalizedSql = sql.toLowerCase().trim();

  if (normalizedSql.startsWith('select')) {
    if (normalizedSql.includes('count(*)')) {
      const count = countQuery(database, normalizedSql, params);
      return { count };
    }
    
    let results = filterQuery(database, normalizedSql, params);
    
    if (type === 'get') {
      return results[0] || null;
    }
    return results;
  }

  if (normalizedSql.startsWith('insert')) {
    return insertQuery(database, normalizedSql, params);
  }

  if (normalizedSql.startsWith('update')) {
    return updateQuery(database, normalizedSql, params);
  }

  return { changes: 0 };
}

function countQuery(db, sql, params) {
  const table = getTableName(sql);
  let data = db[table] || [];
  
  if (sql.includes('where')) {
    data = filterData(data, sql, params);
  }
  
  return data.length;
}

function filterQuery(db, sql, params) {
  const table = getTableName(sql);
  let data = db[table] || [];
  
  if (sql.includes('where')) {
    data = filterData(data, sql, params);
  }
  
  if (sql.includes('order by')) {
    const orderMatch = sql.match(/order\s+by\s+(\w+)(?:\s+(asc|desc))?/i);
    if (orderMatch) {
      const field = orderMatch[1];
      const desc = orderMatch[2]?.toLowerCase() === 'desc';
      data.sort((a, b) => {
        if (desc) return a[field] > b[field] ? -1 : 1;
        return a[field] > b[field] ? 1 : -1;
      });
    }
  }
  
  if (sql.includes('limit')) {
    const limitMatch = sql.match(/limit\s+(\d+)(?:\s+offset\s+(\d+))?/i);
    if (limitMatch) {
      const limit = parseInt(limitMatch[1]);
      const offset = parseInt(limitMatch[2]) || 0;
      data = data.slice(offset, offset + limit);
    }
  }
  
  return data;
}

function filterData(data, sql, params) {
  const whereMatch = sql.match(/where\s+(.+?)(?:\s+order|\s+limit|\s*$)/i);
  if (!whereMatch) return data;
  
  const whereClause = whereMatch[1];
  const conditions = whereMatch[1].split(/\s+and\s+/i);
  
  let result = data;
  let paramIndex = 0;
  
  for (const condition of conditions) {
    const likeMatch = condition.match(/(\w+)\s+like\s+\?/i);
    const equalsMatch = condition.match(/(\w+)\s*=\s*\?/i);
    
    if (likeMatch) {
      const field = likeMatch[1];
      const pattern = `%${params[paramIndex++]}%`;
      result = result.filter(item => 
        item[field] && item[field].toLowerCase().includes(pattern.toLowerCase())
      );
    } else if (equalsMatch) {
      const field = equalsMatch[1];
      const value = params[paramIndex++];
      result = result.filter(item => item[field] == value);
    }
  }
  
  return result;
}

function insertQuery(db, sql, params) {
  const table = getTableName(sql);
  const fields = extractFields(sql);
  
  const obj = {};
  fields.forEach((field, i) => {
    obj[field] = params[i];
  });
  
  if (!db[table]) db[table] = [];
  db[table].push(obj);
  writeDb(db);
  
  return { changes: 1, lastInsertRowid: db[table].length };
}

function updateQuery(db, sql, params) {
  const table = getTableName(sql);
  
  const setMatch = sql.match(/set\s+(.+?)\s+where/i);
  const whereMatch = sql.match(/where\s+(.+)$/i);
  
  if (!setMatch || !whereMatch) return { changes: 0 };
  
  const setFields = setMatch[1].split(',').map(s => s.trim());
  const updates = [];
  
  for (const sf of setFields) {
    const match = sf.match(/(\w+)\s*=\s*\?/);
    if (match) updates.push({ field: match[1], value: params[updates.length] });
  }
  
  const whereClause = whereMatch[1];
  const whereField = whereClause.split('=')[0].trim();
  const whereValue = params[params.length - 1];
  
  let changes = 0;
  db[table] = db[table].map(item => {
    if (item[whereField] == whereValue) {
      updates.forEach(u => item[u.field] = u.value);
      changes++;
    }
    return item;
  });
  
  writeDb(db);
  return { changes };
}

function getTableName(sql) {
  const tables = ['users', 'templates', 'user_templates', 'usage_logs'];
  for (const t of tables) {
    if (sql.includes(t)) return t;
  }
  return 'users';
}

function extractFields(sql) {
  const match = sql.match(/\(([^)]+)\)\s*values/i);
  if (!match) return [];
  return match[1].split(',').map(s => s.trim());
}

module.exports = db;

initDefaultUsers();
