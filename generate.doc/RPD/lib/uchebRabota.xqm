module  namespace
  видыУчебнойРаботы = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/видыУчебнойРаботы';

declare function видыУчебнойРаботы:учебнаяРабота( $дисциплина ){
  let $видыКонтактной := ( '101', '102', '103' )
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
        <cell>Самостоятельная работа</cell>
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
        <cell>- курсовые работы</cell>
        <cell>{ count( $видыРабот[ кодВидаРабот/text() = '5' ]/часы/text() ) * 36 }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $курсовые := $i[ кодВидаРабот/text() = '5' ]/часы/text()
          return
            <cell>{ count( $курсовые )*36 }</cell>
        }
      </row>
       <row>
        <cell>- подготовка к занятиям</cell>
        <cell>{ ( sum( $видыРабот[ кодВидаРабот/text() = '107' ]/часы/text() ) - count( $видыРабот[ кодВидаРабот/text() = '5' ]/часы/text() ) * 36 ) div 2 }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $СРС := $i[ кодВидаРабот/text() = '107' ]/часы/text()
          let $курсовые := $i[ кодВидаРабот/text() = '5' ]/часы/text()
          return
            <cell>{ ( sum( $СРС ) - count( $курсовые ) * 36 ) div 2 }</cell>
        }
      </row>
      <row>
        <cell>- изучение</cell>
        <cell>{ ( sum( $видыРабот[ кодВидаРабот/text() = '107' ]/часы/text() ) - count( $видыРабот[ кодВидаРабот/text() = '5' ]/часы/text() ) * 36 ) div 2 }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $СРС := $i[ кодВидаРабот/text() = '107' ]/часы/text()
          let $курсовые := $i[ кодВидаРабот/text() = '5' ]/часы/text()
          return
            <cell>{ ( sum( $СРС ) - count( $курсовые ) * 36 ) div 2 }</cell>
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
            $i[ кодВидаРабот/text() = ( '1', '2', '3', '4', '5' ) ]
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
        <cell>{ sum( $видыРабот[ кодВидаРабот/text() = '1000' ]/часы/text() ) div 36 }</cell>
        {
          for $i in $видыРабот
          let $семестр := $i/семестр
          group by $семестр
          let $контактная := $i[ кодВидаРабот/text() = '1000' ]/часы/text()
          return
            <cell>{ sum( $контактная ) div 36 }</cell>
        }
      </row>
    </table>
};