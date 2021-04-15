module namespace ivgpu = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/данныеДисциплины';

import module namespace data = '/sandbox/ivgpu/generate/data'
  at '../../generate.doc/generate.data.xqm';

(:
  отправка РПД в "базу Н.Ю. Санутковой"
:)

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/generate/РПД.Титул/{ $ID }/{ $кодДисциплины }/upload' )
  %rest:method( 'GET' )
  %rest:method( 'POST' )
  %rest:query-param( 'дата', '{ $access_token }', '')
function ivgpu:компетенции( $ID, $кодДисциплины, $access_token ){
  if( $access_token = '1844-02-20')
  then(  
  let $индентификаторНачальнойПапки := '352499' (: 55370 :)
  let $индентификаторЦелевойПапки := ivgpu:getFolderID( $индентификаторНачальнойПапки, ivgpu:fileName( $ID ) )
  let $результат :=
    if( $индентификаторЦелевойПапки != '0')
    then(
      let $href :=
        web:create-url(
          'http://localhost:9984/sandbox/ivgpu/api/v01/generate/%D0%A0%D0%9F%D0%94.%D0%A2%D0%B8%D1%82%D1%83%D0%BB/' || $ID || '/' || web:encode-url( $кодДисциплины ),
          map{ 'mode' : 'dev' }
        )
      let $запросРПД :=
        try{
          http:send-request(
            <http:request method='GET'
               href= "{ $href }">
            </http:request>
          )
        }catch*{ false() }
      
      return
        if( $запросРПД )
        then(
          let $fileName :=
            $запросРПД[ 1 ]
            /http:header[ @name="Content-Disposition"]
            /@value/web:decode-url( substring-after( data(), '=' ) )
          let $file := $запросРПД[ 2 ]
          let $folderName := ivgpu:fileName( $ID )
          let $upload := 
            ivgpu:uploadFileToFolder( 
                $индентификаторНачальнойПапки,
                $folderName,
                $file,
                $fileName
            )
          
          return
            $upload
        )
        else( <error>Не удалось сгенеририровать РДП</error> )
        
    )
    else(
      <error>Папка для сохранения РПД не найдена на диске</error>
    )
  return
    web:redirect(
     'http://localhost:9984/sandbox/ivgpu/api/v01/programms/' || $ID || '/' ||  web:encode-url( $кодДисциплины ) ||  '/comp?message=' || web:encode-url( $результат/name() ) || ':' ||web:encode-url( $результат/text() )
    ) 
  ) (: конец основного условния :)
  else(
    web:redirect(
     'http://localhost:9984/sandbox/ivgpu/api/v01/programms/' || $ID || '/' ||  web:encode-url( $кодДисциплины ) ||  '/comp?message=' || web:encode-url( 'error: Неверная дата :( Функция загрузки доступна только членам клуба им. Людвига Больцмана' )  )
    )
};

declare
  %private
function
ivgpu:uploadFileToFolder( 
    $индентификаторНачальнойПапки as xs:string,
    $folderName as item()*,
    $file,
    $fileName
)
{
  let $идентификаторЦелевойПапки :=
   ivgpu:getFolderID( $индентификаторНачальнойПапки, $folderName )
  let $результатЗагрузки :=
    ivgpu:uploadFile( $идентификаторЦелевойПапки, $fileName, $file )
  
  return
      if( $результатЗагрузки[ 1 ]/@status/data() != "200" )
      then(
        <error>{
          $результатЗагрузки[ 2 ]/json/error__description/text()
        }</error>
      )
      else( <result>Загрузка прошла успешно</result> )
};

declare
  %private
function
ivgpu:getFolderID( 
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
      if( $id )
      then(
        ivgpu:getFolderID( $id, $folderName[ position() < last() ] )
      )
      else(
        '0'
      )
      
  )
  else( $parentFolderID )
};

declare 
  %private
function ivgpu:fileName( $ID as xs:string ){
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
  ivgpu:uploadFile(
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