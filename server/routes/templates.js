const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const db = require('../database_mysql');
const { authenticateToken, requireAdmin, logUsage } = require('../middleware/auth');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = process.env.UPLOAD_DIR || 'uploads';
    const fs = require('fs');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueName = `${uuidv4()}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (extname && mimetype) {
      return cb(null, true);
    }
    cb(new Error('只允许上传图片文件 (JPEG, PNG, WebP)'));
  }
});

router.get('/', async (req, res) => {
  try {
    console.log(`🖼️ [${new Date().toLocaleString()}] 查询模板列表`);
    
    const { category, search } = req.query;
    let whereClause = 'is_active = 1';
    const params = [];

    if (category && category !== 'all') {
      whereClause += ' AND category = ?';
      params.push(category);
    }

    if (search) {
      whereClause += ' AND (name LIKE ? OR tags LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }

    const templates = await db.prepare(`
      SELECT * FROM templates 
      WHERE ${whereClause}
      ORDER BY usage_count DESC, created_at DESC
    `).all(...params);

    res.json({
      success: true,
      data: templates
    });
  } catch (error) {
    console.error('获取模板列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取模板列表失败'
    });
  }
});

router.post('/', authenticateToken, requireAdmin, upload.single('thumbnail'), async (req, res) => {
  try {
    console.log(`📤 [${new Date().toLocaleString()}] 管理员上传新模板`);
    
    const { name, category, tags, compositionRules, cameraParams, analysis_prompt, comparison_prompt } = req.body;

    if (!name || !category || !req.file) {
      return res.status(400).json({
        success: false,
        message: '名称、分类和缩略图不能为空'
      });
    }

    const templateId = uuidv4();
    const thumbnailUrl = `/uploads/${req.file.filename}`;

    const categoryData = await db.prepare('SELECT analysis_prompt, comparison_prompt FROM categories WHERE value = ?').get(category);
    const finalAnalysisPrompt = analysis_prompt || categoryData?.analysis_prompt || null;
    const finalComparisonPrompt = comparison_prompt || categoryData?.comparison_prompt || null;

    await db.prepare(`
      INSERT INTO templates (
        id, name, category, thumbnail_url, tags, 
        composition_rules, camera_params, uploaded_by,
        analysis_prompt, comparison_prompt
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      templateId,
      name,
      category,
      thumbnailUrl,
      JSON.stringify(tags ? tags.split(',').map(t => t.trim()) : []),
      JSON.stringify(compositionRules || {}),
      JSON.stringify(cameraParams || {}),
      req.user.id,
      finalAnalysisPrompt,
      finalComparisonPrompt
    );

    logUsage(req.user.id, 'UPLOAD_TEMPLATE', { templateId, name, category });

    console.log(`✅ [${new Date().toLocaleString()}] 模板上传成功: ${name}`);

    res.status(201).json({
      success: true,
      message: '模板上传成功',
      data: {
        id: templateId,
        name,
        category,
        thumbnailUrl
      }
    });
  } catch (error) {
    console.error('上传模板失败:', error);
    res.status(500).json({
      success: false,
      message: '上传失败'
    });
  }
});

