require! <[request cheerio iconv-lite fs async]>

search = (next) ->
  urls = []
  console.log 'Start to Search News ...'
  (err, response, body) <- request.post do
    url: 'http://boxun.com/cgi-bin/search/find_by_date.cgi'
    headers:
      'Referer': 'http://boxun.com/search.shtml'
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131'
    form:
      cat: 'china'
      year: '2014'
      month: '01'
      date: 'all'
    encoding: null
  next err, null if err

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

fetch = (link, next) ->
  (error, response, body) <- request.get do
    url: link.url #'http://boxun.com/news/gb/china/2013/01/201301010059.shtml'
    encoding: null
  shtml = link.filename / '.'
  console.log 'Fetching ... ' + link.title
  $ = iconv-lite.decode body, 'gb2312' |> cheerio.load
  $ 'td.F11 table' .remove!
  title = $ 'td.F11 center' .first!text!trim!
  content = $ 'td.F11' .first!text!trim!
  next error, null if error
  err <- fs.writeFile 'data/' + shtml.0 + '.txt', "\ufeff" + content, encoding: 'utf8' #content
  next err, null if err
  next null, link.title + ' Saved'

main = ->
  fs.mkdirSync 'data' unless fs.existsSync 'data'

  search (err, urls) ->
    console.log '共有 ' + urls.length + '條新聞'
    urls |> JSON.stringify |> fs.writeFileSync 'urls.txt', _

    tasks = for let i from 0 to urls.length - 1 by 1
      (next) ->
        err, msg <- fetch urls[i]
        next err, null if err
        next null, msg
    err, msgs<- async.series tasks
    console.log err if err
    console.log "All tasks are finished." if msgs.length is urls.length
main!