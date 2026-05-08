/**
 * 数据源模型（前端直连用）
 */
export enum DataSourceType {
  KOMGA = 'komga',
  WEBDAV = 'webdav',
  CLOUD_DRIVE = 'clouddrive'
}

export interface DataSourceConfig {
  id: string
  name: string
  type: DataSourceType
  url: string
  username: string
  password: string
  rootPath: string
}

export interface Library {
  id: string
  name: string
  comicCount: number
}

export interface SourceComic {
  id: string
  sourceId: string
  sourceName: string
  sourceType: DataSourceType
  title: string
  author: string
  description: string
  coverUrl: string
  status: string
  chapterCount: number
}

export interface SourceChapter {
  id: string
  comicId: string
  title: string
  sortOrder: number
  pageCount: number
}
