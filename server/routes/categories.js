const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const db = require('../database_mysql');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// 获取所有分类（公开）
router.get('/', async (req, res) => {
  try {
    console.log(`📂 [${new Date().toLocaleString()}] 查询分类列表`);
    
    const categories = await db.prepare(`
      SELECT id, name, value, description, is_active, created_at, updated_at
      FROM categories
      ORDER BY name ASC
    `).all();

    res.json({
      success: true,
      data: categories
    });
  } catch (error) {
    console.error('获取分类列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取分类列表失败'
    });
  }
});

// 获取单个分类详情（公开）
router.get('/:value', async (req, res) => {
  try {
    console.log(`📂 [${new Date().toLocaleString()}] 查询分类详情: ${req.params.value}`);
    
    const category = await db.prepare(`
      SELECT id, name, value, description, analysis_prompt, comparison_prompt, is_active, created_at, updated_at
      FROM categories
      WHERE value = ?
    `).get(req.params.value);

    if (!category) {
      return res.status(404).json({
        success: false,
        message: '分类不存在'
      });
    }

    res.json({
      success: true,
      data: category
    });
  } catch (error) {
    console.error('获取分类详情失败:', error);
    res.status(500).json({
      success: false,
      message: '获取分类详情失败'
    });
  }
});

// 创建分类（仅管理员）
router.post('/', authenticateToken, requireAdmin, async (req, res) => {
  try {
    console.log(`📤 [${new Date().toLocaleString()}] 管理员创建新分类`);
    
    const { name, value, description } = req.body;

    if (!name || !value) {
      return res.status(400).json({
        success: false,
        message: '分类名称和值不能为空'
      });
    }

    const existing = await db.prepare('SELECT id FROM categories WHERE value = ?').get(value);
    if (existing) {
      return res.status(400).json({
        success: false,
        message: '分类值已存在'
      });
    }

    const categoryId = uuidv4();
    const defaultAnalysisPrompt = getDefaultAnalysisPrompt(value);
    const defaultComparisonPrompt = getDefaultComparisonPrompt(value);

    await db.prepare(`
      INSERT INTO categories (
        id, name, value, description, analysis_prompt, comparison_prompt
      ) VALUES (?, ?, ?, ?, ?, ?)
    `).run(
      categoryId,
      name,
      value,
      description || '',
      defaultAnalysisPrompt,
      defaultComparisonPrompt
    );

    console.log(`✅ [${new Date().toLocaleString()}] 分类创建成功: ${name}`);

    res.status(201).json({
      success: true,
      message: '分类创建成功',
      data: {
        id: categoryId,
        name,
        value
      }
    });
  } catch (error) {
    console.error('创建分类失败:', error);
    res.status(500).json({
      success: false,
      message: '创建分类失败'
    });
  }
});

// 更新分类（仅管理员）
router.put('/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    console.log(`✏️ [${new Date().toLocaleString()}] 管理员编辑分类: ${req.params.id}`);
    
    const { name, value, description, analysis_prompt, comparison_prompt } = req.body;
    
    const category = await db.prepare('SELECT * FROM categories WHERE id = ?').get(req.params.id);
    if (!category) {
      return res.status(404).json({
        success: false,
        message: '分类不存在'
      });
    }

    await db.prepare(`
      UPDATE categories 
      SET name = ?, 
          value = ?, 
          description = ?,
          analysis_prompt = ?,
          comparison_prompt = ?,
          updated_at = NOW()
      WHERE id = ?
    `).run(
      name || category.name,
      value || category.value,
      description !== undefined ? description : category.description,
      analysis_prompt !== undefined ? analysis_prompt : category.analysis_prompt,
      comparison_prompt !== undefined ? comparison_prompt : category.comparison_prompt,
      req.params.id
    );

    res.json({
      success: true,
      message: '分类更新成功'
    });
  } catch (error) {
    console.error('更新分类失败:', error);
    res.status(500).json({
      success: false,
      message: '更新分类失败'
    });
  }
});

