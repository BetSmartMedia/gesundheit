$(document).ready(function() {
  // Sidebar section highlighting

  function yOffset(elem) {
    offset = 0
    do {
      offset += elem.offsetTop
    } while(elem = elem.offsetParent)
    return offset
  }
  
  var sectionNames = {}
  var sections = null
  var updateSectionHeights = function() {
    sections = $('div.section').get().map(function (node) {
      node.yTop = yOffset(node)
      var header = $(node).children('h1, h2, h3, h4').first()
      node.yBottom = yOffset(header.get(0)) + header.outerHeight()
      sectionNames[node.id] = node
      return node
    })
  }

  function currentSection() {
    var w = $(window)
    var top = w.scrollTop()
    var bottom = w.scrollTop() + w.height()
    var half = top + ((bottom - top) * 0.66)
    var section = sections.filter(function (section) {
      return section.yBottom >= top && section.yTop < half
    })[0]

    if (!section || $(section).hasClass('currentsection')) return

    highlightSection(section)
  }

  function highlightSection(section) {
    $(".currentsection").removeClass('currentsection')
    $(section).addClass('currentsection')
    $(".sphinxsidebar a[href='#" + section.id + "']")
      .parent().addClass('currentsection')
  }

  $('.sphinxsidebar a.internal.reference').click(function() {
    var id = this.href.split('#').pop()
    if (id) highlightSection(document.getElementById(id))
  })

  // Collapsible code blocks for HTTP request/responses
	$('.highlight-http pre').each(function() {
		this._restoreHeight = $(this).height()
		$(this).parent('.highlight')
		 .prepend('<div class="collapse" style="display: none">[-]</div>')
		 .append('<div class="expand">[+]</div>')
		$(this).height('2.5em')
	})
 
  $('.highlight .expand').click(function() {
    $(this).slideUp('fast', function () {
			$(this).siblings('.collapse').fadeIn('fast')
		})
    var pre = $(this).siblings('pre')
    pre.animate({height: pre.get(0)._restoreHeight}, 200, function () {
      updateSectionHeights()
      currentSection()
    })
  })
 
  $('.highlight .collapse').click(function() {
    $(this).slideUp('fast', function () {
			$(this).siblings('.expand').fadeIn('fast')
		})
    $(this).siblings('pre').animate({height: '2.5em'}, 200, function() {
      updateSectionHeights()
      currentSection()
    })
  })

  updateSectionHeights()

  $(window).scroll(currentSection)
  var hash
  if (hash = document.location.hash) {
    highlightSection(sectionNames[hash.substring(1)])
  } else {
    currentSection()
  }

})
