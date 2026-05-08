/**
 * 后端 API 接口封装
 */
import { get, post, del } from './HttpClient'
import type { ApiResponse, Comic, Chapter, ChapterDetail, User, Favorite, History } from '../model/Types'
import type { ComicListData, ChapterListData } from '../model/Types'

// ---- Auth ----
export async function login(email: string, password: string): Promise<string> {
  const resp = await post<ApiResponse<{ token: string }>>('/auth/login', {
    email: email,
    password: password
  })
  return resp.data.token
}

export async function register(email: string, password: string, nickname: string): Promise<string> {
  const resp = await post<ApiResponse<{ token: string }>>('/auth/register', {
    email: email,
    password: password,
    nickname: nickname
  })
  return resp.data.token
}

export async function getProfile(): Promise<User> {
  const resp = await get<ApiResponse<User>>('/user/profile')
  return resp.data
}

// ---- Comics ----
export async function getComics(page: number = 1, pageSize: number = 20): Promise<ComicListData> {
  const resp = await get<ApiResponse<ComicListData>>(`/comics?page=${page}&page_size=${pageSize}`)
  return resp.data
}

export async function getComicDetail(id: number): Promise<Comic> {
  const resp = await get<ApiResponse<Comic>>(`/comics/${id}`)
  return resp.data
}

// ---- Chapters ----
export async function getChapters(comicId: number): Promise<ChapterListData> {
  const resp = await get<ApiResponse<ChapterListData>>(`/comics/${comicId}/chapters`)
  return resp.data
}

export async function getChapterDetail(id: number): Promise<ChapterDetail> {
  const resp = await get<ApiResponse<ChapterDetail>>(`/chapters/${id}`)
  return resp.data
}
