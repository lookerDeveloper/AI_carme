import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import Login from '../views/Login.vue'
import Layout from '../views/Layout.vue'
import Dashboard from '../views/Dashboard.vue'
import UserManagement from '../views/UserManagement.vue'
import TemplateManagement from '../views/TemplateManagement.vue'
import CategoryManagement from '../views/CategoryManagement.vue'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    component: Layout,
    redirect: '/dashboard',
    meta: { requiresAuth: true },
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: Dashboard,
        meta: { title: '数据概览', icon: 'DataAnalysis' }
      },
      {
        path: 'categories',
        name: 'CategoryManagement',
        component: CategoryManagement,
        meta: { title: '分类Prompt管理', icon: 'Collection' }
      },
      {
        path: 'users',
        name: 'UserManagement',
        component: UserManagement,
        meta: { title: '用户管理', icon: 'User' }
      },
      {
        path: 'templates',
        name: 'TemplateManagement',
        component: TemplateManagement,
        meta: { title: '模板管理', icon: 'Picture' }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/login')
  } else if (to.path === '/login' && authStore.isAuthenticated) {
    next('/dashboard')
  } else {
    next()
  }
})

export default router
