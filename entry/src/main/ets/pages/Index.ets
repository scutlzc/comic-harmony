/**
 * 首页 - 自适应折叠屏/平板/手机
 * - 手机: 底部导航 + 单列列表
 * - 折叠屏展开(600px+): 底部导航 + 双列网格
 * - 平板(840px+): 侧边导航 + 多列网格
 * - 平板横屏(1080px+): 侧边导航 + 主从布局
 */
import router from '@ohos.router'
import display from '@ohos.display'
import window from '@ohos.window'
import { Colors } from '../utils/Utils'
import { 
  getBreakpoint, getLayoutMode, detectDeviceForm,
  Breakpoint, LayoutMode, DeviceForm, ResponsiveSpacing
} from '../utils/Responsive'
import { BottomNav } from '../components/BottomNav'
import { SideNav } from '../components/SideNav'
import { ComicGridCard } from '../components/ComicGridCard'
import { SkeletonCard } from '../components/SkeletonCard'
import { DataSourceCard } from '../components/DataSourceCard'
import { getComics } from '../api/BackendApi'
import { dataSourceManager } from '../datasource/Manager'
import type { DataSourceConfig } from '../model/DataSource'
import type { Comic } from '../model/Types'

const TABS = ['首页', '发现', '收藏', '我的']

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State comics: Comic[] = []
  @State loading: boolean = true
  @State breakpoint: Breakpoint = Breakpoint.SM
  @State layoutMode: LayoutMode = LayoutMode.SINGLE
  @State deviceForm: DeviceForm = DeviceForm.PHONE
  @State windowWidth: number = 360
  @State columns: number = 1
  @State selectedComic: Comic | null = null
  @State sources: DataSourceConfig[] = []  // master-detail 选中

  async aboutToAppear(): void {
    // 获取屏幕信息
    try {
      const win = await window.getLastWindow(undefined as Object as UIAbilityContext)
      const props = win.getWindowProperties()
      this.windowWidth = props.windowRect.width
      this.updateLayout(this.windowWidth)
    } catch {
      this.updateLayout(360)
    }
    this.loadComics()
    this.loadSources()
  }

  onPageShow(): void {
    // 窗口变化时重新适配（折叠屏展开/折叠）
    this.refreshWindowSize()
    this.loadSources()
  }

  async refreshWindowSize(): Promise<void> {
    try {
      const win = await window.getLastWindow(undefined as Object as UIAbilityContext)
      const props = win.getWindowProperties()
      if (props.windowRect.width !== this.windowWidth) {
        this.windowWidth = props.windowRect.width
        this.updateLayout(this.windowWidth)
      }
    } catch {}
  }

  updateLayout(width: number): void {
    this.breakpoint = getBreakpoint(width)
    this.deviceForm = detectDeviceForm(width)
    this.layoutMode = getLayoutMode(this.breakpoint, this.deviceForm === DeviceForm.FOLDABLE)
    this.columns = ResponsiveSpacing.getCardColumns(this.breakpoint)
  }

  async loadComics(): Promise<void> {
    this.loading = true
    try {
      const data = await getComics()
      this.comics = data.comics || []
    } catch (e) {
      console.error('load comics failed', e)
    } finally {
      this.loading = false
    }
  }

  loadSources(): void {
    this.sources = dataSourceManager.getAllConfigs()
  }

  build() {
    // 平板/桌面模式 → 侧边导航 + 内容
    if (this.layoutMode >= LayoutMode.DUAL) {
      this.TabletLayout()
    } else {
      this.PhoneLayout()
    }
  }

  // ---- 手机模式 ----
  @Builder
  PhoneLayout() {
    Column() {
      if (this.currentTab === 0) {
        this.HomeContent()
      } else if (this.currentTab === 1) {
        this.DiscoverContent()
      } else if (this.currentTab === 2) {
        this.FavoritesContent()
      } else if (this.currentTab === 3) {
        this.ProfileContent()
      }
      BottomNav({ currentIndex: $currentTab })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.background)
  }

  // ---- 平板/桌面模式 ----
  @Builder
  TabletLayout() {
    Row() {
      // 侧边导航
      SideNav({ currentIndex: $currentTab })

      // 主内容区
      if (this.layoutMode === LayoutMode.MASTER_DETAIL) {
        // 主从布局: 列表 + 详情
        Row() {
          // 主栏: 漫画列表
          Column() {
            this.PageHeader()
            this.ComicGrid()
          }
          .layoutWeight(1)

          // 从栏: 详情面板
          if (this.selectedComic) {
            Column() {
              Text(this.selectedComic.title)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ffffff')
            }
            .width(360)
            .backgroundColor(Colors.surface)
            .border({ left: { width: 1, color: Colors.border } })
          }
        }
        .layoutWeight(1)
      } else {
        // 普通平板布局
        Column() {
          if (this.currentTab === 0) {
            this.HomeContent()
          } else if (this.currentTab === 1) {
            this.DiscoverContent()
          } else if (this.currentTab === 2) {
            this.FavoritesContent()
          } else if (this.currentTab === 3) {
            this.ProfileContent()
          }
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.background)
  }

  // ---- 首页内容 ----
  @Builder
  HomeContent() {
    Column() {
      this.PageHeader()

      if (this.loading) {
        this.LoadingState()
      } else if (this.comics.length === 0) {
        this.EmptyState()
      } else {
        this.ComicGrid()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  PageHeader() {
    Row() {
      Text('ComicHarmony')
        .fontSize(this.layoutMode >= LayoutMode.DUAL ? 28 : 24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')

      Blank()

      Button() {
        Text('🔍')
          .fontSize(18)
      }
      .width(40)
      .height(40)
      .backgroundColor(Colors.surfaceLight)
      .borderRadius(20)
      .onClick(() => {
        router.pushUrl({ name: 'Search' })
      })

      Button() {
        Text('⚙')
          .fontSize(18)
      }
      .width(40)
      .height(40)
      .backgroundColor(Colors.surfaceLight)
      .borderRadius(20)
      .margin({ left: 8 })
      .onClick(() => {
        router.pushUrl({ name: 'SourceManage' })
      })
    }
    .width('100%')
    .padding({
      left: ResponsiveSpacing.getPadding(this.breakpoint),
      right: ResponsiveSpacing.getPadding(this.breakpoint),
      top: this.layoutMode >= LayoutMode.DUAL ? 24 : 12,
      bottom: 8
    })
  }

  @Builder
  LoadingState() {
    Column() {
      ForEach([1, 2, 3, 4], () => {
        SkeletonCard()
      })
    }
    .padding({ top: 8 })
  }

  @Builder
  EmptyState() {
    Column() {
      Text('📚')
        .fontSize(64)
      Text('还没有漫画')
        .fontSize(16)
        .fontColor(Colors.textSecondary)
        .margin({ top: 16 })
      Text('上传 CBZ/EPUB/PDF 或添加数据源')
        .fontSize(13)
        .fontColor('#64748b')
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ComicGrid() {
    if (this.columns <= 1) {
      // 单列列表（手机）
      List() {
        ForEach(this.comics, (item: Comic) => {
          ListItem() {
            this.ComicListItem(item)
          }
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
    } else {
      // 多列网格（平板）
      Scroll() {
        Column() {
          // 按列数分组
          ForEach(this.chunkArray(this.comics, this.columns), (row: Comic[]) => {
            Row() {
              ForEach(row, (item: Comic) => {
                ComicGridCard({
                  title: item.title,
                  author: item.author,
                  coverUrl: item.cover_url,
                  views: item.total_views,
                  width: this.getCardWidth()
                })
                .layoutWeight(1)
                .onClick(() => {
                  if (this.layoutMode === LayoutMode.MASTER_DETAIL) {
                    this.selectedComic = item
                  } else {
                    router.pushUrl({
                      name: 'ComicDetail',
                      params: { id: item.id }
                    })
                  }
                })
              })
            }
            .width('100%')
            .padding({ left: ResponsiveSpacing.getPadding(this.breakpoint),
                       right: ResponsiveSpacing.getPadding(this.breakpoint) })
          })
        }
        .padding({ top: 8, bottom: 16 })
      }
    }
  }

  getCardWidth(): number {
    return ResponsiveSpacing.getCardWidth(this.breakpoint, this.windowWidth)
  }

  chunkArray(arr: Comic[], size: number): Comic[][] {
    const chunks: Comic[][] = []
    for (let i = 0; i < arr.length; i += size) {
      chunks.push(arr.slice(i, i + size))
    }
    return chunks
  }

  @Builder
  ComicListItem(item: Comic) {
    Row() {
      Stack() {
        if (item.cover_url) {
          Image(item.cover_url)
            .width(100).height(140).borderRadius(8).objectFit(ImageFit.Cover)
        } else {
          Column() {
            Text('📖').fontSize(32)
            Text(item.title.slice(0, 4)).fontSize(12).fontColor('#94a3b8')
          }
          .width(100).height(140).backgroundColor('#1f3056').borderRadius(8)
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        }
      }
      .width(100).height(140)

      Column() {
        Text(item.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#ffffff')
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
        if (item.author) {
          Text(item.author).fontSize(13).fontColor('#94a3b8').margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start).margin({ left: 12 })
      .height(140).justifyContent(FlexAlign.Center)
    }
    .width('100%').padding(12)
    .backgroundColor(Colors.surface).borderRadius(12).margin({ top: 4 })
  }

  // ---- 占位页面 ----
  @Builder
  DiscoverContent() {
    Column() {
      Row() {
        Text('发现').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#ffffff')
        Blank()
        Button('+ 添加').fontSize(13).backgroundColor(Colors.primary).borderRadius(8)
          .onClick(() => { router.pushUrl({ name: 'SourceManage' }) })
      }
      .width('100%').padding({ left: ResponsiveSpacing.getPadding(this.breakpoint), right: 16, top: 16 })

      Text('浏览已添加数据源中的漫画')
        .fontSize(13).fontColor(Colors.textSecondary)
        .width('100%').padding({ left: ResponsiveSpacing.getPadding(this.breakpoint), bottom: 8 })

      if (this.sources.length === 0) {
        Column() {
          Text('🔗').fontSize(48)
          Text('还没有数据源').fontSize(16).fontColor(Colors.textSecondary).margin({ top: 12 })
          Text('在「我的 → 数据源管理」中添加').fontSize(13).fontColor('#64748b').margin({ top: 4 })
        }
        .width('100%').padding({ top: 40 })
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.sources, (item: DataSourceConfig) => {
              DataSourceCard({
                name: item.name,
                sourceType: item.type as DataSourceType,
                url: item.url,
                status: 'connected'
              })
              .margin({ left: ResponsiveSpacing.getPadding(this.breakpoint),
                       right: ResponsiveSpacing.getPadding(this.breakpoint),
                       top: 4, bottom: 4 })
              .onClick(() => {
                router.pushUrl({
                  name: 'DataSourceBrowser',
                  params: { sourceId: item.id }
                })
              })
            })
          }.width('100%')
        }
      }
    }
    .width('100%').height('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  FavoritesContent() {
    Column() {
      Text('收藏').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#ffffff')
        .width('100%').padding({ left: ResponsiveSpacing.getPadding(this.breakpoint), top: 16 })
      Column() {
        Text('⭐').fontSize(48)
        Text('还没有收藏').fontSize(16).fontColor(Colors.textSecondary).margin({ top: 12 })
      }
      .width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%')
  }

  @Builder
  ProfileContent() {
    Column() {
      Text('我的').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#ffffff')
        .width('100%').padding({ left: ResponsiveSpacing.getPadding(this.breakpoint), top: 16 })
      Column() {
        Text('👤').fontSize(48)
        Text('未登录').fontSize(16).fontColor(Colors.textSecondary).margin({ top: 12 })
        Button('登录 / 注册').backgroundColor(Colors.primary).margin({ top: 16 })
          .onClick(() => { router.pushUrl({ name: 'Login' }) })
        Button('数据源管理').backgroundColor(Colors.surfaceLight).fontColor(Colors.text).margin({ top: 12 })
          .onClick(() => { router.pushUrl({ name: 'SourceManage' }) })
      }
      .width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%')
  }
}
