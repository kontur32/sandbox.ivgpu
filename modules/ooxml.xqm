module namespace ooxml = 'ooxml';

declare function ooxml:parse.workbook( $files as xs:base64Binary* ){
  for $i in $files
  return
  let $request := 
    <http:request method='POST'>
        <http:header name="Content-type" value="multipart/form-data; boundary=----7MA4YWxkTrZu0gW"/>
        <http:multipart media-type = "multipart/form-data" >
            <http:header name='Content-Disposition' value='form-data; name="data"'/>
            <http:body media-type = "application/octet-stream">
               { $i }
            </http:body>
        </http:multipart> 
      </http:request>

  let $response := 
      http:send-request(
          $request,
          "http://iro37.ru:9984/ooxml/api/v1.1/xlsx/parse/workbook"
      )
  return
   $response[ 2 ]
};