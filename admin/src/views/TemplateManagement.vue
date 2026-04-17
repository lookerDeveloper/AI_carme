<template>
  <div class="template-management">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>模板管理</span>
          <el-button type="primary" @click="showUploadDialog">
            <el-icon><Plus /></el-icon>
            上传模板
          </el-button>
        </div>
      </template>

      <el-table :data="templates" v-loading="loading" stripe>
        <el-table-column label="缩略图" width="100">
          <template #default="{ row }">
            <el-image
              :src="getImageUrl(row.thumbnail_url)"
              :preview-src-list="[getImageUrl(row.thumbnail_url)]"
              fit="cover"
              style="width: 80px; height: 60px; border-radius: 4px;"
            >
              <template #error>
                <div class="image-placeholder">
                  <el-icon><Picture /></el-icon>
                </div>
              </template>
            </el-image>
          </template>
        </el-table-column>

        <el-table-column prop="name" label="名称" min-width="120" />
        
        <el-table-column prop="category" label="分类" width="100">
          <template #default="{ row }">
            <el-tag size="small">{{ getCategoryName(row.category) }}</el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="tags" label="标签" min-width="150">
          <template #default="{ row }">
            <el-tag
              v-for="tag in parseTags(row.tags)"
              :key="tag"
              size="small"
              style="margin-right: 4px; margin-bottom: 4px;"
            >
              {{ tag }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="Prompt状态" width="120">
          <template #default="{ row }">
            <el-tooltip :content="row.analysis_prompt ? '已配置自定义Prompt' : '使用分类默认Prompt'" placement="top">
              <el-tag :type="row.analysis_prompt ? 'success' : 'info'" size="small">
                {{ row.analysis_prompt ? '自定义' : '继承' }}
              </el-tag>
            </el-tooltip>
          </template>
        </el-table-column>

        <el-table-column prop="usage_count" label="使用次数" width="100" sortable />
        
        <el-table-column prop="created_at" label="创建时间" width="170">
          <template #default="{ row }">
            {{ formatTime(row.created_at) }}
          </template>
        </el-table-column>

        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="editTemplate(row)">
              编辑
            </el-button>
            <el-button type="danger" link size="small" @click="deleteTemplate(row)">
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 上传/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="isEdit ? '编辑模板' : '上传新模板'"
      width="800px"
      top="5vh"
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="模板名称" prop="name">
              <el-input v-model="form.name" placeholder="输入模板名称" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="分类" prop="category">
              <el-select v-model="form.category" placeholder="选择分类" style="width: 100%;">
                <el-option label="人像" value="portrait" />
                <el-option label="风景" value="landscape" />
                <el-option label="美食" value="food" />
                <el-option label="宠物" value="pet" />
                <el-option label="建筑" value="architecture" />
                <el-option label="街拍" value="street" />
                <el-option label="静物" value="still_life" />
                <el-option label="其他" value="other" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="标签">
          <el-input
            v-model="form.tagsStr"
            placeholder="多个标签用逗号分隔，如：人像,经典,半身"
          />
        </el-form-item>

        <el-row :gutter="20">
          <el-col :span="isEdit ? 24 : 16">
            <el-form-item label="缩略图" prop="thumbnail">
              <el-upload
                class="uploader"
                action="#"
                :auto-upload="false"
                :show-file-list="true"
                :limit="1"
                accept="image/*"
                :on-change="handleFileChange"
              >
                <el-button type="primary">选择图片</el-button>
                <template #tip>
                  <div style="font-size: 12px; color: #999; margin-top: 4px;">
                    支持 JPG/PNG/WebP，最大10MB
                  </div>
                </template>
              </el-upload>
            </el-form-item>
          </el-col>
          <el-col :span="8" v-if="!isEdit && form.thumbnail">
            <el-image
              :src="URL.createObjectURL(form.thumbnail)"
              fit="cover"
              style="width: 100%; height: 150px; border-radius: 8px;"
            />
          </el-col>
        </el-row>

        <el-divider content-position="left">
          <el-icon><EditPen /></el-icon>
          AI Prompt 配置（可选）
        </el-divider>

        <el-alert
          type="info"
          :closable="false"
          show-icon
          style="margin-bottom: 16px;"
        >
          <template #default>
            <p style="margin: 0;">为该模板设置专属的AI分析指令。留空则自动继承所属分类的Prompt。</p>
            <p style="margin: 4px 0 0 0;">
              <a href="/categories" target="_blank" style="color: #409eff;" @click.prevent="$router.push('/categories')">
                前往分类Prompt管理 →
              </a>
            </p>
          </template>
        </el-alert>

        <el-form-item label="分析Prompt">
          <el-input
            v-model="form.analysis_prompt"
            type="textarea"
            :rows="6"
            placeholder="留空则使用分类的默认分析Prompt..."
            resize="vertical"
          />
          <div class="form-tip">
            <span>{{ form.analysis_prompt ? `${form.analysis_prompt.length} 字符` : '未设置，将使用分类默认值' }}</span>
            <el-button 
              size="small" 
              link 
              type="warning" 
              v-if="form.analysis_prompt"
              @click="form.analysis_prompt = ''"
            >清除</el-button>
          </div>
        </el-form-item>

        <el-form-item label="对比Prompt">
          <el-input
            v-model="form.comparison_prompt"
            type="textarea"
            :rows="6"
            placeholder="留空则使用分类的默认对比Prompt..."
            resize="vertical"
          />
          <div class="form-tip">
            <span>{{ form.comparison_prompt ? `${form.comparison_prompt.length} 字符` : '未设置，将使用分类默认值' }}</span>
            <el-button 
              size="small" 
              link 
              type="warning" 
              v-if="form.comparison_prompt"
              @click="form.comparison_prompt = ''"
            >清除</el-button>
          </div>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">
          {{ isEdit ? '保存修改' : '上传模板' }}
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'
import { EditPen, Plus, Picture } from '@element-plus/icons-vue'

const templates = ref([])
const loading = ref(false)
const dialogVisible = ref(false)
const isEdit = ref(false)
const submitting = ref(false)
const formRef = ref()
const currentEditId = ref(null)

const form = ref({
  name: '',
  category: '',
  tagsStr: '',
  thumbnail: null,
  analysis_prompt: '',
  comparison_prompt: ''
})

const rules = {
  name: [{ required: true, message: '请输入模板名称', trigger: 'blur' }],
  category: [{ required: true, message: '请选择分类', trigger: 'change' }]
}

async function fetchTemplates() {
  loading.value = true
  
  try {
    const res = await api.get('/templates')
    
    if (res.success) {
      templates.value = res.data || []
    }
  } catch (error) {
    console.error('获取模板列表失败:', error)
  } finally {
    loading.value = false
  }
}

function showUploadDialog() {
  isEdit.value = false
  currentEditId.value = null
  form.value = { 
    name: '', 
    category: '', 
    tagsStr: '', 
    thumbnail: null,
    analysis_prompt: '',
    comparison_prompt: ''
  }
  dialogVisible.value = true
}

function editTemplate(template) {
  isEdit.value = true
  currentEditId.value = template.id
  form.value = {
    name: template.name,
    category: template.category,
    tagsStr: parseTags(template.tags).join(', '),
    thumbnail: null,
    analysis_prompt: template.analysis_prompt || '',
    comparison_prompt: template.comparison_prompt || ''
  }
  dialogVisible.value = true
}

function handleFileChange(file) {
  form.value.thumbnail = file.raw
}

async function handleSubmit() {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  submitting.value = true

  try {
    const formData = new FormData()
    formData.append('name', form.value.name)
    formData.append('category', form.value.category)
    
    const tags = form.value.tagsStr.split(',').map(t => t.trim()).filter(Boolean)
    formData.append('tags', tags.join(','))
    
    if (form.value.thumbnail) {
      formData.append('thumbnail', form.value.thumbnail)
    }

    if (form.value.analysis_prompt) {
      formData.append('analysis_prompt', form.value.analysis_prompt)
    }

    if (form.value.comparison_prompt) {
      formData.append('comparison_prompt', form.value.comparison_prompt)
    }

    let res
    
    if (isEdit.value) {
      res = await api.put(`/templates/${currentEditId.value}`, formData)
    } else {
      res = await api.post('/templates', formData)
    }

    if (res.success) {
      ElMessage.success(res.message)
      dialogVisible.value = false
      fetchTemplates()
    }
  } catch (error) {
    console.error(isEdit.value ? '更新失败' : '上传失败:', error)
  } finally {
    submitting.value = false
  }
}

async function deleteTemplate(template) {
  try {
    await ElMessageBox.confirm(
      `确定要删除模板"${template.name}"吗？`,
      '确认删除',
      { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' }
    )

    const res = await api.delete(`/templates/${template.id}`)
    
    if (res.success) {
      ElMessage.success(res.message)
      fetchTemplates()
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
    }
  }
}

function getImageUrl(url) {
  if (!url) return ''
  return url.startsWith('/') ? url : `/${url}`
}

function parseTags(tags) {
  if (!tags) return []
  
  if (typeof tags === 'string') {
    try {
      return JSON.parse(tags)
    } catch {
      return tags.split(',').map(t => t.trim())
    }
  }
  
  return Array.isArray(tags) ? tags : []
}

function getCategoryName(category) {
  const map = {
    portrait: '人像',
    landscape: '风景',
    food: '美食',
    pet: '宠物',
    architecture: '建筑',
    street: '街拍',
    still_life: '静物',
    other: '其他'
  }
  return map[category] || category
}

function formatTime(time) {
  if (!time) return '-'
  return new Date(time).toLocaleString('zh-CN')
}

onMounted(() => {
  fetchTemplates()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.image-placeholder {
  width: 80px;
  height: 60px;
  background: #f5f7fa;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ccc;
  border-radius: 4px;
}

.uploader {
  width: 100%;
}

.form-tip {
  margin-top: 4px;
  font-size: 12px;
  color: #909399;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
