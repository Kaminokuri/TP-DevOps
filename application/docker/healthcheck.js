const http = require('http');

const request = http.get('http://127.0.0.1:3001/health', (response) => {
  if (response.statusCode === 200) {
    process.exit(0);
  }

  process.exit(1);
});

request.on('error', () => process.exit(1));
request.setTimeout(2000, () => {
  request.destroy();
  process.exit(1);
});

