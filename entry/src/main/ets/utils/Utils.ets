/**
 * 工具函数
 */
import preferences from '@ohos.data.preferences'
import { BusinessError } from '@ohos.base'

// ---- 本地存储 ----
let pref: preferences.Preferences | null = null

export async function initStorage(context: UIAbilityContext): Promise<void> {
  pref = await preferences.getPreferences(context, 'comic_harmony_store')
}

export async function setStorage(key: string, value: string): Promise<void> {
  if (!pref) return
  await pref.put(key, value)
  await pref.flush()
}

export async function getStorage(key: string, defaultValue: string = ''): Promise<string> {
  if (!pref) return defaultValue
  return pref.get(key, defaultValue) as string
}

export async function removeStorage(key: string): Promise<void> {
  if (!pref) return
  await pref.delete(key)
  await pref.flush()
}

// ---- 图片 URL 拼接 ----
export function getPageUrl(baseUrl: string, chapterId: number, pageNum: number): string {
  return `${baseUrl}/uploads/comics/${chapterId}/${String(pageNum).padStart(4, '0')}.webp`
}

// ---- 时间格式化 ----
export function formatTime(isoStr: string): string {
  const d = new Date(isoStr)
  const now = new Date()
  const diff = now.getTime() - d.getTime()

  if (diff < 60000) return '刚刚'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`
  if (diff < 2592000000) return `${Math.floor(diff / 86400000)}天前`

  return `${d.getMonth() + 1}/${d.getDate()}`
}

// ---- 主题色 ----
export const Colors = {
  primary: '#7c3aed',
  primaryLight: '#a78bfa',
  background: '#1a1a2e',
  surface: '#16213e',
  surfaceLight: '#1f3056',
  text: '#ffffff',
  textSecondary: '#94a3b8',
  border: '#2d3748',
  accent: '#e94560',
  success: '#22c55e',
  warning: '#f59e0b'
} as const
