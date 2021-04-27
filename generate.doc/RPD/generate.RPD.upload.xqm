module namespace ivgpu = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/загрузкаРПД';

import module namespace session = "http://basex.org/modules/session";

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../config.xqm';

import module namespace data = '/sandbox/ivgpu/generate/data'
  at '../../generate.doc/generate.data.xqm';

import module namespace 
  check = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/проверкаНаличияРПД'
  at 'generate.RPD.check.xqm';

(:
  отправка РПД в "базу Н.Ю. Санутковой"
:)

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/generate/РПД.Титул/{ $ID }/{ $кодДисциплины }/upload.self' )
  %rest:method( 'POST' )
  %rest:form-param( 'file', '{ $file }' )
function ivgpu:загрузка.РПД.своей( $ID, $кодДисциплины, $file  ){
  let $поля := map:keys( $file )
  let $файл := map:get( $file, $поля[ 1 ] )
  return
  if( ( session:get( 'login' ) ) and bin:length( $файл ) > 0 )
  then(
    
    let $форматФайла :=
      '.' || substring-after( $поля[ 1 ], '.' )
    let $индентификаторНачальнойПапки := config:param( 'upload.Directory.Root' )
    let $folderName := ivgpu:folderName( $ID )
    
    let $индентификаторЦелевойПапки := 
      ivgpu:getFolderIDCreate( $индентификаторНачальнойПапки, $folderName )
    
    let $программа :=  data:getProgrammData()[ Файл/@ID = $ID ]
    let $дисциплина :=
      $программа
      //Дисциплины/Дисциплина[ @КодДисциплины/data() = $кодДисциплины ]
    
    let $имяФайла := check:buildOutputFile( $программа, $дисциплина, $форматФайла )
    let $upload := 
        ivgpu:uploadFileToFolder( 
           $индентификаторЦелевойПапки, $файл, $имяФайла
        )
    let $результат :=
      web:encode-url( $upload/name() ) || ':' ||web:encode-url( $upload/text() ) || ';'
    
    return
      web:redirect(
      config:param( 'host' ) || '/sandbox/ivgpu/api/v01/programms/' || $ID || '/' ||  web:encode-url( $кодДисциплины ) ||  '/comp?message=' || $результат
    )
  )
  else(
     web:redirect(
      config:param( 'host' ) || '/sandbox/ivgpu/api/v01/programms/' || $ID || '/' ||  web:encode-url( $кодДисциплины ) ||  '/comp?message=' || web:encode-url( 'error: Вы не авторизованы либо забыли выбрать файл для загрузки' )  )
  )
};


declare 
  %rest:path( '/sandbox/ivgpu/api/v01/generate/РПД.Титул/{ $ID }/{ $кодДисциплины }/upload' )
  %rest:method( 'GET' )
  %rest:method( 'POST' )
  %rest:form-param( 'file', '{ $file }' )
