module namespace допуски = 'sandbox/ivgpu/вопросник/преподаватель/студент/допуски';

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
  %rest:path( '/sandbox/ivgpu/вопросник/преподаватели/{ $преподаватель }/группы/{ $группа }/студенты/{ $студент }' )
  %output:method( 'xhtml' )
function допуски:main( $группа, $студент, $преподаватель ){
  let $задолженностьСтудента :=
    данные:получитьЗадолженностьСтудента( $студент, $группа )
    [ cell[ @label = 'Преподаватель'] = $преподаватель ]
  
  let $заголовок :=
     <div>
       <div>Студент:</div>
       <span class = 'h3 text-left'>
         { $студент } (группа: <span><a href = "{ '/sandbox/ivgpu/вопросник/группы/' ||  $группа || '/студенты/' }">{ $группа }</a></span>)
       </span>
     </div>
   
   let $данные := 
     for $i in $задолженностьСтудента
     count $c
     let $дисциплина :=
       $i/cell[ @label = "Дисциплина"]/text()
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
       funct:tpl( '/src/examBlank.html', $p )
   
   let $params := 
    map{
      'заголовок' : $заголовок,
      'данные' : <ul>{ $данные }</ul>,
      'меню' : ( <div class = 'col-6 mt-4'>Преподаватель: { $преподаватель }</div>),
      'экзаменационныйЛист' : ''
    }
   return
     funct:tpl( '/src/main.html', $params )
};