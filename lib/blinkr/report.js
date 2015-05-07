function filter() {
  $( ".pages" ).hide();
  $( ".spinner" ).show();
  var selected = [];
  $( "#filters input[type=checkbox" ).each( function() {
    selected.push( $( this ).val();
  });
  $( "li.error[id]" ).each( function() {
    var show = false;
    var id = $( this ).attr("id");
    for (s in selected) {
      if (id.indexOf(s) >= 0) {
        show = true;
        continue;
      }
    }
    $( this ).toggle( show );
  });
  $( ".pages" ).show();
  $( ".spinner" ).hide();
}

