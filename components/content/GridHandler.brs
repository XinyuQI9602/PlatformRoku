' ********** Copyright 2019 Roku Corp.  All Rights Reserved. **********

function fetch(options)
    timeout = options.timeout
    if timeout = invalid then timeout = 0

    response = invalid
    port = CreateObject("roMessagePort")
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    request.RetainBodyOnError(true)
    request.SetMessagePort(port)
    if options.headers <> invalid
        for each header in options.headers
            val = options.headers[header]
            if val <> invalid then request.addHeader(header, val)
        end for
    end if
    if options.method <> invalid
        request.setRequest(options.method)
    end if
    request.SetUrl(options.url)

    requestSent = invalid
    if options.body <> invalid
        requestSent = request.AsyncPostFromString(options.body)
    else
        requestSent = request.AsyncGetToString()
    end if
    if (requestSent)
        msg = wait(timeout, port)
        status = -999
        body = "(TIMEOUT)"
        headers = {}
        if (type(msg) = "roUrlEvent")
            status = msg.GetResponseCode()
            headersArray = msg.GetResponseHeadersArray()
            for each headerObj in headersArray
                for each headerName in headerObj
                    val = {
                        value: headerObj[headerName]
                        next: invalid
                    }
                    current = headers[headerName]
                    if current <> invalid
                        prev = current
                        while current <> invalid
                            prev = current
                            current = current.next
                        end while
                        prev.next = val
                    else
                        headers[headerName] = val
                    end if
                end for
            end for
            body = msg.GetString()
            if status < 0 then body = msg.GetFailureReason()
        end if

        response = {
            _body: body,
            status: status,
            ok: (status >= 200 AND status < 300),
            headers: headers,
            text: function()
                return m._body
            end function,
            json: function()
                return ParseJSON(m._body)
            end function,
            xml: function()
                if m._body = invalid then return invalid
                xml = CreateObject("roXMLElement") '
                if NOT xml.Parse(m._body) then return invalid
                return xml
            end function
        }
    end if

    return response
end function

sub GetContent()
    ' url = CreateObject("roUrlTransfer")
    ' url.SetUrl("FEED_URL")
    ' url.SetCertificatesFile("common:/certs/ca-bundle.crt")
    ' url.AddHeader("X-Roku-Reserved-Dev-Id", "")
    ' url.InitClientCertificates()
    ' feed = url.GetToString()
    ' this is for a sample, usually feed is retrieved from url using roUrlTransfer
   response = fetch({
        url: "http://145.239.194.129:10002/pages/category/15",
        timeout: 5000,
        method: "GET",
        headers: {
            "Content-Type": "application/json",
        }
    })
    
    if response.ok
        'while cookies <> invalid
            '?cookies.value
            'cookies = cookies.next
        'end while
        json = response.json()
        '?json.items.total
    else                          
        ?"The request failed", response.statusCode, response.text()
    end if
   
    'feed = ReadAsciiFile("pkg:/feed/feed.json")
    Sleep(2000) ' to emulate API call

    'json = ParseJson(feed)
    rootNodeArray = ParseJsonToNodeArray(json)
    m.top.content.Update(rootNodeArray)
end sub

function ParseJsonToNodeArray(jsonAA as Object) as Object
    if jsonAA = invalid then return []
    resultNodeArray = {
       children: []
    }

    for each fieldInJsonAA in jsonAA
        ' ***Assigning fields that apply to both movies and series***
        'if fieldInJsonAA = "movies" or fieldInJsonAA = "series"
         '   mediaItemsArray = jsonAA[fieldInJsonAA]
          '  itemsNodeArray = []
           ' for each mediaItem in mediaItemsArray
            '    itemNode = ParseMediaItemToNode(mediaItem, fieldInJsonAA)
            '   itemsNodeArray.Push(itemNode)
            'end for
            'rowAA = {
             '  title: fieldInJsonAA
              ' children: itemsNodeArray
            '}

           'resultNodeArray.children.Push(rowAA)
       'end if
       ' ***Assigning fields that apply to CINEMA***
        if fieldInJsonAA = "contents" 
            mediaItemsArray = jsonAA[fieldInJsonAA]
            itemsNodeArray = []
            for each mediaItem in mediaItemsArray
                itemNode = ParseMediaItemToNode(mediaItem, fieldInJsonAA)
               itemsNodeArray.Push(itemNode)
            end for
            rowAA = {
               title: fieldInJsonAA
               children: itemsNodeArray
            }

           resultNodeArray.children.Push(rowAA)
       end if
    end for

    return resultNodeArray
end function

function ParseMediaItemToNode(mediaItem as Object, mediaType as String) as Object
    itemNode = Utils_AAToContentNode({
            "id": mediaItem.id
            "title": mediaItem.name
            "hdPosterUrl": mediaItem.tile_image
            "Description": mediaItem.description
            "Categories": mediaItem.type
        })

    if mediaItem = invalid then
        return itemNode
    end if

    ' Assign movie specific fields
    if mediaType = "contents"
        Utils_forceSetFields(itemNode, {
            "Url": GetVideoUrl()
        })
    end if
    ' Assign series specific fields
    'if mediaType = "series"
        'seasons = mediaItem.seasons
        'seasonArray = []
        'for each season in seasons
            'episodeArray = []
            'episodes = season.Lookup("episodes")
            'for each episode in episodes
                'episodeNode = Utils_AAToContentNode(episode)
                'Utils_forceSetFields(episodeNode, {
                    '"url": GetVideoUrl(episode)
                    '"title": episode.title
                    '"hdPosterUrl": episode.thumbnail
                    '"Description": episode.shortDescription
                '})
                'episodeArray.Push(episodeNode)
            'end for
            'seasonArray.Push(episodeArray)
        'end for
        'Utils_forceSetFields(itemNode, {
            '"seasons": seasonArray
        '})
    'end if
    return itemNode
end function

function GetVideoUrl() as String
   'content = mediaItem.Lookup("content")
   'if content = invalid then
    '    return ""
    'end if

    'videos = content.Lookup("videos")
    'if videos = invalid then
     '   return ""
    'end if

    'entry = videos.GetEntry(0)
    'if entry = invalid then
     '   return ""
    'end if

    'url = entry.Lookup("url")
    'if url = invalid then
     '   return ""
    'end if

    return "http://roku.content.video.llnw.net/smedia/59021fabe3b645968e382ac726cd6c7b/Gb/siCt-V7LOSU08W_Ve1ByJY5N9emKZeXZvnrH2Yb9c/117_segment_2_twitch__nw_060515.mp4"
end function
