/**
 * 阅读器设置面板（浮层组件）
 * 在阅读器中覆盖显示设置选项
 */
import { Colors } from '../utils/Utils'
import {
  ReaderPreferences, BackgroundMode, ReadingDirection,
  PageTransition, PageLayout, getBackgroundColor
} from '../utils/ReaderSettings'

interface SettingsPanelProps {
  prefs: ReaderPreferences
  onClose: () => void
  onChange: (key: string, value: string | number | boolean) => void
  onJumpPage: (page: number) => void
  currentPage: number
  totalPages: number
}

@Component
export struct SettingsPanel {
  @Prop prefs: ReaderPreferences = {
    direction: ReadingDirection.LTR,
    transition: PageTransition.SLIDE,
    layout: PageLayout.SINGLE,
    background: BackgroundMode.BLACK,
    brightness: 1.0,
    tapToNext: true,
    lockRotation: false,
    showPageNumber: true,
    volumeKeys: true,
  }
  @Prop currentPage: number = 1
  @Prop totalPages: number = 1
  private onClose: () => void = () => {}
  private onChange: (key: string, value: string | number | boolean) => void = () => {}
  private onJumpPage: (page: number) => void = () => {}

  @State jumpInput: string = ''
  @State tab: number = 0  // 0=显示, 1=翻页, 2=其他

