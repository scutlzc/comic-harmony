/**
 * 骨架屏加载组件
 */
@Component
export struct SkeletonCard {
  build() {
    Row() {
      // 封面骨架
      Column() {}
      .width(100)
      .height(140)
      .backgroundColor('#2d3748')
      .borderRadius(8)

      Column() {
        // 标题骨架
        Column() {}
        .width('60%')
        .height(16)
        .backgroundColor('#2d3748')
        .borderRadius(4)

        // 作者骨架
        Column() {}
        .width('30%')
        .height(12)
        .backgroundColor('#2d3748')
        .borderRadius(4)
        .margin({ top: 8 })

        // 标签骨架
        Row() {
          Column() {}
          .width(40)
          .height(20)
          .backgroundColor('#2d3748')
          .borderRadius(4)
        }
        .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#16213e')
    .borderRadius(12)
  }
}
