/**
 * 阅读器偏好设置管理
 * 所有设置持久化到本地 Preferences
 */
import { getStorage, setStorage } from './Utils'

export enum ReadingDirection {
  LTR = 'ltr',   // 从左到右（默认）
  RTL = 'rtl',   // 从右到左（漫画）
}

export enum PageTransition {
  SLIDE = 'slide',    // 滑动翻页（默认）
  FADE = 'fade',      // 淡入淡出
  NONE = 'none',      // 瞬间切换
}

export enum PageLayout {
  SINGLE = 'single',        // 单页（默认）
  DOUBLE = 'double',        // 双页（平板）
  CONTINUOUS = 'continuous', // 连续滚动
}

export enum BackgroundMode {
  BLACK = 'black',       // 纯黑（默认）
  DARK_GREY = 'dark_grey', // 深灰
  SEPIA = 'sepia',       // 护眼黄
  WHITE = 'white',       // 纯白
}

export interface ReaderPreferences {
  direction: ReadingDirection
  transition: PageTransition
  layout: PageLayout
  background: BackgroundMode
  brightness: number        // 0.1 ~ 1.0
  tapToNext: boolean        // 点击翻页
  lockRotation: boolean     // 锁定旋转
  showPageNumber: boolean   // 显示页码
  volumeKeys: boolean       // 音量键翻页
}

const DEFAULTS: ReaderPreferences = {
  direction: ReadingDirection.LTR,
  transition: PageTransition.SLIDE,
  layout: PageLayout.SINGLE,
  background: BackgroundMode.BLACK,
  brightness: 1.0,
  tapToNext: true,
  lockRotation: false,
  showPageNumber: true,
  volumeKeys: true,
}

const STORAGE_KEY = 'reader_prefs'

let cached: ReaderPreferences | null = null

/** 加载设置 */
export async function loadPrefs(): Promise<ReaderPreferences> {
  if (cached) return { ...cached }
  try {
    const json = await getStorage(STORAGE_KEY, '')
    if (json) {
      cached = { ...DEFAULTS, ...JSON.parse(json) }
    } else {
      cached = { ...DEFAULTS }
    }
  } catch {
    cached = { ...DEFAULTS }
  }
  return { ...cached }
}

/** 保存设置 */
export async function savePrefs(prefs: ReaderPreferences): Promise<void> {
  cached = { ...prefs }
  await setStorage(STORAGE_KEY, JSON.stringify(prefs))
}

/** 更新单个设置 */
export async function updatePref<K extends keyof ReaderPreferences>(
  key: K, value: ReaderPreferences[K]
): Promise<ReaderPreferences> {
  const prefs = await loadPrefs()
  prefs[key] = value
  await savePrefs(prefs)
  return prefs
}

/** 获取背景色值 */
export function getBackgroundColor(mode: BackgroundMode): string {
  switch (mode) {
    case BackgroundMode.BLACK: return '#000000'
    case BackgroundMode.DARK_GREY: return '#1a1a2e'
    case BackgroundMode.SEPIA: return '#f5e6c8'
    case BackgroundMode.WHITE: return '#ffffff'
  }
}

/** 获取文字的对比色 */
export function getTextColorForBg(mode: BackgroundMode): string {
  switch (mode) {
    case BackgroundMode.SEPIA: return '#4a3728'
    case BackgroundMode.WHITE: return '#1a1a1a'
    default: return '#ffffff'
  }
}
