import module namespace data = '/sandbox/ivgpu/generate/data'
  at '../generate.doc/generate.data.xqm';
  
declare 
  %private
function local:fileName( $ID as xs:string ){
  let $уровень :=
    (
      [ '03', 'бакалавриат' ],
      [ '04', 'магистратура' ],
      [ '05', 'специалитет' ]
    )
  let $программа := data:getProgrammData()[ Файл/@ID = $ID ]
  let $кодУровня := 
    $уровень[ .?1 = tokenize( $программа/@КодНаправления/data(), '\.' )[ 2 ] ]?2
  return
    (
      $программа/@Год/data(),
      'РПД',
      $программа/@НазваниеПрофиля/data(),
      $программа/@КодНаправления/data(),
      upper-case( substring( $кодУровня, 1, 1 ) ) || substring( $кодУровня, 2 )
    )
};

declare
  %private
function
  local:uploadFile(
    $folderID as xs:string,
    $fileName as xs:string,
    $file
){
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

declare
  %private
function
local:getFolderID( 
    $parentFolderID as xs:string,
    $folderName as item()*
)
{
  if( count( $folderName ) > 0 )
  then(
    let $id := 
      fetch:xml(
        'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren.xml?id=' 
        || $parentFolderID
    )/response/result/item[ NAME/starts-with( text(), $folderName[ last() ] ) ]/ID/text()
    return
        local:getFolderID( $id, $folderName[ position() < last() ] )
      
  )
  else( $parentFolderID )
};

declare
  %private
function
local:uploadFileToFolder( 
    $индентификаторНачальнойПапки as xs:string,
    $folderName as item()*,
    $file,
    $fileName
)
{
  let $идентификаторЦелевойПапки :=
  local:getFolderID( $индентификаторНачальнойПапки, $folderName )
  let $результатЗагрузки :=
    local:uploadFile( $идентификаторЦелевойПапки, $fileName, $file )
  
  return
      if( $результатЗагрузки[ 1 ]/@status/data() != "200" )
      then(
        $результатЗагрузки[ 2 ]/json/error__description/text()
      )
      else()
};

let $s :=
  "Бакалавриат/38.03.01 Экономика/Экономика предприятий и организаций/Аннотации/2020"
  
let $folderName :=
  reverse( tokenize( $s, '/' ) )

let $folderName := local:fileName( '247909' )

let $индентификаторНачальнойПапки := '352499' (: 55370 :)

let $href :=
  web:create-url(
    'http://localhost:9984/sandbox/ivgpu/api/v01/generate/%D0%A0%D0%9F%D0%94.%D0%A2%D0%B8%D1%82%D1%83%D0%BB/' || '247909' || '/' || '%D0%911.%D0%92.09',
    map{ 'mode' : 'dev' }
  )

let $запросРПД :=
  http:send-request(
  <http:request method='GET'
     href= "{ $href }">
  </http:request>
)

let $fileName :=
  $запросРПД[ 1 ]
  /http:header[ @name="Content-Disposition"]
  /@value/web:decode-url( substring-after( data(), '=' ) )

let $file := $запросРПД[ 2 ]

return
  local:uploadFileToFolder( 
      $индентификаторНачальнойПапки,
      $folderName,
      $file,
      $fileName
  )