/**
 * 漫画阅读器
 * - 单指滑动翻页 + 双指缩放 + 亮度调节 + 设置面板
 * - ✅ 离线缓存集成：优先加载本地，后台自动缓存
 */
import router from '@ohos.router'
import { Colors, getStorage, setStorage } from '../utils/Utils'
import { getChapterDetail } from '../api/BackendApi'
import { setBaseURL } from '../api/HttpClient'
import { dataSourceManager } from '../datasource/Manager'
import { isChapterCached, getLocalPageUri, savePage, getCachedPageCount } from '../utils/OfflineStorage'
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

  // 缩放
  @State scale: number = 1.0
  @State minScale: number = 0.8
  @State maxScale: number = 3.0
  @State isZoomed: boolean = false

  // 亮度
  @State brightness: number = 1.0
  private readonly BRIGHTNESS_KEY = 'reader_brightness'
  private readonly EDGE_WIDTH = 60

  // 数据源
  private sourceMode: boolean = false
  private pageUrls: string[] = []
  private comicId: number = 0
  private chapterId: number = 0
  private chapterTitle: string = ''
  private backendHost: string = 'http://10.0.2.2:9090'

  // 缓存状态
  @State cachedPages: Set<number> = new Set()
  @State chapterCached: boolean = false
  @State downloadProgress: string = ''
  private isDownloading: boolean = false
  private errorPages: Set<number> = new Set()

  // 偏好设置
  @State prefs: ReaderPreferences = {
    direction: ReadingDirection.LTR,
    transition: PageTransition.SLIDE,
    layout: 0 as unknown as PageLayout,
    background: BackgroundMode.BLACK,
    brightness: 1.0, tapToNext: true, lockRotation: false,
    showPageNumber: true, volumeKeys: true,
  }
  @State showSettings: boolean = false

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, Object> || {}
    this.backendHost = await getStorage('backend_host', 'http://10.0.2.2:9090')
    this.brightness = parseFloat(await getStorage(this.BRIGHTNESS_KEY, '1.0')) || 1.0
    const saved = await loadPrefs()
    this.prefs = saved
    this.brightness = saved.brightness
    setBaseURL(`${this.backendHost}/api/v1`)

    const sourceId = params.sourceId as string || ''
    if (sourceId) {
      this.sourceMode = true
      this.chapterTitle = params.title as string || '阅读'
      this.totalPagesNumber = params.pageCount as number || 0
      this.loadSourcePages(sourceId, params.srcChapterId as string || '', this.totalPagesNumber)
    } else {
      this.chapterId = params.chapterId as number || 0
      await this.loadBackendChapter(this.chapterId)
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
        // 检查整章缓存状态
        this.chapterCached = await isChapterCached(this.comicId, this.chapterId)
        if (!this.chapterCached) {
          await this.scanCachedPages()
        }
      }
    } catch (e) {
      console.error('load chapter failed', JSON.stringify(e))
    } finally {
      this.loading = false
    }
  }

  loadSourcePages(sourceId: string, srcChapterId: string, pageCount: number): void {
    this.loading = true
    try {
      const source = dataSourceManager.get(sourceId)
      if (source) {
        this.pageUrls = source.getPageUrls(srcChapterId, pageCount)
      }
    } catch (e) {
      console.error('load source pages', e)
    } finally {
      this.loading = false
    }
  }

  /** 扫描已缓存的页面 */
  async scanCachedPages(): Promise<void> {
    try {
      const count = await getCachedPageCount(this.comicId, this.chapterId)
      const cached = new Set<number>()
      for (let i = 1; i <= count; i++) {
        const uri = getLocalPageUri(this.comicId, this.chapterId, i)
        if (uri) cached.add(i)
      }
      this.cachedPages = cached
    } catch {}
  }

  /** 获取页面加载地址：优先本地缓存，回退网络 */
  getPageImageUrl(idx: number): string {
    // 数据源模式：直连（不支持离线缓存）
    if (this.sourceMode) return this.pageUrls[idx] || ''

    const pageNum = idx + 1
    // 检查本地缓存
    const localUri = getLocalPageUri(this.comicId, this.chapterId, pageNum)
    if (localUri) {
      return localUri  // file:// URI
    }
    return this.pageUrls[idx] || '' // http:// 回退
  }

  /** 缓存当前页面到本地 */
  async cacheCurrentPage(): Promise<void> {
    if (this.sourceMode || this.chapterCached || this.isDownloading) return

    const pageNum = this.currentPage
    if (this.cachedPages.has(pageNum)) return  // 已缓存

    try {
      const remoteUrl = this.pageUrls[pageNum - 1]
      if (!remoteUrl) return

      await savePage(this.comicId, this.chapterId, pageNum, remoteUrl)
      this.cachedPages.add(pageNum)
      this.downloadProgress = `📥 ${this.cachedPages.size}/${this.totalPagesNumber}`
    } catch (e) {
      console.error(`cache page ${pageNum} failed`, e)
    }
  }

  /** 缓存整个章节（后台） */
  async downloadChapter(): Promise<void> {
    if (this.sourceMode || this.chapterCached || this.isDownloading) return

    this.isDownloading = true
    this.downloadProgress = '📥 开始缓存...'

    for (let i = 1; i <= this.totalPagesNumber; i++) {
      if (this.cachedPages.has(i)) continue
      try {
        const remoteUrl = this.pageUrls[i - 1]
        if (!remoteUrl) continue
        await savePage(this.comicId, this.chapterId, i, remoteUrl)
        this.cachedPages.add(i)
        this.downloadProgress = `📥 ${i}/${this.totalPagesNumber}`
      } catch (e) {
        console.error(`download page ${i} failed`, e)
      }
    }

    this.chapterCached = this.cachedPages.size >= this.totalPagesNumber
    this.downloadProgress = this.chapterCached ? '✅ 已缓存' : `⚠️ 已缓存 ${this.cachedPages.size} 页`
    this.isDownloading = false
  }

  adjustBrightness(delta: number): void {
    let newVal = this.brightness - delta * 2
    newVal = Math.max(0.1, Math.min(1.0, newVal))
    this.brightness = newVal
    setStorage(this.BRIGHTNESS_KEY, this.brightness.toString())
  }

  resetZoom(): void { this.scale = 1.0; this.isZoomed = false }
  toggleZoom(): void { this.isZoomed ? this.resetZoom() : (this.scale = 2.0, this.isZoomed = true) }
  goToPage(page: number): void {
    this.currentPage = Math.max(1, Math.min(this.totalPagesNumber, page))
  }

  onSettingChange(key: string, value: string | number | boolean): void {
    if (key === 'brightness') this.brightness = value as number
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
        Swiper() {
          ForEach(this.pageUrls, (_url: string, idx: number) => {
            Stack() {
              // 优先本地缓存，回退网络
              Image(this.getPageImageUrl(idx))
                .objectFit(ImageFit.Contain)
                .width('100%').height('100%')
                .scale({ x: this.scale, y: this.scale })
                .animation({ duration: 200, curve: Curve.Friction })
                .onError(() => { this.errorPages.add(idx) })

              // 缓存标记
              if (!this.sourceMode && this.cachedPages.has(idx + 1)) {
                Text('💾').fontSize(14).position({ x: 8, y: 8 })
              }

              // 失败占位
              if (this.errorPages.has(idx)) {
                Column() {
                  Text('⚠️').fontSize(32)
                  Text('加载失败').fontColor('#94a3b8').fontSize(13).margin({ top: 4 })
                  Text('点击重试').fontColor(Colors.primary).fontSize(12)
                }
                .width('100%').height('100%')
                .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
                .backgroundColor('#1a1a2e')
                .onClick(() => { this.errorPages.delete(idx) })
              }

              // 亮度遮罩
              Column() {}.width('100%').height('100%')
                .backgroundColor(`rgba(0,0,0,${1.0 - this.brightness})`)
                .hitTestBehavior(HitTestMode.None)

              // 页码
              Text(`${idx + 1}/${this.totalPagesNumber}`)
                .fontSize(11).fontColor('rgba(255,255,255,0.25)')
                .position({ x: '95%', y: '95%' })
            }
            .width('100%').height('100%').backgroundColor('#000000')
            .gesture(PinchGesture({ fingers: 2 })
              .onActionUpdate((event: GestureEvent) => {
                if (event.scale) {
                  this.scale = Math.max(this.minScale, Math.min(this.maxScale, event.scale * 1.0))
                  this.isZoomed = this.scale > 1.05
                }
              })
              .onActionEnd(() => { if (this.scale < 1.1) this.resetZoom() })
            )
            .gesture(TapGesture({ count: 2 }).onAction(() => { this.toggleZoom() }))
            .gesture(LongPressGesture({ fingers: 1, duration: 500 })
              .onAction(() => { this.showUI = true }))
          })
        }
        .width('100%').height('100%')
        .autoPlay(false).indicator(false).loop(false)
        .onChange((index: number) => {
          this.currentPage = index + 1
          if (this.isZoomed) this.resetZoom()
          // 翻页后触发后台缓存
          this.cacheCurrentPage()
        })

        // 亮度滑动区
        Column() {}.width(this.EDGE_WIDTH).height('100%').position({ x: 0, y: 0 })
          .gesture(PanGesture({ direction: PanDirection.Vertical, distance: 10 })
            .onActionUpdate((event: GestureEvent) => {
              this.adjustBrightness(event.offsetY / 500)
              this.showUI = true
            }))
        .onClick(() => { this.showUI = !this.showUI })

        // 顶部栏
        if (this.showUI) {
          Column() {
            Row() {
              Button() {
                Text('←').fontSize(22).fontColor('#ffffff')
              }.width(40).height(40).backgroundColor('rgba(0,0,0,0.6)').borderRadius(20)
              .onClick(() => { router.back() })

              Column() {
                Text(this.chapterTitle).fontSize(16).fontColor('#ffffff')
                  .fontWeight(FontWeight.Bold).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${this.currentPage}/${this.totalPagesNumber}页`)
                  .fontSize(12).fontColor('#94a3b8').margin({ top: 2 })
              }.alignItems(HorizontalAlign.Center).layoutWeight(1)

              Text(this.isZoomed ? `🔍 ${Math.round(this.scale * 100)}%` : '')
                .fontSize(13).fontColor(Colors.primary)
            }.width('100%').padding({ left: 8, right: 8, top: 36, bottom: 8 })
          }.width('100%').backgroundColor('rgba(0,0,0,0.7)').position({ x: 0, y: 0 })
        }

        // 底部工具栏
        if (this.showUI) {
          Column() {
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

            Row() {
              Text(this.brightness < 0.4 ? '🌙' : '☀️').fontSize(20)
                .onClick(() => {
                  this.brightness = this.brightness < 0.5 ? 1.0 : 0.3
                  setStorage(this.BRIGHTNESS_KEY, this.brightness.toString())
                })

              // 缓存状态/按钮
              if (!this.sourceMode) {
                if (this.chapterCached) {
                  Text('✅ 已缓存').fontSize(12).fontColor(Colors.success).margin({ left: 4 })
                } else if (this.isDownloading) {
                  Text(this.downloadProgress).fontSize(12).fontColor(Colors.warning).margin({ left: 4 })
                } else if (this.cachedPages.size > 0) {
                  Text(`💾 ${this.cachedPages.size}/${this.totalPagesNumber}`)
                    .fontSize(12).fontColor(Colors.primary).margin({ left: 4 })
                    .onClick(() => { this.downloadChapter() })
                }
              }

              Blank()

              Button('◀').fontSize(18).fontColor('#ffffff')
                .backgroundColor('rgba(255,255,255,0.1)').borderRadius(8)
                .onClick(() => { this.goToPage(this.currentPage - 1) })

              Text(`${this.currentPage}/${this.totalPagesNumber}`)
                .fontSize(14).fontColor('#ffffff').margin({ left: 12, right: 12 })

              Button('▶').fontSize(18).fontColor('#ffffff')
                .backgroundColor('rgba(255,255,255,0.1)').borderRadius(8)
                .onClick(() => { this.goToPage(this.currentPage + 1) })

              Blank()

              // 下载整章
              if (!this.sourceMode && !this.chapterCached && !this.isDownloading) {
                Text('📥').fontSize(20).margin({ right: 4 })
                  .onClick(() => { this.downloadChapter() })
              }

              Text('⚙').fontSize(20)
                .onClick(() => { this.showSettings = true })
              Text('⊞').fontSize(22).fontColor('#ffffff').margin({ left: 8 })
                .onClick(() => { this.toggleZoom() })
            }
            .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 32 })
          }
          .width('100%').backgroundColor('rgba(0,0,0,0.7)').position({ x: 0, y: '100%' })
        }

        // 缓存进度提示
        if (this.downloadProgress && !this.showUI) {
          Text(this.downloadProgress).fontSize(12).fontColor('rgba(255,255,255,0.5)')
            .position({ x: '50%', y: 50 }).alignSelf(ItemAlign.Center)
        }

        // 亮度指示
        if (this.brightness < 1.0 && !this.showUI) {
          Text(`🌙 ${Math.round(this.brightness * 100)}%`)
            .fontSize(12).fontColor('rgba(255,255,255,0.5)')
            .position({ x: 8, y: '50%' })
        }

        // 设置面板
        if (this.showSettings) {
          Column() {
            SettingsPanel({
              prefs: this.prefs, currentPage: this.currentPage,
              totalPages: this.totalPagesNumber,
              onClose: () => { this.showSettings = false },
              onChange: (key, value) => { this.onSettingChange(key, value) },
              onJumpPage: (page) => { this.goToPage(page); this.showSettings = false }
            })
          }.width('100%').position({ x: 0, y: '100%' }).backgroundColor('transparent')
        }
      }
    }.width('100%').height('100%')
  }

  @Builder
  LoadingView() {
    Column() {
      Text('📖').fontSize(48)
      Text('加载中...').fontColor('#94a3b8').fontSize(16).margin({ top: 12 })
      LoadingProgress().color(Colors.primary).width(32).height(32).margin({ top: 16 })
    }.width('100%').height('100%')
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .backgroundColor('#000000')
  }

  @Builder
  EmptyView() {
    Column() {
      Text('😅').fontSize(48)
      Text('没有可用的页面').fontColor('#94a3b8').fontSize(16).margin({ top: 12 })
      Button('返回').backgroundColor(Colors.primary).margin({ top: 24 })
        .onClick(() => { router.back() })
    }.width('100%').height('100%')
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .backgroundColor('#000000')
  }
}
