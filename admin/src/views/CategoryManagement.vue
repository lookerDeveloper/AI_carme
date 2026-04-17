<template>
  <div class="category-management">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>分类Prompt管理</span>
          <el-button type="primary" @click="showCreateDialog" :icon="Plus">新建分类</el-button>
        </div>
      </template>

      <el-alert
        title="提示：每个分类的Prompt将作为该分类下模板的默认AI分析指令。修改分类Prompt会影响所有使用默认值的模板。"
        type="info"
        :closable="false"
        show-icon
        style="margin-bottom: 16px;"
      />

      <el-table :data="categories" v-loading="loading" stripe row-key="id">
        <el-table-column prop="name" label="分类名称" width="120">
          <template #default="{ row }">
            <el-tag :type="getCategoryTagType(row.value)" size="large">{{ row.name }}</el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="value" label="标识值" width="100" />

        <el-table-column prop="description" label="描述" min-width="150" />

        <el-table-column label="分析Prompt预览" min-width="200">
          <template #default="{ row }">
            <div class="prompt-preview" @click="viewFullPrompt(row, 'analysis')">
              {{ truncateText(row.analysis_prompt, 80) }}
              <el-icon class="preview-icon"><View /></el-icon>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="对比Prompt预览" min-width="200">
          <template #default="{ row }">
            <div class="prompt-preview" @click="viewFullPrompt(row, 'comparison')">
              {{ truncateText(row.comparison_prompt, 80) }}
              <el-icon class="preview-icon"><View /></el-icon>
            </div>
          </template>
        </el-table-column>

        <el-table-column prop="updated_at" label="更新时间" width="170">
          <template #default="{ row }">
            {{ formatTime(row.updated_at) }}
          </template>
        </el-table-column>

        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="editCategory(row)">编辑Prompt</el-button>
            <el-button type="danger" link size="small" @click="deleteCategory(row)" :disabled="row.template_count > 0">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 编辑/创建对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="isEdit ? `编辑分类 - ${form.name}` : '新建分类'"
      width="800px"
      top="5vh"
      destroy-on-close
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-position="top">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="分类名称" prop="name">
              <el-input v-model="form.name" placeholder="如：人像、风景、美食" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="标识值（英文）" prop="value">
              <el-input v-model="form.value" placeholder="如：portrait、landscape、food" :disabled="isEdit" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="描述">
          <el-input v-model="form.description" placeholder="分类的简要描述" />
        </el-form-item>

        <el-divider content-position="left">
          <el-icon><EditPen /></el-icon>
          分析Prompt (analysis_prompt)
        </el-divider>

        <el-form-item label="分析Prompt内容" prop="analysis_prompt">
          <el-input
            v-model="form.analysis_prompt"
            type="textarea"
            :rows="10"
            placeholder="输入AI分析时使用的提示词，支持Markdown格式..."
            resize="vertical"
          />
          <div class="form-tip">
            <el-text size="small" type="info">
              此Prompt用于AI分析照片时的指导指令。修改后，所有使用此分类默认Prompt的模板将自动更新。
            </el-text>
          </div>
        </el-form-item>

        <el-divider content-position="left">
          <el-icon><Switch /></el-icon>
          对比Prompt (comparison_prompt)
        </el-divider>

        <el-form-item label="对比Prompt内容" prop="comparison_prompt">
          <el-input
            v-model="form.comparison_prompt"
            type="textarea"
            :rows="10"
            placeholder="输入AI对比参考图时使用的提示词..."
            resize="vertical"
          />
          <div class="form-tip">
            <el-text size="small" type="info">
              此Prompt用于AI将用户拍摄的照片与参考图进行对比分析。
            </el-text>
          </div>
        </el-form-item>

        <el-alert
          v-if="isEdit && form.id"
          title="重置为默认值"
          type="warning"
          show-icon
          :closable="false"
          style="margin-top: 8px;"
        >
          <template #default>
            <el-button size="small" type="warning" @click="resetToDefault('analysis')">重置分析Prompt为默认值</el-button>
            <el-button size="small" type="warning" @click="resetToDefault('comparison')" style="margin-left: 8px;">重置对比Prompt为默认值</el-button>
          </template>
        </el-alert>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">
          {{ isEdit ? '保存修改' : '创建' }}
        </el-button>
      </template>
    </el-dialog>

    <!-- Prompt查看对话框 -->
    <el-dialog
      v-model="previewVisible"
      :title="previewTitle"
      width="700px"
      top="8vh"
    >
      <div class="preview-content">
        <pre>{{ previewContent }}</pre>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, EditPen, Switch, View } from '@element-plus/icons-vue'

const categories = ref([])
const loading = ref(false)
const dialogVisible = ref(false)
const previewVisible = ref(false)
const previewTitle = ref('')
const previewContent = ref('')
const isEdit = ref(false)
const submitting = ref(false)
const formRef = ref()
const currentEditId = ref(null)

const form = ref({
  name: '',
  value: '',
  description: '',
  analysis_prompt: '',
  comparison_prompt: ''
})

const rules = {
  name: [{ required: true, message: '请输入分类名称', trigger: 'blur' }],
  value: [{ required: true, message: '请输入标识值', trigger: 'blur' }],
  analysis_prompt: [{ required: true, message: '请输入分析Prompt', trigger: 'blur' }],
  comparison_prompt: [{ required: true, message: '请输入对比Prompt', trigger: 'blur' }]
}

