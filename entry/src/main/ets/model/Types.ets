/**
 * API 响应模型
 */
export interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

export interface PaginatedData<T> {
  total: number
  page: number
  pageSize: number
  hasMore: boolean
  items: T[]
}

export interface ComicListData {
  comics: Comic[]
  total: number
  page: number
  page_size: number
}

export interface ChapterListData {
  chapters: Chapter[]
  comic_id: number
  total: number
}

// Re-export models
export type { Comic, Chapter, ChapterDetail, User, Favorite, History } from './Comic'
export type { DataSourceConfig, Library, SourceComic, SourceChapter } from './DataSource'
export { DataSourceType } from './DataSource'
