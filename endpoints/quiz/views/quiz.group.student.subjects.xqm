module namespace студент.дисциплины = 'sandbox/ivgpu/вопросник/студентыЗадолженники';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at '../functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at '../modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/преп/группы/{ $группа }/студенты/{ $студент }/дисциплины' )
  %rest:query-param( 'преподаватель', '{ $преподаватель }', 'все' )
  %output:method( 'xhtml' )
function студент.дисциплины:main2( $группа, $студент, $преподаватель ){
  студент.дисциплины:main( $группа, $студент, $преподаватель )
};

declare
  %rest:path( '/sandbox/ivgpu/вопросник/группы/{ $группа }/студенты/{ $студент }/дисциплины' )
  %rest:query-param( 'преподаватель', '{ $преподаватель }', 'все' )
  %output:method( 'xhtml' )
function студент.дисциплины:main( $группа, $студент, $преподаватель ){
  let $задолженности := 
    данные:получитьЗадолженностьСтудента( $студент, $группа )
    [ cell[ @label = 'Дата ликвидации'] = '' ]
    [
      if( $преподаватель != 'все')
      then(
        cell[ @label = 'Преподаватель'] = $преподаватель
      )
      else( true() )
    ]
    
  let $данные :=
    for $i in $задолженности
    let $дисциплина := $i/cell[ @label = 'Дисциплина' ]/text()
    let $преподавательТекущий := $i/cell[ @label = 'Преподаватель' ]/text()
    let $формаОтчетности := $i/cell[ @label = 'Форма отчетности' ]/text()
    let $href := 
      if( $преподаватель != 'все' )
      then(
        '/sandbox/ivgpu/вопросник/преп/группы/' ||
        $группа || '/студенты/' || $студент || '/дисциплины/' ||
        $дисциплина || '/отчетность/' || $формаОтчетности
      )
      else( '#')
      
    order by $дисциплина
    return
      <li><a href = '{ $href }'>{ $дисциплина }</a> - { $формаОтчетности } (преподаватель: { $преподавательТекущий })</li>
  
   let $меню :=
     if( $преподаватель != 'все')
     then(
       <span>
         <a href = '{"/sandbox/ivgpu/вопросник/преп/группы/?преподаватель=" || $преподаватель }' >группы</a>/
         <a href = '{"/sandbox/ivgpu/вопросник/преп/группы/" || $группа || "/студенты/?преподаватель=" || $преподаватель }' >{ $группа }</a>
       </span>
       )
     else( <span><a href = '/sandbox/ivgpu/вопросник/группы/' >группы</a></span>  )
  
  let $params := 
    map{
      'заголовок' : <div><span class = 'h3 text-left'>Задолженность студента {  $студент }</span></div>,
      'меню' : $меню,
      'данные' : <div><ol><div class = 'h4'>Дисциплины: {$преподаватель} </div>{  $данные }</ol></div>,
      'экзаменационныйЛист' : ''
    }
   
   return
     funct:tpl( '/src/main.html', $params )
};