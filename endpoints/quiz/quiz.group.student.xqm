module namespace вопросы = 'sandbox/ivgpu/вопросник/билетыСтудента';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at 'functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at 'modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/группы/{$группа}/студенты/{$студент}/билеты' )
  %output:method( 'xhtml' )
function вопросы:main( $группа, $студент ){
  let $номераБилетов := данные:номераБилетов()
  let $билеты := данные:билетыСтудента( $студент, $группа )
  let $result :=
    for $i in $билеты/row
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
    
    return
      <div style="height: 190mm; width: 100%" class = "билет">
        <div class = 'row' >
          <span class = 'h4'>
            <span class = 'pr-2'>
              Билет № { $номераБилетов[ $c ] }
            </span>
          по предмету: { $дисциплина }<span class = 'px-1 no-print'>(<a href ="{$i/cell[@label = 'Ссылка Мудл']/text()}">курс в Мудл</a>)</span>
          <span class = 'no-print'>(<a href = "https://drive.google.com/file/d/1LRSIEFucNMTYl-TQk3PMQ81TqrUutkFZ/view?usp=sharing">бланк экз. листа</a>)</span>
          </span>
        </div>
        <div class = 'row' style="height: 47%;">
          <div class = 'col-12 h5'>Вопрос № 1: { $i/cell[ 1 ]/text() }</div>
          <div class = 'col-9 h-75 border my-auto'>Ответ:</div>
          <div class = 'col-3 h-75 text-center border my-auto'>
            <a href = "{ $короткаяСсылка }">
              <span class = 'py-0 my-0 no-print'>Подсказка</span>
              <img class="img-fluid" style="max-width: 100%; height: auto;" src = '{ $qrHref }'/>
            </a>
          </div>
        </div>
        <div class = 'row' style="height: 47%;">
          <div class = 'col-12 h5'>Вопрос № 2: { $i/cell[ 2 ]/text() }</div>
          <div class = 'col-9 h-75 border'>Ответ:</div>
          <div class = 'col-3 h-75 border'></div>
        </div>
      </div>
   let $экзЛист :=
     for $i in $билеты/row
     let $дисциплина := $i/@label/data()
     let $p :=
         map{
           'группа' : $группа,
           'дисциплина' : $дисциплина,
           'студент' : $студент,
           'преподаватель' : $i/cell[ @label = "Преподаватель"]/text()
         }
     return
       вопросы:шаблонЭкзЛиста( $p )
   
   let $params := 
    map{
      'заголовок' : <div><div>Студент:</div><span class = 'h3 text-left'>{$билеты/@label/data()} (группа: <span><a href = "{ '/sandbox/ivgpu/вопросник/группы/' ||  $группа || '/студенты/' }">{ $группа }</a></span>)</span></div>,
      'данные' : ( $result, <div id = 'разрыв'></div>, <div>{ $экзЛист }</div> ),
      'экзаменационныйЛист' : ''
    }
   return
     funct:tpl( '/src/main.html', $params )
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