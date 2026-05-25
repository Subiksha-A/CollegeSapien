export const useApi = () => {
  const config = useRuntimeConfig()
  const { getToken } = useFirebaseAuth()
  const router = useRouter()

  const request = async <T = unknown>(
    method: string,
    path: string,
    body?: Record<string, unknown>,
  ): Promise<T> => {
    const token = await getToken()
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    }
    if (token) headers['Authorization'] = `Bearer ${token}`

    const debugToken = config.public.appCheckDebugToken as string
    if (debugToken) headers['X-Firebase-AppCheck'] = debugToken

    try {
      return await $fetch<T>(`${config.public.apiBaseUrl}${path}`, {
        method,
        headers,
        body: body ? JSON.stringify(body) : undefined,
      })
    } catch (err: unknown) {
      const fetchErr = err as { status?: number }
      if (fetchErr?.status === 401) {
        router.push('/login')
      }
      throw err
    }
  }

  return {
    get: <T = unknown>(path: string) => request<T>('GET', path),
    post: <T = unknown>(path: string, body?: Record<string, unknown>) =>
      request<T>('POST', path, body),
    patch: <T = unknown>(path: string, body?: Record<string, unknown>) =>
      request<T>('PATCH', path, body),
    delete: <T = unknown>(path: string) => request<T>('DELETE', path),
    put: <T = unknown>(path: string, body?: Record<string, unknown>) =>
      request<T>('PUT', path, body),
  }
}
