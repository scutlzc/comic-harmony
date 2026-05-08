/**
 * 数据源管理页 - 支持真实连接测试 + 本地持久化
 */
import router from '@ohos.router'
import { Colors, setStorage, getStorage } from '../utils/Utils'
import { DataSourceType, DataSourceConfig } from '../model/DataSource'
import { dataSourceManager } from '../datasource/Manager'

const STORAGE_KEY = 'saved_sources'

interface SourceEntry {
  id: string
  name: string
  type: DataSourceType
  url: string
  username: string
  password: string
  status: 'connected' | 'error' | 'pending' | 'testing'
}

@Entry
@Component
struct SourceManage {
  @State sources: SourceEntry[] = []
  @State showAdd: boolean = false
  @State newName: string = ''
  @State newUrl: string = ''
  @State newUser: string = ''
  @State newPass: string = ''
  @State selectedType: DataSourceType = DataSourceType.KOMGA
  @State testing: boolean = false
  @State testResult: string = ''

  async aboutToAppear(): Promise<void> {
    await this.loadSavedSources()
  }

  /** 从本地存储加载已保存的数据源 */
  async loadSavedSources(): Promise<void> {
    const json = await getStorage(STORAGE_KEY, '[]')
    const saved = JSON.parse(json) as SourceEntry[]
    this.sources = saved.map(s => ({ ...s, status: 'pending' }))
    // 恢复到管理器
    this.sources.forEach(s => {
      const config: DataSourceConfig = {
        id: s.id, name: s.name, type: s.type,
        url: s.url, username: s.username, password: s.password,
        rootPath: '/'
      }
      dataSourceManager.add(config)
    })
    // 异步检查状态
    this.sources.forEach(s => this.checkStatus(s))
  }

  /** 保存数据源到本地 */
  async saveSources(): Promise<void> {
    const clean = this.sources.map(s => ({
      id: s.id, name: s.name, type: s.type, url: s.url,
      username: s.username, password: s.password
    }))
    await setStorage(STORAGE_KEY, JSON.stringify(clean))
  }

  /** 异步检测数据源状态 */
  async checkStatus(entry: SourceEntry): Promise<void> {
    entry.status = 'testing'
    this.updateUI()
    try {
      const source = dataSourceManager.get(entry.id)
      if (!source) {
        entry.status = 'error'
        this.updateUI()
        return
      }
      const ok = await source.healthCheck()
      entry.status = ok ? 'connected' : 'error'
    } catch {
      entry.status = 'error'
    }
    this.updateUI()
  }

  /** 强制刷新 UI */
  updateUI(): void {
    this.sources = [...this.sources]
  }

  /** 测试连接并添加 */
  async testAndAdd(): Promise<void> {
    if (!this.newName || !this.newUrl) {
      this.testResult = '请输入名称和地址'
      return
    }

    this.testing = true
    this.testResult = ''

    const id = `src_${Date.now()}`
    const config: DataSourceConfig = {
      id: id,
      name: this.newName,
      type: this.selectedType,
      url: this.newUrl,
      username: this.newUser,
      password: this.newPass,
      rootPath: '/'
    }

    // 添加到管理器
    const source = dataSourceManager.add(config)
    if (!source) {
      this.testResult = '不支持的数据源类型'
      this.testing = false
      return
    }

    // 创建临时条目
    const entry: SourceEntry = {
      id, name: config.name, type: config.type,
      url: config.url, username: config.username,
      password: config.password, status: 'testing'
    }
    this.sources.push(entry)
    this.updateUI()

    // 真实连接测试
    try {
      const ok = await source.healthCheck()
      entry.status = ok ? 'connected' : 'error'
      this.testResult = ok ? '✅ 连接成功' : '❌ 连接失败'
    } catch (e) {
      entry.status = 'error'
      this.testResult = '❌ 连接超时或拒绝连接'
    }

    this.updateUI()
    this.testing = false
    await this.saveSources()
  }

  /** 删除数据源 */
  async removeSource(entry: SourceEntry): Promise<void> {
    dataSourceManager.remove(entry.id)
    this.sources = this.sources.filter(s => s.id !== entry.id)
    await this.saveSources()
  }

  /** 重新检测 */
  async retestSource(entry: SourceEntry): Promise<void> {
    await this.checkStatus(entry)
    await this.saveSources()
  }

  /** 重置添加表单 */
  resetForm(): void {
    this.newName = ''
    this.newUrl = ''
    this.newUser = ''
    this.newPass = ''
    this.testResult = ''
    this.showAdd = false
  }

  getSourceIcon(type: DataSourceType): string {
    switch (type) {
      case DataSourceType.KOMGA: return '📚'
      case DataSourceType.WEBDAV: return '🗂️'
      case DataSourceType.CLOUD_DRIVE: return '☁️'
      default: return '🔗'
    }
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'connected': return '✅'
      case 'error': return '❌'
      case 'testing': return '⏳'
      default: return '○'
    }
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'connected': return Colors.success
      case 'error': return Colors.accent
      case 'testing': return Colors.warning
      default: return '#64748b'
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
        .onClick(() => {
          router.back()
        })

        Text('数据源管理').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#ffffff')
          .margin({ left: 12 }).layoutWeight(1)

