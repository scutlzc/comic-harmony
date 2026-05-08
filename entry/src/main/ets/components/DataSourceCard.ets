/**
 * 数据源卡片组件（发现页用）
 */
import { Colors } from '../utils/Utils'
import { DataSourceType } from '../model/DataSource'

const SOURCE_ICONS: Record<string, string> = {
  komga: '📚',
  webdav: '🗂️',
  clouddrive: '☁️'
}

const SOURCE_LABELS: Record<string, string> = {
  komga: 'Komga 服务器',
  webdav: 'WebDAV',
  clouddrive: '云盘'
}

@Component
export struct DataSourceCard {
  @Prop name: string = ''
  @Prop sourceType: DataSourceType = DataSourceType.KOMGA
  @Prop url: string = ''
  @Prop status: string = 'pending'  // 'connected' | 'error' | 'pending'
  private onClick: () => void = () => {}

  build() {
    Row() {
      // 图标
      Text(SOURCE_ICONS[this.sourceType] || '🔗')
        .fontSize(32)

      Column() {
        Text(this.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(SOURCE_LABELS[this.sourceType] || this.sourceType)
          .fontSize(12)
          .fontColor(Colors.textSecondary)
          .margin({ top: 2 })

        Text(this.url)
          .fontSize(11)
          .fontColor('#64748b')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)

      // 状态指示
      Text(this.status === 'connected' ? '●' :
           this.status === 'error' ? '●' : '○')
        .fontSize(14)
        .fontColor(this.status === 'connected' ? Colors.success :
                   this.status === 'error' ? Colors.accent : '#64748b')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Colors.surface)
    .borderRadius(12)
  }
}
