module namespace ivgpu = 'statistic.oop.subjects';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/statistic/oop.subjects' )
  %rest:query-param( 'dep', '{ $dep }', 'all' )
  %output:method( 'xhtml' )
function ivgpu:view( $dep ){

  let $years := ( 2017 to 2021 )
  let $levels := ( '03', '04', '05' )
  let $forms := ( 'очная', 'заочная', 'очно-заочная')
  
  let $data :=
    data:getProgrammData()
    [ if( $dep = 'all' )then( true() )else( @Кафедра = $dep ) ]
  
  let $result :=
    for $y in $years
    let $pr01 := $data[ @Год = $y ]
    
    for $l in $levels
    let $pr02 := $pr01[ substring( @КодНаправления, 4, 2 ) = $l ]
    
    for $f in $forms
    where  
      ( ( $l='04' and $y >= 2019 ) or 
      ( $l='03' and ( ( $y >= 2016 and $f = 'заочная' ) or ( $y >= 2017 and $f = 'очная' ) ) ) or 
      ( $l='05' and $y >= 2016 ) ) or true()
      
    let $pr03 := $pr02[ @ФормаОбучения = $f ]
    let $d := $pr03//Дисциплина/@Название/data()
    
    return
      [( $y, $l, $f ), ( count($pr03), count( $d ), count( distinct-values( $d ) ) )]
    
  let $rows := 
    for $y in $years
    return
      (
        <tr align="center">
        <td><a href = '{ "/sandbox/ivgpu/directions?year=" || $y }'>{ $y }</a></td>
        {
          for $l in $levels
          for $f in $forms
          let $r := $result[?1[1]=$y and ?1[2]=$l and ?1[3]=$f]?2
          return
            if( not( empty( $r ) ) )
            then(
              <td>{ $r[1]}</td>,
              <td>{ $r[2]}</td>,
              <td>{ $r[3]}</td>
            )
            else(
              <td>{ 0 }</td>,
              <td>{ 0 }</td>,
              <td>{ 0 }</td>
            )
        }
        {
          for $f in $forms
          let $res := $result[?1[1]=$y and ?1[3]=$f ]
          return
            (
              <td>{sum( for $i in $res return $i?2[1] )}</td>,
              <td>{sum( for $i in $res return $i?2[2] )}</td>,
              <td>{sum( for $i in $res return $i?2[3] )}</td>
            )
        }
        {
          let $res := $result[ ?1[1]=$y ]
          return
            (
              <td>{sum( for $i in $res return $i?2[1] )}</td>,
              <td>{sum( for $i in $res return $i?2[2] )}</td>,
              <td>{sum( for $i in $res return $i?2[3] )}</td>
            )
        }
      </tr>
    ) 
  let $table:= 
      <table border='1px'>
        <tr style='font-weight: bold;' align="center">
          <td rowspan="4">Год</td>
          <td colspan="36">Уровень образования</td>
          <td rowspan="3" colspan="3">Всего</td>
        </tr>
        <tr align="center" style='font-weight: bold;'>
          <td colspan="9">баклавриат</td>
          <td colspan="9">магистратура</td>
          <td colspan="9">специалитет</td>
          <td colspan="9">Итого</td>
        </tr>
        <tr align="center">
          {
            for $i in 1 to 4
            return
              (<td colspan="3">очная</td>,
              <td colspan="3">заочная</td>,
              <td colspan="3">очно-заочная</td>)
          }
        </tr>
        <tr align="center">
          {
            for $i in 1 to 13
            return
              (
                <td>прогр.</td>,
                <td>дисц.</td>,
                <td>уник.</td>
              )
          }
        </tr>
        {
          $rows
        }
        <tr style='font-weight: bold;' align="center">
          <td>Всего</td>
        {
          for $l in $levels
          for $f in $forms
          let $res := $result[?1[1]=$years and ?1[2]=$l and ?1[3]=$f]
          return
            (
              <td>{sum( for $i in $res return $i?2[1] )}</td>,
              <td>{sum( for $i in $res return $i?2[2] )}</td>,
              <td>{sum( for $i in $res return $i?2[3]  )}</td>
            )
        }
        {
          for $f in $forms
          let $res := $result[ ?1[3]=$f ]
          return
            (
              <td>{sum( for $i in $res return $i?2[1] )}</td>,
              <td>{sum( for $i in $res return $i?2[2] )}</td>,
              <td>{sum( for $i in $res return $i?2[3] )}</td>
            )
        }
        {
          let $res := $result
          return
            (
              <td>{sum( for $i in $res return $i?2[1] )}</td>,
              <td>{sum( for $i in $res return $i?2[2] )}</td>,
              <td>{sum( for $i in $res return $i?2[3] )}</td>
            )
        }
        </tr>
      </table>
  let $кафедры :=
    for $i in 1 to 21
    let $href := '?dep=' || $i
    return
      <span> <a href = "{ $href }">{$i}</a> </span>
  
  let $body :=
      <body>
        <h2>Сводные данные о количестве ООП и дисцпилин на аккредитацию 2021 года</h2>
        <p>По кафедрам: { $кафедры } <span> <a href = "?dep=all">все</a> </span></p>
        <p>(подробности см. по активным ссылкам)</p>
        {
          $table
        }
      </body>
  let $tpl := doc( "html/main.tpl.html" )
  return
    $tpl update insert node $body into .//body
};

