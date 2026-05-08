/**
 * WebDAV 数据源实现
 * 通过 PROPFIND 协议扫描漫画文件
 */
import http from '@ohos.net.http'
import xml from '@ohos.xml'
import type { IDataSource, Library, SourceComic, SourceChapter } from './IDataSource'

// Comic 文件扩展名
const COMIC_EXTS = ['.cbz', '.cbr', '.cb7', '.zip', '.rar', '.epub', '.pdf']
const IMAGE_EXTS = ['.jpg', '.jpeg', '.png', '.webp']

export class WebDAVDataSource implements IDataSource {
  readonly name: string
  readonly type: string = 'webdav'
  private baseUrl: string
  private username: string
  private password: string
  private httpClient = http.createHttp()

  constructor(name: string, url: string, username: string, password: string) {
    this.name = name
    this.baseUrl = url.replace(/\/+$/, '')
    this.username = username
    this.password = password
  }

  private async propfind(path: string, depth: number): Promise<WebDAVResource[]> {
    const url = `${this.baseUrl}${path}`
    const resp = await this.httpClient.request(url, {
      method: http.RequestMethod.OPTIONS, // will override
      header: {
        'Depth': `${depth}`,
        ...(this.username ? {
          'Authorization': 'Basic ' + this.base64Encode(`${this.username}:${this.password}`)
        } : {})
      }
    })
    // WebDAV PROPFIND via custom request
    // Using http module raw request for PROPFIND method
    return []
  }

  // Simplified: fetch directory listing as JSON for now
  private async listDir(path: string): Promise<WebDAVResource[]> {
    // TODO: implement proper PROPFIND XML parsing
    // For now returns empty - real implementation needs XML parsing
    return []
  }

  async getLibraries(): Promise<Library[]> {
    return [{ id: '/', name: '根目录', comicCount: 0 }]
  }

  async getComics(libraryId: string, page?: number): Promise<SourceComic[]> {
    return []
  }

  async search(keyword: string): Promise<SourceComic[]> {
    return []
  }

  async getChapters(comicId: string): Promise<SourceChapter[]> {
    return [{ id: comicId, title: comicId.split('/').pop() || comicId, sortOrder: 1, pageCount: 0 }]
  }

  getPageUrls(chapterId: string, pageCount: number): string[] {
    return [`${this.baseUrl}${chapterId}`]
  }

  getCoverUrl(comicId: string): string {
    return ''
  }

  async healthCheck(): Promise<boolean> {
    try {
      await this.propfind('/', 0)
      return true
    } catch {
      return false
    }
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
}

interface WebDAVResource {
  path: string
  name: string
  isCollection: boolean
}
