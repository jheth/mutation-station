$(document).ready(function(){
  var repos = new Bloodhound({
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    datumTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {
      url: "/repositories/search?term=%QUERY",
      wildcard: "%QUERY"
    }
  });

  $(".typeahead").typeahead({
    minLength: 4,
    highlight: true
  }, {
    name: "repos",
    source: repos
  });
});
