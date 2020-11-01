module namespace ivgpu = '/sandbox/ivgpu/v0.2/subjects.Department.Direction';

import module namespace parseXLSX = "http://www.iro37.ru/stasova/api/v1.1/parseXLSX" 
  at "C:\Program Files (x86)\BaseX\webapp\ooxml\xlsx\funct\parseXLSX-to-TRCI.xqm"; 
    (:dev-2:)

declare 
  %rest:path( '/sandbox/ivgpu/covid-19/отчетППСнагрузка' )
  %output:method( 'html' )
  %rest:query-param( 'date', '{ $date }', '2020-03-23' )
  %rest:query-param( 'days', '{ $days }', '6' )
function ivgpu:main( $date as xs:date, $days as xs:integer ){
 let $path := 
  "https://docs.google.com/spreadsheets/d/e/2PACX-1vRIDQdcbUE-dyvXzEdRLJHmLNkhOBx4WkzKCCBZsAwXJHp0Fw7K70B4Qh9gOsvWBbE71SjdRtfBspxu/pub?output=xlsx"

let $file :=
  file:write-binary(
    file:temp-dir()|| '/polnaya-ydalenka.xls',
    fetch:binary(
     $path
    )
 )

let $raw :=
    fetch:binary(
     file:temp-dir()|| '/polnaya-ydalenka.xls'
    )

let $период := 
  for $i in 0 to $days - 1
  let $actualDate :=  $date + xs:dayTimeDuration( 'P' || $i || 'D' )
  return
   replace( xs:string( $actualDate ), '(\d{4})-(\d{2})-(\d{2})', '$3.$2.$1' )

let $парсинг := parseXLSX:xlsx( $raw )
let $data := $парсинг/table[ 1 ]/row[cell/@label/data() = $период ]

let $результат := 
  for $занятияЗаПериод in $data
  let $преподаватель := 
    normalize-space(
      $занятияЗаПериод/cell[ @label = "ФИО" ]/text()
    )
  order by $преподаватель
  for $занятие in $занятияЗаПериод/cell[ @label[ data() = $период ]/data() ][ text() ]
  let $датаЗанятия := $занятие/@label/data()
  let $ссылкаЦифровыеСледы :=  $занятияЗаПериод/cell[ @label = "Ссылка на курс в Moodle" ]/text()
  return
    <record>
      <преподаватель>{ $преподаватель }</преподаватель>
      <группа>{ $занятияЗаПериод/cell[ @label = "Группа" ]/text() }</группа>
      <контингент>{ $занятияЗаПериод/cell[ @label = "Студентов в группе" ]/round( text() ) }</контингент>
      <дисциплина>{ $занятияЗаПериод/cell[ @label = "Дисциплина" ]/text() }</дисциплина>
      <дата>{ $датаЗанятия }</дата>
      <нагрузка>2</нагрузка>
      <вовлеченность>{ round( number( $занятие/text() ) ) }</вовлеченность>
      <выполнилиЗадания>{ round( number( $занятие/text() ) * 0.8 ) }</выполнилиЗадания>
      <цифровыеСледы>{ $ссылкаЦифровыеСледы }</цифровыеСледы>
    </record>

let $столбцы :=
  (
    "преподаватель", "группа", "контингент", "дисциплина", "дата", "нагрузка", "вовлеченность", "выполнилиЗадания", "цифровыеСледы"
  )
  
let $недели :=
  (
    [ '2020-04-20', 6 ], [ '2020-04-27', 4 ], [ '2020-05-06', 3 ], 
    [ '2020-05-12', 5 ], ['2020-05-18', 6], [ '2020-05-25', 6 ],
    [ '2020-06-01', 6 ], ['2020-06-08', 6], ['2020-06-15', 6],
    ['2020-06-22', 6], ['2020-06-29', 6],  ['2020-07-06', 6]
  )

let $таблица :=
  <table border='1px'>{
    <tr>{
      for $i in $столбцы
      return
        <th>{ $i }</th>
    }</tr>,
      for $row in $результат
      return
        <tr>{
          for $столбец in $столбцы
          return
            <td>{ $row/child::*[ name() = $столбец ]/text() }</td>
        }</tr>
  }</table>
    
    return
      <div>
        <h1>Еженедельный отчет кафедры ЭУФ</h1>
        <h2>Выполнение педагогической нагрузки в дистанционной форме</h2>
        <div>{
          for $i in $недели
          let $href := 
            web:create-url(
              '/sandbox/ivgpu/covid-19/отчетППСнагрузка',
              map{
                'date' : $i?1
              }
            )
          return
            <a href = "{ $href }">{ $i?1 }</a>
        }</div>
        <div>{ $таблица }</div>
      </div>
};