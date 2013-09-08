$(function ($) {
  var queryInput = $("#try-it-modal textarea.code");
  var dialect = new gesundheit.dialects.pretty()

  queryInput.change(evaluateQuery);
  queryInput.keyup(evaluateQuery);
  evaluateQuery();

  function evaluateQuery () {
    var result;
    try {
      eval([
        'var result = (function (g) {',
        '  with (g) {',
        '    ' + queryInput.val(),
        '  }',
        '})(gesundheit)'
      ].join('\n'));
      if (result && result.compile) {
        if (result.q) result = result.q;
        var sp = dialect.compile(result);
        $('#try-it-modal .sql').text(sp[0])
        $('#try-it-modal .params').text(JSON.stringify(sp[1]))
      } else {
        $('#try-it-modal .sql').text(result + ' has no "compile" method')
        $('#try-it-modal .params').text('');
      }
    } catch (err) {
      if (!(err instanceof SyntaxError)) {
        $('#try-it-modal .sql').text('' + err)
        $('#try-it-modal .params').text('');
      }
    }
  }
})
