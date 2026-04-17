<template>
  <el-container class="layout-container">
    <el-aside :width="isCollapse ? '64px' : '220px'" class="sidebar">
      <div class="logo">
        <el-icon :size="28" color="#1A73E8"><Camera /></el-icon>
        <span v-show="!isCollapse" class="logo-text">智眸管理</span>
      </div>

      <el-menu
        :default-active="$route.path"
        :collapse="isCollapse"
        background-color="#001529"
        text-color="#ffffffa6"
        active-text-color="#1A73E8"
        router
      >
        <el-menu-item index="/dashboard">
          <el-icon><DataAnalysis /></el-icon>
          <template #title>数据概览</template>
        </el-menu-item>

        <el-menu-item index="/categories">
          <el-icon><Collection /></el-icon>
          <template #title>分类Prompt管理</template>
        </el-menu-item>

        <el-menu-item index="/users">
          <el-icon><User /></el-icon>
          <template #title>用户管理</template>
        </el-menu-item>

        <el-menu-item index="/templates">
          <el-icon><Picture /></el-icon>
          <template #title>模板管理</template>
        </el-menu-item>
      </el-menu>

      <div class="collapse-btn" @click="isCollapse = !isCollapse">
        <el-icon>
          <component :is="isCollapse ? 'Expand' : 'Fold'" />
        </el-icon>
      </div>
    </el-aside>

    <el-container>
      <el-header class="header">
        <div class="header-left">
          <el-breadcrumb separator="/">
            <el-breadcrumb-item>{{ currentRoute.meta?.title || '首页' }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>

        <div class="header-right">
          <el-dropdown trigger="click" @command="handleCommand">
            <span class="user-info">
              <el-avatar :size="32" icon="UserFilled" />
              <span class="username">{{ authStore.user?.username || '管理员' }}</span>
              <el-icon><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="refresh">刷新数据</el-dropdown-item>
                <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <el-main class="main-content">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const authStore = useAuthStore()
const isCollapse = ref(false)

const currentRoute = computed(() => route)

function handleCommand(command) {
  if (command === 'logout') {
    authStore.logout()
    window.location.href = '/login'
  } else if (command === 'refresh') {
    window.location.reload()
  }
}
</script>

<style scoped>
.layout-container {
  min-height: 100vh;
}

.sidebar {
  background-color: #001529;
  transition: width 0.3s;
  display: flex;
  flex-direction: column;
}

.logo {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 0 16px;
  border-bottom: 1px solid #ffffff1a;
}

.logo-text {
  font-size: 18px;
  font-weight: bold;
  color: white;
  white-space: nowrap;
}

.el-menu {
  border-right: none;
  flex: 1;
}

.collapse-btn {
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: #ffffffa6;
  border-top: 1px solid #ffffff1a;
  transition: all 0.3s;
}

.collapse-btn:hover {
  color: #1A73E8;
  background-color: #ffffff0a;
}

.header {
  background: white;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
  padding: 0 20px;
  z-index: 1;
}

.header-right {
  display: flex;
  align-items: center;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  transition: background 0.2s;
}

.user-info:hover {
  background: #f5f7fa;
}

.username {
  font-size: 14px;
  color: #333;
}

.main-content {
  background: #f5f7fa;
  padding: 20px;
}
</style>
