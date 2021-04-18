module namespace ivgpu = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/проверкаНаличияРПД';

import module namespace 
  rpd.upload = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/загрузкаРПД'
  at 'generate.RPD.upload.xqm';
import module  namespace
  rpd.generate = '/sandbox/ivgpu/api/v01/generate/РПД.Титул' 
  at 'generate.RPD.titul.xqm';  

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/generate/РПД.Титул/{ $ID }/{ $кодДисциплины }/check' )
  %rest:method( 'GET' )
function ivgpu:компетенции( $ID, $кодДисциплины ){
  let $индентификаторКорневойПапки := '352499'
  let $folderName := rpd.upload:folderName( $ID )
  let $targetFolderID := rpd.upload:getFolderID( $индентификаторКорневойПапки, $folderName )
  
  let $folderItemsList := 
    if( number( $targetFolderID ) != 0 )
    then(
        fetch:xml(
          'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren.xml?id=' 
          || $targetFolderID
      )/response/result/item
    )
    else( <error>целевая папка не найдена</error> )
  
  let $форматФайла := ''
  let $fileName := 
    rpd.generate:buildOutputFile( $ID, $кодДисциплины, $форматФайла )
  
  return
    <items>
      { $folderItemsList[ starts-with( NAME/text(), $fileName ) ][ 1 ] }
    </items>
    
};