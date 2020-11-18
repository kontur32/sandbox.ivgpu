module namespace студент.дисциплины = 'sandbox/ivgpu/вопросник/студентыЗадолженники';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at '../functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at '../modules/modules.data.xqm';
    
import module namespace 
  вопросы = 'sandbox/ivgpu/вопросник/билетыСтудента'
    at 'quiz.group.student.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/группы/{ $группа }/студенты/{ $студент }/дисциплины/{ $дисциплина }/отчетность/{ $отчетность }' )
  %output:method( 'xhtml' )
function студент.дисциплины:main( $группа, $студент, $дисциплина, $отчетность ){
  let $задолженностьСтудента := 
    данные:получитьЗадолженностьСтудента( $студент, $группа )
    [ cell[ @label = 'Дисциплина' ] = $дисциплина ]
    [ cell[ @label = 'Форма отчетности' ] = $отчетность ]
  
  
  
  let $данные := 
     for $i in $задолженностьСтудента
     count $c
     let $преподаватель := $i/cell[ @label = "Преподаватель"]/text()
     let $ФИО :=
       let $t := tokenize( $преподаватель )
       return
         substring( $t[ 2 ], 1, 1 ) ||'.'
         ||substring( $t[ 3 ], 1, 1 ) ||'. '||
         $t[ 1 ]
     let $формаОтчетности := 
       $i/cell[ @label = "Форма отчетности"]/text()  
     let $p :=
         map{
           'номерЛиста' : $c,
           'курс' : substring( replace( $группа, '\D', ''), 1, 1 ),
           'группа' : $группа,
           'дисциплина' : $дисциплина,
           'формаОтчетности' : $формаОтчетности,
           'оценка' : вопросы:списокОценок( $формаОтчетности, 'лист' || $c ),
           'студент' : $студент,
           'преподаватель' : $преподаватель,
           'ФИОпреподавателя' : $ФИО,
           'текущаяДата' : substring-before( xs:string( current-date() ), '+')
         }
     return
       funct:tpl( '/src/examBlankDispaly.html', $p )
  
  let $params := 
    map{
      'заголовок' : <div><span class = 'h3 text-left'>Задолженность студента {  $студент }</span></div>,
      'меню' : 
        <span>
          <a href = '/sandbox/ivgpu/вопросник/группы/'>список групп</a>/
          <a href = "{ '/sandbox/ivgpu/вопросник/группы/' || $группа || '/студенты/' }">{ $группа }</a>/
          <a href = "{ '/sandbox/ivgpu/вопросник/группы/' || $группа || '/студенты/' || $студент|| '/дисциплины/' }">{ $студент }</a>
        </span>,
      'данные' : <div><ol><div class = 'h4'>Дисциплины:  </div>{  $данные }</ol></div>,
      'экзаменационныйЛист' : ''
    }
   
   return
     funct:tpl( '/src/main.html', $params )
};