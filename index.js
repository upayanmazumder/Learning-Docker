const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hey what are you doing trying to access my VPS!');
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});