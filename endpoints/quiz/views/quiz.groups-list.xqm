module namespace вопросы = 'sandbox/ivgpu/вопросник/студентыЗадолженники';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at '../functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at '../modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/преп/группы' )
  %rest:query-param( 'преподаватель', '{ $преподаватель }', 'все' )
  %output:method( 'xhtml' )
function вопросы:main2( $преподаватель ){
  вопросы:main( $преподаватель )
};

declare
  %rest:path( '/sandbox/ivgpu/вопросник/группы' )
  %rest:query-param( 'преподаватель', '{ $преподаватель }', 'все' )
  %output:method( 'xhtml' )
function вопросы:main( $преподаватель ){
   let $данные := 
     данные:получитьГуглТаблицу( $данные:задолженностьПутьГугл )
      /file/table[ @label = 'Актуальная' ]
      /row
      [ if( $преподаватель != 'все')then( cell [@label="Преподаватель"] = $преподаватель )else( true()) ]
  
   let $неСданы := $данные[ not( cell[ @label = 'Дата ликвидации' ]/text() ) ]
   let $сданы := $данные[ cell[ @label = 'Дата ликвидации' ]/text() ]
   
   let $результат :=
     for $i in $неСданы
     let $группа := $i/cell[ @label = 'Группа']/text()
     order by $группа
     group by $группа
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
         $группа || '/студенты/?преподаватель=' || $преподаватель
     return 
       <li><a href = "{ $href }">{ $группа }</a> (всего долгов: { count( $i ) }, в том числе: { string-join( $долги, ', ' ) })</li>
   
   let $меню :=
     if( $преподаватель != 'все')
     then( <span><a href = '{"/sandbox/ivgpu/вопросник/преподаватели/" }' >преподаватели</a></span> )
     else( <span><a href = '/sandbox/ivgpu/вопросник/' >главная</a></span>  )

   let $params := 
      map{
        'заголовок' : <div><span class = 'h3 text-left'>Все группы по кафедре ЭУФ</span><br/><span>по преподавателю: { $преподаватель }</span></div>,
        'меню' : $меню,
        'данные' : <div><ol><div class = 'h4'>Группы:</div>{ $результат }</ol><div>Всего долгов: { count( $неСданы ) } (было: { count( $данные ) }, в том числе сданы: { count( $сданы ) })</div></div>,
        'экзаменационныйЛист' : ''
      }
   
   return
     funct:tpl( '/src/main.html', $params )
};