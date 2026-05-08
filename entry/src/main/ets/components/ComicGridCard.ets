/**
 * 漫画网格卡片（平板/桌面网格视图）
 */
import { Colors } from '../utils/Utils'

@Component
export struct ComicGridCard {
  @Prop title: string = ''
  @Prop author: string = ''
  @Prop coverUrl: string = ''
  @Prop views: number = 0
  @Prop width: number = 180

  build() {
    Column() {
      // 封面
      Stack() {
        if (this.coverUrl) {
          Image(this.coverUrl)
            .width(this.width - 16)
            .height((this.width - 16) * 1.4)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            Text('📖')
              .fontSize(40)
          }
          .width(this.width - 16)
          .height((this.width - 16) * 1.4)
          .backgroundColor('#1f3056')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width(this.width - 16)

      // 标题
      Text(this.title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width(this.width - 16)
        .margin({ top: 6 })

      // 作者
      if (this.author) {
        Text(this.author)
          .fontSize(12)
          .fontColor('#94a3b8')
          .maxLines(1)
          .width(this.width - 16)
          .margin({ top: 2 })
      }
    }
    .width(this.width)
    .padding(8)
    .backgroundColor(Colors.surface)
    .borderRadius(12)
    .margin({ top: 8, bottom: 4 })
  }
}
