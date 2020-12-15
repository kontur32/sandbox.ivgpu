module namespace вопросы = 'sandbox/ivgpu/вопросник';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at '../functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at '../modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник' )
  %output:method( 'xhtml' )
function вопросы:main( ){
   let $данные := 
     данные:получитьГуглТаблицу( $данные:задолженностьПутьГугл )
      /file/table[ @label = 'Актуальная' ]
      /row
  
   let $неСданы := $данные[ not( cell[ @label = 'Дата ликвидации' ]/text() ) ]
   let $сданы := $данные[ cell[ @label = 'Дата ликвидации' ]/text() ]
   
   let $содержание :=
     <div>
         <li><a href = "группы/">группы</a></li>
         <li><a href = "дисциплины/">дисциплины</a></li>
         <li><a href = "преподаватели/">преподаватели</a></li>
     </div>
   let $params := 
      map{
        'заголовок' : <div><span class = 'h3 text-left'>Академическая задолженность по дисциплинам кафедры ЭУФ у студентов ИРК</span></div>,
        'меню' : <a href = '/sandbox/ivgpu/вопросник/деканат/допуски/кафедры/эуф/годы/2020'>Эл. допуски</a>,
        'данные' : 
          <div>
            <ol>
              <div class = 'h4'>Разделы:</div>{ $содержание }
            </ol>
            <div>Всего долгов: { count( $неСданы ) } (было: { count( $данные ) }, в том числе сданы: { count( $сданы ) })
            </div>
            <div>
              <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
              <script type="text/javascript" src = '/static/ivgpu/src/js/promis.monitoring.requestSpeed.js'></script>
              <div id="chart_div" style="width: 100%; height: 500px">
                <p>идет загрузка диаграммы ...</p>
                <div class="preloader-5"></div>
              </div>
            </div>
          </div>,
        'экзаменационныйЛист' : ''
      }
   
   return
     funct:tpl( '/src/main.html', $params )

};