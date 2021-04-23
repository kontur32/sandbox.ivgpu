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
function ivgpu:check-api( $ID as xs:string, $кодДисциплины as xs:string ){
  let $программа :=  data:getProgrammData()[ Файл/@ID = $ID ]
  return
    ivgpu:check( $программа, $кодДисциплины )
};

declare 
function ivgpu:check( $программа as element( Программа ), $кодДисциплины as xs:string ){
  let $ID := $программа/Файл/@ID/data()
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
  let $дисциплина :=
    $программа
    //Дисциплины/Дисциплина[ @КодДисциплины/data() = $кодДисциплины ]
  
  let $fileName := 
    ivgpu:buildOutputFile( $программа, $дисциплина, $форматФайла )
  let $кодФормы :=
    switch ( tokenize( $fileName, '_' )[ 1 ] )
    case 'o' return '^[o|о|0-9]{1,2}'
    case 'v' return '^[v|в]'
    case 'z' return '^[z|з]'
    default return '^[o|о|0-9]{1,2}'

  let $fileNamePattern :=
    $кодФормы || '.*' || tokenize( $fileName, '_')[ 5 ] || '[\.|_].*'
  
  return
    <items>
      <кодДисциплины>{ $кодДисциплины }</кодДисциплины>
      { $folderItemsList[ matches( NAME/text(),  $fileNamePattern ) ][ 1 ] }
      <folderName>{ $folderName }</folderName>
      <targetFolderID>{ $targetFolderID }</targetFolderID>
      <fileName>{ $fileName }</fileName>
    </items>   
};

declare 
function ivgpu:check.Folder( $программа as element( Программа ) ){
  let $ID := $программа/Файл/@ID/data()
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
  let $программа := data:getProgrammData()[ Файл/@ID/data() = $ID ]
  let $дисциплины := $программа//Дисциплины/Дисциплина
  
  let $списокФайлов :=
    for $i in $дисциплины
    let $fileName := 
      replace(
        ivgpu:buildOutputFile( $программа, $i, $форматФайла ),
        ':', '_'
      )
      
    let $кодФормы :=
      switch ( tokenize( $fileName, '_' )[ 1 ] )
      case 'o' return '^[o|о|0-9]{1,2}'
      case 'v' return '^[v|в]'
      case 'z' return '^[z|з]'
      default return '^[o|о|0-9]{1,2}'

    let $fileNamePattern :=
      $кодФормы || '.*' ||tokenize( $fileName, '_')[ 5 ] || '[\.|_].*'
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

declare function ivgpu:buildOutputFile( $Программа, $Дисциплина, $format ){
  
  let $АббревиатураПрограммы := 
    $Программа/@НазваниеПрофиля
    /upper-case(
      string-join(
        for-each(
          tokenize( . ), function( $result) { substring( $result[ . != 'и' ], 1, 1 ) }
        ) 
      ) 
    )
 let $формыОбучения := 
   map{
     'очная' : 'o',
     'заочная' : 'z',
     'очно-заочная' : 'v'
   }
 let $fileName := 
   map:get( $формыОбучения, $Программа/@ФормаОбучения/data() ) || '_' ||
    replace( $Программа/@КодНаправления, '\.', '' ) || '_' ||
    $АббревиатураПрограммы || '_' ||
    $Программа/@Год || '_' ||
    $Дисциплина/@Название || 
    $format
  return
    replace( $fileName, '["|№|(|)]', '' )
};