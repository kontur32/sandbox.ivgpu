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
  let $result :=
    let $поля := map:keys( $file )
    let $файл := map:get( $file, $поля[ 1 ] )    
    return
      if( ( session:get( 'login' ) ) and bin:length( $файл ) > 0 )
      then(
        let $форматФайла :=
            '.' || substring-after( $поля[ 1 ], '.' )
        let $программа :=  data:getProgrammData()[ Файл/@ID = $ID ]
        let $дисциплина :=
          $программа
          //Дисциплины/Дисциплина[ @КодДисциплины/data() = $кодДисциплины ]
        let $имяФайла := check:buildOutputFile( $программа, $дисциплина, $форматФайла )
        return
          ivgpu:uploadFileToFolders( $ID, $файл, $имяФайла )
      )
      else(
         web:encode-url( 'error: Вы не авторизованы либо забыли выбрать файл для загрузки' )
      )
  return
    web:redirect(
      config:param( 'host' ) || '/sandbox/ivgpu/api/v01/programms/' || $ID || '/' ||  web:encode-url( $кодДисциплины ) ||  '/comp?message=' || $result
    )
};


declare 
  %rest:path( '/sandbox/ivgpu/api/v01/generate/РПД.Титул/{ $ID }/{ $кодДисциплины }/upload' )
  %rest:method( 'POST' )
function ivgpu:компетенции( $ID, $кодДисциплины ){
  let $result :=
    if( 1 or session:get( 'login' ) )
    then(  
      let $href :=
            web:create-url(
              config:param( 'host' ) || '/sandbox/ivgpu/api/v01/generate/%D0%A0%D0%9F%D0%94.%D0%A2%D0%B8%D1%82%D1%83%D0%BB/' || $ID || '/' || web:encode-url( $кодДисциплины ),
              map{ 'mode' : 'dev' }
            )
      let $запросРПД :=
        try{
          http:send-request( <http:request method='GET' href= "{ $href }"/> )
        }catch*{ false() }
    
    let $результат :=
      if( $запросРПД )
      then(
        let $программа :=  data:getProgrammData()[ Файл/@ID = $ID ]
        let $дисциплина :=
          $программа//Дисциплины/Дисциплина
          [ @КодДисциплины/data() = $кодДисциплины ]
        let $имяФайла := check:buildOutputFile( $программа, $дисциплина, '.docx' )
        return
          ivgpu:uploadFileToFolders( $ID, $запросРПД[ 2 ], $имяФайла )
      )
      else(
        web:encode-url( 'error: не удалось получить файл РПД;' )  )
    
    return
         $результат
    ) (: конец основного условния :)
    else(
       web:encode-url( 'error: Функция загрузки доступна только членам клуба им. Людвига Больцмана;' )
      )
  return
    web:redirect(
      config:param( 'host' ) || '/sandbox/ivgpu/api/v01/programms/' || $ID || '/' ||  web:encode-url( $кодДисциплины ) ||  '/comp?message=' || $result
    )
};


declare 
  %private
function ivgpu:uploadFileToFolders( $ID, $file, $fileName ){
      let $кореньОсновнойПапки := config:param( 'upload.Directory.Root' )
      let $кореньДополнительнойПапки := config:param( 'upload.Directory.Secondary' )
      let $folderName := ivgpu:folderNameCreate( $ID )
      
      let $индентификаторОсновнойПапки := 
        ivgpu:getFolderIDCreate( $кореньОсновнойПапки, $folderName )
      let $индентификаторДополнительнойПапки := 
        ivgpu:getFolderID( $кореньДополнительнойПапки, $folderName )
      
      return
        if( $индентификаторОсновнойПапки != '0' or $кореньДополнительнойПапки != '0' )
        then(
          let $uploadRoot := 
            ivgpu:uploadFileToFolder( 
               $индентификаторОсновнойПапки, $file, $fileName
            )
          let $uploadSecondary := 
            ivgpu:uploadFileToFolder( 
                $индентификаторДополнительнойПапки, $file, $fileName
            )
          return
            web:encode-url( $uploadRoot/name() ) || ':' ||web:encode-url( $uploadRoot/text() )
            || ';' ||
            web:encode-url( $uploadSecondary/name() ) || ':' ||web:encode-url( $uploadSecondary/text() )
          )
        else(
          web:encode-url( 'error: нет целевой папки ни в одном из хранилищ;'  )
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


(: возвращает ID папки или 0 :)
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
    let $url := 
      config:bitrixAPI() || 'disk.folder.getchildren.xml?id=' || $parentFolderID
    let $id := 
      fetch:xml( $url)
      /response/result/item
      [ starts-with( NAME/text(), $folderName[ last() ] ) ]
      /ID/text()
    return
      if( $id )
      then( ivgpu:getFolderID( $id, $folderName[ position() < last() ] ) )
      else( '0' )
  )
  else( $parentFolderID )
};

(: возращает ID папки; в случае отсусутсвия пытается создать; 0 если не удается создать :)
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
          if( $newID/name() = 'ID' )
          then(
            ivgpu:getFolderIDCreate( $newID, $folderName[ position() < last() ] )
          )
          else( '0' )
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
function ivgpu:folderNameCreate( $ID as xs:string ){
  let $уровень :=
    (
      [ '03', 'бакалавриат' ],
      [ '04', 'магистратура' ],
      [ '05', 'специалитет' ]
    )
  let $программа := data:getProgrammData()[ Файл/@ID = $ID ]
  let $наличиеДубликатов :=
    count( data:getProgrammsEqual( $программа ) ) > 1  
  
  let $кодУровня := 
    $уровень[ .?1 = tokenize( $программа/@КодНаправления/data(), '\.' )[ 2 ] ]?2
  return
    (
      $программа/@Год/data(),
      'РПД',
      if( $наличиеДубликатов )then( $программа/Файл/@ID || '--' )else() 
      || replace( $программа/@НазваниеПрофиля/data(), '"', '' )
      ,
      $программа/@КодНаправления/data(),
      upper-case( substring( $кодУровня, 1, 1 ) ) || substring( $кодУровня, 2 )
    )
};

declare 
  %public
function ivgpu:folderName( $ID as xs:string ){
  let $папки := 
    csv:parse(  
      fetch:text(
        'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=1070885511&amp;single=true&amp;output=csv'
    ), map{ 'header' : true() } )/csv/record
  
  let $уровень :=
    (
      [ '03', 'бакалавриат' ],
      [ '04', 'магистратура' ],
      [ '05', 'специалитет' ]
    )
  let $программа := data:getProgrammData()[ Файл/@ID = $ID ]
  let $кодУровня := 
    $уровень[ .?1 = tokenize( $программа/@КодНаправления/data(), '\.' )[ 2 ] ]?2
  let $наличиеДубликатов :=
    count( data:getProgrammsEqual( $программа ) ) > 1 
  let $папкаВБазеУМУ := 
        $папки[ Профиль = $программа/@НазваниеПрофиля/data() ][ 1 ]
        /Название_папки/text()
  return
    (
      $программа/@Год/data(),
      'РПД',
      if( $папкаВБазеУМУ )
      then(
        if( $наличиеДубликатов )then( $программа/Файл/@ID || '--' )else() 
        || $папкаВБазеУМУ
      )
      else(
        if( $наличиеДубликатов )then( $программа/Файл/@ID || '--' )else() 
        || normalize-space( replace( $программа/@НазваниеПрофиля/data(), '"', '' ) )
      )
      ,
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