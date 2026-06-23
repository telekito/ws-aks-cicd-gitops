const http = require('http');

const port = process.env.PORT || 3000;
const appName = process.env.APP_NAME || 'aks-workshop-app';
const environment = process.env.ENVIRONMENT || 'dev';

function jsonResponse(res, statusCode, payload) {
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    jsonResponse(res, 200, { status: 'ok' });
    return;
  }

  if (req.url === '/readyz') {
    jsonResponse(res, 200, { status: 'ready' });
    return;
  }

  jsonResponse(res, 200, {
    app: appName,
    environment,
    path: req.url,
    method: req.method,
    pod: process.env.HOSTNAME || 'local',
    timestamp: new Date().toISOString(),
  });
});

server.listen(port, () => {
  console.log(`${appName} listening on port ${port}`);
});
