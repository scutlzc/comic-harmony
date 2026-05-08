/**
 * 折叠屏/自适应布局工具
 * 使用 HarmonyOS breakpoint + mediaquery 实现多屏适配
 */
import mediaquery from '@ohos.mediaquery'
import display from '@ohos.display'

/** 屏幕尺寸断点 */
export enum Breakpoint {
  XS = 'xs',    // < 360
  SM = 'sm',    // 360-600
  MD = 'md',    // 600-840 (折叠屏展开)
  LG = 'lg',    // 840-1080 (平板竖屏)
  XL = 'xl',    // 1080+ (平板横屏)
}

/** 设备形态 */
export enum DeviceForm {
  PHONE = 'phone',
  FOLDABLE = 'foldable',   // 折叠屏（展开=小平板）
  TABLET = 'tablet',       // 平板
  DESKTOP = 'desktop',     // 2in1 桌面
}

/** 布局模式 */
export enum LayoutMode {
  SINGLE = 'single',           // 单列（手机折叠态）
  SINGLE_WIDE = 'single_wide', // 单列宽屏（折叠屏展开）
  DUAL = 'dual',               // 双列（平板）
  MASTER_DETAIL = 'master_detail', // 主从布局（平板横屏/桌面）
}

/** 根据宽度判断断点 */
export function getBreakpoint(width: number): Breakpoint {
  if (width < 360) return Breakpoint.XS
  if (width < 600) return Breakpoint.SM
  if (width < 840) return Breakpoint.MD
  if (width < 1080) return Breakpoint.LG
  return Breakpoint.XL
}

/** 根据断点判断布局模式 */
export function getLayoutMode(bp: Breakpoint, isFoldable: boolean): LayoutMode {
  if (bp === Breakpoint.XS || bp === Breakpoint.SM) {
    return LayoutMode.SINGLE
  }
  if (bp === Breakpoint.MD) {
    return isFoldable ? LayoutMode.SINGLE_WIDE : LayoutMode.DUAL
  }
  if (bp === Breakpoint.LG) {
    return LayoutMode.DUAL
  }
  return LayoutMode.MASTER_DETAIL // XL
}

/** 根据宽度推断设备形态 */
export function detectDeviceForm(width: number): DeviceForm {
  if (width >= 1080) return DeviceForm.DESKTOP
  if (width >= 840) return DeviceForm.TABLET
  if (width >= 600) return DeviceForm.FOLDABLE
  return DeviceForm.PHONE
}

/** 获取当前显示信息 */
export async function getDisplayInfo(): Promise<{
  width: number
  height: number
  dpi: number
  isFoldable: boolean
}> {
  const defaultDisplay = display.getDefaultDisplaySync()
  return {
    width: defaultDisplay.width,
    height: defaultDisplay.height,
    dpi: defaultDisplay.densityDPI,
    isFoldable: defaultDisplay.isFoldable
  }
}

// ---- 响应式间距 ----
export const ResponsiveSpacing = {
  getPadding(bp: Breakpoint): number {
    if (bp <= Breakpoint.SM) return 12
    if (bp === Breakpoint.MD) return 16
    return 24
  },
  getCardColumns(bp: Breakpoint): number {
    if (bp <= Breakpoint.SM) return 1
    if (bp === Breakpoint.MD) return 2
    if (bp === Breakpoint.LG) return 3
    return 4
  },
  getCardWidth(bp: Breakpoint, totalWidth: number): number {
    const cols = this.getCardColumns(bp)
    const gap = 12 * (cols - 1)
    const padding = this.getPadding(bp) * 2
    return Math.floor((totalWidth - padding - gap) / cols)
  }
}

/** 断点监听器 */
export function createBreakpointListener(callback: (bp: Breakpoint) => void): {
  on(): void
  off(): void
} {
  const listener = mediaquery.matchMediaSync('(min-width: 600px)')
  const handler = (result: mediaquery.MediaQueryResult) => {
    const width = result.width || 0
    callback(getBreakpoint(width))
  }
  return {
    on: () => listener.on('change', handler),
    off: () => listener.off('change', handler)
  }
}
