module namespace вопросы = 'sandbox/ivgpu/вопросник/преподавателиЗадолженники';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at '../functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at '../modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/преподаватели' )
  %output:method( 'xhtml' )
function вопросы:main( ){
   let $данные := 
     данные:получитьГуглТаблицу( $данные:задолженностьПутьГугл )
      /file/table[ @label = 'Актуальная' ]
      /row
  
   let $неСданы := $данные[ not( cell[ @label = 'Дата ликвидации' ]/text() ) ]
   let $сданы := $данные[ cell[ @label = 'Дата ликвидации' ]/text() ]
   
   let $результат :=
     for $i in $неСданы
     let $преподаватель :=
       if( $i/cell[ @label = 'Преподаватель']/text() != "" )
       then( $i/cell[ @label = 'Преподаватель']/text() )
       else( 'неизвестный преподаватель' )
     
     group by $преподаватель
     order by count( $i ) descending
     let $долги:=
       for $j in $i
       let $формаКонтроля := 
         if( $j/cell[ @label = "Форма отчетности"]/text() != "" )
         then( $j/cell[ @label = "Форма отчетности"]/text() )
         else( 'иное' )
       group by $формаКонтроля
       return
         $формаКонтроля || ': ' || count( $j )
     let $href := 
       '/sandbox/ivgpu/вопросник/группы/?преподаватель=' || $преподаватель
     return 
       <li><a href = "{ $href }">{ $преподаватель }</a> (всего долгов: { count( $i ) }, в том числе: { string-join( $долги, ', ' ) })</li>
   
   let $params := 
      map{
        'заголовок' : <div><span class = 'h3 text-left'>Все преподаватели по кафедре ЭУФ</span></div>,
        'данные' : <div><ol><div class = 'h4'>Преподаватели:</div>{ $результат }</ol><div>Всего долгов: { count( $неСданы ) } (было: { count( $данные ) }, в том числе сданы: { count( $сданы ) })</div></div>,
        'экзаменационныйЛист' : ''
      }
   
   return
     funct:tpl( '/src/main.html', $params )
};