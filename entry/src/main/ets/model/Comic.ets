/**
 * 漫画数据模型
 */
export interface Comic {
  id: number
  title: string
  author: string
  description: string
  cover_url: string
  status: number       // 0:连载 1:完结
  total_views: number
  total_likes: number
  total_favorites: number
  category_id: number
  category_name?: string
  created_at: string
  updated_at: string
}

export interface Chapter {
  id: number
  comic_id: number
  title: string
  sort_order: number
  page_count: number
  created_at: string
}

export interface ChapterDetail {
  chapter: Chapter
  pages: number
  pages_url?: string[]  // 前端动态拼接
}

export interface User {
  id: number
  nickname: string
  email: string
  avatar_url: string
  created_at: string
}

export interface Favorite {
  id: number
  comic_id: number
  comic_title: string
  comic_cover: string
  latest_chapter: string
  unread_count: number
  created_at: string
}

export interface History {
  id: number
  comic_id: number
  comic_title: string
  comic_cover: string
  chapter_id: number
  chapter_title: string
  page: number
  progress: number  // 0.0 ~ 1.0
  read_at: string
}