async function fetchCategories() {
  loading.value = true
  
  try {
    const res = await api.get('/categories')
    
    if (res.success) {
      categories.value = res.data || []
    }
  } catch (error) {
    console.error('获取分类列表失败:', error)
  } finally {
    loading.value = false
  }
}

function showCreateDialog() {
  isEdit.value = false
  currentEditId.value = null
  form.value = {
    name: '',
    value: '',
    description: '',
    analysis_prompt: getDefaultAnalysisPrompt(),
    comparison_prompt: getDefaultComparisonPrompt()
  }
  dialogVisible.value = true
}

function editCategory(category) {
  isEdit.value = true
  currentEditId.value = category.id
  form.value = {
    name: category.name,
    value: category.value,
    description: category.description || '',
    analysis_prompt: category.analysis_prompt || '',
    comparison_prompt: category.comparison_prompt || ''
  }
  dialogVisible.value = true
}

function viewFullPrompt(category, type) {
  const prompt = type === 'analysis' ? category.analysis_prompt : category.comparison_prompt
  previewTitle.value = `${category.name} - ${type === 'analysis' ? '分析Prompt' : '对比Prompt'}`
  previewContent.value = prompt || '(空)'
  previewVisible.value = true
}

function resetToDefault(type) {
  const defaultPrompt = type === 'analysis'
    ? getDefaultAnalysisPrompt(form.value.value)
    : getDefaultComparisonPrompt(form.value.value)

  ElMessageBox.confirm(
    `确定要将${type === 'analysis' ? '分析' : '对比'}Prompt重置为${form.value.value}分类的默认值吗？`,
    '确认重置',
    { confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning' }
  ).then(() => {
    if (type === 'analysis') {
      form.value.analysis_prompt = defaultPrompt
    } else {
      form.value.comparison_prompt = defaultPrompt
    }
    ElMessage.success(`已重置为默认值`)
  }).catch(() => {})
}

async function handleSubmit() {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  submitting.value = true

  try {
    let res
    
    if (isEdit.value) {
      res = await api.put(`/categories/${currentEditId.value}`, form.value)
    } else {
      res = await api.post('/categories', form.value)
    }

    if (res.success) {
      ElMessage.success(res.message)
      dialogVisible.value = false
      fetchCategories()
    }
  } catch (error) {
    console.error(isEdit.value ? '更新失败' : '创建失败:', error)
  } finally {
    submitting.value = false
  }
}

async function deleteCategory(category) {
  try {
    await ElMessageBox.confirm(
      `确定要删除分类"${category.name}"吗？`,
      '确认删除',
      { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' }
    )

    const res = await api.delete(`/categories/${category.id}`)
    
    if (res.success) {
      ElMessage.success(res.message)
      fetchCategories()
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
    }
  }
}

function getCategoryTagType(value) {
  const map = {
    portrait: '',
    landscape: 'success',
    food: 'warning',
    pet: 'danger',
    architecture: 'info',
    street: '',
    still_life: 'success',
    custom: 'info'
  }
  return map[value] || ''
}

function truncateText(text, maxLen) {
  if (!text) return '(空)'
  return text.length > maxLen ? text.substring(0, maxLen) + '...' : text
}

function formatTime(time) {
  if (!time) return '-'
  return new Date(time).toLocaleString('zh-CN')
}

function getDefaultAnalysisPrompt(categoryValue) {
  return `你是一位专业摄影指导专家。请分析这张照片的构图质量，并给出具体、可操作的调整建议。

请从以下维度分析：
1. 主体是否突出
2. 构图是否平衡
3. 光线运用
4. 背景处理
5. 景深控制

请以JSON格式返回，包含以下字段：
{
  "aesthetic_score": 0-100的整数,
  "scene_type": "${categoryValue || 'unknown'}",
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
    "focal_length": "24mm/35mm/50mm/85mm",
    "aperture": "f/2.8/f/4/f/5.6/f/8",
    "exposure_compensation": "+0.3/0/-0.3",
    "iso": 100-800
  }
}

注意：只返回JSON，不要包含其他文字。`
}

function getDefaultComparisonPrompt() {
  return `你是一位专业摄影指导专家。用户希望拍摄出与参考图类似效果的照片。

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
}

onMounted(() => {
  fetchCategories()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.prompt-preview {
  font-size: 12px;
  color: #606266;
  line-height: 1.6;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  transition: background-color 0.2s;
  word-break: break-all;
}

.prompt-preview:hover {
  background-color: #f0f7ff;
  color: #409eff;
}

.preview-icon {
  margin-left: 4px;
  vertical-align: middle;
  font-size: 14px;
  opacity: 0;
  transition: opacity 0.2s;
}

.prompt-preview:hover .preview-icon {
  opacity: 1;
}

.form-tip {
  margin-top: 4px;
}

.preview-content {
  max-height: 500px;
  overflow-y: auto;
  padding: 16px;
  background: #f5f7fa;
  border-radius: 8px;
}

.preview-content pre {
  margin: 0;
  white-space: pre-wrap;
  word-wrap: break-word;
  font-size: 13px;
  line-height: 1.6;
  color: #303133;
  font-family: 'Consolas', 'Monaco', monospace;
}
</style>
