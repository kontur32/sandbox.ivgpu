module namespace студент.дисциплины = 'sandbox/ivgpu/вопросник/студентыЗадолженники';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at '../functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at '../modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/преп/группы/{ $группа }/студенты/{ $студент }/дисциплины' )
  %output:method( 'xhtml' )
function студент.дисциплины:main2( $группа, $студент ){
  студент.дисциплины:main( $группа, $студент, 'преподаватель' )
};

declare
  %rest:path( '/sandbox/ivgpu/вопросник/группы/{ $группа }/студенты/{ $студент }/дисциплины' )
  %rest:query-param( 'режим', '{ $режим }', 'студент' )
  %output:method( 'xhtml' )
function студент.дисциплины:main( $группа, $студент, $режим ){
  let $задолженности := 
    данные:получитьЗадолженностьСтудента( $студент, $группа )
    [ cell[ @label = 'Дата ликвидации'] = '' ]
    
  let $данные :=
    for $i in $задолженности
    let $дисциплина := $i/cell[ @label = 'Дисциплина' ]/text()
    let $преподаватель := $i/cell[ @label = 'Преподаватель' ]/text()
    let $формаОтчетности := $i/cell[ @label = 'Форма отчетности' ]/text()
    let $href := 
      if( $режим = 'преподаватель' )
      then(
        '/sandbox/ivgpu/вопросник/группы/' ||
        $группа || '/студенты/' || $студент || '/дисциплины/' ||
        $дисциплина || '/отчетность/' || $формаОтчетности
      )
      else( '#')
      
    order by $дисциплина
    return
      <li><a href = '{ $href }'>{ $дисциплина }</a> - { $формаОтчетности } (преподаватель: { $преподаватель })</li>
  
  let $params := 
    map{
      'заголовок' : <div><span class = 'h3 text-left'>Задолженность студента {  $студент }</span></div>,
      'меню' : <span><a href = '/sandbox/ivgpu/вопросник/группы/'>список групп</a>/<a href = "{ '/sandbox/ivgpu/вопросник/группы/' || $группа || '/студенты/'}">{ $группа }</a></span>,
      'данные' : <div><ol><div class = 'h4'>Дисциплины:  </div>{  $данные }</ol></div>,
      'экзаменационныйЛист' : ''
    }
   
   return
     funct:tpl( '/src/main.html', $params )
};