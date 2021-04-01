module namespace ivgpu = '/sandbox/ivgpu/v0.2/subjects.Department.Direction';

import module namespace request = 'http://exquery.org/ns/request';
import module namespace functx = "http://www.functx.com";

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
  %rest:query-param( 'annot', '{ $annot }', 'yes' )
  %output:method( 'xhtml' )
function ivgpu:main( $id, $year, $mode, $subj, $fgos, $annot ){

let $кафедры := 
    csv:parse(  
      fetch:text(
        'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=183523999&amp;single=true&amp;output=csv'
    ), map{ 'header' : true() } )/csv/record

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
    rup:getFileContentList( '46686' )
    /NAME/
    functx:replace-multi( normalize-space( substring-before( text(), '_' ) ), ':', '_' )

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
                 let $filePath := $План/Файл/@DETAIL__URL/data()
                 let $fileName := tokenize( $filePath,'/' )[last()]
                 let $xlsPath := replace( $filePath, '.plx', '.plx.xls' )
                 return
                 <li>
                   <i>
                     { $План/@НазваниеПрофиля/data() } ({ $План/@Год/data() }, {$План/@ФормаОбучения/data()})
                     (скачать РУП:<a href = '{ $filePath }'>"шахтинский"</a>, <a href = '{ $xlsPath }'>excel</a>)
                   </i>:
                   <ol>
                     {
                       for $i in $План/Дисциплины/Дисциплина[ @КодКафедры = $id ]
                       
                       where if( $subj )then( $i/@Название = $subj )else( true() )
                       let $hrefA := 
                         "/sandbox/ivgpu/generate/Аннотация/" || 
                         $План/Файл/@ID || "/" || $i/@КодДисциплины
                       (: старый РПД :)
                       let $hrefT := 
                         "/sandbox/ivgpu/generate/РПД.Титул/" || 
                         $План/Файл/@ID || "/" || $i/@КодДисциплины
                       (: новый РПД :)
                       let $hrefT := 
                         "/sandbox/ivgpu/api/v01/generate/РПД.Титул/" || 
                         $План/Файл/@ID || "/" || $i/@КодДисциплины
                       let $hrefT-dev := $hrefT || '?mode=dev'
                      
                       let $hrefPDFA := $hrefA || '/pdf'
                       let $hrefPDFT := $hrefT || '/pdf'
                       let $hrefшаблонСодержания := $hrefA || '/шаблон.содержания'
                       
                       let $hrefCompList :=
                         string-join(
                           (
                             '/sandbox/ivgpu/api/v01/programms',
                             $План/Файл/@ID/data(),
                             $i/@КодДисциплины/data(),
                             'comp'
                           ),
                           '/'
                         )
                       let $discName :=  normalize-space( $i/@Название )
                       let $естьКонтент := 
                         functx:replace-multi( $discName , ( ':', ',' ), ( '-', '.' ) ) = $fileContentList
                       let $mark :=
                         if( $естьКонтент )
                         then( <span style = 'color : green;'>&#9679;</span> )
                         else( <span style = 'color : red;'>&#9679;</span> )
                       let $ссылкаШаблонКонтент :=
                         if( $естьКонтент )
                         then(
                           <span>
                           аннотация: с подписью <a href = '{ $hrefA }'>docx</a>
                           |<a href = '{ $hrefPDFA }'>pdf</a>
                           </span>,
                           <span>
                           без подписи <a href = '{ $hrefA || "?mode=s"}'>docx</a>
                           |<a href = '{ $hrefPDFA || "?mode=s" }'>pdf</a>
                           </span>
                         )
                         else(
                           <span><a href = '{ $hrefшаблонСодержания }'>шаблон</a></span>
                         )
                      let $ссылкаРПД :=
                        if( $year )
                        then(
                          <span>РПД: <a href = '{ $hrefT }'>титул</a>|<a href = '{ $hrefT-dev }'>вся</a>, </span>
                        )
                        else() 
                       order by $i/@Название/data()
                       order by $mark/@style/data() descending
                       
                       let $ссылкаДляСкачивания :=
                         if( $annot = 'yes' )
                         then(
                           <span>{ $ссылкаРПД }{ $ссылкаШаблонКонтент }</span>
                         )
                         else()
                       return
                         <li>
                           { $mark }{ $discName } ({ $i/@КодДисциплины/data()}, сем. { $i/@Семестр/data()}) 
                           ({ $ссылкаДляСкачивания }, <a target = "_blank" href="{ $hrefCompList }">настройка РПД</a>)
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
    <a href = "/sandbox/ivgpu/statistic">На главную</a>
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
     По годy: 
    {
      for $i in ( 2016 to 2020 )
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
        if( $i = xs:integer( $year ) )
        then(
           <span><b>{ $i }</b>| </span>
        )
        else(
          <span><a href = '{ $href }'>{ $i }</a>| </span>
        )
    }
    <span> <a href = "{'/sandbox/ivgpu/statistic/lists/subjects/' || $id }" target = '_blank'>полный список дисциплин за 2016-2020 годы</a></span>
    <span style = "visibility: hidden;">
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
        </span>
    <br/>
      По кафедре:
      {
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
      let $названиеКафедры := 
        $кафедры[ КафедраКод =  $i ]/КафедраСокращенноеНазвание/text()
      return
        if( $i = $id)
        then(
           <span><b>{ $названиеКафедры }</b>| </span>
        )
        else(
          <span><a href = '{ $href }'>{ $названиеКафедры }</a>| </span>
        )
        
    } (<a href = 'https://portal.ivgpu.com/~k35kp'>подсказка по кодам</a>)
    </p>
    <hr/>
    <table>
      <tr>
        <td>
          <h3>
            Аннотации по дисцилинам кафедры "{ $кафедры[ КафедраКод =  $id ]/КафедраСокращенноеНазвание/text() }" <br/> по ООП { $year } года поступления
            { if( $fgos )then( if( $fgos = '3P' )then( ' по ФГОС 3+' )else( ' по ФГОС 3++' ) )else() }
          </h3>
          <p>
            Всего дисциплин: { $КоличествоДисциплин } (из них уникальных: { count( distinct-values( $ДисциплиныКафедры/@Название/data() ) ) })
            (из них готовы <span id = 'ready'>{ $ПроцентВыполнения }</span> %)
          </p>
        </td>
        <td>
          <div style = "{ if( $annot != 'yes')then('visibility: hidden;')else('visibility:visible;') }">
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

declare 
  %rest:path( '/sandbox/ivgpu/p/subjects.Department.Direction' )
  %rest:query-param( 'id', '{ $id }', '21' )
  %rest:query-param( 'year', '{ $year }', '2019' )
  %rest:query-param( 'mode', '{ $mode }', 'other' )
  %rest:query-param( 'subj', '{ $subj }' )
  %rest:query-param( 'fgos', '{ $fgos }' )
  %output:method( 'xhtml' )
function ivgpu:main2( $id, $year, $mode, $subj, $fgos ){
  ivgpu:main( $id, $year, $mode, $subj, $fgos, "no" )
};