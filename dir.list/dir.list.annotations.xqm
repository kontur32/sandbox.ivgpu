module namespace ivgpu = 'oop.List';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../generate.doc/config.xqm';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at '../generate.doc/generate.data.xqm';

import module namespace 
  rup = 'subjects.Department.Direction' 
    at '../tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}/{$ID}/annot' )
  %output:method( 'xhtml' )
function ivgpu:аннотации( $year, $dir, $ID ){
  let $fileContentList := 
    rup:getFileContentList( '46686' )
    /NAME/
    replace( normalize-space( substring-before( text(), '_' ) ), ':', '_' )

  let $План := data:getProgrammData( $ID )

  let $дисциплины := $План/Дисциплины/Дисциплина

  let $таблица :=
    <table>
       <tr class = "text-center">
          <th>Код</th>
          <th width = "60%">Название</th>
          <th>Кафедра</th>
          <th>ЗЕТ</th>
          <th>Аннотация</th>
       </tr>
      {
        for $i in $дисциплины 
        count $c
        let $естьКонтент := 
          replace(
            $i/@Название/data() , ( ':' ), ( '_' )
          ) = $fileContentList
        
        let $hrefA := 
         "/sandbox/ivgpu/generate/Аннотация/" || 
         $План/Файл/@ID || "/" || $i/@КодДисциплины || "/pdf"
         
        let $маркер :=
          if( $естьКонтент )
          then( <span style = 'color : green;'>&#9679;</span> )
          else( <span style = 'color : red;'>&#9679;</span> )

        return
           <tr>
              <td style = "width: 150px;">{ $маркер } ({ $c }) { $i/@КодДисциплины/data() }</td>
              <td>{ $i/@Название/data() }</td>
              <td align="center">{ $i/@КодКафедры/data() }</td>
              <td align="center">{ $i/@ЗЕТ/data() }</td>
              <td align="center">{
                 if( $естьКонтент )
                 then(
                      <a href = "{ $hrefA }" class = "btn btn-success" style = "width: 100px;">скачать</a>
                    )
                 else()
              }
              </td>
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