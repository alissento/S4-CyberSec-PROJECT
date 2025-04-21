import { createRouter, createWebHistory } from 'vue-router'
import LandingPage from '@/components/LandingPage.vue'
import LoginPage from '@/components/LoginPage.vue'
import SignupPage from '@/components/SignupPage.vue'
import SettingsPage from '@/components/SettingsPage.vue'
import DashboardLayout from '@/components/DashboardLayout.vue'
import DashboardFiles from '@/components/DashboardFiles.vue'

const routes = [
  { path: '/', name: 'Home', component: LandingPage },
  { path: '/login', name: 'Login', component: LoginPage },
  { path: '/signup', name: 'Signup', component: SignupPage },
  {
    path: '/dashboard',
    component: DashboardLayout,
    children: [
      { path: '', redirect: { name: 'Files' } },
      { path: 'files', name: 'Files', component: DashboardFiles },
      { path: 'settings', name: 'Settings', component: SettingsPage }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router