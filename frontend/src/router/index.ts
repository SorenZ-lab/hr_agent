import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { public: true },
    },
    {
      path: '/',
      component: () => import('@/components/layout/AppLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          redirect: '/dashboard',
        },
        {
          path: 'dashboard',
          name: 'dashboard',
          component: () => import('@/views/DashboardView.vue'),
        },
        // AI 助手（统一入口）
        {
          path: 'chat',
          name: 'chat',
          component: () => import('@/views/UnifiedChatView.vue'),
        },
        // QA 智能问答
        {
          path: 'qa',
          name: 'qa',
          component: () => import('@/views/qa/QAChatView.vue'),
        },
        // 简历审查
        {
          path: 'resume',
          name: 'resume',
          component: () => import('@/views/resume/ResumeUploadView.vue'),
        },
        {
          path: 'resume/:reviewId',
          name: 'resume-report',
          component: () => import('@/views/resume/ResumeReportView.vue'),
        },
      ],
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/dashboard',
    },
  ],
})

router.beforeEach((to, _from, next) => {
  const auth = useAuthStore()

  if (to.meta.public) {
    if (auth.isLoggedIn && to.name === 'login') return next('/dashboard')
    return next()
  }

  if (!auth.isLoggedIn) return next('/login')

  next()
})

export default router
