module namespace bitrix.disk = 'bitrix.disk';

import module namespace 
  ooxml = 'ooxml' at 'ooxml.xqm';

declare variable $bitrix.disk:bitrixAPI := 
  'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/';
  
declare variable $bitrix.disk:defaultRootFolderID := '1378';

declare function bitrix.disk:getFolderListURL( $id ){ 
    'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren?id=' || $id
  };

declare function bitrix.disk:getList ( $url )
{
  json:parse( fetch:text( $url ) )/json/result/_
};

declare function bitrix.disk:getFileList( $folderID, $params ){
  let $list := 
    bitrix.disk:getList( bitrix.disk:getFolderListURL( $folderID ) )
  let $mask := 
    if( $params?name )then( $params?name )else( '.' )
  return
     (
       $list[ TYPE = 'file' ][ matches( NAME/text(), $mask ) ],
       if( $params?recursive = 'yes' )
       then(
         for $f in $list[ TYPE = 'folder' ]
         return
           bitrix.disk:getFileList( $f/ID/text(), $params )
       )
       else()       
     ) 
};

declare function bitrix.disk:getFileList( $folderID ){
   bitrix.disk:getFileList( $folderID, map{} )
};

declare function bitrix.disk:getFileData( $полноеИмяФайла, $rootFolderID ){
  let $полноеИмяТокенезированное := tokenize( $полноеИмяФайла, '/' )
  let $имяФайла := $полноеИмяТокенезированное[ last() ]
  let $путьФайла := reverse( $полноеИмяТокенезированное[ position() < last() ] )
  let $IDпапки := bitrix.disk:getFolderIDRequest( $rootFolderID, $путьФайла )
  return
    bitrix.disk:getFileList( $IDпапки )[ NAME/text() = $имяФайла ]
};

(:
  проверяет наличие файла по полному имени,
  начиная с папки с идентификатором $rootFolderID
:)
declare
  %public
function bitrix.disk:fileExists(
   $полноеИмяФайла as xs:string,
   $rootFolderID as xs:string
 ) as xs:string*
{
   let $fileData :=
     try{ bitrix.disk:getFileData( $полноеИмяФайла, $rootFolderID ) }
     catch*{}
   return
     if( $fileData )then( $fileData/ID/text() )else()
 
};

declare
  %public
function bitrix.disk:fileExists(
   $полноеИмяФайла as xs:string
 ) as xs:string*
{
  bitrix.disk:fileExists( $полноеИмяФайла, $bitrix.disk:defaultRootFolderID )
};

(: возвращает файл по полному имени начиная с папки с идентификатором $rootFolderID :)
declare
  %public
function bitrix.disk:getFile(
   $полноеИмяФайла as xs:string,
   $rootFolderID as xs:string)
as xs:base64Binary
{
  let $ссылкаДляСкачивания :=  
    bitrix.disk:getFileData( $полноеИмяФайла, $rootFolderID )
    /DOWNLOAD__URL/text()
  return
   fetch:binary( $ссылкаДляСкачивания )
};

declare
  %public
function bitrix.disk:getFile(
   $полноеИмяФайла as xs:string
  )
as xs:base64Binary
{
  bitrix.disk:getFile( $полноеИмяФайла, $bitrix.disk:defaultRootFolderID )
};

declare function bitrix.disk:getFileBinary( $folderID, $params ){
  let $filesList := 
    bitrix.disk:getFileList( $folderID, $params )
  for $i in $filesList
  return
    fetch:binary( $i/DOWNLOAD__URL/text() )
};

declare function bitrix.disk:getFileXLSX( $folderID, $params ){
  let $xlsxBinary :=
    bitrix.disk:getFileBinary( $folderID,  $params )
  return
    ooxml:parse.workbook( $xlsxBinary )
};

(:
  заменяет содержимое файла на диске
:)

declare function
  bitrix.disk:fileReplace(
    $полноеИмяФайла as xs:string,
    $файл
){
  bitrix.disk:fileReplace(
      $полноеИмяФайла,
      $файл,
      $bitrix.disk:defaultRootFolderID
  )
};

declare function
  bitrix.disk:fileReplace(
    $полноеИмяФайла as xs:string,
    $файл,
    $rootFolderID as xs:string
){
  let $имяФайла :=
    tokenize( $полноеИмяФайла, '/')[ last() ]
  let $путьФайла :=
    string-join( tokenize( $полноеИмяФайла, '/')[ position() < last() ], '/' )
  let $идентификаторФайла := bitrix.disk:fileExists( $полноеИмяФайла, $rootFolderID )
  let $идентификаторПапкиДляЗагрузки := bitrix.disk:getFolderID( $путьФайла, $rootFolderID )
  return
      if( $идентификаторФайла )
      then(    
      let $request := 
          <http:request method='post'>
              <http:multipart media-type = "multipart/form-data" >
                  <http:header name="Content-Disposition" value= 'form-data; name="id"'/>
                  <http:body media-type = "text"/>
                  <http:header name="Content-Disposition" value= 'form-data; name="fileContent"'/>
                  <http:body media-type = "application/octet-stream"/>
              </http:multipart> 
            </http:request>
        
      let $response := 
          http:send-request(
            $request, $bitrix.disk:bitrixAPI || 'disk.file.uploadversion.xml',
            ( $идентификаторФайла, $файл )
          )
      return
       $response[ 2 ]
      )
      else( <err:bitrix>Файл не найден</err:bitrix> )
};

