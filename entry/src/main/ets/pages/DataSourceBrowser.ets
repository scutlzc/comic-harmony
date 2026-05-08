/**
 * 数据源浏览页
 * 浏览数据源中的漫画库 → 漫画 → 章节 → 阅读
 */
import router from '@ohos.router'
import { Colors, getStorage } from '../utils/Utils'
import { dataSourceManager, IDataSource } from '../datasource/Manager'
import { DataSourceType, DataSourceConfig } from '../model/DataSource'
import { getBreakpoint, ResponsiveSpacing, Breakpoint } from '../utils/Responsive'

interface SourceComic {
  id: string
  title: string
  author: string
  description: string
  coverUrl: string
  chapterCount: number
}

interface SourceChapter {
  id: string
  title: string
  sortOrder: number
  pageCount: number
}

enum BrowseLevel {
  LIBRARIES,   // 显示书库
  COMICS,      // 显示漫画
  CHAPTERS,    // 显示章节
  READING      // 阅读中
}

@Entry
@Component
struct DataSourceBrowser {
  @State level: BrowseLevel = BrowseLevel.LIBRARIES
  @State libraries: { id: string, name: string }[] = []
  @State comics: SourceComic[] = []
  @State chapters: SourceChapter[] = []
  @State loading: boolean = true
  @State currentTitle: string = ''
  @State selectedLibraryId: string = ''
  @State selectedComicId: string = ''
  @State error: string = ''

  private sourceId: string = ''
  private source: IDataSource | null = null

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, Object> || {}
    this.sourceId = params.sourceId as string || ''

