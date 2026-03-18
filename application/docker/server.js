const http = require('http');

const port = Number(process.env.PORT || 3001);
const start = Date.now();
let totalRequests = 0;

const metrics = () => {
  const uptimeSeconds = Math.floor((Date.now() - start) / 1000);

  return [
    '# HELP gitops_app_uptime_seconds Uptime of the demo application',
    '# TYPE gitops_app_uptime_seconds counter',
    `gitops_app_uptime_seconds ${uptimeSeconds}`,
    '# HELP gitops_app_requests_total Total number of handled requests',
    '# TYPE gitops_app_requests_total counter',
    `gitops_app_requests_total ${totalRequests}`
  ].join('\n');
};

const server = http.createServer((req, res) => {
  totalRequests += 1;

  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', service: 'monitoring-app' }));
    return;
  }

  if (req.url === '/metrics') {
    res.writeHead(200, { 'Content-Type': 'text/plain; version=0.0.4' });
    res.end(`${metrics()}\n`);
    return;
  }

  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(
    JSON.stringify({
      name: 'gitops-monitoring-app',
      status: 'running',
      documentation: '/metrics and /health are available'
    })
  );
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Monitoring app listening on port ${port}`);
});

