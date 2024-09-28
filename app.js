// app.js
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('Hello from my VPS! Did docker! Also setup webhook! Also did the nohup thing');
});

app.listen(port, () => {
  console.log(`App running on port ${port}`);
});
