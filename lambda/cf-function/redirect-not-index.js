async function handler(event) {
  const request = event.request

  if (request.uri === "/index.html")
    return request
      
  return {
    statusCode: 302,
    headers: {
      location: {
        value: '/index.html'
      }
    }
  }
}
