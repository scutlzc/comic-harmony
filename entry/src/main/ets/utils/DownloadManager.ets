/**
 * 下载管理器
 * 管理漫画章节的离线下载队列
 */
import http from '@ohos.net.http'
import { BusinessError } from '@ohos.base'
import preferences from '@ohos.data.preferences'
import { savePage, isChapterCached, getCachedPageCount } from './OfflineStorage'

export interface DownloadTask {
  comicId: number
  chapterId: number
  chapterTitle: string
  totalPages: number
  downloaded: number
  status: 'pending' | 'downloading' | 'completed' | 'error'
  error?: string
}

type ProgressCallback = (task: DownloadTask) => void

class DownloadManager {
  private tasks: Map<string, DownloadTask> = new Map()
  private running: boolean = false
  private pref: preferences.Preferences | null = null

  async init(context: UIAbilityContext): Promise<void> {
    this.pref = await preferences.getPreferences(context, 'download_tasks')
    await this.restoreTasks()
  }

  private taskKey(comicId: number, chapterId: number): string {
    return `${comicId}_${chapterId}`
  }

  /** 创建下载任务 */
  addTask(comicId: number, chapterId: number, chapterTitle: string, totalPages: number): DownloadTask {
    const key = this.taskKey(comicId, chapterId)
    const task: DownloadTask = {
      comicId, chapterId, chapterTitle,
      totalPages, downloaded: 0,
      status: 'pending'
    }
    this.tasks.set(key, task)
    this.scheduleNext()
    return task
  }

  /** 获取任务状态 */
  getTask(comicId: number, chapterId: number): DownloadTask | undefined {
    return this.tasks.get(this.taskKey(comicId, chapterId))
  }

  /** 获取所有任务 */
  getAllTasks(): DownloadTask[] {
    return Array.from(this.tasks.values())
  }

  /** 删除任务 */
  removeTask(comicId: number, chapterId: number): void {
    this.tasks.delete(this.taskKey(comicId, chapterId))
  }

  private async scheduleNext(): Promise<void> {
    if (this.running) return
    this.running = true

    for (const [key, task] of this.tasks) {
      if (task.status === 'pending' || task.status === 'error') {
        task.status = 'downloading'
        this.onProgress(task)
        try {
          await this.downloadChapter(task)
          task.status = 'completed'
          task.downloaded = task.totalPages
          this.onProgress(task)
        } catch (e) {
          task.status = 'error'
          task.error = '下载失败'
          this.onProgress(task)
        }
      }
    }

    this.running = false
  }

  private async downloadChapter(task: DownloadTask): Promise<void> {
    // 从后端API获取每页图片并下载
    const httpClient = http.createHttp()

    for (let i = 1; i <= task.totalPages; i++) {
      const padded = String(i).padStart(4, '0')
      const url = `http://10.0.2.2:9090/uploads/comics/${task.comicId}/${padded}.webp`

      try {
        const resp = await httpClient.request(url, {
          method: http.RequestMethod.GET,
          connectTimeout: 10000,
          readTimeout: 30000
        })

        if (resp.responseCode === 200 && resp.result instanceof ArrayBuffer) {
          await savePage(task.comicId, task.chapterId, i, resp.result as ArrayBuffer)
          task.downloaded = i
          this.onProgress(task)
        } else {
          throw new Error(`HTTP ${resp.responseCode}`)
        }
      } catch (e) {
        // 跳过失败页，继续下载
        console.error(`download page ${i} failed`, JSON.stringify(e))
        task.downloaded = i
      }
    }

    httpClient.destroy()
  }

  private onProgress(_task: DownloadTask): void {
    // 可以在这里添加通知回调
  }

  private async restoreTasks(): Promise<void> {
    // 从 preferences 恢复未完成的任务
  }
}

export const downloadManager = new DownloadManager()
