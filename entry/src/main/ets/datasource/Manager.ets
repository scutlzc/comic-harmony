/**
 * 数据源管理器
 * 统一管理多个前端直连的数据源
 */
import { KomgaDataSource } from './KomgaDataSource'
import { WebDAVDataSource } from './WebDAVDataSource'
import type { IDataSource, Library, SourceComic, SourceChapter } from './IDataSource'
import type { DataSourceConfig, DataSourceType } from '../model/DataSource'

export type { IDataSource }

export class DataSourceManager {
  private sources: Map<string, IDataSource> = new Map()
  private configs: Map<string, DataSourceConfig> = new Map()

  /** 添加数据源 */
  add(config: DataSourceConfig): IDataSource | null {
    let source: IDataSource | null = null

    switch (config.type) {
      case DataSourceType.KOMGA:
        source = new KomgaDataSource(config.name, config.url, config.username, config.password)
        break
      case DataSourceType.WEBDAV:
        source = new WebDAVDataSource(config.name, config.url, config.username, config.password)
        break
      default:
        return null
    }

    this.sources.set(config.id, source)
    this.configs.set(config.id, config)
    return source
  }

  /** 移除数据源 */
  remove(id: string): void {
    this.sources.delete(id)
    this.configs.delete(id)
  }

  /** 获取数据源 */
  get(id: string): IDataSource | undefined {
    return this.sources.get(id)
  }

  /** 获取所有配置 */
  getAllConfigs(): DataSourceConfig[] {
    return Array.from(this.configs.values())
  }

  /** 获取所有数据源 */
  getAll(): IDataSource[] {
    return Array.from(this.sources.values())
  }
}

// 全局单例
export const dataSourceManager = new DataSourceManager()
