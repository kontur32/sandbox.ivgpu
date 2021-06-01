module  namespace
  видыУчебнойРаботы = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/видыУчебнойРаботы';

declare function видыУчебнойРаботы:учебнаяРабота( $дисциплина ){
  let $видыКонтактной := ( '101', '102', '103', '114', '115', '141')
  let $видыРабот := 
    $дисциплина/видыРабот/видРабот
  let $контактнаяВсего := 
    $видыРабот[ кодВидаРабот/text() = $видыКонтактной ]/часы/text()
  
  return
    <table>
      <row>
        <cell>Вид учебной работы</cell>
        <cell>Всего часов</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр/text()
          group by $семестр
          return
            <cell>{ $семестр } семестр</cell>
        }
      </row>
      <row>
        <cell>Контактная работа (аудиторные занятия) (всего)</cell>
        <cell>{ sum( $контактнаяВсего ) }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная := $i[ кодВидаРабот/text() = $видыКонтактной ]/часы/text()
          return
            <cell>{ sum( $контактная ) }</cell>
        }
      </row>
      <row>
        <cell>в том числе:</cell>
        <cell></cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          return
            <cell></cell>
        }
      </row>
      <row>
        <cell>Лекции</cell>
        <cell>{ sum( $видыРабот[ кодВидаРабот/text() = '101' ]/часы/text() ) }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная := $i[ кодВидаРабот/text() = '101' ]/часы/text()
          return
            <cell>{ sum( $контактная ) }</cell>
        }
      </row>
      <row>
        <cell>Лабораторные работы</cell>
        <cell>{ sum( $видыРабот[ кодВидаРабот/text() = '102' ]/часы/text() ) }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная := $i[ кодВидаРабот/text() = '102' ]/часы/text()
          return
            <cell>{ sum( $контактная ) }</cell>
        }
      </row>
      <row>
        <cell>Практические занятия</cell>
        <cell>{ sum( $видыРабот[ кодВидаРабот/text() = '103' ]/часы/text() ) }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная := $i[ кодВидаРабот/text() = '103' ]/часы/text()
          return
            <cell>{ sum( $контактная ) }</cell>
        }
      </row>
      <row>
        <cell>КРП</cell>
        <cell>{ sum( $видыРабот[ кодВидаРабот/text() = '114' ]/часы/text() ) }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная := $i[ кодВидаРабот/text() = '114' ]/часы/text()
          return
            <cell>{ sum( $контактная ) }</cell>
        }
      </row>
      <row>
        <cell>СРП</cell>
        <cell>{ sum( $видыРабот[ кодВидаРабот/text() = '115' ]/часы/text() ) }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная := $i[ кодВидаРабот/text() = '115' ]/часы/text()
          return
            <cell>{ sum( $контактная ) }</cell>
        }
      </row>
      <row>
        <cell>Консультации</cell>
        <cell>{ sum( $видыРабот[ кодВидаРабот/text() = '141' ]/часы/text() ) }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная := $i[ кодВидаРабот/text() = '141' ]/часы/text()
          return
            <cell>{ sum( $контактная ) }</cell>
        }
      </row>
      <row>
        <cell>Самостоятельная работа (всего)</cell>
        <cell>{ sum( $видыРабот[ кодВидаРабот/text() = '107' ]/часы/text() ) }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная := $i[ кодВидаРабот/text() = '107' ]/часы/text()
          return
            <cell>{ sum( $контактная ) }</cell>
        }
      </row>
      <row>
        <cell>{
          if(  $видыРабот[ кодВидаРабот/text() = ( '4', '5' ) ] )
          then(
            '- курсовая работа/проект и проектная деятельность'
          )
          else(
            '- проектная деятельность'
          )
        }</cell>
        <cell>{
            let $курсовые := $видыРабот[ кодВидаРабот/text() = '107' ]/часы/text()
            return
              sum( for-each( $курсовые, function( $var ){ round( $var * 0.3 ) } ) )
            }
         </cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $СРС := sum( $i[ кодВидаРабот/text() = '107' ]/часы/text() )
          return
            <cell>{ round( $СРС * 0.3 ) }</cell>
        }
      </row>
       <row>
        <cell>- подготовка к занятиям</cell>
        <cell>{
          let $курсовые := $видыРабот[ кодВидаРабот/text() = '107' ]/часы/text()
          return
            sum( for-each( $курсовые, function( $var ){ round( $var * 0.3 ) } ) )
        }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $СРС := sum( $i[ кодВидаРабот/text() = '107' ]/часы/text() )
          return
            <cell>{ round( $СРС * 0.3 ) }</cell>
        }
      </row>
      <row>
        <cell>- изучение учебной, научной, методической, справочной литературы, в том числе с привлечением электронных средств информации</cell>
        <cell>{
          let $курсовые := $видыРабот[ кодВидаРабот/text() = '107' ]/часы/text()
          return
            sum( $видыРабот[ кодВидаРабот/text() = '107' ]/часы/text() ) -
            sum( for-each( $курсовые, function( $var ){ round( $var * 0.3 ) } ) ) * 2
        }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $СРС := sum( $i[ кодВидаРабот/text() = '107' ]/часы/text() )
          return
            <cell>{ $СРС - round( $СРС * 0.3 ) * 2 }</cell>
        }
      </row>
      <row>
        <cell>Промежуточная аттестация</cell>
        <cell>{ sum( $видыРабот[ кодВидаРабот/text() = '108' ]/часы/text() ) }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная := $i[ кодВидаРабот/text() = '108' ]/часы/text()
          return
            <cell>{ sum( $контактная ) }</cell>
        }
      </row>
      <row>
        <cell>Виды промежуточной аттестации</cell>
        <cell></cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная :=
            $i[ кодВидаРабот/text() = ( '1', '2', '3', '4', '5', '6' ) ]
            /названиеВидаРабота/text()
          return
            <cell>{ string-join( $контактная, ', ' ) }</cell>
        }
      </row>
      <row>
        <cell>Общая трудоемкость</cell>
        <cell></cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          return
            <cell></cell>
        }
      </row>
      <row>
        <cell>- часы</cell>
        <cell>{ sum( $видыРабот[ кодВидаРабот/text() = '1000' ]/часы/text() ) }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная := $i[ кодВидаРабот/text() = '1000' ]/часы/text()
          return
            <cell>{ sum( $контактная ) }</cell>
        }
      </row>
      <row>
        <cell>- зачетные единицы</cell>
        <cell>{ round( sum( $видыРабот[ кодВидаРабот/text() = '1000' ]/часы/text() ) div 36 ) }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная := $i[ кодВидаРабот/text() = '1000' ]/часы/text()
          return
            <cell>{ round( sum( $контактная ) div 36, 2 ) }</cell>
        }
      </row>
    </table>
};