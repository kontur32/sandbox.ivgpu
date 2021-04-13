declare function local:uploadFile( $folderID, $fileName, $file ){
  let $requestParams :=
    let $requestUrl :=
      json:parse(
        fetch:text(
          'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.uploadFile?id=' || $folderID
        )
      )
    return
      map{
         'field' : $requestUrl/json/result/field/text(),
         'uploadUrl' : $requestUrl/json/result/uploadUrl/text()
       }
  
  let $request := 
      <http:request method='post'>
          <http:multipart media-type = "multipart/form-data" >
              <http:header name="Content-Disposition" value= 'form-data; name="{ $requestParams?field }"; filename="{ $fileName }"'/>
              <http:body media-type = "application/octet-stream"></http:body>
          </http:multipart> 
        </http:request>
    
    let $response := 
        http:send-request( $request, $requestParams?uploadUrl, $file )
    return
     $response
};


let $fileName := "аннотация.docx"
let $file := 
  file:read-binary(
   "C:\Users\sseme\Downloads\o_20.03.01_БТПИП_Экономика безопасности труда_2018.docx"
  )

let $folderID := '46686'


let $requestParams :=
  let $requestUrl :=
    json:parse(
      fetch:text(
        'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.uploadFile?id=' || $folderID
      )
    )
  return
    map{
       'field' : $requestUrl/json/result/field/text(),
       'uploadUrl' : $requestUrl/json/result/uploadUrl/text()
     }

let $request := 
    <http:request method='post'>
        <http:multipart media-type = "multipart/form-data" >
            <http:header name="Content-Disposition" value= 'form-data; name="{ $requestParams?field }"; filename="file5.pdf"'/>
            <http:body media-type = "application/octet-stream"></http:body>
        </http:multipart> 
      </http:request>
  
  let $response := 
      http:send-request( $request, $requestParams?uploadUrl, $file )
  
  return
   local:uploadFile( $folderID, $fileName, $file )