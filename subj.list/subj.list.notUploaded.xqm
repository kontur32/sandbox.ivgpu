module namespace ivgpu = 'subj.List';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../generate.doc/config.xqm';

import module namespace data = '/sandbox/ivgpu/generate/data'
  at '../generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/subjects/departments/{ $dep }/rpd/not.uploaded' )
  %rest:query-param( 'mode', '{ $mode }', '' )
  %output:method( 'xhtml' )
function ivgpu:аннотации( $dep, $mode ){
  let $дисциплины := 
    data:getResourceXML( config:param( 'host' ) || '/sandbox/ivgpu/api/v01/check/subjects/' || $dep, map{ 'mode' : $mode } )/csv/record
  let $программы := data:getProgrammData()
  
  let $строки :=
    for $i in $дисциплины
    return
      <ul>{ $i/@название/data() }{
        for $j in $i/программа
        let $программа := $программы[ Файл/@ID/data() = $j/text() ]
        let $href :=
          '/sandbox/ivgpu/api/directions/' ||
          $программа/@Год || '/' ||
          $программа/@КодНаправления || '/' ||
          $j/text() || '/rpd'
  
        return
          <li><a href = "{ $href }">{ $программа/@КодНаправления/data() }:{ $программа/@НазваниеПрофиля/data() }:{ $программа/@Год/data() }:{ $программа/@ФормаОбучения/data() }</a></li>
      }</ul>
  
  let $содержание :=
    <div>
      <h2>Незагруженные РПД по кафедре "{ $dep }"</h2>
      <div>Всего не загружены { count( $дисциплины/программа ) } РПД по {  count( $дисциплины ) } дисциплинам:</div>
      <div>{ $строки }</div>
    </div>
  let $tpl := doc( "../html/main.tpl.html" )
  return
    $tpl update insert node $содержание into .//body
};