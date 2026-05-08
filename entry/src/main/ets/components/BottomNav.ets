/**
 * 底部导航栏组件
 */
@Component
export struct BottomNav {
  @Link currentIndex: number

  private tabs: string[] = ['首页', '发现', '收藏', '我的']
  private icons: string[] = ['🏠', '🔍', '⭐', '👤']

  build() {
    Row() {
      ForEach(this.tabs, (tab: string, index: number) => {
        Column() {
          Text(this.icons[index])
            .fontSize(22)
          Text(tab)
            .fontSize(11)
            .fontColor(this.currentIndex === index ? '#7c3aed' : '#94a3b8')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .onClick(() => {
          this.currentIndex = index
        })
      })
    }
    .width('100%')
    .padding({ top: 8, bottom: 12 })
    .backgroundColor('#16213e')
  }
}