// 删除分类（仅管理员）
router.delete('/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    console.log(`🗑️ [${new Date().toLocaleString()}] 管理员删除分类: ${req.params.id}`);
    
    const category = await db.prepare('SELECT * FROM categories WHERE id = ?').get(req.params.id);
    if (!category) {
      return res.status(404).json({
        success: false,
        message: '分类不存在'
      });
    }

    const templateCount = await db.prepare('SELECT COUNT(*) as count FROM templates WHERE category = ?').get(category.value);
    if (templateCount.count > 0) {
      return res.status(400).json({
        success: false,
        message: `该分类下有 ${templateCount.count} 个模板，无法删除`
      });
    }

    await db.prepare('DELETE FROM categories WHERE id = ?').run(req.params.id);

    res.json({
      success: true,
      message: '分类已删除'
    });
  } catch (error) {
    console.error('删除分类失败:', error);
    res.status(500).json({
      success: false,
      message: '删除分类失败'
    });
  }
});

// 获取分类的默认prompt模板（辅助函数）
function getDefaultAnalysisPrompt(categoryValue) {
  const prompts = {
    portrait: `你是一位专业人像摄影指导专家。请分析这张人像照片的构图质量，并给出具体、可操作的调整建议。

【人像摄影核心维度】
1. 主体突出度：人物是否在画面中足够突出，背景是否有干扰元素
2. 人物位置：是否符合三分法或黄金分割比例
3. 姿态自然度：人物姿态是否自然放松
4. 面部表情：表情是否到位，眼神是否传神
5. 光线运用：面部受光是否均匀
6. 景深控制：背景虚化是否适度
7. 拍摄角度：机位高度是否适合人物特点

请以JSON格式返回，包含以下字段：
{
  "aesthetic_score": 0-100的整数,
  "scene_type": "portrait",
  "issues": ["问题1", "问题2"],
  "suggestions": ["建议1", "建议2"],
  "camera_adjustments": {
    "move_direction": "left/right/up/down/forward/backward/none",
    "move_amount": "small/medium/large",
    "tilt_adjustment": "tilt_up/tilt_down/level",
    "zoom_adjustment": "zoom_in/zoom_out/none"
  },
  "pose_adjustments": ["模特姿势调整建议1"],
  "recommended_params": {
    "focal_length": "35mm/50mm/85mm/135mm",
    "aperture": "f/1.4/f/2.0/f/2.8/f/4.0",
    "exposure_compensation": "+0.3/0/-0.3",
    "iso": 100-800
  }
}

注意：只返回JSON，不要包含其他文字。`,

    landscape: `你是一位专业风景摄影指导专家。请分析这张风景照片的构图质量，并给出具体、可操作的调整建议。

【风景摄影核心维度】
1. 构图法则应用：三分法/对称/框架/引导线等
2. 地平线位置：是否水平，位置是否恰当
3. 层次感：前景/中景/远景是否分明
4. 主体明确性：视觉中心是否清晰
5. 光线时机：是否抓住黄金时段
6. 色彩表现：色彩搭配是否和谐

请以JSON格式返回，包含以下字段：
{
  "aesthetic_score": 0-100的整数,
  "scene_type": "landscape",
  "issues": ["问题1", "问题2"],
  "suggestions": ["建议1", "建议2"],
  "camera_adjustments": {
    "move_direction": "left/right/up/down/forward/backward/none",
    "move_amount": "small/medium/large",
    "tilt_adjustment": "tilt_up/tilt_down/level",
    "zoom_adjustment": "zoom_in/zoom_out/none"
  },
  "pose_adjustments": [],
  "recommended_params": {
    "focal_length": "16mm/24mm/35mm/50mm",
    "aperture": "f/8/f/11/f/16/f/22",
    "exposure_compensation": "+0.3/0/-0.3",
    "iso": 100-400
  }
}

注意：只返回JSON，不要包含其他文字。`,

    food: `你是一位专业美食摄影指导专家。请分析这张美食照片的构图质量，并给出具体、可操作的调整建议。

【美食摄影核心维度】
1. 主体突出：食物是否占据视觉中心
2. 拍摄角度：俯拍/45度角/平视是否适合
3. 光线质量：光线是否柔和
4. 背景处理：是否干净简洁
5. 色彩表现：食物颜色是否诱人

请以JSON格式返回，包含以下字段：
{
  "aesthetic_score": 0-100的整数,
  "scene_type": "food",
  "issues": ["问题1", "问题2"],
  "suggestions": ["建议1", "建议2"],
  "camera_adjustments": {
    "move_direction": "left/right/up/down/forward/backward/none",
    "move_amount": "small/medium/large",
    "tilt_adjustment": "tilt_up/tilt_down/level",
    "zoom_adjustment": "zoom_in/zoom_out/none"
  },
  "pose_adjustments": [],
  "recommended_params": {
    "focal_length": "35mm/50mm/85mm/100mm",
    "aperture": "f/2.8/f/4/f/5.6/f/8",
    "exposure_compensation": "+0.3/+0.7/0",
    "iso": 100-800
  }
}

注意：只返回JSON，不要包含其他文字。`,

    pet: `你是一位专业宠物摄影指导专家。请分析这张宠物照片的构图质量，并给出具体、可操作的调整建议。

【宠物摄影核心维度】
1. 眼神捕捉：宠物的眼神是否清晰锐利
2. 拍摄角度：是否与宠物处于同一水平线
3. 主体突出：宠物是否占据主要画面
4. 动作姿态：是否捕捉到自然姿态
5. 光线运用：面部是否有充足光线

请以JSON格式返回，包含以下字段：
{
  "aesthetic_score": 0-100的整数,
  "scene_type": "pet",
  "issues": ["问题1", "问题2"],
  "suggestions": ["建议1", "建议2"],
  "camera_adjustments": {
    "move_direction": "left/right/up/down/forward/backward/none",
    "move_amount": "small/medium/large",
    "tilt_adjustment": "tilt_up/tilt_down/level",
    "zoom_adjustment": "zoom_in/zoom_out/none"
  },
  "pose_adjustments": ["如何吸引宠物注意力"],
  "recommended_params": {
    "focal_length": "50mm/85mm/105mm/135mm",
    "aperture": "f/1.4/f/2.0/f/2.8/f/4",
    "exposure_compensation": "+0.3/0/-0.3",
    "iso": 100-1600
  }
}

注意：只返回JSON，不要包含其他文字。`,

    architecture: `你是一位专业建筑摄影指导专家。请分析这张建筑照片的构图质量，并给出具体、可操作的调整建议。

【建筑摄影核心维度】
1. 透视控制：垂直线是否垂直
2. 对称与平衡：建筑对称轴是否在画面中央
3. 线条引导：建筑线条是否形成引导
4. 拍摄角度：仰拍/平视/俯拍是否恰当
5. 光线时机：建筑受光面是否美观

请以JSON格式返回，包含以下字段：
{
  "aesthetic_score": 0-100的整数,
  "scene_type": "architecture",
  "issues": ["问题1", "问题2"],
  "suggestions": ["建议1", "建议2"],
  "camera_adjustments": {
    "move_direction": "left/right/up/down/forward/backward/none",
    "move_amount": "small/medium/large",
    "tilt_adjustment": "tilt_up/tilt_down/level",
    "zoom_adjustment": "zoom_in/zoom_out/none"
  },
  "pose_adjustments": [],
  "recommended_params": {
    "focal_length": "16mm/24mm/35mm/50mm",
    "aperture": "f/8/f/11/f/16",
    "exposure_compensation": "0/-0.3/-0.7",
    "iso": 100-400
  }
}

注意：只返回JSON，不要包含其他文字。`,

    street: `你是一位专业街头摄影指导专家。请分析这张街拍照片的构图质量，并给出具体、可操作的调整建议。

【街头摄影核心维度】
1. 决定性瞬间：是否捕捉到有趣的瞬间
2. 主体明确：视觉中心是否清晰
3. 背景处理：背景是否有意义
4. 构图法则：三分法/框架构图/引导线的运用
5. 故事性：画面是否传达故事或情感

请以JSON格式返回，包含以下字段：
{
  "aesthetic_score": 0-100的整数,
  "scene_type": "street",
  "issues": ["问题1", "问题2"],
  "suggestions": ["建议1", "建议2"],
  "camera_adjustments": {
    "move_direction": "left/right/up/down/forward/backward/none",
    "move_amount": "small/medium/large",
    "tilt_adjustment": "tilt_up/tilt_down/level",
    "zoom_adjustment": "zoom_in/zoom_out/none"
  },
  "pose_adjustments": [],
  "recommended_params": {
    "focal_length": "28mm/35mm/50mm/85mm",
    "aperture": "f/2.8/f/4/f/5.6/f/8",
    "exposure_compensation": "0/-0.3/-0.7",
    "iso": 100-1600
  }
}

注意：只返回JSON，不要包含其他文字。`,

    still_life: `你是一位专业静物摄影指导专家。请分析这张静物照片的构图质量，并给出具体、可操作的调整建议。

【静物摄影核心维度】
1. 主体布局：主体摆放位置是否符合构图法则
2. 道具搭配：辅助道具是否与主题协调
3. 光线质量：光线软硬、方向、色温
4. 背景选择：背景材质、颜色是否搭配
5. 色彩搭配：主体与背景的色彩关系

请以JSON格式返回，包含以下字段：
{
  "aesthetic_score": 0-100的整数,
  "scene_type": "still_life",
  "issues": ["问题1", "问题2"],
  "suggestions": ["建议1", "建议2"],
  "camera_adjustments": {
    "move_direction": "left/right/up/down/forward/backward/none",
    "move_amount": "small/medium/large",
    "tilt_adjustment": "tilt_up/tilt_down/level",
    "zoom_adjustment": "zoom_in/zoom_out/none"
  },
  "pose_adjustments": [],
  "recommended_params": {
    "focal_length": "50mm/85mm/100mm/105mm",
    "aperture": "f/4/f/5.6/f/8/f/11",
    "exposure_compensation": "+0.3/0/-0.3",
    "iso": 100-400
  }
}

注意：只返回JSON，不要包含其他文字。`,

    custom: `你是一位专业摄影指导专家。请分析这张照片的构图质量，并给出具体、可操作的调整建议。

请从以下维度分析：
1. 主体是否突出
2. 构图是否平衡
3. 光线运用
4. 背景处理
5. 景深控制

请以JSON格式返回，包含以下字段：
{
  "aesthetic_score": 0-100的整数,
  "scene_type": "unknown",
  "issues": ["问题1", "问题2"],
  "suggestions": ["建议1", "建议2"],
  "camera_adjustments": {
    "move_direction": "left/right/up/down/forward/backward/none",
    "move_amount": "small/medium/large",
    "tilt_adjustment": "tilt_up/tilt_down/level",
    "zoom_adjustment": "zoom_in/zoom_out/none"
  },
  "pose_adjustments": ["模特调整建议1"],
  "recommended_params": {
    "focal_length": "24mm/35mm/50mm/85mm",
    "aperture": "f/2.8/f/4/f/5.6/f/8",
    "exposure_compensation": "+0.3/0/-0.3",
    "iso": 100-800
  }
}

注意：只返回JSON，不要包含其他文字。`
  };

  return prompts[categoryValue] || prompts.custom;
}

