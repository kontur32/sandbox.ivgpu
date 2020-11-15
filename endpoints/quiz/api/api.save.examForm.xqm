module namespace ivgpu.api.save.examForm = 'sandbox/ivgpu/api/jwt/save';

import module namespace 
  jwt = 'sandbox/ivgpu/вопросник/модули/jwt'
    at '../modules/modules.jwt.xqm';

declare
  %rest:path( '/sandbox/ivgpu/api/v01/save/exam-form' )
  %output:method( 'xhtml' )
  %rest:query-param( '_signature', '{ $signature }', '' )
  %rest:query-param( 'курс', '{ $курс }', '' )
  %rest:query-param( 'группа', '{ $группа }', '' )
  %rest:query-param( 'преподаватель', '{ $преподаватель }', '' )
  %rest:query-param( 'ФИОпреподавателя', '{ $ФИОпреподавателя }', '' )
  %rest:query-param( 'студент', '{ $студент }', '' )
  %rest:query-param( 'дисциплина', '{ $дисциплина }', '' )
  %rest:query-param( 'формаОтчетности', '{ $формаОтчетности }', '' )
  %rest:query-param( 'датаСдачи', '{ $датаСдачи }', '' )
  %rest:query-param( 'оценка', '{ $оценка }', '' )
function 
ivgpu.api.save.examForm:saveToken(
  $signature as xs:string,
  $курс as xs:string,
  $группа as xs:string,
  $преподаватель as xs:string,
  $ФИОпреподавателя as xs:string,
  $студент as xs:string,
  $дисциплина as xs:string,
  $формаОтчетности as xs:string,
  $датаСдачи as xs:string,
  $оценка as xs:string
){
  let $ЭЦП := 
    csv:parse( fetch:text('https://docs.google.com/spreadsheets/d/e/2PACX-1vQnKyXRmpX52iJ6Oj4A9xlcLC35KKd61UArCiCKpu-yogCOEW7TolfPe95Pm_st82C_3JF2qYa26uJZ/pub?gid=0&amp;single=true&amp;output=csv'), map{'header': 'yes'} )
    /csv/record[ ФИО/text() = $преподаватель ]/ЭЦП/text()
  let $callBackURL := 
    '/sandbox/ivgpu/вопросник/преподаватели/' || $преподаватель || '/группы/' || $группа || '/студенты/' || $студент
  return
    if( $ЭЦП = $signature )
    then(
      let $currentDateTime := string( current-dateTime() )
      let $payLoad := 
        <json type="object">
          <группа>{ $группа }</группа>
          <студент>{ $студент }</студент>
          <дисцилина>{ $дисциплина }</дисцилина>
          <формаОтчетности>{ $формаОтчетности }</формаОтчетности>
          <преподаватель>{ $преподаватель }</преподаватель>
          <кафедра>ЭУФ</кафедра>
          <оценка>{ $оценка }</оценка>
          <датаСдачи>{ $датаСдачи }</датаСдачи>
          <датаВремяПодписи>{ $currentDateTime }</датаВремяПодписи>
          <подписавшееЛицо>{ $преподаватель }</подписавшееЛицо>
        </json>
      let $jwt := jwt:buildJWT( json:serialize( $payLoad ) )
      let $path := 
         web:create-url(
            'http://localhost:9984/sandbox/ivgpu/api/v01/jwt/validate',
            map{
              'jwt' :  $jwt
            }
          )
      let $dirName := 
        Q{org.basex.util.Prop}HOMEDIR() || 'webapp/static/ivgpu/euf/exBlank/2020/' || substring-before( $currentDateTime, 'T' ) || '/'
      let $fileName := 
        $датаСдачи || '--' || $группа || '--' || $студент ||
        '--' || $дисциплина || '--' || $формаОтчетности || '.txt'
      
      let $createDir :=
        file:create-dir( $dirName )
      return
        (
          file:write-text( $dirName || $fileName, $jwt ),
          <div>
            <p>Результат успешно записан</p>
            <p><a href = "{ $callBackURL }"><button>вернуться назад</button></a></p>
          </div>
        )
     )
    else( <div><p>Результат не записан, так как подпись недействительна</p><p><a href = "{ $callBackURL }"><button>вернуться назад</button></a></p></div> )
};