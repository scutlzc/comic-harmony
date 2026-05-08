/**
 * 登录页
 */
import router from '@ohos.router'
import { Colors, setStorage } from '../utils/Utils'
import { login } from '../api/BackendApi'
import { setToken } from '../api/HttpClient'

@Entry
@Component
struct Login {
  @State email: string = ''
  @State password: string = ''
  @State loading: boolean = false
  @State error: string = ''

  async doLogin(): Promise<void> {
    if (!this.email || !this.password) {
      this.error = '请输入邮箱和密码'
      return
    }

    this.loading = true
    this.error = ''

    try {
      const token = await login(this.email, this.password)
      setToken(token)
      await setStorage('auth_token', token)
      router.back()
    } catch (e) {
      this.error = '登录失败，请检查账号密码'
    } finally {
      this.loading = false
    }
  }

  build() {
    Column() {
      // 标题
      Text('欢迎回来')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
        .width('100%')
        .margin({ top: 60 })

      Text('登录 Comicharmony')
        .fontSize(15)
        .fontColor(Colors.textSecondary)
        .width('100%')
        .margin({ top: 8 })

      // 表单
      Column() {
        TextInput({ placeholder: '邮箱' })
          .placeholderColor('#64748b')
          .backgroundColor(Colors.surface)
          .fontColor('#ffffff')
          .height(48)
          .borderRadius(12)
          .padding({ left: 16 })
          .onChange((val: string) => { this.email = val })

        TextInput({ placeholder: '密码' })
          .placeholderColor('#64748b')
          .backgroundColor(Colors.surface)
          .fontColor('#ffffff')
          .height(48)
          .borderRadius(12)
          .padding({ left: 16 })
          .margin({ top: 12 })
          .type(InputType.Password)
          .onChange((val: string) => { this.password = val })

        if (this.error) {
          Text(this.error)
            .fontSize(13)
            .fontColor(Colors.accent)
            .margin({ top: 8 })
        }

        Button(this.loading ? '登录中...' : '登录')
          .width('100%')
          .height(48)
          .backgroundColor(Colors.primary)
          .borderRadius(12)
          .margin({ top: 24 })
          .enabled(!this.loading)
          .onClick(() => { this.doLogin() })
      }
      .width('100%')
      .padding({ top: 40 })
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .backgroundColor(Colors.background)
  }
}
