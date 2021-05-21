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
      
declare 
  %rest:path( '/sandbox/ivgpu/directions' )
  %rest:query-param( 'year', '{ $yearsList }' )
  %rest:query-param( 'dep', '{ $dep }' )
  %output:method( 'xhtml' )
function ivgpu:view( $yearsList, $dep ){
  let $b := 
    data:getProgrammData()
    [ if( $dep )then( @Кафедра = tokenize( $dep, ',' ) )else( true() ) ]
  
  let $years := 
    if( $yearsList )
    then(
      tokenize( $yearsList, ',' )
    )
    else(
      distinct-values( $b/@Год/data() )[. != '' ]
    )
    
  let $list :=
    function( $year ){
    let $oop := $b[ @Год = $year ]
    let $oopKod := distinct-values( $oop/@КодНаправления/data() )
    for $i in $oopKod
    where $i
    order by $i
    let $dep := sort( distinct-values( $oop[@КодНаправления = $i ]/@Кафедра/number( . ) ) )
    
    return
      <li>{ $i } : <a href = '{ "/sandbox/ivgpu/directions/" || $i }'>{ normalize-space( $oop[@КодНаправления = $i ][1]/@НазваниеНаправления/data() ) }</a>; кафедра(ы): { string-join( $dep, ', ' ) }</li>
    }
  return
   <html>
     <body>
       <h2>Направления подготовки за { string-join( sort( $years ), ', ') } год(ы)</h2>
       {
         for $y in $years
         order by number( $y )
         return
           <ol><h3>{ $y }</h3>{ $list( $y ) }</ol>
       }
     </body>
   </html>
};

declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}' )
  %output:method( 'csv' )
  %output:csv ("header=yes, separator=semicolon")
function ivgpu:dir( $year){
  let $b := 
    data:getProgrammData()[ @Год/data() = $year ]

return
  <csv>
    {
      for $i in distinct-values( $b /@КодНаправления/data() )
      order by $i
      return
         <record>
            <Код>{$i}</Код>
            <НазваниеНаправления>{ $b[ @КодНаправления = $i ][1]/@НазваниеНаправления/data()}</НазваниеНаправления>
         </record>
    }
  </csv>  

};

declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}' )
  %output:csv ("header=yes, separator=semicolon")
  %output:method( 'csv' )
function ivgpu:oop( $year, $dir ){
  let $b := 

      data:getProgrammData()
      [ @Год/data() = $year ]
      [ @КодНаправления/data() = $dir ]
      

return
  <csv>
    {
      for $i in $b
      return
         <record>
            <НазваниеПрофиля>{$i/@НазваниеПрофиля/data()}</НазваниеПрофиля>
            <ФормаОбучения>{$i/@ФормаОбучения/data() }</ФормаОбучения>
            <ID>{$i/Файл/@ID/data() }</ID>
         </record>
    }
  </csv>  
};

declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}/{$oop}/{$form}' )
  %output:method( 'csv' )
  %output:csv ("header=yes, separator=semicolon")
function ivgpu:disc( $year, $dir, $oop, $form ){
  let $b := 
      data:getProgrammData()
      [ @Год/data() = $year ]
      [ @КодНаправления/data() = $dir ]
      [ @НазваниеПрофиля/data() = $oop ]
      [ @ФормаОбучения/data() = $form ]
      //Дисциплина

return
  <csv>
    {
      for $i in $b
      return
         <record>
            <КодДисциплины>{$i/@КодДисциплины/data() }</КодДисциплины>
            <НазваниеДисциплины>{ $i/@Название/data() }</НазваниеДисциплины>
            <КодКафедры>{$i/@КодКафедры/data() }</КодКафедры>
            <ЗЕТ>{$i/@ЗЕТ/data() }</ЗЕТ>
         </record>
    }
  </csv>  
};

declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}/{$ID}/аннотации' )
  %output:method( 'xhtml' )