function getDefaultComparisonPrompt(categoryValue) {
  const prompts = {
    portrait: `你是一位专业人像摄影指导专家。用户希望拍摄出与参考图类似效果的人像照片。

第一张图是参考图，第二张图是当前画面。

【人像对比核心维度】
1. 姿势匹配度：身体朝向、重心分布、肢体角度是否一致
2. 面部表情：表情类型、眼神方向
3. 人物位置：在画面中的位置比例
4. 拍摄角度：机位高低差异
5. 拍摄距离：全身/半身/特写的景别匹配
6. 光线方向：主光方向、阴影位置

请以JSON格式返回：
{
  "similarity_score": 0-100的整数,
  "composition_gap": {
    "subject_position_diff": "左侧偏多/右侧偏多/基本一致",
    "angle_diff": "需要降低机位/需要抬高机位/基本一致",
    "distance_diff": "需要靠近/需要拉远/基本一致"
  },
  "steps": ["步骤1", "步骤2", "步骤3"],
  "current_adjustment": "当前最需要调整的是什么"
}

注意：只返回JSON，不要包含其他文字。`,

    landscape: `你是一位专业风景摄影指导专家。用户希望拍摄出与参考图类似效果的风景照片。

第一张图是参考图，第二张图是当前画面。

【风景对比核心维度】
1. 构图结构：构图法则应用是否一致
2. 地平线位置：地平线高度是否匹配
3. 层次关系：前景/中景/远景的分布和比例
4. 拍摄高度：机位高低差异
5. 拍摄距离：广角程度、视野范围
6. 光线方向：光源方向是否一致

请以JSON格式返回：
{
  "similarity_score": 0-100的整数,
  "composition_gap": {
    "subject_position_diff": "左侧偏多/右侧偏多/基本一致",
    "angle_diff": "需要降低机位/需要抬高机位/基本一致",
    "distance_diff": "需要靠近/需要拉远/基本一致"
  },
  "steps": ["步骤1", "步骤2", "步骤3"],
  "current_adjustment": "当前最需要调整的是什么"
}

注意：只返回JSON，不要包含其他文字。`,

    food: `你是一位专业美食摄影指导专家。用户希望拍摄出与参考图类似效果的美食照片。

第一张图是参考图，第二张图是当前画面。

【美食对比核心维度】
1. 拍摄角度：俯拍/斜拍/平视的角度差异
2. 食物摆放：食物在画面中的位置、角度
3. 餐具搭配：盘子类型、餐具摆放位置
4. 光线方向：主光方向、光线软硬程度
5. 背景风格：背景颜色、材质、道具使用

请以JSON格式返回：
{
  "similarity_score": 0-100的整数,
  "composition_gap": {
    "subject_position_diff": "左侧偏多/右侧偏多/基本一致",
    "angle_diff": "需要降低机位/需要抬高机位/基本一致",
    "distance_diff": "需要靠近/需要拉远/基本一致"
  },
  "steps": ["步骤1", "步骤2", "步骤3"],
  "current_adjustment": "当前最需要调整的是什么"
}

注意：只返回JSON，不要包含其他文字。`,

    pet: `你是一位专业宠物摄影指导专家。用户希望拍摄出与参考图类似效果的宠物照片。

第一张图是参考图，第二张图是当前画面。

【宠物对比核心维度】
1. 拍摄角度：机位高度（俯视/平视宠物/仰视）
2. 宠物位置：在画面中的位置比例
3. 眼神方向：宠物视线方向
4. 姿态匹配：宠物姿势（坐/卧/站立/奔跑）
5. 拍摄距离：特写/半身/全身

请以JSON格式返回：
{
  "similarity_score": 0-100的整数,
  "composition_gap": {
    "subject_position_diff": "左侧偏多/右侧偏多/基本一致",
    "angle_diff": "需要降低机位/需要抬高机位/基本一致",
    "distance_diff": "需要靠近/需要拉远/基本一致"
  },
  "steps": ["步骤1", "步骤2", "步骤3"],
  "current_adjustment": "当前最需要调整的是什么"
}

注意：只返回JSON，不要包含其他文字。`,

    architecture: `你是一位专业建筑摄影指导专家。用户希望拍摄出与参考图类似效果的建筑照片。

第一张图是参考图，第二张图是当前画面。

【建筑对比核心维度】
1. 拍摄角度：仰视/平视/俯视的角度差异
2. 透视控制：垂直线是否平行
3. 对称轴位置：建筑中心在画面中的位置
4. 构图比例：建筑在画面中的占比
5. 光线方向：建筑受光面是否一致

请以JSON格式返回：
{
  "similarity_score": 0-100的整数,
  "composition_gap": {
    "subject_position_diff": "左侧偏多/右侧偏多/基本一致",
    "angle_diff": "需要降低机位/需要抬高机位/基本一致",
    "distance_diff": "需要靠近/需要拉远/基本一致"
  },
  "steps": ["步骤1", "步骤2", "步骤3"],
  "current_adjustment": "当前最需要调整的是什么"
}

注意：只返回JSON，不要包含其他文字。`,

    street: `你是一位专业街头摄影指导专家。用户希望拍摄出与参考图类似效果的街拍照片。

第一张图是参考图，第二张图是当前画面。

【街拍对比核心维度】
1. 拍摄角度：视角高低、拍摄方向
2. 主体位置：人物或主体在画面中的位置
3. 背景元素：背景建筑/环境是否匹配
4. 光线条件：光线方向、光影效果
5. 构图方式：构图法则应用是否一致

请以JSON格式返回：
{
  "similarity_score": 0-100的整数,
  "composition_gap": {
    "subject_position_diff": "左侧偏多/右侧偏多/基本一致",
    "angle_diff": "需要降低机位/需要抬高机位/基本一致",
    "distance_diff": "需要靠近/需要拉远/基本一致"
  },
  "steps": ["步骤1", "步骤2", "步骤3"],
  "current_adjustment": "当前最需要调整的是什么"
}

注意：只返回JSON，不要包含其他文字。`,

    still_life: `你是一位专业静物摄影指导专家。用户希望拍摄出与参考图类似效果的静物照片。

第一张图是参考图，第二张图是当前画面。

【静物对比核心维度】
1. 主体位置：物品在画面中的位置、角度
2. 摆放方式：物品角度、朝向、排列方式
3. 拍摄角度：俯拍/斜拍/平视的角度差异
4. 光线方向：主光方向、光线软硬程度
5. 背景风格：背景颜色、材质、纹理

请以JSON格式返回：
{
  "similarity_score": 0-100的整数,
  "composition_gap": {
    "subject_position_diff": "左侧偏多/右侧偏多/基本一致",
    "angle_diff": "需要降低机位/需要抬高机位/基本一致",
    "distance_diff": "需要靠近/需要拉远/基本一致"
  },
  "steps": ["步骤1", "步骤2", "步骤3"],
  "current_adjustment": "当前最需要调整的是什么"
}

注意：只返回JSON，不要包含其他文字。`,

    custom: `你是一位专业摄影指导专家。用户希望拍摄出与参考图类似效果的照片。

第一张图是参考图，第二张图是当前画面。

请对比两张图，分析以下差异：
1. 构图差异（主体位置、视角、景别）
2. 光线差异
3. 色调差异
4. 拍摄角度差异

请给出具体调整建议，让用户逐步接近参考图效果。

以JSON格式返回：
{
  "similarity_score": 0-100的整数,
  "composition_gap": {
    "subject_position_diff": "左侧偏多/右侧偏多/基本一致",
    "angle_diff": "需要降低机位/需要抬高机位/基本一致",
    "distance_diff": "需要靠近/需要拉远/基本一致"
  },
  "steps": ["步骤1", "步骤2", "步骤3"],
  "current_adjustment": "当前最需要调整的是什么"
}

注意：只返回JSON，不要包含其他文字。`
  };

  return prompts[categoryValue] || prompts.custom;
}

module.exports = router;