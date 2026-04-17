import { defineStore } from 'pinia'
import api from '../api'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem('admin_token') || '',
    user: JSON.parse(localStorage.getItem('admin_user') || 'null')
  }),

  getters: {
    isAuthenticated: (state) => !!state.token,
    isAdmin: (state) => state.user?.role === 'admin'
  },

  actions: {
    initAuth() {
      if (this.token) {
        console.log('[Auth] 恢复登录状态:', this.user?.username)
      }
    },

    async login(username, password) {
      try {
        const response = await api.post('/auth/login', { username, password })
        
        if (response.success) {
          this.token = response.data.token
          this.user = response.data.user
          localStorage.setItem('admin_token', response.data.token)
          localStorage.setItem('admin_user', JSON.stringify(response.data.user))
          
          if (this.user.role !== 'admin') {
            this.logout()
            throw new Error('需要管理员权限')
          }
          
          return true
        } else {
          throw new Error(response.message)
        }
      } catch (error) {
        console.error('[Auth] 登录失败:', error.message)
        throw error
      }
    },

    logout() {
      this.token = ''
      this.user = null
      localStorage.removeItem('admin_token')
      localStorage.removeItem('admin_user')
      console.log('[Auth] 已登出')
    },

    async fetchUserInfo() {
      try {
        const response = await api.get('/auth/me')
        if (response.success) {
          this.user = response.data
          localStorage.setItem('admin_user', JSON.stringify(response.data))
        }
      } catch (error) {
        console.error('[Auth] 获取用户信息失败:', error)
      }
    }
  }
})