router.put('/:id', authenticateToken, requireAdmin, upload.single('thumbnail'), async (req, res) => {
  try {
    console.log(`✏️ [${new Date().toLocaleString()}] 管理员编辑模板: ${req.params.id}`);
    
    const { name, category, tags, compositionRules, cameraParams, analysis_prompt, comparison_prompt } = req.body;
    const template = await db.prepare('SELECT * FROM templates WHERE id = ?').get(req.params.id);

    if (!template) {
      return res.status(404).json({
        success: false,
        message: '模板不存在'
      });
    }

    let thumbnailUrl = template.thumbnail_url;
    if (req.file) {
      thumbnailUrl = `/uploads/${req.file.filename}`;
    }

    const finalCategory = category || template.category;
    let finalAnalysisPrompt = analysis_prompt;
    let finalComparisonPrompt = comparison_prompt;

    if (finalAnalysisPrompt === null) {
      const categoryData = await db.prepare('SELECT analysis_prompt FROM categories WHERE value = ?').get(finalCategory);
      finalAnalysisPrompt = categoryData?.analysis_prompt || null;
    } else if (finalAnalysisPrompt === undefined) {
      finalAnalysisPrompt = template.analysis_prompt;
    }

    if (finalComparisonPrompt === null) {
      const categoryData = await db.prepare('SELECT comparison_prompt FROM categories WHERE value = ?').get(finalCategory);
      finalComparisonPrompt = categoryData?.comparison_prompt || null;
    } else if (finalComparisonPrompt === undefined) {
      finalComparisonPrompt = template.comparison_prompt;
    }

    await db.prepare(`
      UPDATE templates 
      SET name = ?, category = ?, thumbnail_url = ?, 
          tags = ?, composition_rules = ?, camera_params = ?,
          analysis_prompt = ?, comparison_prompt = ?,
          updated_at = NOW()
      WHERE id = ?
    `).run(
      name || template.name,
      finalCategory,
      thumbnailUrl,
      JSON.stringify(tags ? tags.split(',').map(t => t.trim()) : JSON.parse(template.tags)),
      JSON.stringify(compositionRules || JSON.parse(template.composition_rules)),
      JSON.stringify(cameraParams || JSON.parse(template.camera_params)),
      finalAnalysisPrompt,
      finalComparisonPrompt,
      req.params.id
    );

    logUsage(req.user.id, 'UPDATE_TEMPLATE', { templateId: req.params.id });

    res.json({
      success: true,
      message: '模板更新成功'
    });
  } catch (error) {
    console.error('更新模板失败:', error);
    res.status(500).json({
      success: false,
      message: '更新失败'
    });
  }
});

router.delete('/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    console.log(`🗑️ [${new Date().toLocaleString()}] 管理员删除模板: ${req.params.id}`);
    
    const template = await db.prepare('SELECT * FROM templates WHERE id = ?').get(req.params.id);

    if (!template) {
      return res.status(404).json({
        success: false,
        message: '模板不存在'
      });
    }

    await db.prepare('UPDATE templates SET is_active = 0 WHERE id = ?').run(req.params.id);

    logUsage(req.user.id, 'DELETE_TEMPLATE', { templateId: req.params.id, name: template.name });

    res.json({
      success: true,
      message: '模板已删除'
    });
  } catch (error) {
    console.error('删除模板失败:', error);
    res.status(500).json({
      success: false,
      message: '删除失败'
    });
  }
});

router.post('/user-custom', authenticateToken, upload.single('image'), async (req, res) => {
  try {
    console.log(`📷 [${new Date().toLocaleString()}] 用户上传自定义参考图`);
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: '请选择图片'
      });
    }

    const customId = uuidv4();
    const imageUrl = `/uploads/${req.file.filename}`;
    const { customName, category } = req.body;

    await db.prepare(`
      INSERT INTO user_templates (id, user_id, custom_name, image_url, category)
      VALUES (?, ?, ?, ?, ?)
    `).run(customId, req.user.id, customName || '自定义参考图', imageUrl, category || 'custom');

    logUsage(req.user.id, 'UPLOAD_CUSTOM_TEMPLATE', { customId });

    res.status(201).json({
      success: true,
      message: '自定义参考图上传成功',
      data: {
        id: customId,
        imageUrl,
        name: customName || '自定义参考图'
      }
    });
  } catch (error) {
    console.error('上传自定义参考图失败:', error);
    res.status(500).json({
      success: false,
      message: '上传失败'
    });
  }
});

router.get('/user-custom/my', authenticateToken, async (req, res) => {
  try {
    const customs = await db.prepare(`
      SELECT * FROM user_templates 
      WHERE user_id = ?
      ORDER BY created_at DESC
    `).all(req.user.id);

    res.json({ success: true, data: customs });
  } catch (error) {
    console.error('获取自定义模板失败:', error);
    res.status(500).json({
      success: false,
      message: '获取失败'
    });
  }
});

module.exports = router;
