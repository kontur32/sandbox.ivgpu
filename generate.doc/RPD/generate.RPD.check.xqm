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

import module namespace cache = '/sandbox/ivgpu/api/v01/generate/rpd/cache'
  at '../lib/getResource.cache.xqm';
  
declare 
  %rest:path( '/sandbox/ivgpu/api/v01/generate/РПД.Титул/{ $ID }/{ $кодДисциплины }/check/{ $storeID }' )
  %rest:method( 'GET' )
function ivgpu:check-api( $ID as xs:string, $кодДисциплины as xs:string, $storeID as xs:string ){
  let $программа :=  data:getProgrammData( $ID )
  return
    ivgpu:check( $программа, $кодДисциплины, $storeID )
};


declare 
function ivgpu:check( $программа as element( Программа ), $кодДисциплины as xs:string ){
  let $индентификаторКорневойПапки := config:param( 'upload.Directory.Root' )
  return
    ivgpu:check( $программа, $кодДисциплины, $индентификаторКорневойПапки )
};

declare 
function ivgpu:check(
    $программа as element( Программа ),
    $кодДисциплины as xs:string,
    $индентификаторКорневойПапки as xs:string
){
  ivgpu:check(
    $программа,
    $кодДисциплины,
    $индентификаторКорневойПапки,
    map{}
)
};

declare 
function ivgpu:check(
    $программа as element( Программа ),
    $кодДисциплины as xs:string,
    $индентификаторКорневойПапки as xs:string,
    $params as map(*)
){
  let $ID := $программа/Файл/@ID/data()
  let $targetFolderID :=
    cache:getFolderID( $индентификаторКорневойПапки, $ID, $params )
  
  let $folderItemsList := 
    if( $targetFolderID != '0' )
    then( ivgpu:getFolderList( $targetFolderID, '0' )//item )
    else( <error>целевая папка не найдена</error> )
  
  let $форматФайла := ''
  let $дисциплина :=
    $программа
    //Дисциплины/Дисциплина[ @КодДисциплины/data() = $кодДисциплины ]
  
  let $fileName := 
    ivgpu:buildOutputFile( $программа, $дисциплина, $форматФайла )
  let $кодФормы :=
      switch ( tokenize( $fileName, '_' )[ 1 ] )
      case 'o' return '[o|о]'
      case 'v' return '[v|в]'
      case 'z' return '[z|з]'
      default return '[o|о]'
      
  return
    <items>
      <кодДисциплины>{ $кодДисциплины }</кодДисциплины>
      {
        $folderItemsList[
          matches(
            NAME/text(),
            ivgpu:pattern( NAME/text(),
            tokenize( $fileName, '_')[ 5 ], $кодФормы )
          )
        ][ 1 ]
      }
      <targetFolderID>{ $targetFolderID }</targetFolderID>
      <fileName>{ $fileName }</fileName>
    </items>   
};

declare 
function ivgpu:check.Folder( $программа as element( Программа ) ){
  let $индентификаторКорневойПапки := config:param( 'upload.Directory.Root' )
  return
    ivgpu:check.Folder( $программа, $индентификаторКорневойПапки )
};

declare 
function ivgpu:check.Folder( $программа as element( Программа ), $индентификаторКорневойПапки as xs:string ){
  let $ID := $программа/Файл/@ID/data()
  let $folderName := rpd.upload:folderName( $ID )
  let $targetFolderID := rpd.upload:getFolderID( $индентификаторКорневойПапки, $folderName )
  
  let $folderItemsList := 
    if( number( $targetFolderID ) != 0 )
    then(
      ivgpu:getFolderList( $targetFolderID, '0' )//item
      )
    else( <error>целевая папка не найдена</error> )
  
  let $форматФайла := ''
  let $дисциплины := $программа/Дисциплины/Дисциплина
  
  let $списокФайлов :=
    for $i in $дисциплины
    let $fileName := 
      replace(
        ivgpu:buildOutputFile( $программа, $i, $форматФайла ),
        ':', '_'
      )
      
    let $кодФормы :=
      switch ( tokenize( $fileName, '_' )[ 1 ] )
      case 'o' return '[o|о]'
      case 'v' return '[v|в]'
      case 'z' return '[z|з]'
      default return '[o|о]'

    where $folderItemsList[ matches( NAME/text(),  ivgpu:pattern( NAME/text(), tokenize( $fileName, '_')[ 5 ], $кодФормы ) ) ]
    return
      <item>
        <кодДисциплины>{ $i/@КодДисциплины/data() }</кодДисциплины>
        { $folderItemsList[ matches( NAME/text(),  ivgpu:pattern( NAME/text(), tokenize( $fileName, '_')[ 5 ], $кодФормы ) ) ][ 1 ] }
        <folderName>{ $folderName }</folderName>
        <targetFolderID>{ $targetFolderID }</targetFolderID>
        <fileName>{ $fileName }</fileName>
      </item>
   return
     <items>{ $списокФайлов }</items>
};

declare function ivgpu:pattern( $fname as xs:string*, $discName as xs:string , $маскаФормы as xs:string ) as xs:string {
  if( matches( $fname, '^[0-9]{2}' ) )
  then(
    '^[0-9]{2}_.{2}_' || $discName || '_' || $маскаФормы 
  )
  else(
    '^' || $маскаФормы || '_[0-9]{6}_.*_' || $discName || '[_|\.]'
  )
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
    replace( normalize-space( $Дисциплина/@Название/data() ), ':', '.' ) || 
    $format
  return
    replace( $fileName, '["|№|(|)]', '' )
};