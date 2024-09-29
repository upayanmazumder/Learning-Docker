// app.js
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('uhh what about this? does this work?');
});

app.listen(port, () => {
  console.log(`App running on port ${port}`);
});
