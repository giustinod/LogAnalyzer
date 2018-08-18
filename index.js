const express = require('express');
const cors = require('cors')
const multer = require("multer");
const shell = require('shelljs');

var baseDir = '/home/osboxes/evtloader/';
var esHost = 'localhost';

var storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, baseDir)
  },
  filename: function (req, file, cb) {
    cb(null, file.originalname)
  }
})

var upload = multer({
  storage: storage,

});

var app = express();

app.use(cors())

app.post("/evtlog", upload.single('evtlog'), function(req, res) {

    console.log('Requested /evtlog, file: ' + req.file.filename);
    if (!req.file) {
      return res.status(400).send('No files were uploaded');
    }
    else {
      console.dir(req.file);
      shell.cd(baseDir); 
      shell.exec('./loadcsv.sh ' + req.file.filename, { silent:true }, function(code, stdout, stderr) {

        console.log('Exit code:', code);
        // console.log('Program output:', stdout);
        // console.log('Program stderr:', stderr);

        if (code === 0) {
            return res.status(200).send(stdout);
        }
        else {
            return res.status(500).send(stderr);
        }
      });
    }
});

app.post("/crl", upload.single('crl'), function(req, res) {

    console.log('Requested /crl, file: ' + req.file.filename);
    if (!req.file) {
      return res.status(400).send('No files were uploaded');
    }
    else {
      console.dir(req.file);
      return res.status(200).send('File ' + req.file.filename + ' uploaded');
    }
});

app.get('/', function (req, res) {
  res.send('This is Bombardier eventlog loader in elasticsearch!');
});

app.listen(3000, function () {
  console.log('Bombardier eventlog loader listening on port 3000!');

  // print process.argv
  process.argv.forEach(function (val, index) {
    // console.log(`${index}: ${val}`);
    if (index === 2) {
      baseDir = val;
    }
    if (index === 3) {
      esHost = val;
    }
  });
  
  console.log('Elastic search URL: ', esHost);
  console.log('Base dir: ', baseDir);
});

