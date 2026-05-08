/**
 * 数据源抽象层（前端直连）
 * 统一接口供 UI 调用，由具体实现类解析不同协议
 */
export interface IDataSource {
  readonly name: string
  readonly type: string

  /** 获取书库/根目录列表 */
  getLibraries(): Promise<Library[]>

  /** 获取漫画列表 */
  getComics(libraryId: string, page?: number): Promise<SourceComic[]>

  /** 搜索漫画 */
  search(keyword: string): Promise<SourceComic[]>

  /** 获取章节列表 */
  getChapters(comicId: string): Promise<SourceChapter[]>

  /** 获取页面图片 URL（可直接加载） */
  getPageUrls(chapterId: string, pageCount: number): string[]

  /** 获取封面 URL */
  getCoverUrl(comicId: string): string

  /** 健康检查 */
  healthCheck(): Promise<boolean>
}

// Types used by data sources
export interface Library {
  id: string
  name: string
  comicCount: number
}

export interface SourceComic {
  id: string
  title: string
  author: string
  description: string
  coverUrl: string
  status: string
  chapterCount: number
}

export interface SourceChapter {
  id: string
  title: string
  sortOrder: number
  pageCount: number
}
