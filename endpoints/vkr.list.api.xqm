module namespace vkr.api = 'sandbox/ivgpu/vkr/api';

import module namespace vkr = 'sandbox/ivgpu/vkr' at 'vkr.list.xqm';

declare
  %rest:path( '/sandbox/ivgpu/vkr/api/эуф/2019-2020/профили' )
function vkr.api:профили(){
  let $группы := vkr:request()/file/table[ @label = 'Список групп' ]
  let $result := 
    <csv>
      {
        for $i in $группы/row
        let $профиль := $i/cell[ @label = 'Название профиля' ]
        group by $профиль
        return
          <record>
            <профильНазвание>{ $профиль }</профильНазвание>
            <направлениеКод>{
              $i[ last() ]/cell[ @label = "Код направления" ]/substring-before( text(), ' '  )
            }</направлениеКод>
          </record>
      }</csv>
  return
   $result
  
};

declare
  %rest:path( '/sandbox/ivgpu/vkr/api/эуф/2019-2020/профили/{ $профиль }' )
function vkr.api:студентыПоПрофилям( $профиль ){
  let $data := vkr:request()
  let $группы := $data/file/table[ @label = 'Список групп' ]/row[ cell[ @label = 'Название профиля' ] = $профиль ]
  let $result := 
    <csv>{
      for $i in $группы
      let $кодГруппы := $i/cell[ @label = 'Код группы' ]/text()
      for $студент in $data/file/table[ @label = $кодГруппы ]/row
      let $ФИОстудента := $студент/cell[ @label = "ФИО_студента" ]/text()
      let $ФИОстудентаКороткое := 
         let $t := tokenize( $ФИОстудента )
         return
           string-join(
             ( $t[1], '_', substring( $t[2], 1, 1 ), '.', substring( $t[3], 1, 1 ) )
           )
      let $зачетка :=  substring-before( $студент/cell[ @label = 'Зачетка']/text(), '.' )
      let $path :=
        'http://iro37.ru:9984/static/ivgpu/Зима 2020/' || $кодГруппы || '/'
      return
        <record>
          <студентФИО>{ $ФИОстудента }</студентФИО>
          <номерЗачетнойКнижки>{ $зачетка }</номерЗачетнойКнижки>
          <направлениеКод>{
            $i/cell[ @label = 'Код направления' ]/substring-before( text(), ' ' )
          }</направлениеКод>
          <профильНазвание>{ $профиль }</профильНазвание>
          <темаВКР>{ $студент/cell[ @label = 'Тема_ВКР']/text() }</темаВКР>
          <ключевыеСлова>{ $студент/cell[ @label = 'Ключевые слова']/text() }</ключевыеСлова>
          <руководитель>{ $студент/cell[ @label = 'ФИО_должность_руководителя']/text() }</руководитель>
          <текстСсылка>{ iri-to-uri( $path || 'ВКР_' || $ФИОстудентаКороткое || '.pdf' ) }</текстСсылка>
          <антиплагиатСсылка>{ iri-to-uri( $path || 'Антиплагиат_' || $ФИОстудентаКороткое || '.pdf' ) }</антиплагиатСсылка>
        </record>
     }</csv>
  return
     $result
  
};

declare
  %private
function vkr.api:response( $result ){
  (
    <rest:response>
        <http:response status="200">
          <http:header name="Content-Disposition" value="attachment; filename=result.csv" />
          <http:header name="Content-type" value="plain/csv"/>
        </http:response>
    </rest:response>,
    csv:serialize( $result, map{ 'header' : 'yes' } )
  )
};