(:
  загружает файл;
  возвращает идентификатор файла, если успешно, и пустое значение, если файл уже существует
  если нет папок, то пытается создать
:)
declare function
  bitrix.disk:fileUpload(
    $полноеИмяФайла as xs:string,
    $файл
){
  bitrix.disk:fileUpload(
      $полноеИмяФайла,
      $файл,
      $bitrix.disk:defaultRootFolderID
  )
};

declare function
  bitrix.disk:fileUpload(
    $полноеИмяФайла as xs:string,
    $файл,
    $rootFolderID as xs:string
){
  let $идентификаторФайла := bitrix.disk:fileExists( $полноеИмяФайла, $rootFolderID )
  let $папкаФайла := 
    string-join(  tokenize( $полноеИмяФайла, '/' )[ position() < last() ], '/' )
  let $имяФайла := tokenize( $полноеИмяФайла, '/' )[ last() ]

  return
    if( $идентификаторФайла )
    then()
    else(
      let $currentFolder := 
        bitrix.disk:addFolderRecursive( $папкаФайла , $rootFolderID )
      let $requestParams :=
        let $requestUrl :=
            fetch:xml(
              $bitrix.disk:bitrixAPI || 'disk.folder.uploadFile.xml?id=' || $currentFolder
            )
        return
          map{
             'field' : $requestUrl/response/result/field/text(),
             'uploadUrl' : $requestUrl/response/result/uploadUrl/text()
           }
      let $request := 
        <http:request method='get'>
            <http:multipart media-type = "multipart/form-data" >
                <http:header name="Content-Disposition" value= 'form-data; name="{ $requestParams?field }"; filename="{ $имяФайла }"'/>
                <http:body media-type = "application/octet-stream"></http:body>
            </http:multipart> 
          </http:request>
      let $response := 
        http:send-request( $request, $requestParams?uploadUrl, $файл )
      return
       $response[ 2 ]/json/result/ID/text()
    )
};



declare function
  bitrix.disk:uploadFile(
    $folderID as xs:string,
    $fileName as xs:string,
    $file
){
  let $requestParams :=
    let $requestUrl :=
      json:parse(
        fetch:text(
          $bitrix.disk:bitrixAPI || 'disk.folder.uploadFile?id=' || $folderID
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

declare function
  bitrix.disk:deleteFile(
    $fileID as xs:string
){
  http:send-request( 
   <http:request method='get'/>, 
    $bitrix.disk:bitrixAPI || 'disk.file.markdeleted?id=' || $fileID
 )
};

declare
  %public
function
bitrix.disk:getFolderID(
    $folderName as xs:string,
    $parentFolderID as xs:string
){
  bitrix.disk:getFolderIDRequest(
    $parentFolderID,
    reverse( tokenize( $folderName, '/' ) )
  )
};

declare
  %public
function
bitrix.disk:getFolderID(
    $folderName as xs:string
){
  bitrix.disk:getFolderID(
    $folderName,
    $bitrix.disk:defaultRootFolderID
)
};

declare
  %public
function
bitrix.disk:getFolderIDRequest( 
    $parentFolderID as xs:string,
    $folderName as item()*
){
if( count( $folderName ) > 0 )
  then(
    let $url := 
      $bitrix.disk:bitrixAPI || 'disk.folder.getchildren.xml?id=' || $parentFolderID
    let $res := fetch:xml( $url )
    let $id :=
      $res
        /response/result/item
       [ NAME/text() = $folderName[ last() ] ]/ID/text()
    
    return
      if( count( $id ) = 1 )
      then( bitrix.disk:getFolderIDRequest( $id, $folderName[ position() < last() ] ) )
      else( '0' )
  )
  else( $parentFolderID )
};

declare
  %public
function
bitrix.disk:addFolder( 
    $folderName as xs:string,
    $rootFolderID as xs:string
){
  let $request := 
      <http:request method='post'>
          <http:multipart media-type = "multipart/form-data" >
              <http:header name="Content-Disposition" value= 'form-data; name="id"'/>
              <http:body media-type = "text"/>
              <http:header name="Content-Disposition" value= 'form-data; name="data[NAME]"'/>
              <http:body media-type = "text"/>
          </http:multipart> 
        </http:request>
    
  return 
      http:send-request(
        $request,
        $bitrix.disk:bitrixAPI || 'disk.folder.addsubfolder.xml',
        ( $rootFolderID,  $folderName )
      )[ 2 ]
};

(:
  создает папки рекурсивно
:)
declare
  %public
function
bitrix.disk:addFolderRecursive( 
    $folderName as xs:string,
    $rootFolderID as xs:string
){
  let $t := tokenize( $folderName, '/' )
  let $i := bitrix.disk:getFolderID( $t[ 1 ], $rootFolderID )
  let $folderID :=
    if( $i = '0' )
    then(
      bitrix.disk:addFolder( $t[ 1 ], $rootFolderID )
      /response/result/ID/text()
    )
    else( $i )
  return
    if( count( $t ) > 1 )
    then(
      bitrix.disk:addFolderRecursive(
        substring-after( $folderName, '/' ), $folderID
      )
    )
    else(
      $folderID
    )
};