function ivgpu:компетенции( $ID, $кодДисциплины, $file  ){
  if( session:get( 'login' ) )
  then(  
  let $индентификаторНачальнойПапки := config:param( 'upload.Directory.Root' )
   (: боевая - 55370, полигон - 352499:)
  let $folderName := ivgpu:folderName( $ID )
  let $индентификаторЦелевойПапки := 
    ivgpu:getFolderID( $индентификаторНачальнойПапки, $folderName )
  let $индентификаторЦелевойПапки2 := 
    ivgpu:getFolderID( '55370', $folderName )
  let $результат :=
    if( $индентификаторЦелевойПапки != '0' or $индентификаторЦелевойПапки2 != '0' )
    then(
      let $href :=
        web:create-url(
          config:param( 'host' ) || '/sandbox/ivgpu/api/v01/generate/%D0%A0%D0%9F%D0%94.%D0%A2%D0%B8%D1%82%D1%83%D0%BB/' || $ID || '/' || web:encode-url( $кодДисциплины ),
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
          let $upload := 
            ivgpu:uploadFileToFolder( 
               $индентификаторЦелевойПапки, $file, $fileName
            )
          let $upload2 := 
            ivgpu:uploadFileToFolder( 
                $индентификаторЦелевойПапки, $file, $fileName
            )
          return
            web:encode-url( $upload/name() ) || ':' ||web:encode-url( $upload/text() ) || ';' ||
            web:encode-url( $upload2/name() ) || ':' ||web:encode-url( $upload2/text() )
        )
        else(
          config:param( 'host' ) || '/sandbox/ivgpu/api/v01/programms/' || $ID || '/' ||  web:encode-url( $кодДисциплины ) ||  '/comp?message=' || web:encode-url( 'error: не удалось сгенерировать РПД;' )  )        
    )
    else(
       web:redirect(
          config:param( 'host' ) || '/sandbox/ivgpu/api/v01/programms/' || $ID || '/' ||  web:encode-url( $кодДисциплины ) ||  '/comp?message=' || web:encode-url( 'error: нет целевой папки ни в одном из хранилищ;' )  )
    )
  return
    web:redirect(
      config:param( 'host' ) || '/sandbox/ivgpu/api/v01/programms/' || $ID || '/' ||  web:encode-url( $кодДисциплины ) ||  '/comp?message=' || $результат
    ) 
  ) (: конец основного условния :)
  else(
    web:redirect(
      config:param( 'host' ) || '/sandbox/ivgpu/api/v01/programms/' || $ID || '/' ||  web:encode-url( $кодДисциплины ) ||  '/comp?message=' || web:encode-url( 'error: Функция загрузки доступна только членам клуба им. Людвига Больцмана:' )  )
    )
};

declare
  %public
function
ivgpu:uploadFileToFolder( 
    $идентификаторЦелевойПапки as xs:string,
    $file,
    $fileName
)
{
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
  %public
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
    )/response/result/item[ starts-with( NAME/text(), $folderName[ last() ] ) ]/ID/text()
    return
      if( $id )
      then( ivgpu:getFolderID( $id, $folderName[ position() < last() ] ) )
      else( '0' )
      
  )
  else( $parentFolderID )
};

declare
  %public
function
ivgpu:getFolderIDCreate( 
    $parentFolderID as xs:string,
    $folderName as item()*
)
{
  if( count( $folderName ) > 0 )
  then(
    let $url := 
      config:bitrixAPI() || 'disk.folder.getchildren.xml?id=' || $parentFolderID
    let $id := 
      fetch:xml( $url )
      /response/result/item
      [ starts-with( NAME/text(), $folderName[ last() ] ) ]/ID/text()
    
    return
      if( $id )
      then( ivgpu:getFolderIDCreate( $id, $folderName[ position() < last() ] ) )
      else(
        let $newID := ivgpu:createFolder( $parentFolderID, $folderName[ last() ] )
        return
          ivgpu:getFolderIDCreate( $newID, $folderName[ position() < last() ] )
      )
  )
  else( $parentFolderID )
};

declare function ivgpu:createFolder( $parentFolderID, $folderName ){
  let $request :=
      <http:request method='post'>
        <http:multipart media-type = "multipart/form-data" >
            <http:header name="Content-Disposition" value= 'form-data; name="id";'/>
            <http:body media-type = "application/text" >{ $parentFolderID }</http:body>
            <http:header name="Content-Disposition" value= 'form-data; name="data[NAME]";'/>
            <http:body media-type = "application/text">{ $folderName }</http:body>
        </http:multipart> 
      </http:request>
  let $url := 
      config:bitrixAPI() || 'disk.folder.addsubfolder.xml'
  let $результат := http:send-request( $request, $url )
  return
      if( $результат[ 1 ]/@status/data() = '200' )
      then( <ID>{ $результат[ 2 ]/response/result/ID/text()  }</ID> )
      else(
        <err:BTX-DISK05>{ $результат[ 2 ]/response/error_description/text() }</err:BTX-DISK05>
      )
};

declare 
  %public
function ivgpu:folderName( $ID as xs:string ){
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
      replace( $программа/@НазваниеПрофиля/data(), '"', '' ),
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