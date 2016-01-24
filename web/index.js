var convert = function(url) {

  document.getElementById('error').innerHTML = '';
  var request = new XMLHttpRequest();
  request.open('POST', 'http://johnmacfarlane.net/cgi-bin/to_commonmark.lua', true);
  request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
  request.onreadystatechange = function (oEvent) {
    if (request.readyState === 4) {
        if (request.status === 200) {
           document.getElementById('result').innerText = request.responseText;
        } else {
           document.getElementById('error').innerHTML = request.responseText;
        }
    }
  };
  request.send('url=' + encodeURIComponent(url));
}
