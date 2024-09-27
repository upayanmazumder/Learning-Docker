// app.js
const express = require('express');
const app = express();
const port = process.env.PORT || 5100;

app.get('/', (req, res) => {
  res.send('Hello from my VPS!');
});

app.listen(port, () => {
  console.log(`App running on port ${port}`);
});
