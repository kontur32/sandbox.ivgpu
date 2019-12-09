module namespace transform = 'transformator';

declare namespace a = 'urn:schemas-microsoft-com:xml-diffgram-v1';
declare namespace b = 'http://tempuri.org/dsMMISDB.xsd';

declare function transform:P-to-simplex( $Data as element( Документ )* ){
let $Планы := $Data

for $План in $Планы
let $Титул := $План/План/Титул
let $НазваниеНаправления := 
  normalize-space(
    substring-after( $Титул/Специальности/Специальность[ 1 ]/@Название/data(), ' ' )
  )
let $НазваниеПрофиля := 
  normalize-space(
    replace(
      substring-after( $Титул/Специальности/Специальность[ 2 ]/@Название/data(), ' ' ),
      'программа', ''
    )
  )
return
  <Программа 
    КодНаправления = '{ normalize-space( $Титул/@ПоследнийШифр ) }' 
    НазваниеНаправления = '{ replace( $НазваниеНаправления, "\d{2}.", "")   }' 
    НазваниеПрофиля = '{ normalize-space( $НазваниеПрофиля ) }' 
    Кафедра = '{ $Титул/@КодКафедры }' 
    Год = '{ $Титул/@ГодНачалаПодготовки }' 
    ФормаОбучения = '{ $Титул/parent::*/@ФормаОбучения }'
    ФГОС = '3P'>
    <Файл DETAIL__URL = '{ $План/@DETAIL__URL/data() }' ID = '{ $План/@ID/data() }'/>
    <Дисциплины>
      {
        for $i in $План/План/СтрокиПлана/Строка
        return
          <Дисциплина КодДисциплины = '{ $i/@ИдетификаторДисциплины }' Название = '{ $i/@Дис }' КодКафедры = '{ $i/@Кафедра }' ЗЕТ = '{ $i/@КредитовНаДисциплину }'>
            <Компетенции>
              {
                for $i in $План/План/Компетенции/Строка[ @Код = tokenize( $i/@КомпетенцииКоды, '&amp;' ) ]
                return
                  <Компетенция ШифрКомпетенции = '{ $i/@Индекс }' Название = '{ $i/@Содержание }'/>
              }
            </Компетенции>
          </Дисциплина>
      }
    </Дисциплины>
  </Программа>
};

declare function transform:PP-to-simplex( $Data as element( Документ )* ){
let $Планы :=
  $Data/a:diffgram/b:dsMMISDB

for $План in $Планы
let $КодАктивногоПлана := $План/b:Планы/@КодАктивногоООП/data()
let $OOP := $План/b:ООП/b:ООП[ @Код = $КодАктивногоПлана  ]
return
  <Программа 
    КодНаправления = '{ $План/b:ООП/@Шифр }' 
    НазваниеНаправления = '{ $План/b:ООП/@Название  }' 
    НазваниеПрофиля = '{ $OOP/@Название}' 
    Кафедра = '{ $План/b:Планы/@КодПрофКафедры }' 
    Год = '{ $План/b:Планы/@ГодНачалаПодготовки }' 
    КодФормыОбучения = '{ $План/b:Планы/@КодФормыОбучения }'
    ФГОС = '3PP'>
    <Файл DETAIL__URL = '{ $План/parent::*/parent::*/@DETAIL__URL }' ID = '{ $План/parent::*/parent::*/@ID}' />
    <Дисциплины>
      {
        for $i in $План/b:ПланыСтроки[ @ТипОбъекта = '2' and ( ( @КодООП/data() = $План/b:ООП/@Код/data() ) or ( @КодООП/data() = $КодАктивногоПлана ) ) ]
        
        let $discComp := 
          $План/b:ПланыКомпетенцииДисциплины
            [ @КодСтроки/data() = $i/@Код/data() ]/@КодКомпетенции/data()
        
        return
          <Дисциплина КодДисциплины = '{ $i/@ДисциплинаКод }' Название = '{ $i/@Дисциплина }' КодКафедры = '{ $План/b:Кафедры[ @Код = $i/@КодКафедры ]/@Номер/data() }' ЗЕТ = '{$i/@ЗЕТфакт}'>
            <Компетенции>
              {
                for $i in $План/b:ПланыКомпетенции [ @Код/data() = $discComp ]
                return
                  <Компетенция 
                    ШифрКомпетенции = '{ $i/@ШифрКомпетенции }' 
                    Название = '{ $i/@Наименование }'
                  />
              }
            </Компетенции>
          </Дисциплина>
      }
    </Дисциплины>
  </Программа>
};