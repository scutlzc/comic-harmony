/**
 * Komga 数据源实现
 * 通过 Komga REST API 直接获取漫画数据
 */
import http from '@ohos.net.http'
import { BusinessError } from '@ohos.base'
import type { IDataSource, Library, SourceComic, SourceChapter } from './IDataSource'

export class KomgaDataSource implements IDataSource {
  readonly name: string
  readonly type: string = 'komga'
  private baseUrl: string
  private authHeader: string
  private httpClient = http.createHttp()
  private libraryCache: Library[] = []

  constructor(name: string, url: string, username: string, password: string) {
    this.name = name
    this.baseUrl = url.replace(/\/+$/, '')
    const credentials = `${username}:${password}`
    this.authHeader = `Basic ${this.base64Encode(credentials)}`
  }

  private base64Encode(str: string): string {
    const encoder = new util.TextEncoder()
    const bytes = encoder.encodeInto(str)
    let binary = ''
    for (let i = 0; i < bytes.length; i++) {
      binary += String.fromCharCode(bytes[i])
    }
    return util.Base64Helper.encodeToString(bytes)
  }

  private async getJson(path: string): Promise<Record<string, Object>> {
    const resp = await this.httpClient.request(`${this.baseUrl}${path}`, {
      method: http.RequestMethod.GET,
      header: {
        'Authorization': this.authHeader,
        'Accept': 'application/json'
      }
    })
    return JSON.parse(resp.result as string) as Record<string, Object>
  }

  async getLibraries(): Promise<Library[]> {
    const data = await this.getJson('/api/v1/libraries') as Array<Record<string, Object>>
    this.libraryCache = data.map((lib: Record<string, Object>) => ({
      id: lib.id as string,
      name: lib.name as string,
      comicCount: 0
    }))
    return this.libraryCache
  }

  async getComics(libraryId: string, page: number = 1): Promise<SourceComic[]> {
    const data = await this.getJson(
      `/api/v1/series?library_id=${libraryId}&page=${page - 1}&size=20`
    ) as Record<string, Object>
    const content = data.content as Array<Record<string, Object>> || []
    return content.map((item: Record<string, Object>) => {
      const meta = item.metadata as Record<string, Object> || {}
      return {
        id: item.id as string,
        title: (meta.title as string) || (item.name as string),
        author: this.extractAuthor(meta),
        description: (meta.summary as string) || '',
        coverUrl: `${this.baseUrl}/api/v1/series/${item.id}/thumbnail`,
        status: (meta.status as string) || '',
        chapterCount: (item.booksCount as number) || 0
      }
    })
  }

  async search(keyword: string): Promise<SourceComic[]> {
    const data = await this.getJson(
      `/api/v1/series?search=${encodeURIComponent(keyword)}`
    ) as Record<string, Object>
    const content = data.content as Array<Record<string, Object>> || []
    return this.mapSeriesToComics(content)
  }

  async getChapters(comicId: string): Promise<SourceChapter[]> {
    const data = await this.getJson(
      `/api/v1/series/${comicId}/books?sort=number`
    ) as Record<string, Object>
    const content = data.content as Array<Record<string, Object>> || []
    return content.map((book: Record<string, Object>) => ({
      id: book.id as string,
      title: book.name as string,
      sortOrder: Math.round((book.number as number) || 0),
      pageCount: (book.pageCount as number) || 0
    }))
  }

  getPageUrls(chapterId: string, pageCount: number): string[] {
    const urls: string[] = []
    for (let i = 0; i < pageCount; i++) {
      urls.push(`${this.baseUrl}/api/v1/books/${chapterId}/pages/${i}`)
    }
    return urls
  }

  getCoverUrl(comicId: string): string {
    return `${this.baseUrl}/api/v1/series/${comicId}/thumbnail`
  }

  async healthCheck(): Promise<boolean> {
    try {
      await this.getJson('/api/v1/libraries')
      return true
    } catch {
      return false
    }
  }

  private extractAuthor(meta: Record<string, Object>): string {
    const authors = meta.authors as Array<Record<string, string>> || []
    for (const a of authors) {
      if (a.role === 'writer' || a.role === 'artist') {
        return a.name
      }
    }
    return ''
  }

  private mapSeriesToComics(items: Array<Record<string, Object>>): SourceComic[] {
    return items.map((item: Record<string, Object>) => {
      const meta = item.metadata as Record<string, Object> || {}
      return {
        id: item.id as string,
        title: (meta.title as string) || (item.name as string),
        author: this.extractAuthor(meta),
        description: (meta.summary as string) || '',
        coverUrl: `${this.baseUrl}/api/v1/series/${item.id}/thumbnail`,
        status: (meta.status as string) || '',
        chapterCount: (item.booksCount as number) || 0
      }
    })
  }
}