  build() {
    Column() {
      // 顶部
      Row() {
        Text('设置').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#ffffff')
        Blank()
        Button('✕').fontSize(18).fontColor('#ffffff')
          .backgroundColor('transparent')
          .onClick(() => { this.onClose() })
      }
      .width('100%').padding(16)

      // Tab 切换
      Row() {
        ForEach(['显示', '翻页', '其他'], (label: string, idx: number) => {
          Button(label).fontSize(13)
            .backgroundColor(this.tab === idx ? Colors.primary : 'transparent')
            .fontColor('#ffffff').borderRadius(16)
            .height(32)
            .onClick(() => { this.tab = idx })
        })
      }
      .width('100%').padding({ left: 16, bottom: 8 })

      Scroll() {
        Column() {
          if (this.tab === 0) {
            this.DisplayTab()
          } else if (this.tab === 1) {
            this.NavigationTab()
          } else {
            this.OtherTab()
          }
        }.width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%').height(400)
    .backgroundColor('#1a1a2e')
    .borderRadius({ topLeft: 20, topRight: 20 })
  }

  @Builder
  DisplayTab() {
    Column() {
      // 背景色
      this.SettingRow('背景颜色', () => {
        Row() {
          ForEach([
            { key: BackgroundMode.BLACK, label: '纯黑', color: '#000000' },
            { key: BackgroundMode.DARK_GREY, label: '深灰', color: '#1a1a2e' },
            { key: BackgroundMode.SEPIA, label: '护眼', color: '#f5e6c8' },
            { key: BackgroundMode.WHITE, label: '纯白', color: '#ffffff' },
          ], (item: { key: BackgroundMode, label: string, color: string }) => {
            Column() {
              Column() {}.width(28).height(28)
                .backgroundColor(item.color)
                .border({ width: this.prefs.background === item.key ? 2 : 0,
                         color: Colors.primary })
                .borderRadius(14)
              Text(item.label).fontSize(11)
                .fontColor(this.prefs.background === item.key ?
                  Colors.primary : '#94a3b8')
                .margin({ top: 4 })
            }
            .margin({ right: 16 })
            .onClick(() => {
              this.onChange('background', item.key)
            })
          })
        }
      })

      // 亮度
      this.SettingRow('亮度', () => {
        Row() {
          Text('🌙').fontSize(14)
          Slider({
            value: this.prefs.brightness * 100,
            min: 10, max: 100, step: 5
          })
          .width('70%').margin({ left: 8, right: 8 })
          .onChange((val: number) => {
            this.onChange('brightness', val / 100)
          })
          Text('☀️').fontSize(14)
          Text(`${Math.round(this.prefs.brightness * 100)}%`)
            .fontSize(12).fontColor('#94a3b8').width(40).textAlign(TextAlign.End)
        }.width('100%')
      })

      // 显示页码
      this.ToggleRow('显示页码水印', this.prefs.showPageNumber,
        (val: boolean) => { this.onChange('showPageNumber', val) })

      // 布局模式
      this.SettingRow('页面布局', () => {
        Row() {
          ForEach([
            { key: PageLayout.SINGLE, label: '单页' },
            { key: PageLayout.DOUBLE, label: '双页' },
            { key: PageLayout.CONTINUOUS, label: '连续' },
          ], (item: { key: PageLayout, label: string }) => {
            Column() {
              Text(item.label).fontSize(13)
                .fontColor(this.prefs.layout === item.key ?
                  Colors.primary : '#e2e8f0')
              if (this.prefs.layout === item.key) {
                Column() {}.width('100%').height(2)
                  .backgroundColor(Colors.primary).margin({ top: 4 })
              }
            }
            .layoutWeight(1).margin({ right: 8 })
            .onClick(() => { this.onChange('layout', item.key) })
          })
        }.width('100%')
      })
    }.padding({ left: 16, right: 16 })
  }

  @Builder
  NavigationTab() {
    Column() {
      // 阅读方向
      this.SettingRow('阅读方向', () => {
        Row() {
          ForEach([
            { key: ReadingDirection.LTR, label: '← 从左到右' },
            { key: ReadingDirection.RTL, label: '从右到左 →' },
          ], (item: { key: ReadingDirection, label: string }) => {
            Button(item.label).fontSize(13)
              .backgroundColor(this.prefs.direction === item.key ?
                Colors.primary : Colors.surfaceLight)
              .fontColor('#ffffff').borderRadius(8).height(36)
              .onClick(() => { this.onChange('direction', item.key) })
          })
        }.width('100%')
      })

      // 翻页过渡
      this.SettingRow('翻页效果', () => {
        Row() {
          ForEach([
            { key: PageTransition.SLIDE, label: '滑动' },
            { key: PageTransition.FADE, label: '淡入' },
            { key: PageTransition.NONE, label: '无' },
          ], (item: { key: PageTransition, label: string }) => {
            Button(item.label).fontSize(13)
              .backgroundColor(this.prefs.transition === item.key ?
                Colors.primary : Colors.surfaceLight)
              .fontColor('#ffffff').borderRadius(8).height(36)
              .onClick(() => { this.onChange('transition', item.key) })
          })
        }.width('100%')
      })

      // 点击翻页
      this.ToggleRow('点击屏幕翻页', this.prefs.tapToNext,
        (val: boolean) => { this.onChange('tapToNext', val) })

      // 跳转页面
      this.SettingRow('跳转到', () => {
        Row() {
          TextInput({ placeholder: '页码' })
            .placeholderColor('#64748b').backgroundColor(Colors.surface)
            .fontColor('#ffffff').height(36).borderRadius(8)
            .width(80).padding({ left: 8 })
            .type(InputType.Number)
            .onChange((val: string) => { this.jumpInput = val })
          Button('跳转').fontSize(13).backgroundColor(Colors.primary)
            .borderRadius(8).margin({ left: 8 })
            .onClick(() => {
              const page = parseInt(this.jumpInput)
              if (page >= 1 && page <= this.totalPages) {
                this.onJumpPage(page)
              }
            })
          Text(`共 ${this.totalPages} 页`).fontSize(12).fontColor('#64748b')
            .margin({ left: 8 })
        }.width('100%')
      })
    }.padding({ left: 16, right: 16 })
  }

  @Builder
  OtherTab() {
    Column() {
      this.ToggleRow('锁定屏幕旋转', this.prefs.lockRotation,
        (val: boolean) => { this.onChange('lockRotation', val) })

      this.ToggleRow('音量键翻页', this.prefs.volumeKeys,
        (val: boolean) => { this.onChange('volumeKeys', val) })
    }.padding({ left: 16, right: 16 })
  }

  @Builder
  SettingRow(label: string, content: () => void) {
    Column() {
      Text(label).fontSize(14).fontColor('#94a3b8').width('100%').margin({ bottom: 8 })
      content()
    }
    .width('100%').margin({ top: 16 })
  }

  @Builder
  ToggleRow(label: string, value: boolean, onChange: (val: boolean) => void) {
    Row() {
      Text(label).fontSize(14).fontColor('#e2e8f0')
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: value })
        .onChange((isOn: boolean) => { onChange(isOn) })
    }
    .width('100%').margin({ top: 12 })
  }
}
