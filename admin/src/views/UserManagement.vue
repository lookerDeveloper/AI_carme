<template>
  <div class="user-management">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>用户列表</span>
          <el-input
            v-model="search"
            placeholder="搜索用户名/邮箱"
            style="width: 260px;"
            clearable
            @input="handleSearch"
            prefix-icon="Search"
          />
        </div>
      </template>

      <el-table :data="users" v-loading="loading" stripe>
        <el-table-column prop="username" label="用户名" width="120" />
        <el-table-column prop="email" label="邮箱" min-width="180" />
        <el-table-column prop="role" label="角色" width="100">
          <template #default="{ row }">
            <el-tag :type="row.role === 'admin' ? 'danger' : 'info'" size="small">
              {{ row.role === 'admin' ? '管理员' : '普通用户' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="usage_count" label="使用次数" width="100" sortable />
        <el-table-column prop="last_login_at" label="最后登录" width="170">
          <template #default="{ row }">
            {{ formatTime(row.last_login_at) }}
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="注册时间" width="170">
          <template #default="{ row }">
            {{ formatTime(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80">
          <template #default="{ row }">
            <el-switch
              v-model="row.is_active"
              :disabled="row.role === 'admin'"
              @change="(val) => handleToggleStatus(row, val)"
              active-color="#67C23A"
            />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="viewUserDetail(row)">
              详情
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          :total="total"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next"
          @size-change="fetchUsers"
          @current-change="fetchUsers"
        />
      </div>
    </el-card>

    <el-dialog v-model="detailVisible" title="用户详情" width="600px">
      <el-descriptions :column="2" border v-if="currentUser">
        <el-descriptions-item label="用户名">{{ currentUser.username }}</el-descriptions-item>
        <el-descriptions-item label="邮箱">{{ currentUser.email }}</el-descriptions-item>
        <el-descriptions-item label="角色">{{ currentUser.role === 'admin' ? '管理员' : '普通用户' }}</el-descriptions-item>
        <el-descriptions-item label="使用次数">{{ currentUser.usage_count }}</el-descriptions-item>
        <el-descriptions-item label="注册时间">{{ formatTime(currentUser.created_at) }}</el-descriptions-item>
        <el-descriptions-item label="最后登录">{{ formatTime(currentUser.last_login_at) || '从未登录' }}</el-descriptions-item>
      </el-descriptions>

      <template #footer>
        <el-button @click="detailVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../api'
import { ElMessage } from 'element-plus'

const users = ref([])
const loading = ref(false)
const search = ref('')
const page = ref(1)
const pageSize = ref(20)
const total = ref(0)

const detailVisible = ref(false)
const currentUser = ref(null)

async function fetchUsers() {
  loading.value = true
  
  try {
    const res = await api.get('/users', {
      params: {
        page: page.value,
        limit: pageSize.value,
        search: search.value
      }
    })

    if (res.success) {
      users.value = res.data.users
      total.value = res.data.pagination.total
    }
  } catch (error) {
    console.error('获取用户列表失败:', error)
  } finally {
    loading.value = false
  }
}

function handleSearch() {
  page.value = 1
  fetchUsers()
}

async function handleToggleStatus(user, isActive) {
  try {
    const res = await api.put(`/users/${user.id}/toggle-status`)
    
    if (res.success) {
      ElMessage.success(res.message)
      user.is_active = isActive
    }
  } catch (error) {
    user.is_active = !isActive
  }
}

function viewUserDetail(user) {
  currentUser.value = user
  detailVisible.value = true
}

function formatTime(time) {
  if (!time) return '-'
  return new Date(time).toLocaleString('zh-CN')
}

onMounted(() => {
  fetchUsers()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.pagination-wrapper {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}
</style>
