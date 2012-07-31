fs = require('fs')
coffee = require('coffee-script')

// Hacky little test to make sure the examples in the readme run
require('tap').test("README examples", function (t) {
  var readme = fs.readFileSync(__dirname+'/../../README.rst', 'utf-8')
    , code = readme.split('\n').filter(function (line) {
        return line.match(/^    /)
      })

  code[0] = code[0].replace('./', '../../')
  code.pop() // Remove npm install line
  code.join('\n')
  eval(code)
  t.end()
})
