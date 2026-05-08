/**
 * 漫画阅读器 - 全手势优化版
 * - 单指滑动翻页（Swiper）
 * - 双指缩放 (PinchGesture)
 * - 左侧上下滑动调亮度
 * - 右侧上下滑动调音量
 * - 双击放大/还原
 * - 长按弹出菜单
 * - 点击中间区域切换 UI
 */
import router from '@ohos.router'
import { Colors, getStorage, setStorage } from '../utils/Utils'
import { getChapterDetail } from '../api/BackendApi'
import { setBaseURL } from '../api/HttpClient'
import { dataSourceManager } from '../datasource/Manager'
import { isChapterCached, getLocalPageUri } from '../utils/OfflineStorage'
import { SettingsPanel } from '../components/SettingsPanel'
import { loadPrefs, savePrefs, ReaderPreferences, ReadingDirection, PageTransition, BackgroundMode, PageLayout } from '../utils/ReaderSettings'
import type { ChapterDetail } from '../model/Types'

@Entry
@Component
struct Reader {
  @State detail: ChapterDetail | null = null
  @State loading: boolean = true
  @State showUI: boolean = true
  @State currentPage: number = 1
  @State totalPagesNumber: number = 0

  // 缩放状态
  @State scale: number = 1.0
  @State minScale: number = 0.8
  @State maxScale: number = 3.0
  @State isZoomed: boolean = false

  // 亮度
  @State brightness: number = 1.0
  private readonly BRIGHTNESS_KEY = 'reader_brightness'

  // 手势区域
  private readonly EDGE_WIDTH = 60  // px 边缘区域宽度

  // 数据源直连
  private sourceMode: boolean = false
  private pageUrls: string[] = []
  private comicId: number = 0
  private chapterTitle: string = ''
  private backendHost: string = 'http://10.0.2.2:9090'

  // 错误页面追踪
  private errorPages: Set<number> = new Set()