        Button('+ 添加').backgroundColor(Colors.primary).borderRadius(8).fontSize(14)
          .onClick(() => { this.showAdd = !this.showAdd; this.testResult = '' })
      }
      .width('100%').padding(16)

      Scroll() {
        Column() {
          // 添加表单
          if (this.showAdd) {
            this.AddForm()
          }

          // 数据源列表
          if (this.sources.length === 0 && !this.showAdd) {
            Column() {
              Text(this.getSourceIcon(DataSourceType.KOMGA)).fontSize(48)
              Text('还没有数据源').fontSize(16).fontColor(Colors.textSecondary).margin({ top: 12 })
              Text('点击右上角 + 添加').fontSize(13).fontColor('#64748b').margin({ top: 4 })
            }
            .width('100%').padding({ top: 80 })
            .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
          }

          ForEach(this.sources, (item: SourceEntry) => {
            this.SourceCard(item)
          })
        }
        .width('100%').padding({ bottom: 24 })
      }
    }
    .width('100%').height('100%').backgroundColor(Colors.background)
  }

  @Builder
  AddForm() {
    Column() {
      Text('添加数据源').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#ffffff').width('100%')

      // 类型选择
      Row() {
        ForEach([
          { label: 'Komga', type: DataSourceType.KOMGA },
          { label: 'WebDAV', type: DataSourceType.WEBDAV },
          { label: '云盘', type: DataSourceType.CLOUD_DRIVE }
        ], (item: { label: string, type: DataSourceType }) => {
          Button(item.label)
            .backgroundColor(this.selectedType === item.type ? Colors.primary : Colors.surfaceLight)
            .fontColor('#ffffff').borderRadius(8).fontSize(13)
            .onClick(() => { this.selectedType = item.type })
        })
      }
      .width('100%').justifyContent(FlexAlign.SpaceEvenly).margin({ top: 12 })

      TextInput({ placeholder: '名称（如：我的NAS）' })
        .placeholderColor('#64748b').backgroundColor(Colors.surface).fontColor('#ffffff')
        .height(44).borderRadius(8).padding({ left: 12 }).margin({ top: 12 })
        .onChange((v: string) => { this.newName = v })

      TextInput({ placeholder: '服务器地址（http://...）' })
        .placeholderColor('#64748b').backgroundColor(Colors.surface).fontColor('#ffffff')
        .height(44).borderRadius(8).padding({ left: 12 }).margin({ top: 8 })
        .onChange((v: string) => { this.newUrl = v })

      if (this.selectedType === DataSourceType.KOMGA) {
        TextInput({ placeholder: '用户名' })
          .placeholderColor('#64748b').backgroundColor(Colors.surface).fontColor('#ffffff')
          .height(44).borderRadius(8).padding({ left: 12 }).margin({ top: 8 })
          .onChange((v: string) => { this.newUser = v })

        TextInput({ placeholder: '密码' })
          .placeholderColor('#64748b').backgroundColor(Colors.surface).fontColor('#ffffff')
          .height(44).borderRadius(8).padding({ left: 12 }).margin({ top: 8 })
          .type(InputType.Password)
          .onChange((v: string) => { this.newPass = v })
      }

      if (this.testResult) {
        Text(this.testResult).fontSize(13).fontColor(
          this.testResult.includes('✅') ? Colors.success : Colors.accent
        ).margin({ top: 8 })
      }

      Row() {
        Button('取消').backgroundColor('#475569').fontColor('#ffffff').borderRadius(8)
          .layoutWeight(1).height(44)
          .onClick(() => { this.resetForm() })

        Button(this.testing ? '测试中...' : '测试连接并添加')
          .backgroundColor(Colors.success).fontColor('#ffffff').borderRadius(8)
          .layoutWeight(1).height(44).margin({ left: 8 })
          .enabled(!this.testing)
          .onClick(() => { this.testAndAdd() })
      }
      .width('100%').margin({ top: 12 })
    }
    .width('100%').padding(16)
    .backgroundColor(Colors.surface).borderRadius(12)
    .margin({ left: 16, right: 16 })
  }

  @Builder
  SourceCard(item: SourceEntry) {
    Row() {
      // 类型图标
      Text(this.getSourceIcon(item.type)).fontSize(28)

      // 信息
      Column() {
        Text(item.name).fontSize(15).fontColor('#e2e8f0').maxLines(1)
        Text(item.url).fontSize(12).fontColor(Colors.textSecondary).maxLines(1).margin({ top: 2 })
        Text(item.type === DataSourceType.KOMGA ? '需账号密码' : '无需登录')
          .fontSize(11).fontColor('#64748b').margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1)

      // 操作区
      Column() {
        // 状态
        Text(this.getStatusIcon(item.status)).fontSize(18)

        // 重测按钮
        if (item.status === 'error') {
          Button('重试').fontSize(11).backgroundColor(Colors.primary).borderRadius(4)
            .height(24).margin({ top: 4 }).width(48)
            .onClick(() => { this.retestSource(item) })
        }

        // 删除
        Button('✕').fontSize(14).fontColor('#94a3b8')
          .backgroundColor('transparent')
          .width(28).height(28).margin({ top: 4 })
          .onClick(() => { this.removeSource(item) })
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%').padding(16)
    .backgroundColor(Colors.surface).borderRadius(12)
    .margin({ left: 16, right: 16, top: 8 })
  }
}
