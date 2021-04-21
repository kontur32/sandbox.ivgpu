module namespace ivgpu = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/проверкаНаличияРПД';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../config.xqm';
  
import module namespace 
  rpd.upload = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/загрузкаРПД'
  at 'generate.RPD.upload.xqm';

import module  namespace
  rpd.generate = '/sandbox/ivgpu/api/v01/generate/РПД.Титул' 
    at 'generate.RPD.titul.xqm';  

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
    at '../../generate.doc/generate.data.xqm';

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
  let $кодФормы :=
    if( tokenize( $fileName, '_' )[ 1 ] = 'o' )then( '^[o|о]')else( '^[z|з]' )
  let $fileNamePattern :=
    $кодФормы || '.*' || tokenize( $fileName, '_')[ 5 ] || '.*'
  
  return
    <items>
      { $folderItemsList[ matches( NAME/text(),  $fileNamePattern ) ][ 1 ] }
      <folderName>{ $folderName }</folderName>
      <targetFolderID>{ $targetFolderID }</targetFolderID>
      <fileName>{ $fileName }</fileName>
    </items>   
};

declare 
function ivgpu:check.Folder( $ID ){
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
  
  let $дисциплины := 
      data:getProgrammData()[ Файл/@ID/data() = $ID ]//Дисциплины/Дисциплина
  
  let $списокФайлов :=
    for $i in $дисциплины
    let $fileName := 
      replace(
        rpd.generate:buildOutputFile( $ID, $i/@КодДисциплины/data(), $форматФайла ),
        ':', '_'
      )
      
    let $кодФормы :=
      if( tokenize( $fileName, '_' )[ 1 ] = 'o' )then( '^[o|о]')else( '^[v|в|z|з]' )
    let $fileNamePattern :=
      $кодФормы || '.*' ||tokenize( $fileName, '_')[ 5 ] || '.*'
    where $folderItemsList[ matches( NAME/text() ,  $fileNamePattern ) ]
    return
      <item>
        <кодДисциплины>{ $i/@КодДисциплины/data() }</кодДисциплины>
        { $folderItemsList[ matches( NAME/text(),  $fileNamePattern ) ][ 1 ] }
        <folderName>{ $folderName }</folderName>
        <targetFolderID>{ $targetFolderID }</targetFolderID>
        <fileName>{ $fileName }</fileName>
      </item>
   return
     <items>{ $списокФайлов }</items>
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