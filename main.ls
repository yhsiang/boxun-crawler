require! <[request cheerio iconv-lite fs async]>

search = (next) ->
  urls = []
  (err, response, body) <- request.post do
    url: 'http://boxun.com/cgi-bin/search/find_by_date.cgi'
    form:
      cat: 'china'
      year: '2014'
      month: '01'
      date: 'all'
    encoding: null
  $ = iconv-lite.decode body, 'gb2312' |> cheerio.load
  links = $('li').first!

  while links.children!text!
    paths = links.children!attr('href') / '/'
    urls.push do
      title: links.children!text!trim!
      url: 'http://boxun.com' + links.children!attr 'href'
      filename: paths.6
    links .= next!

  next null, urls

fetch = (link) ->
  (error, response, body) <- request.get do
    url: link.url #'http://boxun.com/news/gb/china/2013/01/201301010059.shtml'
    encoding: null
  $ = iconv-lite.decode body, 'gb2312' |> cheerio.load
  $ 'td.F11 table' .remove!
  title = $ 'td.F11 center' .first!text!trim!
  content = $ 'td.F11' .first!text!trim!
  fs.writeFileSync 'data/' + link.filename, content

fs.mkdirSync 'data' unless fs.existsSync 'data'

search (err, urls)->
  urls |> JSON.stringify |> fs.writeFileSync 'urls.txt', _

  tasks = for let i from 0 to urls.length - 1 by 1
    -> fetch urls[i]

  error <- async.parallel tasks
  console.log error if error
  console.log 'done'