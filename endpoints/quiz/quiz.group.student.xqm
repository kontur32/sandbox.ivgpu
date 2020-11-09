module namespace вопросы = 'sandbox/ivgpu/вопросник/билетыСтудента';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at 'functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at 'modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/группы/{$группа}/студенты/{$студент}/билеты' )
  %rest:query-param( 'раздел', '{ $раздел }', 'все')
  %rest:query-param( 'преподаватель', '{ $преподаватель }' )
  %output:method( 'xhtml' )
function вопросы:main( $группа, $студент, $раздел, $преподаватель ){
  let $номераБилетов := данные:номераБилетов()
  let $билеты := 
    данные:билетыСтудента( $студент, $группа )
  
  let $билетыОтбор := 
    $билеты/row
    [ if( $преподаватель != "" )then( cell[ @label = 'Преподаватель'] = $преподаватель )else(true() ) ]
  
  let $result :=
    for $i in $билетыОтбор
    count $c
    let $дисциплина := $i/@label/data()
    let $короткаяСсылка :=
      fetch:text( iri-to-uri( 'https://clck.ru/--?url=http://dbx.iro37.ru/sandbox/ivgpu/вопросник/' || $группа ||'/' || $дисциплина || '/ответы' ) )
    
    let $qrHref := 
      web:create-url(
        'https://chart.googleapis.com/chart',
        map{
          'cht': 'qr',
          'chs' : '200x200',
          'choe' : 'UTF-8',
          'chld' : 'H',
          'chl' : $короткаяСсылка
        }
      )
    let $p := 
      map{
        'номерБилета' : $номераБилетов[ $c ],
        'дисциплина' : $дисциплина,
        'ссылкаНаМудл' : $i/cell[@label = 'Ссылка Мудл']/text(),
        'вопросПервый' : $i/cell[ 1 ]/text(),
        'короткаяСсылка' : $короткаяСсылка,
        'QRссылка' : $qrHref,
        'вопросВторой' : $i/cell[ 2 ]/text()
      }
    return
       funct:tpl( '/src/bilet.html', $p )
   let $экзЛист :=
     for $i in $билетыОтбор
     let $дисциплина := $i/@label/data()
     let $p :=
         map{
           'группа' : $группа,
           'дисциплина' : $дисциплина,
           'студент' : $студент,
           'преподаватель' : $i/cell[ @label = "Преподаватель"]/text()
         }
     return
       funct:tpl( '/src/examBlank.html', $p )
   
   let $данные := 
     (
       вопросы:формаРазделов( $раздел ),
       if( $раздел !=  'листы' )then( $result ),
       if( $раздел =  'все' )then( <div id = 'разрыв'></div> ),
       if( $раздел !=  'билеты' )then( <div>{ $экзЛист }</div> )
     )
   
   
   let $params := 
    map{
      'заголовок' : <div><div>Студент:</div><span class = 'h3 text-left'>{$билеты/@label/data()} (группа: <span><a href = "{ '/sandbox/ivgpu/вопросник/группы/' ||  $группа || '/студенты/' }">{ $группа }</a></span>)</span></div>,
      'данные' : $данные,
      'экзаменационныйЛист' : ''
    }
   return
     funct:tpl( '/src/main.html', $params )
};
 
 declare function вопросы:формаРазделов( $раздел ){
   <form action = "#" >
     <input type = "radio" name = "раздел" value = "все">Показать все</input>
     <input type = "radio" name = "раздел" value = "билеты">Только билеты</input>
     <input type = "radio" name = "раздел" value = "листы">Только экзам. листы</input>
     <input type = "submit" class="btn btn-primary" value = "Обновить"/>
   </form>
   update insert node attribute {'checked'} {'yes'} into ./input[ @value/data() = $раздел ]
 };
 
 declare function вопросы:шаблонЭкзЛиста( $params ){
   <div class = 'row' id = "экзЛисты">
			<div style="height: 190mm; width: 100%; font-family: 'Times New Roman', Times, serif; font-size: 14pt;" class = 'col-12 border no-display' >
				<div  class = "h4 mt-2 text-center">ЭКЗАМЕНАЦИОННЫЙ ЛИСТ №____</div>
				<div class = "text-center" style = "font-family: 'Times New Roman', Times, serif;"><b>Ивановский государственный политехнический университет</b></div>
				<div class = "text-center ">Очное, <b>заочное</b>, очно-заочное обучение</div>
				<div class = "text-center">(для сдачи экзамена или зачета вне группы)</div>
				<div class = "text-right pr-5 mr-6">Отчетность_____________</div>
				<div class = "text-right pr-5 mr-6">Часы ГОС______</div>
				<div class = "text-left pl-5 ml-5 pb-3">Институт ИРК курс ________ группа <u>{ $params?группа }</u></div>
				<div class = "text-left pl-5 ml-5 pb-3">Дисциплина <u>{ $params?дисциплина }</u></div>
				<div class = "text-left pl-5 ml-5">Экзаменатор <u>{ $params?преподаватель }</u></div>
				<div class = "text-left pb-3 pl-5 ml-5" style = "font-size: 10pt; margin-left: 20em!important">(уч. звание, фамилия, инициалы)</div>
				<div class = "text-left pb-3 pl-5 ml-5">Фамилия и инициалы студента <u>{ $params?студент }</u></div>
				<div class = "text-left pb-3 pl-5 ml-5">№ зачетной книжки _______________________</div>
				<div class = "text-left pb-3 pl-5 ml-5">Направление действительно до ___________________________________________</div>
				<div class = "text-left pb-3 pl-5 ml-5">Дата выдачи _______________ Директор ИРК   _________________ /Т.Н. Новосад/</div>
				<div class = "text-left pl-5 ml-5">Оценка ________________________		_______________________</div>
				<div class = "text-left pb-3 pl-5 ml-5" style = "font-size: 10pt; margin-left: 8em!important">(традиционный подход цифрой и прописью) (рейтинговый подход цифрой и прописью)</div>
				<div class = "text-left pb-3 pl-5 ml-5">Дата сдачи _________________________</div>
				<div class = "text-center">Подпись экзаменатора _____________________ /__________________/</div>
				<div class = "text-center pb-3" style = "font-size: 10pt; margin-left: 30em!important">(расшифровка подписи)</div>
			</div>
		</div>
 };