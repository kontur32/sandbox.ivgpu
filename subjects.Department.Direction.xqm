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
  %rest:query-param( 'subj', '{ $subj }' )
  %rest:query-param( 'fgos', '{ $fgos }' )
  %output:method( 'xhtml' )
function ivgpu:main( $id, $year, $mode, $subj, $fgos ){

let $ПрограммыВсего := 
  data:getProgrammData()
    [ @Год = $year ]
    [ if( $fgos )then( @ФГОС = $fgos )else( true() ) ]
    
let $Программы := 
  $ПрограммыВсего
    [ Дисциплины/Дисциплина[ @КодКафедры = $id ]  ]
    [ if( $mode = 'other' )
      then( ./@Кафедра != $id )
      else(
        if( $mode = 'own' )then( ./@Кафедра = $id )else( true() )
      )
    ]
    

let $fileContentList :=
    rup:getFileContentList( '46686' )/NAME/ normalize-space( substring-before( text(), '_' ) )

let $ДисциплиныКафедры := 
  $Программы/Дисциплины/Дисциплина
    [ @КодКафедры = $id ]
    [ if( $subj )then( @Название = $subj )else( true() ) ]

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
                 let $fileName := tokenize( $План/Файл/@DETAIL__URL/data(),'/' )[last()]
                 return
                 <li>
                   <i>
                     { $План/@НазваниеПрофиля/data() } ({ $План/@Год/data() })
                     (<a href = '{ $План/Файл/@DETAIL__URL/data() }'>{ $fileName }</a>)
                   </i>:
                   <ol>
                     {
                       for $i in $План/Дисциплины/Дисциплина[ @КодКафедры = $id ]
                       
                       where if( $subj )then( $i/@Название = $subj )else( true() )
                       let $hrefA := 
                         "/sandbox/ivgpu/generate/Аннотация/" || 
                         $План/Файл/@ID || "/" || $i/@КодДисциплины
                       let $hrefT := 
                         "/sandbox/ivgpu/generate/РПД.Титул/" || 
                         $План/Файл/@ID || "/" || $i/@КодДисциплины
                       let $hrefPDF := $hrefA || '/pdf'
                       let $discName := normalize-space( $i/@Название )
                       let $mark := if( $discName = $fileContentList )then( <span style = 'color : green;'>&#9679;</span> )else( <span style = 'color : red;'>&#9679;</span> )
                      
                       order by $i/@Название/data()
                       order by $mark/@style/data() descending
                       return
                         <li>
                           { $mark }{ $discName } ({ $i/@КодДисциплины/data()}) 
                           (Скачать: аннотацию <a href = '{ $hrefA }'>docx</a>|<a href = '{ $hrefPDF }'>pdf</a>{if( $year = '2019' )then( <span>, титул РПД </span>,<a href = '{ $hrefT }'>docx</a> )else() } )
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

let $body := 
  <div>
    <hr/>
    <p>По ООП: 
      {
        for $m in ( ['own', '"Свои"'], ['other', '"Чужие"'], ['full', 'Все'] )
        let $href := 
          web:create-url(
            request:path(),
            map{
              'id' : $id,
              'year' : $year,
              'mode' : $m?1,
              'fgos' : $fgos
            }
          )
        return 
          <a href = '{ $href }'>{ $m?2 }</a> 
      }
       
           / По ФГОС: 
           {
            for $f in ( ['3P', '3+'], ['3PP', '3++'], ['', 'Все'] )
            let $href := 
              web:create-url(
                request:path(),
                map{
                  'id' : $id,
                  'year' : $year,
                  'mode' : $mode,
                  'fgos' : $f?1
                }
              )
            return 
              <a href = '{ $href }'>{ $f?2 }</a> 
       }
    / По годy: 
    {
      for $i in ( 2015 to 2019 )
      let $href := 
        web:create-url(
          request:path(),
          map{
            'id' : $id,
            'year' : $i,
            'mode' : $mode,
            'fgos' : $fgos
          }
        )
      return
        <a href = '{ $href }'>{ $i }</a>
    }<br/>По кафедре: {
      for $i in $КодыКафедр
      order by number( $i )
      let $href := 
        web:create-url(
          request:path(),
          map{
            'id' : $i,
            'year' : $year,
            'mode' : $mode,
            'fgos' : $fgos
          }
        )
      return
        <a href = '{ $href }'>{ $i }</a>
    } (<a href = 'https://portal.ivgpu.com/~k35kp'>подсказка по кодам</a>)
    </p>
    <hr/>
    <table>
      <tr>
        <td>
          <h3>
            Аннотации по дисцилинам кафедры "{ $id }" за { $year } год 
            { if( $fgos )then( if( $fgos = '3P' )then( ' по ФГОС 3+' )else( ' по ФГОС 3++' ) )else() }
          </h3>
          <p>
            Всего дисциплин: { $КоличествоДисциплин } (из уникальных: { count( distinct-values( $ДисциплиныКафедры/@Название/data() ) ) })
            (из них готовы <span id = 'ready'>{ $ПроцентВыполнения }</span> %)
          </p>
        </td>
        <td>
          <div>
            <div id="chart_div" style="width: 500px; height: 150px;"></div>
          </div>
        </td>
      </tr>
    </table>
    
    {
      $result
    }
  </div>
  let $tpl := doc( "html/main.tpl.html" )
  return
    $tpl update insert node $body into .//body
};