const http = require('http');
const fs = require('fs');
const path = require('path');

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

function htmlResponse(res, statusCode, content) {
  res.writeHead(statusCode, {
    'Content-Type': 'text/html; charset=utf-8',
    'Content-Length': Buffer.byteLength(content),
  });
  res.end(content);
}

let indexHtml = '';
try {
  indexHtml = fs.readFileSync(path.join(__dirname, 'index.html'), 'utf8');
} catch (err) {
  console.warn('Could not load index.html:', err.message);
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

  if (req.url === '/api/info') {
    jsonResponse(res, 200, {
      app: appName,
      environment,
      pod: process.env.HOSTNAME || 'local',
      timestamp: new Date().toISOString(),
    });
    return;
  }

  if (req.url === '/' || req.url === '') {
    if (indexHtml) {
      htmlResponse(res, 200, indexHtml);
    } else {
      jsonResponse(res, 200, {
        app: appName,
        environment,
        pod: process.env.HOSTNAME || 'local',
        timestamp: new Date().toISOString(),
      });
    }
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