declare 
  %rest:path( '/sandbox/ivgpu/statistic/oop.subjects.dep' )
  %output:method( 'xhtml' )
function ivgpu:view2(){
  
  let $кафедры := 
    csv:parse(  
      fetch:text(
        'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=183523999&amp;single=true&amp;output=csv'
    ), map{ 'header' : true() } )/csv/record

  let $dep := ( 1 to 21 )
  let $levels := ( '03', '04', '05' )
  let $forms := ( 'очная', 'заочная', 'очно-заочная')
  
  let $data := data:getProgrammData()

  let $result :=
    for $y in $dep    
    for $l in $levels
    for $f in $forms
         
    let $disc :=
      $data
      [ @ФормаОбучения = $f ]
      [ substring( @КодНаправления, 4, 2 ) = $l ]
      /Дисциплины/Дисциплина[ @КодКафедры = xs:string( $y ) ]
    let $программВсего := 
      count( distinct-values( $disc/parent::*/parent::*/Файл/@ID/data() ) )
    let $дисциплинВсего := 
      count( $disc )
    let $дисциплинУникальных := 
      count( distinct-values( $disc/@Название/data() ) ) 
    return
      [
        ( $y, $l, $f ),
        ( $программВсего, $дисциплинВсего, $дисциплинУникальных )
      ]
    
  let $rows := 
    for $d in $dep
    order by count( $data//Дисциплина[ @КодКафедры = xs:string( $d ) ] ) descending
    let $href := 
      web:create-url(
        '/sandbox/ivgpu/p/subjects.Department.Direction',
        map{
          'mode' : 'full',
          'id' : $d
        }
      )
    where $result[ ?1[ 1 ] = $d ]?2 > 0
    return
      <tr align="center">
        <td align="left">
          <a href = "{ $href}" target = "_blank">
            { $кафедры[ КафедраКод =  xs:string( $d ) ]/КафедраСокращенноеНазвание/text() }
          </a>({$d})
        </td>
        {
          for $l in $levels
          for $f in $forms
          let $r := $result[?1[1]=$d and ?1[2]=$l and ?1[3]=$f]?2
          
          return
            if( not( empty( $r ) ) )
            then(
              <td>{ $r[1]}</td>,
              <td>{ $r[2]}</td>,
              <td>{ $r[3]}</td>
            )
            else(
              <td>{ 0 }</td>,
              <td>{ 0 }</td>,
              <td>{ 0 }</td>
            )
        }
        {
          for $f in $forms
          let $res :=
            $data
            [ @ФормаОбучения = $f ]
            /Дисциплины/Дисциплина[ @КодКафедры = xs:string( $d ) ]
          let $программВсего := 
            count( distinct-values( $res/parent::*/parent::*/Файл/@ID/data() ) )
          return
            (
              <td>{ $программВсего }</td>,
              <td>{ count( $res ) }</td>,
              <td>{ count( distinct-values( $res/@Название/data() ) ) }</td>
            )
        }
        {
          let $res := $data//Дисциплина[ @КодКафедры = xs:string( $d ) ]
          let $программВсего := 
            count( distinct-values( $res/parent::*/parent::*/Файл/@ID/data() ) )
          let $общееКоличествоДисциплин :=
            count( $res ) 
          let $количествоУникальныхДисциплин :=
             count( distinct-values( $res/@Название  ) ) 
          let $коэфУникальности :=
            if( $количествоУникальныхДисциплин > 0 )   
            then(
              round(
                  $общееКоличествоДисциплин div $количествоУникальныхДисциплин
              )
            )
            else()
          return
            (
              <td>{ $программВсего }</td>,
              <td><b>{ $общееКоличествоДисциплин }</b></td>,
              <td>{ $количествоУникальныхДисциплин }</td>,
              <td>{ $коэфУникальности }</td>
            )
        }
      </tr>
      
  let $table:= 
      <table border='1px'>
        <tr style='font-weight: bold;' align="center">
          <td rowspan="4">Кафедра(код)</td>
          <td colspan="36">Уровень образования</td>
          <td rowspan="3" colspan="4">Всего</td>
        </tr>
        <tr align="center" style='font-weight: bold;'>
          <td colspan="9">баклавриат</td>
          <td colspan="9">магистратура</td>
          <td colspan="9">специалитет</td>
          <td colspan="9">Итого</td>
        </tr>
        <tr align="center">
          {
            for $i in 1 to 4
            return
              (<td colspan="3">очная</td>,
              <td colspan="3">заочная</td>,
              <td colspan="3">очно-заочная</td>)
          }
        </tr>
        <tr align="center">
          {
            for $i in 1 to 12
            return
              (
                <td>прогр.</td>,
                <td>дисц.</td>,
                <td>уник.</td>
              )
          }
          <td>прогр.</td>,
          <td>дисц.</td>,
          <td>уник.</td>
          <td>коэф.</td>
        </tr>
        {
          $rows
        }
        <tr style='font-weight: bold;' align="center">
          <td>Всего</td>
        {
          for $l in $levels
          for $f in $forms
          let $res :=
            $data
              [ @ФормаОбучения = $f ]
              [ substring( @КодНаправления, 4, 2 ) = $l ]
          let $общееКоличествоДисциплин :=
            count( $res//Дисциплина/@Название )
          let $количествоУникальныхДисциплин :=
            count( distinct-values( $res//Дисциплина/@Название ) )
          
          let $коэфУникальности :=
            if( $общееКоличествоДисциплин > 0 )   
            then(
              round(
                 $количествоУникальныхДисциплин div $общееКоличествоДисциплин,
                1
              )
            )
            else()
          return
            (
              <td>{ count( $res ) }</td>,
              <td>{ $общееКоличествоДисциплин }</td>,
              <td>{ $количествоУникальныхДисциплин }</td>
            )
        }
        {
          for $f in $forms
          let $res := 
            $data
              [ @ФормаОбучения = $f ]
              //Дисциплина/@Название 
          
          return
            (
              <td>{ count( $data[ @ФормаОбучения = $f ] ) }</td>,
              <td>{ count( $res ) }</td>,
              <td>{ count( distinct-values( $res ) ) }</td>
            )
        }
        {
          let $res := $data//Дисциплина/@Название 
          return
            (
              <td>{ count( $data ) }</td>,
              <td>{ count( $res ) }</td>,
              <td>{ count( distinct-values( $res ) ) }</td>,
              <td>{ round( count( $res ) div  count( distinct-values( $res ) ), 1 )}</td>
            )
        }
        </tr>
      </table>
 
  let $body :=
      <body>
        <a href = "/sandbox/ivgpu/statistic">На гравную</a>
        <h2>Сводные данные о количестве дисцпилин на аккредитацию 2021 года</h2>
        <p>(полный список дисциплин по кафедре см. по активным ссылкам)</p>
        {
          $table
        }
        <ul>Значения в таблице:
          <li>"прогр." - количество ООП, по которым за кафедрой есть дисцплины</li>
          <li>"дисц." - количество дисциплин по аккредитуемым программам</li>
          <li>"уник." - количество уникальных названий дисциплин по аккредитуемым программам</li>
        </ul>
        
        <div class = "h2">Сводные данные по количеству ООП ВО на <a href = "https://ivgpu.com/sveden/education/edu-op">сайте ИВГПУ</a></div>
        {  ivgpu:статистикаООПсСайта() }
      </body>
  let $tpl := doc( "html/main.tpl.html" )
  return
    $tpl update insert node $body into .//body
};

declare function ivgpu:статистикаООПсСайта(){
  let $data :=
  html:parse( fetch:text( 'https://ivgpu.com/sveden/education/edu-op' ) )
  
let $программы :=  
  $data
  //table[ 1 ]/tbody
  /tr/ td[ @itemprop="educationPlan" ]/a[ matches( @href/data(), '.*\d{2}\.0[3-5]\.\d{2}.*' )  ]

let $строки :=   
  for $i in $программы
  let $кодНаправления := 
     replace(
      $i/@href/data(),
      '.*(\d{2})\.(\d{2})\.(\d{2}).*',
      '$1.$2.$3'
    )
  group by $кодНаправления
  return
    <tr>
      <td>{ $кодНаправления }</td>
      {
        for $год in 2017 to 2021
        return
          <td>{ count( $i[ matches( @href/data(), string( $год ) ) ] ) }</td>
      }
      <td>{ count( $i ) }</td>
    </tr>
return
  <table border='1px'>
    <tr>
      <td>Направление</td>
      {
        for $год in 2017 to 2021
        return
          <td>{ $год }</td>
      }
      <td>Итого</td>
    </tr>
    { $строки }
    <tr>
      <td>Всего</td>
      {
        for $год in 2017 to 2021
          return
            <td>{ count( $программы[ matches( @href/data(), string( $год ) ) ] ) }</td>
      }
      <td>{ count( $программы ) }</td>
    </tr>    
  </table>  
};