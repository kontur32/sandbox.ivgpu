module namespace ivgpu = 'statistic.oop.subjects';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/statistic/oop.subjects' )
  %rest:query-param( 'year', '{ $yearsList }' )
  %rest:query-param( 'dep', '{ $dep }' )
  %output:method( 'xhtml' )
function ivgpu:view( $yearsList, $dep ){

let $years := ( 2015 to 2019 )
let $levels := ( '03', '04', '05' )
let $forms := ( 'очная', 'заочная', 'очно-заочная')

let $data := data:getProgrammData()

let $result :=
  for $y in $years
  let $pr01 := $data[ @Год = $y ]
  
  for $l in $levels
  let $pr02 := $pr01[ substring( @КодНаправления, 4, 2 ) = $l ]
  
  for $f in $forms
  where  
    ( $l='04' and $y >= 2018 ) or 
    ( $l='03' and ( ( $y >= 2015 and $f = 'заочная' ) or ( $y >= 2016 and $f = 'очная' ) ) ) or 
    ( $l='05' and $y >= 2015 )
    
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
            <td>{ 0}</td>,
            <td>{ 0}</td>,
            <td>{ 0}</td>
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
return
  <html>
      <body>
        <h2>Сводные данные о количестве ООП и дисцпилин на аккредитацию 2020 года</h2>
        <p>(подробности см. по активным ссылкам)</p>
        {
          $table
        }
      </body>
    </html>
};