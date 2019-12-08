module namespace ivgpu = '/sandbox/ivgpu/v0.2/subjects.Department.Direction';

import module namespace request = 'http://exquery.org/ns/request';

import module namespace 
  rup = 'subjects.Department.Direction' 
    at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';
import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.doc/generate.data.xqm';



declare variable 
  $ivgpu:endPoint := '/sandbox/ivgpu/subjects.Department.Direction';

declare 
  %rest:path( '/sandbox/ivgpu/subjects.Department.Direction' )
  %rest:query-param( 'id', '{ $id }', '21' )
  %rest:query-param( 'year', '{ $year }', '2019' )
  %rest:query-param( 'mode', '{ $mode }', 'other' )
  %output:method( 'xhtml' )
function ivgpu:main( $id, $year, $mode ){

let $ПрограммыВсего := 
  data:getProgrammData()[ @Год = $year ]

let $Программы := 
  $ПрограммыВсего
    [ Дисциплины/Дисциплина[ @КодКафедры = $id ]  ]
    [ if( $mode = 'other' )then( ./@Кафедра != $id )else( true() ) ]

let $fileContentList :=
    rup:getFileContentList( '46686' )/NAME/substring-before( text(), '_' )

let $ДисциплиныКафедры := $Программы/Дисциплины/Дисциплина[ @КодКафедры = $id ]

let $КоличествоДисциплин := 
  count( $ДисциплиныКафедры )
  
let $КоличествоДисциплинКонтент := 
  count( $ДисциплиныКафедры[ @Название = $fileContentList ] )

let $КодыКафедр := 
  distinct-values( $ПрограммыВсего/Дисциплины/Дисциплина/@КодКафедры/data() )

let $КодыНаправлений := distinct-values( $Программы/@КодНаправления )

let $result := 
    for $КодНаправления in $КодыНаправлений
    order by $КодНаправления
    return
      <div>
         <ul>
          <li><b>{ $КодНаправления } Программы:</b>
            <ul>
              {
                 for $План in $Программы[ @КодНаправления = $КодНаправления ]
                 return
                 <li>
                   <i>
                     { $План/@НазваниеПрофиля/data() } ({ $План/@Год/data() })
                   </i>:
                   <ol>
                     {
                       for $i in $План/Дисциплины/Дисциплина[ @КодКафедры = $id ]
                       let $href := 
                         "/sandbox/ivgpu/generate/Аннотация/" || 
                         $План/Файл/@ID || "/" || $i/@КодДисциплины
                       let $discName := normalize-space( $i/@Название )
                       let $mark := if( $discName = $fileContentList )then( <span style = 'color : green;'>&#9679;</span> )else( <span style = 'color : red;'>&#9679;</span> )
                       return
                         <li>
                           { $mark }{ $discName } ({ $i/@КодДисциплины/data()}) (<a href = '{ $href }'>Аннотация</a>)
                           </li>
                     }
                   </ol>
                 </li>
              }
            </ul>{   
           }</li>
        </ul>  
      </div>
let $ПроцентВыполнения := 
  if(  $КоличествоДисциплин > 0 )
  then(
    round( $КоличествоДисциплинКонтент div $КоличествоДисциплин * 100 )
  )
  else( '-' )
  
return
  <div>
    <p>Годы: {
      for $i in ( 2016 to 2019 )
      let $href := 
        web:create-url(
          request:path(),
          map{
            'id' : $id,
            'year' : $i,
            'mode' : $mode
          }
        )
      return
        <a href = '{ $href }'>{ $i }</a>
    }</p>
    <p>Кафедры (коды): {
      for $i in $КодыКафедр
      order by number( $i )
      let $href := 
        web:create-url(
          request:path(),
          map{
            'id' : $i,
            'year' : $year,
            'mode' : $mode
          }
        )
      return
        <a href = '{ $href }'>{ $i }</a>
    }</p>
    <p>(<a href = 'https://portal.ivgpu.com/~k35kp'>подсказка по кодам</a>)</p>
    <p><b>Аннотации по дисцилинам кафедры "{$id}" за { $year } год</b></p>
    <p>
      Всего дисциплин: { $КоличествоДисциплин } (из уникальных: { count( distinct-values( $ДисциплиныКафедры/@Название/data() ) ) })
      (из них готовы { $ПроцентВыполнения } %)
    </p>
    {
      $result
    }
  </div>
};