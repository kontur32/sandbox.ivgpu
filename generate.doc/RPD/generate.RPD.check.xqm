module namespace ivgpu = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/проверкаНаличияРПД';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../config.xqm';
  
import module namespace 
  rpd.upload = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/загрузкаРПД'
  at 'generate.RPD.upload.xqm';

import module  namespace
  rpd.generate = '/sandbox/ivgpu/api/v01/generate/РПД.Титул' 
    at 'generate.RPD.titul.xqm';  

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/generate/РПД.Титул/{ $ID }/{ $кодДисциплины }/check' )
  %rest:method( 'GET' )
function ivgpu:check( $ID, $кодДисциплины ){
  let $индентификаторКорневойПапки := config:param( 'upload.Directory.Root' )
  let $folderName := rpd.upload:folderName( $ID )
  let $targetFolderID := rpd.upload:getFolderID( $индентификаторКорневойПапки, $folderName )
  
  let $folderItemsList := 
    if( number( $targetFolderID ) != 0 )
    then(
      ivgpu:getFolderList( $targetFolderID, '0' )//item
      )
    else( <error>целевая папка не найдена</error> )
  
  let $форматФайла := ''
  
  let $fileName := 
    rpd.generate:buildOutputFile( $ID, $кодДисциплины, $форматФайла )
  
  return
    <items>
      { $folderItemsList[ starts-with( NAME/text(), $fileName ) ][ 1 ] }
      <folderName>{ $folderName }</folderName>
      <targetFolderID>{ $targetFolderID }</targetFolderID>
      <fileName>{ $fileName }</fileName>
    </items>   
};

declare function ivgpu:getFolderList( $folderID, $start ){
  let $list := 
     fetch:xml(
       web:create-url(
         'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren.xml',
         map{
           'id' : $folderID,
           'start' : $start
         }
       )
     )
 let $next := $list/response/next/text()
 return
    if( $next )
    then( $list, ivgpu:getFolderList( $folderID, $next ) )
    else( $list )
};