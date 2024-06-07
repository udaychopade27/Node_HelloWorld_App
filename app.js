// Load the http module to create an HTTP server.
const http = require('http');

// Configure the HTTP server to respond with "Hello, World!" to all requests.
const server = http.createServer((req, res) => {
  // Set the response HTTP header with HTTP status and Content type.
  res.writeHead(200, { 'Content-Type': 'text/plain' });

  // Send the response body "Hello, World!"
  res.end('Hello, World!\n');
});

// Listen on port 3000, IP defaults to 127.0.0.1
const port = 3000;
server.listen(port, () => {
  console.log(`Server running at http://127.0.0.1:${port}/`);
});
