/**
 * 离线存储管理
 * 漫画图片本地缓存到 app 沙箱目录
 */
import fs from '@ohos.file.fs'
import { BusinessError } from '@ohos.base'

let BASE_DIR = ''  // 应用沙箱根目录
const COMIC_DIR = 'comics'  // 漫画缓存目录

/** 初始化存储目录 */
export async function initOfflineStorage(context: UIAbilityContext): Promise<void> {
  BASE_DIR = context.cacheDir + '/offline/'
  await mkdir(BASE_DIR)
  await mkdir(BASE_DIR + COMIC_DIR)
}

/** 确保目录存在 */
async function mkdir(dir: string): Promise<void> {
  try {
    await fs.mkdir(dir, true)
  } catch (e) {
    // 目录已存在忽略
  }
}

/** 获取章节缓存路径 */
function getChapterDir(comicId: number, chapterId: number): string {
  return `${BASE_DIR}${COMIC_DIR}/${comicId}/${chapterId}/`
}

/** 获取页面文件路径 */
function getPagePath(comicId: number, chapterId: number, pageNum: number): string {
  return `${BASE_DIR}${COMIC_DIR}/${comicId}/${chapterId}/${pageNum}.webp`
}

/** 检查章节是否已缓存 */
export async function isChapterCached(comicId: number, chapterId: number): Promise<boolean> {
  try {
    const dir = getChapterDir(comicId, chapterId)
    const stat = await fs.stat(dir)
    return stat.isDirectory()
  } catch {
    return false
  }
}

/** 获取已缓存页数 */
export async function getCachedPageCount(comicId: number, chapterId: number): Promise<number> {
  const dir = getChapterDir(comicId, chapterId)
  try {
    const files = await fs.listFile(dir)
    return files.filter((name: string) => name.endsWith('.webp')).length
  } catch {
    return 0
  }
}

/** 保存单页图片到本地 */
export async function savePage(
  comicId: number,
  chapterId: number,
  pageNum: number,
  imageData: ArrayBuffer
): Promise<string> {
  const dir = getChapterDir(comicId, chapterId)
  await mkdir(dir)
  const filePath = getPagePath(comicId, chapterId, pageNum)
  const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)
  try {
    await fs.write(file.fd, imageData)
    return filePath
  } finally {
    await fs.close(file)
  }
}

/** 获取本地页面 URI（供 Image 组件加载） */
export function getLocalPageUri(comicId: number, chapterId: number, pageNum: number): string {
  return getPagePath(comicId, chapterId, pageNum)
}

/** 获取缓存统计 */
export async function getCacheStats(): Promise<{ comics: number, chapters: number, pages: number, size: string }> {
  try {
    let totalPages = 0
    let totalSize = 0
    let comicDirs = 0
    let chapterDirs = 0

    const comicList = await fs.listFile(`${BASE_DIR}${COMIC_DIR}`)
    for (const comicId of comicList) {
      comicDirs++
      const chapterList = await fs.listFile(`${BASE_DIR}${COMIC_DIR}/${comicId}`)
      for (const chapterId of chapterList) {
        chapterDirs++
        const files = await fs.listFile(`${BASE_DIR}${COMIC_DIR}/${comicId}/${chapterId}`)
        for (const file of files) {
          if (file.endsWith('.webp')) {
            totalPages++
            try {
              const stat = await fs.stat(`${BASE_DIR}${COMIC_DIR}/${comicId}/${chapterId}/${file}`)
              totalSize += stat.size
            } catch {}
          }
        }
      }
    }

    return {
      comics: comicDirs,
      chapters: chapterDirs,
      pages: totalPages,
      size: formatBytes(totalSize)
    }
  } catch {
    return { comics: 0, chapters: 0, pages: 0, size: '0 B' }
  }
}

/** 删除章节缓存 */
export async function deleteChapterCache(comicId: number, chapterId: number): Promise<void> {
  const dir = getChapterDir(comicId, chapterId)
  try {
    await fs.rmdir(dir, true)
  } catch {}
}

/** 清空所有缓存 */
export async function clearAllCache(): Promise<void> {
  try {
    await fs.rmdir(`${BASE_DIR}${COMIC_DIR}`, true)
    await mkdir(`${BASE_DIR}${COMIC_DIR}`)
  } catch {}
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / 1048576).toFixed(1)} MB`
}
