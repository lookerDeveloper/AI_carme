<template>
  <div class="dashboard">
    <el-row :gutter="20" class="stat-cards">
      <el-col :span="6" v-for="stat in stats" :key="stat.title">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <div class="stat-icon" :style="{ background: stat.color }">
              <el-icon :size="28"><component :is="stat.icon" /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stat.value }}</div>
              <div class="stat-title">{{ stat.title }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" style="margin-top: 20px;">
      <el-col :span="16">
        <el-card shadow="never">
          <template #header>
            <span>用户活跃趋势（近30天）</span>
          </template>
          <v-chart :option="chartOption" style="height: 400px;" autoresize />
        </el-card>
      </el-col>

      <el-col :span="8">
        <el-card shadow="never" style="margin-bottom: 20px;">
          <template #header>
            <span>最近登录用户</span>
          </template>
          <el-table :data="recentLogins" size="small" max-height="300">
            <el-table-column prop="username" label="用户名" />
            <el-table-column prop="role" label="角色" width="80">
              <template #default="{ row }">
                <el-tag :type="row.role === 'admin' ? 'danger' : 'info'" size="small">
                  {{ row.role === 'admin' ? '管理员' : '用户' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="last_login_at" label="最后登录" width="160">
              <template #default="{ row }">
                {{ formatTime(row.last_login_at) }}
              </template>
            </el-table-column>
          </el-table>
        </el-card>

        <el-card shadow="never">
          <template #header>
            <span>操作统计</span>
          </template>
          <div v-for="action in actionStats" :key="action.action" class="action-stat">
            <span>{{ getActionName(action.action) }}</span>
            <el-tag>{{ action.count }}次</el-tag>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart } from 'echarts/charts'
import {
  TitleComponent,
  TooltipComponent,
  GridComponent
} from 'echarts/components'
import VChart from 'vue-echarts'
import api from '../api'

use([CanvasRenderer, LineChart, TitleComponent, TooltipComponent, GridComponent])

const stats = ref([
  { title: '总用户数', value: 0, icon: 'User', color: '#409EFF' },
  { title: '今日新增', value: 0, icon: 'UserFilled', color: '#67C23A' },
  { title: '今日活跃', value: 0, icon: 'TrendCharts', color: '#E6A23C' },
  { title: '模板总数', value: 0, icon: 'Picture', color: '#F56C6C' }
])

const recentLogins = ref([])
const actionStats = ref([])
const chartOption = ref({})

async function fetchDashboard() {
  try {
    const res = await api.get('/analytics/dashboard')
    
    if (res.success) {
      const data = res.data
      
      stats.value[0].value = data.overview.totalUsers
      stats.value[1].value = data.overview.newUsersToday
      stats.value[2].value = data.overview.activeUsersToday
      stats.value[3].value = data.overview.totalTemplates

      recentLogins.value = data.recentLogins || []
      actionStats.value = data.actionStats || []

      chartOption.value = {
        tooltip: {
          trigger: 'axis',
          axisPointer: { type: 'cross' }
        },
        grid: {
          left: '3%',
          right: '4%',
          bottom: '3%',
          containLabel: true
        },
        xAxis: {
          type: 'category',
          data: (data.dailyActiveUsers || []).map(item => item.date),
          axisLabel: {
            rotate: 45,
            fontSize: 11
          }
        },
        yAxis: {
          type: 'value',
          name: '活跃用户数'
        },
        series: [{
          name: '日活用户',
          type: 'line',
          smooth: true,
          data: (data.dailyActiveUsers || []).map(item => item.active_users),
          areaStyle: {
            color: {
              type: 'linear',
              x: 0, y: 0, x2: 0, y2: 1,
              colorStops: [
                { offset: 0, color: 'rgba(26,115,232,0.4)' },
                { offset: 1, color: 'rgba(26,115,232,0.05)' }
              ]
            }
          },
          lineStyle: { color: '#1A73E8', width: 2 },
          itemStyle: { color: '#1A73E8' }
        }]
      }
    }
  } catch (error) {
    console.error('获取仪表盘数据失败:', error)
  }
}

function formatTime(time) {
  if (!time) return '-'
  return new Date(time).toLocaleString('zh-CN')
}

function getActionName(action) {
  const map = {
    LOGIN: '用户登录',
    REGISTER: '新注册',
    UPLOAD_TEMPLATE: '上传模板',
    UPLOAD_CUSTOM_TEMPLATE: '自定义模板',
    TOGGLE_USER_STATUS: '状态变更'
  }
  return map[action] || action
}

onMounted(() => {
  fetchDashboard()
})
</script>

<style scoped>
.stat-cards {
  margin-bottom: 20px;
}

.stat-card {
  border-radius: 12px;
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  width: 64px;
  height: 64px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.stat-value {
  font-size: 28px;
  font-weight: bold;
  color: #333;
}

.stat-title {
  font-size: 14px;
  color: #999;
  margin-top: 4px;
}

.action-stat {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 0;
  border-bottom: 1px solid #f0f0f0;
}

.action-stat:last-child {
  border-bottom: none;
}
</style>
