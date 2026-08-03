import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

interface UserInfo {
  userId: string
  role: 'candidate' | 'hr' | 'admin'
  tenantId: string
  username?: string
}

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(localStorage.getItem('hr-agent-token'))
  const user = ref<UserInfo | null>((() => {
    try {
      return JSON.parse(localStorage.getItem('hr-agent-user') ?? 'null')
    } catch {
      return null
    }
  })())

  const isLoggedIn = computed(() => !!token.value)
  const isHR = computed(() =>
    user.value?.role === 'hr' || user.value?.role === 'admin'
  )

  function login(accessToken: string, userInfo: UserInfo) {
    token.value = accessToken
    user.value = userInfo
    localStorage.setItem('hr-agent-token', accessToken)
    localStorage.setItem('hr-agent-user', JSON.stringify(userInfo))
  }

  function logout() {
    token.value = null
    user.value = null
    localStorage.removeItem('hr-agent-token')
    localStorage.removeItem('hr-agent-user')
  }

  return { token, user, isLoggedIn, isHR, login, logout }
})
