/**
 * 个人中心页
 */
import router from '@ohos.router'
import { Colors, getStorage, removeStorage } from '../utils/Utils'
import { setToken, getToken } from '../api/HttpClient'

@Entry
@Component
struct Profile {
  @State isLoggedIn: boolean = false
  @State nickname: string = ''

  aboutToAppear(): void {
    this.checkLogin()
  }

  async checkLogin(): Promise<void> {
    const token = await getStorage('auth_token', '')
    this.isLoggedIn = !!token
  }

  async doLogout(): Promise<void> {
    await removeStorage('auth_token')
    setToken('')
    this.isLoggedIn = false
  }

  build() {
    Column() {
      // 头部
      Column() {
        Text('我的')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .width('100%')

        // 用户信息
        Row() {
          Column() {
            Text('👤')
              .fontSize(48)
          }
          .width(72)
          .height(72)
          .backgroundColor(Colors.surfaceLight)
          .borderRadius(36)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(this.isLoggedIn ? this.nickname || '用户' : '未登录')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ffffff')

            if (!this.isLoggedIn) {
              Text('点击登录')
                .fontSize(13)
                .fontColor(Colors.primary)
                .margin({ top: 4 })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16 })
          .onClick(() => {
            if (!this.isLoggedIn) {
              router.pushUrl({ name: 'Login' })
            }
          })
        }
        .width('100%')
        .padding(16)
      }

      // 菜单列表
      Column() {
        // 数据源管理
        Row() {
          Text('🔗')
            .fontSize(20)
          Text('数据源管理')
            .fontSize(15)
            .fontColor('#e2e8f0')
            .margin({ left: 12 })
          Blank()
          Text('>')
            .fontColor(Colors.textSecondary)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Colors.surface)
        .borderRadius(12)
        .onClick(() => {
          router.pushUrl({ name: 'SourceManage' })
        })

        // 收藏
        Row() {
          Text('⭐')
            .fontSize(20)
          Text('我的收藏')
            .fontSize(15)
            .fontColor('#e2e8f0')
            .margin({ left: 12 })
          Blank()
          Text('>')
            .fontColor(Colors.textSecondary)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Colors.surface)
        .borderRadius(12)
        .margin({ top: 8 })
        .onClick(() => {
          router.pushUrl({ name: 'Favorites' })
        })

        // 阅读历史
        Row() {
          Text('📖')
            .fontSize(20)
          Text('阅读历史')
            .fontSize(15)
            .fontColor('#e2e8f0')
            .margin({ left: 12 })
          Blank()
          Text('>')
            .fontColor(Colors.textSecondary)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Colors.surface)
        .borderRadius(12)
        .margin({ top: 8 })
      }

      // 离线缓存
      Row() {
        Text('📦')
          .fontSize(20)
        Text('离线缓存')
          .fontSize(15)
          .fontColor('#e2e8f0')
          .margin({ left: 12 })
        Blank()
        Text('>')
          .fontColor(Colors.textSecondary)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Colors.surface)
      .borderRadius(12)
      .margin({ top: 8 })
      .onClick(() => {
        router.pushUrl({ name: 'Offline' })
      })
      .width('100%')
      .padding(16)

      if (this.isLoggedIn) {
        Button('退出登录')
          .width('90%')
          .height(44)
          .backgroundColor(Colors.accent)
          .borderRadius(12)
          .margin({ top: 24 })
          .onClick(() => { this.doLogout() })
      }

      Blank()

      Text('ComicHarmony v1.0.0')
        .fontSize(12)
        .fontColor('#475569')
        .margin({ bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.background)
  }
}
