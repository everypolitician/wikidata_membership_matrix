$(function() {
  var $results = $('#results');
  $.get('/query').success(function(response) {
    response.results.bindings.forEach(function(b) {
      $results.append('<p>' + b.itemLabel.value + '</p>');
    });
  });
});
