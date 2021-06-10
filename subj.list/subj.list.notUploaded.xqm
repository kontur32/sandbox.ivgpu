module namespace ivgpu = 'subj.List';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../generate.doc/config.xqm';

import module namespace data = '/sandbox/ivgpu/generate/data'
  at '../generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/subjects/departments/{ $dep }/rpd/not.uploaded' )
  %rest:query-param( 'refresh', '{ $refresh }', '' )
  %rest:query-param( 'mode', '{ $mode }', 'full' )
  %output:method( 'xhtml' )
function ivgpu:аннотации( $dep, $refresh, $mode ){
  let $дисциплины := 
    data:getResourceXML( config:param( 'host' ) || '/sandbox/ivgpu/api/v01/check/subjects/' || $dep, map{ 'mode' : $refresh } )/csv/record
  let $программы := data:getProgrammData()
      [ if( $mode = 'own' )then( @Кафедра = $dep )else( @Кафедра != $dep ) ]
  let $строки :=
    for $i in $дисциплины
    where $программы
          [ Файл/@ID/data() = $i/программа/text() ]
    let $ссылкаСтраницаДисцплины :=
      web:create-url(
        '/sandbox/ivgpu/statistic/lists/subjects/' || $i/@название/data() || '/directions',
        map{
          'deps' : 'all',
          'dep' : $dep
        }
      )
    return
      <ul><b><a href = "{ $ссылкаСтраницаДисцплины }">{ $i/@название/data() }</a></b>{
        for $j in $i/программа
        let $программа := 
          $программы
          [ Файл/@ID/data() = $j/text() ]
        where $программа 
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
      <div>Всего не загружены { count( $дисциплины/программа[ ./text() = $программы/Файл/@ID/data() ] ) } РПД:</div>
      <div>{ $строки }</div>
    </div>
  let $tpl := doc( "../html/main.tpl.html" )
  return
    $tpl update insert node $содержание into .//body
};