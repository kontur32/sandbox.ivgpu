module namespace вопросы = 'sandbox/ivgpu/вопросник/студентыЗадолженники';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at 'functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at 'modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/группы/{$группа}/студенты' )
  %output:method( 'xhtml' )
function вопросы:main( $группа ){
   let $данные := 
     данные:получитьГуглТаблицу( $данные:задолженностьПутьГугл )
      /file/table[ @label = 'Актуальная' ]
      /row[ cell [ @label = 'Группа' ] = $группа ]
   let $результат :=
     for $i in $данные
     let $студент := $i/cell[ @label = 'ФИО студента']/text()
     group by $студент
     return 
       <li><a href = "{ $студент || '/билеты' }">{ $студент }</a> (долгов: { count( $i ) })</li>
   
   let $params := 
      map{
        'заголовок' : <div><span class = 'h3 text-left'>Группа: { $группа }</span></div>,
        'данные' : <div><ol><div class = 'h4'>Студенты:</div>{ $результат }</ol><div>Всего долгов: { count( $данные ) }</div></div>,
        'экзаменационныйЛист' : <div class = 'article d-none' style="width: 100%;"></div>
      }
   
   return
     funct:tpl( '/src/main.html', $params )
};