// app.js
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('now running on screen. 2');
});

app.listen(port, () => {
  console.log(`App running on port ${port}`);
});