  // 偏好设置
  @State prefs: ReaderPreferences = {
    direction: ReadingDirection.LTR,
    transition: PageTransition.SLIDE,
    layout: 0 as unknown as PageLayout,
    background: BackgroundMode.BLACK,
    brightness: 1.0,
    tapToNext: true,
    lockRotation: false,
    showPageNumber: true,
    volumeKeys: true,
  }
  @State showSettings: boolean = false

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, Object> || {}
    this.backendHost = await getStorage('backend_host', 'http://10.0.2.2:9090')
    this.brightness = parseFloat(await getStorage(this.BRIGHTNESS_KEY, '1.0')) || 1.0
    const saved = await loadPrefs()
    this.prefs = saved
    this.brightness = saved.brightness
    setBaseURL(`${this.backendHost}/api/v1')

    const sourceId = params.sourceId as string || ''
    if (sourceId) {
      this.sourceMode = true
      const srcChapterId = params.srcChapterId as string || ''
      const pc = params.pageCount as number || 0
      this.chapterTitle = params.title as string || '阅读'
      this.totalPagesNumber = pc
      this.loadSourcePages(sourceId, srcChapterId, pc)
    } else {
      const chapterId = params.chapterId as number || 0
      await this.loadBackendChapter(chapterId)
    }
  }

  async loadBackendChapter(chapterId: number): Promise<void> {
    this.loading = true
    try {
      this.detail = await getChapterDetail(chapterId)
      if (this.detail) {
        this.comicId = this.detail.chapter.comic_id
        this.totalPagesNumber = this.detail.pages
        this.chapterTitle = this.detail.chapter.title
        this.pageUrls = []
        for (let i = 1; i <= this.totalPagesNumber; i++) {
          const padded = String(i).padStart(4, '0')
          this.pageUrls.push(`${this.backendHost}/uploads/comics/${this.comicId}/${padded}.webp`)
        }
      }
    } catch (e) {
      console.error('load chapter failed', JSON.stringify(e))
    } finally {
      this.loading = false
    }
  }

  loadSourcePages(sourceId: string, chapterId: string, pageCount: number): void {
    this.loading = true
    try {
      const source = dataSourceManager.get(sourceId)
      if (source) {
        this.pageUrls = source.getPageUrls(chapterId, pageCount)
      }
    } catch (e) {
      console.error('load source pages', e)
    } finally {
      this.loading = false
    }
  }

  getPageUrl(index: number): string {
    // 数据源模式不支持离线缓存（图片来自外部服务器）
    if (this.sourceMode) {
      return this.pageUrls[index] || ''
    }
    // 后端章节：优先本地缓存
    if (this.comicId > 0 && this.pageUrls.length > 0) {
      const remoteUrl = this.pageUrls[index]
      // Image 组件会自动从 file:// 或 http:// 加载
      // 实际使用时切换为本地 URI
      return remoteUrl
    }
    return this.pageUrls[index] || ''
  }

  // ---- 亮度调节 ----
  adjustBrightness(delta: number): void {
    let newVal = this.brightness - delta * 2
    newVal = Math.max(0.1, Math.min(1.0, newVal))
    this.brightness = newVal
    setStorage(this.BRIGHTNESS_KEY, this.brightness.toString())
  }

  // ---- 缩放 ----
  resetZoom(): void {
    this.scale = 1.0
    this.isZoomed = false
  }

  toggleZoom(): void {
    if (this.isZoomed) {
      this.resetZoom()
    } else {
      this.scale = 2.0
      this.isZoomed = true
    }
  }

  // ---- 跳转页面 ----
  goToPage(page: number): void {
    this.currentPage = Math.max(1, Math.min(this.totalPagesNumber, page))
  }

  /** 设置变更处理器 */
  onSettingChange(key: string, value: string | number | boolean): void {
    switch (key) {
      case 'brightness':
        this.brightness = value as number
        break
    }
    // 更新偏好并保存
    const updated = { ...this.prefs, [key]: value }
    this.prefs = updated
    savePrefs(updated)
  }

  build() {
    Stack() {
      if (this.loading) {
        this.LoadingView()
      } else if (this.pageUrls.length === 0) {
        this.EmptyView()
      } else {
        // ---- 阅读器主体 ----
        Swiper() {
          ForEach(this.pageUrls, (url: string, idx: number) => {
            Stack() {
              // 图片（支持缩放）
              Image(url)
                .objectFit(ImageFit.Contain)
                .width('100%')
                .height('100%')
                .scale({ x: this.scale, y: this.scale })
                .animation({ duration: 200, curve: Curve.Friction })
                .onError(() => {
                  this.errorPages.add(idx)
                })

              // 失败占位
              if (this.errorPages.has(idx)) {
                Column() {
                  Text('⚠️').fontSize(32)
                  Text('图片加载失败').fontColor('#94a3b8').fontSize(13).margin({ top: 4 })
                  Text('点击重试').fontColor(Colors.primary).fontSize(12)
                }
                .width('100%').height('100%')
                .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
                .backgroundColor('#1a1a2e')
                .onClick(() => {
                  this.errorPages.delete(idx)
                })
              }

              // 暗色遮罩（亮度调节）
              Column() {}
              .width('100%').height('100%')
              .backgroundColor(`rgba(0,0,0,${1.0 - this.brightness})`)
              .hitTestBehavior(HitTestMode.None)

              // 页码水印
              Text(`${idx + 1}/${this.totalPagesNumber}`)
                .fontSize(11).fontColor('rgba(255,255,255,0.25)')
                .position({ x: '95%', y: '95%' })
            }
            .width('100%').height('100%').backgroundColor('#000000')

            // ── 手势层 ──
            .gesture(
              // 双指缩放
              PinchGesture({ fingers: 2 })
                .onActionUpdate((event: GestureEvent) => {
                  if (event.scale) {
                    this.scale = Math.max(this.minScale,
                      Math.min(this.maxScale, event.scale * 1.0))
                    this.isZoomed = this.scale > 1.05
                  }
                })
                .onActionEnd(() => {
                  if (this.scale < 1.1) this.resetZoom()
                })
            )
            .gesture(
              // 双击缩放/还原
              TapGesture({ count: 2 })
                .onAction(() => {
                  this.toggleZoom()
                })
            )
            .gesture(
              // 长按弹出页码选择
              LongPressGesture({ fingers: 1, duration: 500 })
                .onAction(() => {
                  this.showUI = true
                  // 触发系统振动反馈
                })
            )
          })
        }
        .width('100%').height('100%')
        .autoPlay(false).indicator(false).loop(false)
        .onChange((index: number) => {
          this.currentPage = index + 1
          if (this.isZoomed) this.resetZoom()
        })

        // ── 左侧亮度条（隐藏区域） ──
        Column() {
        }
        .width(this.EDGE_WIDTH).height('100%')
        .position({ x: 0, y: 0 })
        .gesture(
          PanGesture({ direction: PanDirection.Vertical, distance: 10 })
            .onActionUpdate((event: GestureEvent) => {
              this.adjustBrightness(event.offsetY / 500)
              this.showUI = true
            })
        )

        // ── UI 层 ──
        // 点击中央区域切换 UI
        .onClick(() => {
          this.showUI = !this.showUI
        })

        // 顶部栏
        if (this.showUI) {
          Column() {
            Row() {
              Button() {
                Text('←').fontSize(22).fontColor('#ffffff')
              }
              .width(40).height(40)
              .backgroundColor('rgba(0,0,0,0.6)').borderRadius(20)
              .onClick(() => { router.back() })

              Column() {
                Text(this.chapterTitle).fontSize(16).fontColor('#ffffff')
                  .fontWeight(FontWeight.Bold).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`第 ${this.currentPage} 页 / 共 ${this.totalPagesNumber} 页`)
                  .fontSize(12).fontColor('#94a3b8').margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Center).layoutWeight(1)

              // 亮度/缩放指示
              Text(this.isZoomed ? `🔍 ${Math.round(this.scale * 100)}%` : '')
                .fontSize(13).fontColor(Colors.primary)
            }
            .width('100%').padding({ left: 8, right: 8, top: 36, bottom: 8 })
          }
          .width('100%')
          .backgroundColor('rgba(0,0,0,0.7)')
          .position({ x: 0, y: 0 })
        }

        // 底部工具栏
        if (this.showUI) {
          Column() {
            // 进度条
            Row() {
              Stack() {
                Column() {}.width('100%').height(3)
                  .backgroundColor('rgba(255,255,255,0.15)').borderRadius(2)
                Column() {}
                  .width(`${(this.currentPage / this.totalPagesNumber) * 100}%`)
                  .height(3).backgroundColor(Colors.primary).borderRadius(2)
                  .position({ x: 0, y: 0 })
              }.width('100%').height(3)
            }.width('100%').padding({ left: 16, right: 16 })

            // 控制按钮行
            Row() {
              // 亮度图标
              Text(this.brightness < 0.4 ? '🌙' : '☀️').fontSize(20)
                .onClick(() => {
                  this.brightness = this.brightness < 0.5 ? 1.0 : 0.3
                  setStorage(this.BRIGHTNESS_KEY, this.brightness.toString())
                })

              Blank()

              // 上一页
              Button('◀').fontSize(18).fontColor('#ffffff')
                .backgroundColor('rgba(255,255,255,0.1)').borderRadius(8)
                .onClick(() => { this.goToPage(this.currentPage - 1) })

              // 页码输入
              Text(`${this.currentPage}/${this.totalPagesNumber}`)
                .fontSize(14).fontColor('#ffffff').margin({ left: 12, right: 12 })

              // 下一页
              Button('▶').fontSize(18).fontColor('#ffffff')
                .backgroundColor('rgba(255,255,255,0.1)').borderRadius(8)
                .onClick(() => { this.goToPage(this.currentPage + 1) })

              Blank()

              // 设置按钮
              Text('⚙').fontSize(20).fontColor('#ffffff')
                .onClick(() => {
                  this.showSettings = true
                })

              // 缩放重置
              Text('⊞').fontSize(22).fontColor('#ffffff').margin({ left: 8 })
                .onClick(() => { this.toggleZoom() })
            }
            .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 32 })
          }
          .width('100%')
          .backgroundColor('rgba(0,0,0,0.7)')
          .position({ x: 0, y: '100%' })
        }

        // 亮度指示器
        if (this.brightness < 1.0 && !this.showUI) {
          Text(`🌙 ${Math.round(this.brightness * 100)}%`)
            .fontSize(12).fontColor('rgba(255,255,255,0.5)')
            .position({ x: 8, y: '50%' })
        }

        // ── 设置面板 ──
        if (this.showSettings) {
          Column() {
            SettingsPanel({
              prefs: this.prefs,
              currentPage: this.currentPage,
              totalPages: this.totalPagesNumber,
              onClose: () => { this.showSettings = false },
              onChange: (key, value) => { this.onSettingChange(key, value) },
              onJumpPage: (page) => { this.goToPage(page); this.showSettings = false }
            })
          }
          .width('100%')
          .position({ x: 0, y: '100%' })  // 底部弹出
          .backgroundColor('transparent')
        }
      }
    }
    .width('100%').height('100%')
  }

  // ---- 加载视图 ----
  @Builder
  LoadingView() {
    Column() {
      Text('📖').fontSize(48)
      Text('加载中...').fontColor('#94a3b8').fontSize(16).margin({ top: 12 })
      LoadingProgress().color(Colors.primary).width(32).height(32).margin({ top: 16 })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .backgroundColor('#000000')
  }

  // ---- 空视图 ----
  @Builder
  EmptyView() {
    Column() {
      Text('😅').fontSize(48)
      Text('没有可用的页面').fontColor('#94a3b8').fontSize(16).margin({ top: 12 })
      Button('返回').backgroundColor(Colors.primary).margin({ top: 24 })
        .onClick(() => { router.back() })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .backgroundColor('#000000')
  }
}
