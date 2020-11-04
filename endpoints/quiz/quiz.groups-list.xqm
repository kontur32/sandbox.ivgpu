module namespace вопросы = 'sandbox/ivgpu/вопросник/студентыЗадолженники';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at 'functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at 'modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/группы' )
  %output:method( 'xhtml' )
function вопросы:main( ){
   let $данные := 
     данные:получитьГуглТаблицу( $данные:задолженностьПутьГугл )
      /file/table[ @label = 'Актуальная' ]
      /row
   let $результат :=
     for $i in $данные
     let $группа := $i/cell[ @label = 'Группа']/text()
     group by $группа
     return 
       <li><a href = "{ $группа || '/студенты/' }">{ $группа }</a> (долгов: { count( $i ) })</li>
   
   let $params := 
      map{
        'заголовок' : <div><span class = 'h3 text-left'>Все группы</span></div>,
        'данные' : <div><ol><div class = 'h4'>Группы:</div>{ $результат }</ol><div>Всего долгов: { count( $данные ) }</div></div>,
        'экзаменационныйЛист' : ''
      }
   
   return
     funct:tpl( '/src/main.html', $params )
};