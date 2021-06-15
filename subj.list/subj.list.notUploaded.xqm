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
  let $кафедры :=
     data:getResourceCSV( config:param( 'ресурс.кафедры' ) )/csv/record
  let $дисциплиныЗакрепление :=
     if( $кафедры[ КафедраКод = $dep ]/Дисциплины/text() )
     then(
       data:getResourceCSV( $кафедры[ КафедраКод = $dep ]/Дисциплины/text(), map{ 'mode' : 'refresh' } )
       /csv/record
     )
     else()
  
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
        order by $программа/@КодНаправления/data()
        let $href :=
          '/sandbox/ivgpu/api/directions/' ||
          $программа/@Год || '/' ||
          $программа/@КодНаправления || '/' ||
          $j/text() || '/rpd'
        let $отвественныйПреподаватель :=
          ivgpu:ответственныйПреподаватель(
            $дисциплиныЗакрепление,
            $программа/@кодНаправления/data(),
            $i/@название/data()
          )
        let $hrefОтветственныйПреподаватель := 
          '/sandbox/ivgpu/statistic/lists/subjects/' || $dep 
          || '/' || $отвественныйПреподаватель
        return
          <li><a href = "{ $href }">{ $программа/@КодНаправления/data() }:{ $программа/@НазваниеПрофиля/data() }:{ $программа/@Год/data() }:{ $программа/@ФормаОбучения/data() }</a>
          (<b><a href = "{ $hrefОтветственныйПреподаватель }">{ $отвественныйПреподаватель }</a></b>)
          </li>
      }</ul>
  let $фильтр :=
    if( $mode = 'own')
    then(
      <span>
        <a href = "{ '/sandbox/ivgpu/api/v01/subjects/departments/' || $dep || '/rpd/not.uploaded' }">"Чужие"</a>
        <b>"Свои"</b>
      </span>
    )
    else(
      <span>
        <b>"Чужие"</b>
        <a href = "{ '/sandbox/ivgpu/api/v01/subjects/departments/' || $dep || '/rpd/not.uploaded?mode=own' }">"Свои"</a>
      </span>
      
    )
  let $содержание :=
    <div>
      <h2>Незагруженные РПД по кафедре "{ $dep }"</h2>
      <div>Фильтр дисциплин: { $фильтр }</div>
      <div>Всего не загружены { count( $дисциплины/программа[ ./text() = $программы/Файл/@ID/data() ] ) } РПД:</div>
      <div>{ $строки }</div>
    </div>
  let $tpl := doc( "../html/main.tpl.html" )
  return
    $tpl update insert node $содержание into .//body
};

declare
  %private
function ivgpu:ответственныйПреподаватель(
  $дисциплины as element( record )*,
  $кодНаправления as xs:string*,
  $названиеДисциплины as xs:string
){
  let $дисциплина := $дисциплины[ Дисциплина/text() = $названиеДисциплины ]

  return
     if( $дисциплина[ Код_направления/text() = $кодНаправления ] )
     then(
       $дисциплина[ Код_направления/text() = $кодНаправления ]/Преподаватель/text()
     )
     else(
       if( $дисциплина[ not( Код_направления/text() ) ]/Преподаватель/text() )
       then(
         $дисциплина[ not( Код_направления/text() ) ]/Преподаватель/text()
       )
       else(
         'Не закреплена'
       )
     )
};