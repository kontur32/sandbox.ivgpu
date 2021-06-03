module namespace ivgpu = 'oop.List';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../generate.doc/config.xqm';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at '../generate.doc/generate.data.xqm';

import module namespace 
  rup = 'subjects.Department.Direction' 
    at '../tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

import module namespace 
  check = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/проверкаНаличияРПД'
    at '../generate.doc/RPD/generate.RPD.check.xqm'; 

declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}/{$ID}/rpd' )
  %output:method( 'xhtml' )
function ivgpu:аннотации( $year, $dir, $ID ){
  let $План := data:getProgrammData( $ID )

  let $дисциплины := $План/Дисциплины/Дисциплина
          
  let $check :=
    check:check.Folder( $План, config:param( 'upload.Directory.Root' ) )/item
  let $checkSecondary := 
    check:check.Folder( $План, config:param( 'upload.Directory.Secondary' ) )/item
  
  let $таблица :=
    <table>
       <tr class = "text-center">
          <th>Код</th>
          <th width = "60%">Название</th>
          <th>Кафедра</th>
          <th>ЗЕТ</th>
          <th>РПД в Simplex ({ count( $check ) }/{ count( $дисциплины )})</th>
          <th>РПД в УМУ ({ count( $checkSecondary ) }/{ count( $дисциплины )})</th>
       </tr>
      {
        for $i in $дисциплины
        count $c
        let $exist := $check[ кодДисциплины/text() = $i/@КодДисциплины/data() ]
        let $existSecondary := $checkSecondary[ кодДисциплины/text() = $i/@КодДисциплины/data() ]
        
        let $маркер :=
          if( $exist )
          then( <span style = 'color : green;'>&#9679;</span> )
          else( <span style = 'color : red;'>&#9679;</span> )

        return
           <tr>
              <td style = "width: 150px;">{ $маркер } ({ $c }) { $i/@КодДисциплины/data() }</td>
              <td>{ $i/@Название/data() }</td>
              <td align="center">{ $i/@КодКафедры/data() }</td>
              <td align="center">{ $i/@ЗЕТ/data() }</td>
              <td align="center">{
                 if( $exist )
                     then(
                        <a href = "{ $exist/item/DOWNLOAD_URL/text() }" class = "btn btn-success" style = "width: 100px;">
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

  let $tpl := doc( "../html/main.tpl.html" )
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