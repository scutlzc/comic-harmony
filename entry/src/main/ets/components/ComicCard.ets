/**
 * 漫画卡片组件（首页列表项）
 * @State 驱动
 */
@Component
export struct ComicCard {
  @Prop title: string = ''
  @Prop author: string = ''
  @Prop coverUrl: string = ''
  @Prop views: number = 0
  @Prop chapterCount: number = 0

  build() {
    Row() {
      // 封面
      Stack() {
        if (this.coverUrl) {
          Image(this.coverUrl)
            .width(100)
            .height(140)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            Text('📖')
              .fontSize(32)
            Text(this.title.length > 4 ? this.title.slice(0, 4) : this.title)
              .fontSize(12)
              .fontColor('#94a3b8')
          }
          .width(100)
          .height(140)
          .backgroundColor('#1f3056')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width(100)
      .height(140)

      // 信息
      Column() {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        if (this.author) {
          Text(this.author)
            .fontSize(13)
            .fontColor('#94a3b8')
            .margin({ top: 4 })
        }

        // 标签行
        Row() {
          Text(`${this.chapterCount}话`)
            .fontSize(12)
            .fontColor('#94a3b8')
            .backgroundColor('#2d3748')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(4)

          if (this.views > 0) {
            Text(`${formatCount(this.views)}阅读`)
              .fontSize(12)
              .fontColor('#94a3b8')
              .margin({ left: 8 })
          }
        }
        .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .height(140)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#16213e')
    .borderRadius(12)
  }
}

function formatCount(n: number): string {
  if (n >= 10000) return (n / 10000).toFixed(1) + '万'
  if (n >= 1000) return (n / 1000).toFixed(1) + 'k'
  return n.toString()
}