function ivgpu:аннотации( $year, $dir, $ID ){
  let $fileContentList := 
    rup:getFileContentList( '46686' )
    /NAME/
    replace( normalize-space( substring-before( text(), '_' ) ), ':', '_' )

  let $План := data:getProgrammData()[ Файл/@ID/data() = $ID ]

  let $дисциплины := $План/Дисциплины/Дисциплина
          
  let $check :=
    check:check.Folder( $План, config:param( 'upload.Directory.Root' ) )//item
  let $checkSecondary := 
    check:check.Folder( $План, config:param( 'upload.Directory.Secondary' ) )//item
  
  let $таблица :=
    <table>
       <tr class = "text-center">
          <th>Код</th>
          <th width = "60%">Название</th>
          <th>Кафедра</th>
          <th>ЗЕТ</th>
          <th>Аннотация</th>
          <th>РПД в Simplex</th>
          <th>РПД в УМУ</th>
       </tr>
      {
        for $i in $дисциплины
        let $естьКонтент := 
          replace(
            $i/@Название/data() , ( ':' ), ( '_' )
          ) = $fileContentList
        
        let $hrefA := 
         "/sandbox/ivgpu/generate/Аннотация/" || 
         $План/Файл/@ID || "/" || $i/@КодДисциплины || "/pdf"

        let $exist := $check[ кодДисциплины/text() = $i/@КодДисциплины/data() ]
        let $existSecondary := $checkSecondary[ кодДисциплины/text() = $i/@КодДисциплины/data() ]
        
        let $маркер :=
          if( $exist or $existSecondary )
          then( <span style = 'color : green;'>&#9679;</span> )
          else( <span style = 'color : red;'>&#9679;</span> )

        return
           <tr>
              <td>{ $маркер }{ $i/@КодДисциплины/data() }</td>
              <td>{ $i/@Название/data() }</td>
              <td align="center">{ $i/@КодКафедры/data() }</td>
              <td align="center">{ $i/@ЗЕТ/data() }</td>
              <td align="center">{
                 if( $естьКонтент )
                 then(
                      <a href = "{ $hrefA }">
                        <i class="bi-download" style="font-size: 1.5rem; color: #17a2b8;"/>
                      </a>
                    )
                 else()
              }</td>
               <td align="center">{
                 if( $exist )
                     then(
                        <a href = "{ $exist/item/DOWNLOAD_URL/text() }" style = "width: 100px;">
                          скачать
                        </a>
                     )
                     else(
                       let $hrefUpload := 
                         '/sandbox/ivgpu/api/v01/programms/' || 
                         $План/Файл/@ID/data() || '/' || 
                         web:encode-url( $i/@КодДисциплины ) || '/comp'
                       return
                         <a class = "btn btn-warning" href = '{ $hrefUpload }' style = "width: 100px;">загрузить</a>
                     )
               }</td>
               <td align="center">{
                 if( $existSecondary )
                     then(
                        <a href = "{ $existSecondary/item/DOWNLOAD_URL/text() }" class = "btn btn-success" style = "width: 100px;">
                          скачать
                        </a>
                     )
                     else(
                       let $hrefUpload := 
                         '/sandbox/ivgpu/api/v01/programms/' || 
                         $План/Файл/@ID/data() || '/' || 
                         web:encode-url( $i/@КодДисциплины ) || '/comp'
                       return
                         <a class = "btn btn-warning" href = '{ $hrefUpload }' style = "width: 100px;">загрузить</a>
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
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}/{$oop}/{$form}/{$disc}' )
  %output:method( 'csv' )
  %output:csv ("header=yes, separator=semicolon")
function ivgpu:control( $year, $dir, $oop, $form, $disc ){
  let $b := 
      data:getProgrammData()
      [ @Год/data() = $year ]
      [ @КодНаправления/data() = $dir ]
      [ @НазваниеПрофиля/data() = $oop ]
      [ @ФормаОбучения/data() = $form ]
      //Дисциплина[ @КодДисциплины/data() = $disc ]
      
let $sem := tokenize( $b/@Семестр/data(), ',' )
let $control := tokenize( $b/@ФормыКонтроля/data(), ',' )
return
  <csv>
    {
      for $i in 1 to count( $sem )
      return
         <record>
            <Семестр>{ $sem[$i] }</Семестр>
            <ФормыКонтроля>{ $control[$i] }</ФормыКонтроля>
         </record>
    }
  </csv>  
};

(: старый вариант - на удаление :)
declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}/{$oop}/{$form}/{$disc}/comp' )
function ivgpu:компетенции( $year, $dir, $oop, $form, $disc ){
  let $дисциплина := 
      data:getProgrammData()
      [ @Год/data() = $year ]
      [ @КодНаправления/data() = $dir ]
      [ @НазваниеПрофиля/data() = $oop ]
      [ @ФормаОбучения/data() = $form ][ 1 ]
      //Дисциплина[ @КодДисциплины/data() = $disc ]
  
  let $видыРабот := 
    for $i in $дисциплина/видыРабот/видРабот
    let $семестр := $i/семестр/text()
    group by $семестр
    return
      <видыРабот семестр = "{ $семестр }">
        {
        for $j in $i
        where $j/кодВидаРабот/text() = ( '101', '102', '103', '104', '105', '107','108', '109', '141', '1000')
        return 
            $j/названиеВидаРабота/text() || ':' || $j/часы/text()
        }
      </видыРабот>
  return
     <Дисциплина>
       { $дисциплина/@Название }
       { $дисциплина/@КодДисциплины }
       { $дисциплина/@ФормыКонтроля }
       { $дисциплина/Компетенции }
       { $видыРабот }
     </Дисциплина>
};