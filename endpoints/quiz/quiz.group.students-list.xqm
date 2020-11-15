module namespace вопросы = 'sandbox/ivgpu/вопросник/студентыЗадолженники';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at 'functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at 'modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/группы/{ $группа }/студенты' )
  %rest:query-param( 'преподаватель', '{ $преподаватель }', 'все' )
  %output:method( 'xhtml' )
function вопросы:main( $группа, $преподаватель ){
   let $данные := 
     данные:получитьГуглТаблицу( $данные:задолженностьПутьГугл )
      /file/table[ @label = 'Актуальная' ]
      /row
      [ cell [ @label = 'Группа' ] = $группа ]
      [ if( $преподаватель != 'все' )then( cell[ @label = 'Преподаватель' ] = $преподаватель )else( true() ) ]
      
   let $результат :=
     for $i in $данные
     let $студент := $i/cell[ @label = 'ФИО студента']/text()
     group by $студент
     let $href := 
       $студент || '/билеты?раздел=листы&amp;преподаватель=' || $преподаватель
     let $href2 :=
       '/sandbox/ivgpu/вопросник/преподаватели/' || $преподаватель || '/группы/' || $группа || '/студенты/' || $студент
     return 
       <li>{ $студент } (<a href = "{ $href }">билеты</a>, <a href = "{ $href2 }">экз. листы: { count( $i ) }</a>)</li>
   
   let $params := 
      map{
        'заголовок' : <div><span class = 'h3 text-left'>Группа: { $группа }</span><br/><span>по преподавателю: { $преподаватель }</span></div>,
        'данные' : <div><ol><div class = 'h4'>Студенты:</div>{ $результат }</ol><div>Всего долгов: { count( $данные ) }</div></div>,
        'экзаменационныйЛист' : <div class = 'article d-none' style="width: 100%;"></div>
      }
   
   return
     funct:tpl( '/src/main.html', $params )
};