module.exports = function (fn) { 
  return function() { 
    fn.apply(this, arguments)
    return this
  }
}
