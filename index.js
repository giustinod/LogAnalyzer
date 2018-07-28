const express = require('express');
const cors = require('cors')
const multer = require("multer");
const shell = require('shelljs');

var baseDir = '/home/osboxes/evtloader/';
var esHost = 'localhost';

var upload = multer({
  dest: baseDir
});

var app = express();

app.use(cors())

app.post("/upload", upload.single('evtlog'), function(req, res) {

    if (!req.file) {
      return res.status(400).send('No files were uploaded.');
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


