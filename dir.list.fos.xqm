module namespace ivgpu = 'oop.List';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at 'generate.doc/config.xqm';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.doc/generate.data.xqm';

import module namespace 
  rup = 'subjects.Department.Direction' 
    at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

import module namespace 
  check = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/проверкаНаличияРПД'
    at 'generate.doc/RPD/generate.RPD.check.xqm'; 

import module namespace 
  rpd.upload = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/загрузкаРПД'
  at 'generate.doc/RPD/generate.RPD.upload.xqm';
      
declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}/{$ID}/ФОС' )
  %output:method( 'xhtml' )
function ivgpu:аннотации( $year, $dir, $ID ){

  let $План := data:getProgrammData( $ID )

  let $дисциплины := $План/Дисциплины/Дисциплина
          
  let $check :=
    ivgpu:check.Folder( $План, config:param( 'upload.Directory.Root' ) )/item
  let $checkSecondary := 
    ivgpu:check.Folder( $План, config:param( 'upload.Directory.Secondary' ) )/item
  
  let $таблица :=
    <table>
       <tr class = "text-center">
          <th>Код</th>
          <th width = "60%">Название</th>
          <th>Кафедра</th>
          <th>ФОС в Simplex ({ count( $check ) }/{ count( $дисциплины )})</th>
          <th>ФОС в УМУ ({ count( $checkSecondary ) }/{ count( $дисциплины )})</th>
       </tr>
      {
        for $i in $дисциплины
        let $exist :=
          $check[ кодДисциплины/text() = $i/@КодДисциплины/data() ]
        let $existSecondary :=
          $checkSecondary[ кодДисциплины/text() = $i/@КодДисциплины/data() ]
        
        let $маркер :=
          if( $exist or $existSecondary )
          then( <span style = 'color : green;'>&#9679;</span> )
          else( <span style = 'color : red;'>&#9679;</span> )

        return
           <tr>
              <td>{ $маркер }{ $i/@КодДисциплины/data() }</td>
              <td>{ $i/@Название/data() }</td>
              <td align="center">{ $i/@КодКафедры/data() }</td>
              <td align="center">{
                 if( $exist )
                     then(
                        <a href = "{ $exist/item/DOWNLOAD_URL/text() }" class = "btn btn-success" style = "width: 130px;">
                          скачать
                        </a>
                     )
                     else(
                       <a class = "btn btn-warning" href = '#' style = "width: 130px;">не загружен</a>
                     )
               }</td>
               <td align="center">{
                 if( $existSecondary )
                     then(
                        <a href = "{ $existSecondary/item/DOWNLOAD_URL/text() }" class = "btn btn-success" style = "width: 130px;">
                          скачать
                        </a>
                     )
                     else(
                         <a class = "btn btn-warning" href = '#' style = "width: 130px;">не загружен</a>
                     )
               }</td>
           </tr>
      }
    </table>
  let $содержание := 
    <div class = "mb-4">
      <table>
        <tr>
          <th align="left">Код направления</th>
          <td>{$dir}</td>
        </tr >
        <tr>
          <th align="left">Название направления</th>
          <td>{$План/@НазваниеНаправления/data()}</td>
        </tr>
        <tr>
          <th align="left">Название ООП</th>
          <td>{$План/@НазваниеПрофиля/data()}</td>
        </tr>
        <tr>
          <th align="left">Форма обучения</th>
          <td>{ $План/@ФормаОбучения/data() }</td>
        </tr>
        <tr>
          <th align="left">Год приема</th>
          <td>{$year}</td>
        </tr>
        <tr>
          <th align="left">Выпускающая кафедра</th>
          <td>{ $План/@Кафедра/data() }</td>
        </tr>
      </table>
      <div class = "mt-2">{
        $таблица
      }</div>
      
    </div>
  return
    let $tpl := doc( "html/main.tpl.html" )
  return
    $tpl update insert node $содержание into .//body
};

declare 
function ivgpu:check.Folder( $программа as element( Программа ), $индентификаторКорневойПапки as xs:string ){
  let $ID := $программа/Файл/@ID/data()
  let $folderName := rpd.upload:folderName( $ID, 'ФОС' )
  let $targetFolderID := rpd.upload:getFolderID( $индентификаторКорневойПапки, $folderName )
  
  let $folderItemsList := 
    if( number( $targetFolderID ) != 0 )
    then( check:getFolderList( $targetFolderID, '0' )//item )
    else( <error>целевая папка не найдена</error> )
  
  let $форматФайла := ''
  let $дисциплины := $программа/Дисциплины/Дисциплина
  let $кодФормы :=
      switch ( $программа/@ФормаОбучения/data() )
      case 'очная' return '[o|о]'
      case 'очно-заочная' return '[v|в]'
      case 'заочная' return '[z|з]'
      default return '[o|о]'
  
  let $списокФайлов :=
    for $i in $дисциплины
    let $item :=
      $folderItemsList
      [ matches( tokenize( NAME/text(), '_' )[ 1 ], $кодФормы ) ]
      [ matches( tokenize( NAME/text(), '_' )[ 4 ], $i/@Название/data() ) ][ 1 ]
    where $item
    return
      <item>
        <кодДисциплины>{ $i/@КодДисциплины/data() }</кодДисциплины>
        { $item }
        <folderName>{ $folderName }</folderName>
        <targetFolderID>{ $targetFolderID }</targetFolderID>
        <fileName>{ $i/@Название/data() }</fileName>
      </item>
   return
     <items>{ $списокФайлов }</items>
};