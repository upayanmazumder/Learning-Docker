// app.js
const express = require('express');
const app = express();
const port = process.env.PORT || 7000;

app.get('/', (req, res) => {
  res.send('gggs s ss s s s s s a s as as ');
});

app.listen(port, () => {
  console.log(`App running on port ${port}`);
});
