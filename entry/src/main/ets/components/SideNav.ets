/**
 * 侧边导航栏（平板/桌面）
 */
import { Colors } from '../utils/Utils'

const TABS = [
  { icon: '🏠', label: '首页' },
  { icon: '🔍', label: '发现' },
  { icon: '⭐', label: '收藏' },
  { icon: '👤', label: '我的' },
]

@Component
export struct SideNav {
  @Link currentIndex: number

  build() {
    Column() {
      // Logo
      Column() {
        Text('📖')
          .fontSize(32)
        Text('CH')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .margin({ top: 4 })
      }
      .padding({ top: 32, bottom: 24 })

      // 导航项
      ForEach(TABS, (tab: { icon: string, label: string }, index: number) => {
        Column() {
          Text(tab.icon)
            .fontSize(22)
          Text(tab.label)
            .fontSize(11)
            .fontColor(this.currentIndex === index ? '#7c3aed' : '#94a3b8')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .backgroundColor(this.currentIndex === index ?
          'rgba(124, 58, 237, 0.1)' : 'transparent')
        .border({ left: this.currentIndex === index ?
          { width: 3, color: Colors.primary } : { width: 0 } })
        .onClick(() => {
          this.currentIndex = index
        })
      })

      Blank()
    }
    .width(72)
    .height('100%')
    .backgroundColor(Colors.surface)
    .border({ right: { width: 1, color: Colors.border } })
  }
}
