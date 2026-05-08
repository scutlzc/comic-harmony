/**
 * HTTP 客户端封装
 * 使用 HarmonyOS 原生 http 模块
 */
import http from '@ohos.net.http'
import { BusinessError } from '@ohos.base'

let baseURL = 'http://10.0.2.2:9090/api/v1'  // 模拟器访问宿主机
let authToken = ''

export function setBaseURL(url: string) {
  baseURL = url
}

export function setToken(token: string) {
  authToken = token
}

export function getToken(): string {
  return authToken
}

export async function request<T>(
  method: http.RequestMethod,
  path: string,
  body?: Record<string, Object>
): Promise<T> {
  const url = `${baseURL}${path}`
  const httpRequest = http.createHttp()

  try {
    const resp = await httpRequest.request(url, {
      method: method,
      header: {
        'Content-Type': 'application/json',
        ...(authToken ? { 'Authorization': `Bearer ${authToken}` } : {})
      },
      extraData: body ? JSON.stringify(body) : undefined,
      connectTimeout: 10000,
      readTimeout: 15000
    })

    const data = JSON.parse(resp.result as string)
    return data as T
  } catch (err) {
    const bizErr = err as BusinessError
    throw new Error(`HTTP ${method} ${path} failed: ${bizErr.message}`)
  } finally {
    httpRequest.destroy()
  }
}

export async function get<T>(path: string): Promise<T> {
  return request<T>(http.RequestMethod.GET, path)
}

export async function post<T>(path: string, body?: Record<string, Object>): Promise<T> {
  return request<T>(http.RequestMethod.POST, path, body)
}

export async function del<T>(path: string): Promise<T> {
  return request<T>(http.RequestMethod.DELETE, path)
}
