/**
 * 离线管理页
 * 查看已缓存的章节、清理缓存
 */
import router from '@ohos.router'
import { Colors } from '../utils/Utils'
import { getCacheStats, clearAllCache } from '../utils/OfflineStorage'

interface CacheInfo {
  comics: number
  chapters: number
  pages: number
  size: string
}

@Entry
@Component
struct OfflineManage {
  @State cache: CacheInfo = { comics: 0, chapters: 0, pages: 0, size: '0 B' }
  @State loading: boolean = true

  async aboutToAppear(): Promise<void> {
    await this.refreshStats()
  }

  async refreshStats(): Promise<void> {
    this.loading = true
    try {
      this.cache = await getCacheStats()
    } catch (e) {
      console.error('cache stats', e)
    } finally {
      this.loading = false
    }
  }

  build() {
    Column() {
      // 顶部
      Row() {
        Button() {
          Text('←').fontSize(20).fontColor('#ffffff')
        }
        .width(40).height(40).backgroundColor(Colors.surfaceLight).borderRadius(20)
        .onClick(() => { router.back() })

        Text('离线缓存').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#ffffff')
          .margin({ left: 12 })
      }
      .width('100%').padding(16)

      // 缓存统计卡片
      Column() {
        Text('📦').fontSize(40)
        Text(this.cache.size).fontSize(32).fontWeight(FontWeight.Bold)
          .fontColor('#ffffff').margin({ top: 8 })

        Row() {
          Column() {
            Text(`${this.cache.comics}`).fontSize(20).fontColor('#e2e8f0')
            Text('部漫画').fontSize(12).fontColor(Colors.textSecondary)
          }.layoutWeight(1)

          Column() {
            Text(`${this.cache.chapters}`).fontSize(20).fontColor('#e2e8f0')
            Text('个章节').fontSize(12).fontColor(Colors.textSecondary)
          }.layoutWeight(1)

          Column() {
            Text(`${this.cache.pages}`).fontSize(20).fontColor('#e2e8f0')
            Text('张图片').fontSize(12).fontColor(Colors.textSecondary)
          }.layoutWeight(1)
        }
        .width('100%').padding({ top: 16 })
      }
      .width('90%').padding(24)
      .backgroundColor(Colors.surface).borderRadius(16)
      .margin({ top: 8 })

      // 说明
      Column() {
        Row() {
          Text('💡').fontSize(16)
          Text('漫画图片在阅读时自动缓存到本地，下次阅读无需网络').fontSize(13)
            .fontColor(Colors.textSecondary).margin({ left: 8 })
        }.width('100%').margin({ top: 16 })

        Row() {
          Text('💡').fontSize(16)
          Text('浏览「数据源」中的漫画不会缓存').fontSize(13)
            .fontColor(Colors.textSecondary).margin({ left: 8 })
        }.width('100%').margin({ top: 8 })
      }
      .padding(16)

      Blank()

      // 操作按钮
      Column() {
        if (this.cache.pages > 0) {
          Button('清空所有缓存')
            .width('90%').height(48)
            .backgroundColor(Colors.accent).borderRadius(12)
            .onClick(async () => {
              await clearAllCache()
              await this.refreshStats()
            })
            .margin({ bottom: 12 })
        }

        Button('刷新统计')
          .width('90%').height(48)
          .backgroundColor(Colors.surfaceLight).fontColor('#ffffff').borderRadius(12)
          .onClick(() => { this.refreshStats() })
      }
      .width('100%')
      .margin({ bottom: 32 })
    }
    .width('100%').height('100%').backgroundColor(Colors.background)
  }
}
