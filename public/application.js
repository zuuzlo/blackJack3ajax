$(document).ready(function() {
  player_hits();
  player_stays();
  player_dd();

});
function player_hits() {
  $(document).on("click", "form#hit_form input", function() {
    $.ajax({
      type: "POST",
      url: "/game/player/hit",
    }).done(function(msg) {
      $("#game").replaceWith(msg)
    });

    return false;
  });
}

function player_stays() {
  $(document).on("click", "form#stay_form input", function() {
    $.ajax({
      type: "POST",
      url: "/game/dealer/hit",
    }).done(function(msg) {
      $("#game").replaceWith(msg)
    });

    return false;
  });
}

function player_dd() {
  $(document).on("click", "form#dd_form input", function() {
    $.ajax({
      type: "POST",
      url: "/game/dealer/hit",
      data: {'double_down' : "Double Down"},
    }).done(function(msg) {
      $("#game").replaceWith(msg)
    });

    return false;
  });
} 