/**
 * 搜索页
 */
import router from '@ohos.router'
import { Colors } from '../utils/Utils'
import { getComics } from '../api/BackendApi'
import type { Comic } from '../model/Types'
import { ComicCard } from '../components/ComicCard'

@Entry
@Component
struct Search {
  @State keyword: string = ''
  @State results: Comic[] = []
  @State searching: boolean = false

  build() {
    Column() {
      // 搜索栏
      Row() {
        Button() {
          Text('←')
            .fontSize(20)
            .fontColor('#ffffff')
        }
        .width(40)
        .height(40)
        .backgroundColor(Colors.surfaceLight)
        .borderRadius(20)
        .onClick(() => { router.back() })

        TextInput({ placeholder: '搜索漫画标题...' })
          .placeholderColor('#64748b')
          .backgroundColor(Colors.surface)
          .fontColor('#ffffff')
          .height(44)
          .borderRadius(22)
          .padding({ left: 16 })
          .margin({ left: 8 })
          .layoutWeight(1)
          .onChange((val: string) => {
            this.keyword = val
          })
          .onSubmit(() => {
            this.doSearch()
          })

        Button('搜索')
          .backgroundColor(Colors.primary)
          .fontSize(14)
          .borderRadius(8)
          .margin({ left: 8 })
          .onClick(() => { this.doSearch() })
      }
      .width('100%')
      .padding(16)

      // 搜索结果
      if (this.searching) {
        Column() {
          LoadingProgress()
            .color(Colors.primary)
          Text('搜索中...')
            .fontSize(14)
            .fontColor(Colors.textSecondary)
            .margin({ top: 8 })
        }
        .width('100%')
        .padding({ top: 60 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.keyword && this.results.length === 0) {
        Column() {
          Text('🔍')
            .fontSize(48)
          Text('没有找到相关漫画')
            .fontSize(16)
            .fontColor(Colors.textSecondary)
            .margin({ top: 12 })
        }
        .width('100%')
        .padding({ top: 60 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (!this.keyword) {
        Column() {
          Text('🔍')
            .fontSize(48)
          Text('输入关键词搜索漫画')
            .fontSize(16)
            .fontColor(Colors.textSecondary)
            .margin({ top: 12 })
        }
        .width('100%')
        .padding({ top: 60 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.results, (item: Comic) => {
            ListItem() {
              ComicCard({
                title: item.title,
                author: item.author,
                coverUrl: item.cover_url,
                views: item.total_views,
                chapterCount: 1
              })
              .onClick(() => {
                router.pushUrl({
                  name: 'ComicDetail',
                  params: { id: item.id }
                })
              })
            }
          })
        }
        .width('100%')
        .padding({ left: 12, right: 12 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.background)
  }

  async doSearch(): Promise<void> {
    if (!this.keyword) return
    this.searching = true
    try {
      const data = await getComics(1, 100)
      const kw = this.keyword.toLowerCase()
      this.results = (data.comics || []).filter((c: Comic) =>
        c.title.toLowerCase().includes(kw) ||
        c.author?.toLowerCase().includes(kw)
      )
    } catch (e) {
      console.error('search failed', e)
    } finally {
      this.searching = false
    }
  }
}
