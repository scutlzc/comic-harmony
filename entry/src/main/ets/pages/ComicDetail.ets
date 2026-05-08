/**
 * 漫画详情页 - 自适应折叠屏
 */
import router from '@ohos.router'
import window from '@ohos.window'
import { Colors, formatTime } from '../utils/Utils'
import { getBreakpoint, LayoutMode, ResponsiveSpacing, Breakpoint } from '../utils/Responsive'
import { getComicDetail, getChapters } from '../api/BackendApi'
import type { Comic, Chapter } from '../model/Types'

interface Params {
  id: number
}

@Entry
@Component
struct ComicDetail {
  @State comic: Comic | null = null
  @State chapters: Chapter[] = []
  @State loading: boolean = true
  @State breakpoint: Breakpoint = Breakpoint.SM
  @State windowWidth: number = 360
  private comicId: number = 0

  async aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object> || {}
    this.comicId = params.id as number
    try {
      const win = await window.getLastWindow(undefined as Object as UIAbilityContext)
      const props = win.getWindowProperties()
      this.windowWidth = props.windowRect.width
      this.breakpoint = getBreakpoint(this.windowWidth)
    } catch {}
    this.loadDetail()
  }

  onPageShow(): void {
    this.refreshWindowSize()
  }

  async refreshWindowSize(): Promise<void> {
    try {
      const win = await window.getLastWindow(undefined as Object as UIAbilityContext)
      const props = win.getWindowProperties()
      if (props.windowRect.width !== this.windowWidth) {
        this.windowWidth = props.windowRect.width
        this.breakpoint = getBreakpoint(this.windowWidth)
      }
    } catch {}
  }

  async loadDetail(): Promise<void> {
    this.loading = true
    try {
      const [comic, chapterData] = await Promise.all([
        getComicDetail(this.comicId),
        getChapters(this.comicId)
      ])
      this.comic = comic
      this.chapters = chapterData.chapters || []
    } catch (e) {
      console.error('load detail failed', e)
    } finally {
      this.loading = false
    }
  }

  get padding(): number {
    return ResponsiveSpacing.getPadding(this.breakpoint)
  }

  build() {
    Column() {
      if (this.loading) {
        Column() {
          Text('加载中...').fontColor(Colors.textSecondary)
        }.width('100%').height('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else if (this.comic) {
        Scroll() {
          Column() {
            // 横向布局（封面+信息），可按屏幕自适应
            Row() {
              Stack() {
                if (this.comic.cover_url) {
                  Image(this.comic.cover_url)
                    .width(this.breakpoint >= Breakpoint.MD ? 180 : 140)
                    .height(this.breakpoint >= Breakpoint.MD ? 260 : 200)
                    .borderRadius(12).objectFit(ImageFit.Cover)
                } else {
                  Column() {
                    Text('📖').fontSize(48)
                  }
                  .width(this.breakpoint >= Breakpoint.MD ? 180 : 140)
                  .height(this.breakpoint >= Breakpoint.MD ? 260 : 200)
                  .backgroundColor(Colors.surfaceLight).borderRadius(12)
                  .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
                }
              }

              Column() {
                Text(this.comic.title)
                  .fontSize(this.breakpoint >= Breakpoint.MD ? 24 : 20)
                  .fontWeight(FontWeight.Bold).fontColor('#ffffff').maxLines(2)
                if (this.comic.author) {
                  Text(this.comic.author).fontSize(14).fontColor(Colors.textSecondary).margin({ top: 4 })
                }
                Row() {
                  Text(this.comic.status === 1 ? '已完结' : '连载中')
                    .fontSize(12).fontColor(Colors.success)
                    .backgroundColor('#1a3a2a').padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(4)
                }.margin({ top: 12 })

                Row() {
                  Text(`❤️ ${this.comic.total_likes}`).fontSize(13).fontColor(Colors.textSecondary)
                  Text(`👁️ ${this.comic.total_views}`).fontSize(13).fontColor(Colors.textSecondary).margin({ left: 16 })
                }.margin({ top: 8 })
              }
              .alignItems(HorizontalAlign.Start).margin({ left: 16 })
            }
            .padding(this.padding)

            // 简介
            if (this.comic.description) {
              Column() {
                Text('简介').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#ffffff').width('100%')
                Text(this.comic.description).fontSize(14).fontColor(Colors.textSecondary)
                  .lineHeight(22).width('100%').margin({ top: 8 })
              }.padding({ left: this.padding, right: this.padding })
            }

            // 章节列表
            Column() {
              Text(`章节 (${this.chapters.length})`)
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#ffffff')
                .width('100%').margin({ bottom: 8 })

              ForEach(this.chapters, (item: Chapter) => {
                Row() {
                  Column() {
                    Text(item.title).fontSize(15).fontColor('#e2e8f0').maxLines(1)
                    Row() {
                      Text(`${item.page_count}页`).fontSize(12).fontColor(Colors.textSecondary)
                      Text(formatTime(item.created_at)).fontSize(12).fontColor(Colors.textSecondary).margin({ left: 12 })
                    }.margin({ top: 4 })
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  Text('▶').fontSize(16).fontColor(Colors.primary)
                }
                .width('100%').padding({ left: this.padding, right: this.padding, top: 12, bottom: 12 })
                .backgroundColor(Colors.surface).borderRadius(8).margin({ top: 6 })
                .onClick(() => {
                  router.pushUrl({
                    name: 'Reader',
                    params: { chapterId: item.id }
                  })
                })
              })
            }.padding(this.padding)
          }.width('100%')
        }
      }
    }
    .width('100%').height('100%').backgroundColor(Colors.background)
  }
}
