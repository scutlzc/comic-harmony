/**
 * 收藏页
 */
import router from '@ohos.router'
import { Colors } from '../utils/Utils'

interface FavoriteItem {
  id: number
  title: string
  coverUrl: string
  latestChapter: string
  updateTime: string
}

@Entry
@Component
struct Favorites {
  @State items: FavoriteItem[] = []

  build() {
    Column() {
      // 顶部
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

        Text('我的收藏')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .margin({ left: 12 })
      }
      .width('100%')
      .padding(16)

      if (this.items.length === 0) {
        Column() {
          Text('⭐')
            .fontSize(64)
          Text('还没有收藏任何漫画')
            .fontSize(16)
            .fontColor(Colors.textSecondary)
            .margin({ top: 16 })
          Text('浏览漫画时点击收藏即可')
            .fontSize(13)
            .fontColor('#64748b')
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.items, (item: FavoriteItem) => {
            ListItem() {
              Row() {
                // 封面
                Stack() {
                  Text('📖')
                    .fontSize(32)
                }
                .width(64)
                .height(90)
                .backgroundColor(Colors.surfaceLight)
                .borderRadius(8)

                Column() {
                  Text(item.title)
                    .fontSize(15)
                    .fontColor('#e2e8f0')
                    .maxLines(1)

                  if (item.latestChapter) {
                    Text(`最新: ${item.latestChapter}`)
                      .fontSize(12)
                      .fontColor(Colors.textSecondary)
                      .margin({ top: 4 })
                  }

                  Text(item.updateTime)
                    .fontSize(11)
                    .fontColor('#64748b')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 12 })
                .layoutWeight(1)
              }
              .width('100%')
              .padding(12)
              .backgroundColor(Colors.surface)
              .borderRadius(12)
            }
          })
        }
        .width('100%')
        .padding(16)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.background)
  }
}