    this.source = dataSourceManager.get(this.sourceId)
    if (!this.source) {
      this.error = '数据源未连接'
      return
    }
    await this.loadLibraries()
  }

  async loadLibraries(): Promise<void> {
    this.loading = true
    this.level = BrowseLevel.LIBRARIES
    this.currentTitle = this.source?.name || '浏览'
    try {
      const libs = await this.source?.getLibraries() || []
      this.libraries = libs
    } catch (e) {
      this.error = '加载书库失败: ' + JSON.stringify(e)
    } finally {
      this.loading = false
    }
  }

  async loadComics(libraryId: string): Promise<void> {
    this.loading = true
    this.level = BrowseLevel.COMICS
    this.selectedLibraryId = libraryId
    const libName = this.libraries.find(l => l.id === libraryId)?.name || ''
    this.currentTitle = libName
    try {
      const cmics = await this.source?.getComics(libraryId) || []
      this.comics = cmics
    } catch (e) {
      this.error = '加载漫画列表失败'
    } finally {
      this.loading = false
    }
  }

  async loadChapters(comicId: string): Promise<void> {
    this.loading = true
    this.level = BrowseLevel.CHAPTERS
    this.selectedComicId = comicId
    const comic = this.comics.find(c => c.id === comicId)
    this.currentTitle = comic?.title || '章节'
    try {
      const chaps = await this.source?.getChapters(comicId) || []
      this.chapters = chaps
    } catch (e) {
      this.error = '加载章节失败'
    } finally {
      this.loading = false
    }
  }

  goToReader(chapterId: string, pageCount: number): void {
    router.pushUrl({
      name: 'Reader',
      params: {
        sourceId: this.sourceId,
        srcChapterId: chapterId,
        pageCount: pageCount,
        title: this.chapters.find(c => c.id === chapterId)?.title || ''
      }
    })
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Button() {
          Text('←').fontSize(20).fontColor('#ffffff')
        }
        .width(40).height(40)
        .backgroundColor(Colors.surfaceLight).borderRadius(20)
        .onClick(() => {
          if (this.level === BrowseLevel.LIBRARIES) {
            router.back()
          } else if (this.level === BrowseLevel.COMICS) {
            this.loadLibraries()
          } else {
            this.loadComics(this.selectedLibraryId)
          }
        })

        Text(this.currentTitle)
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#ffffff')
          .margin({ left: 12 }).layoutWeight(1)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.level === BrowseLevel.CHAPTERS) {
          Text(`共${this.chapters.length}话`).fontSize(12).fontColor(Colors.textSecondary)
        }
      }
      .width('100%').padding(16)

      if (this.error) {
        Column() {
          Text('⚠️').fontSize(48)
          Text(this.error).fontSize(14).fontColor(Colors.accent).margin({ top: 12 })
          Button('重试').backgroundColor(Colors.primary).margin({ top: 16 })
            .onClick(() => { this.loadLibraries() })
        }
        .width('100%').padding({ top: 60 })
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else if (this.loading) {
        Column() {
          LoadingProgress().color(Colors.primary).width(32).height(32)
          Text('加载中...').fontColor(Colors.textSecondary).fontSize(14).margin({ top: 12 })
        }
        .width('100%').padding({ top: 60 })
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            if (this.level === BrowseLevel.LIBRARIES) {
              this.LibraryList()
            } else if (this.level === BrowseLevel.COMICS) {
              this.ComicList()
            } else if (this.level === BrowseLevel.CHAPTERS) {
              this.ChapterList()
            }
          }.width('100%')
        }
      }
    }
    .width('100%').height('100%').backgroundColor(Colors.background)
  }

  @Builder
  LibraryList() {
    ForEach(this.libraries, (lib: { id: string, name: string }) => {
      Row() {
        Text('📁').fontSize(28)
        Text(lib.name).fontSize(16).fontColor('#e2e8f0').margin({ left: 12 })
        Blank()
        Text('>').fontColor(Colors.textSecondary).fontSize(16)
      }
      .width('100%').padding(16)
      .backgroundColor(Colors.surface).borderRadius(12)
      .margin({ left: 16, right: 16, top: 8 })
      .onClick(() => { this.loadComics(lib.id) })
    })

    if (this.libraries.length === 0) {
      Column() {
        Text('📂').fontSize(48)
        Text('没有找到书库').fontSize(16).fontColor(Colors.textSecondary).margin({ top: 12 })
      }
      .width('100%').padding({ top: 40 })
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    }
  }

  @Builder
  ComicList() {
    if (this.comics.length === 0) {
      Column() {
        Text('📖').fontSize(48)
        Text('没有漫画').fontSize(16).fontColor(Colors.textSecondary).margin({ top: 12 })
      }
      .width('100%').padding({ top: 40 })
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    } else {
      Grid() {
        ForEach(this.comics, (item: SourceComic) => {
          GridItem() {
            Column() {
              // 封面
              Stack() {
                if (item.coverUrl) {
                  Image(item.coverUrl)
                    .width('100%')
                    .aspectRatio(0.7)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)
                } else {
                  Column() {
                    Text('📖').fontSize(36)
                    Text(item.title.slice(0, 4)).fontSize(11).fontColor('#94a3b8')
                  }
                  .width('100%')
                  .aspectRatio(0.7)
                  .backgroundColor('#1f3056').borderRadius(8)
                  .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
                }
              }

              Text(item.title)
                .fontSize(13).fontWeight(FontWeight.Bold).fontColor('#e2e8f0')
                .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%').margin({ top: 4 })

              if (item.chapterCount > 0) {
                Text(`${item.chapterCount}话`).fontSize(11).fontColor(Colors.textSecondary)
              }
            }
            .width('100%').padding(6)
            .backgroundColor(Colors.surface).borderRadius(10)
          }
          .onClick(() => { this.loadChapters(item.id) })
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(8).columnsGap(8)
      .padding({ left: 16, right: 16, top: 8 })
    }
  }

  @Builder
  ChapterList() {
    ForEach(this.chapters, (item: SourceChapter) => {
      Row() {
        Column() {
          Text(item.title).fontSize(15).fontColor('#e2e8f0').maxLines(1)
          if (item.pageCount > 0) {
            Text(`${item.pageCount}页`).fontSize(12).fontColor(Colors.textSecondary).margin({ top: 4 })
          }
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Text('▶').fontSize(16).fontColor(Colors.primary)
      }
      .width('100%').padding(16)
      .backgroundColor(Colors.surface).borderRadius(12)
      .margin({ left: 16, right: 16, top: 6 })
      .onClick(() => {
        this.goToReader(item.id, item.pageCount)
      })
    })

    if (this.chapters.length === 0) {
      Column() {
        Text('📄').fontSize(48)
        Text('没有章节').fontSize(16).fontColor(Colors.textSecondary).margin({ top: 12 })
      }
      .width('100%').padding({ top: 40 })
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    }
  }
}
