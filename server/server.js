const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const { initDatabase } = require('./database_mysql');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const templateRoutes = require('./routes/templates');
const categoryRoutes = require('./routes/categories');
const analyticsRoutes = require('./routes/analytics');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

console.log(`🚀 [${new Date().toLocaleString()}] 服务器启动中...`);
console.log(`📂 上传目录: ${path.join(__dirname, 'uploads')}`);

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/templates', templateRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/analytics', analyticsRoutes);

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'AICam Coach API',
    version: '1.0.0',
    database: 'MySQL'
  });
});

app.use((err, req, res, next) => {
  console.error(`❌ [${new Date().toLocaleString()}] 服务器错误:`, err.message);
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: '服务器内部错误',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

app.use((req, res) => {
  console.log(`⚠️ [${new Date().toLocaleString()}] 未找到路由: ${req.method} ${req.path}`);
  res.status(404).json({
    success: false,
    message: '接口不存在'
  });
});

async function startServer() {
  try {
    await initDatabase();
    
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`\n✅ [${new Date().toLocaleString()}] AICam Coach API 服务已启动 (MySQL模式)`);
      console.log(`📍 地址: http://0.0.0.0:${PORT}`);
      console.log(`📍 局域网: http://10.56.193.133:${PORT}`);
      console.log(`🏥 健康检查: http://10.56.193.133:${PORT}/api/health`);
      console.log(`📝 认证接口: http://10.56.193.133:${PORT}/api/auth`);
      console.log(`👥 用户接口: http://10.56.193.133:${PORT}/api/users`);
      console.log(`🖼️ 模板接口: http://10.56.193.133:${PORT}/api/templates`);
      console.log(`📊 统计接口: http://10.56.193.133:${PORT}/api/analytics\n`);
    });
  } catch (error) {
    console.error('❌ 服务器启动失败:', error.message);
    process.exit(1);
  }
}

startServer();
