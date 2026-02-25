const express = require('express');
const app = express();

app.use(function(req, res, next) {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  next();
});

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

const CourseController = require('./course/CourseController');
app.use('/courses', CourseController);

const AuthorController = require('./author/AuthorController');
app.use('/authors', AuthorController);

module.exports = app;

module.exports = app;