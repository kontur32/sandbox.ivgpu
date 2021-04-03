module namespace ivgpu.api.save.examForm = 'sandbox/ivgpu/api/jwt/save';

import module namespace 
  jwt = 'sandbox/ivgpu/вопросник/модули/jwt'
    at '../modules/modules.jwt.xqm';

import module namespace 
  config = 'sandbox/ivgpu/вопросник/модули/config'
    at '../config.xqm';
    
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
    config:получитьКодПодписи( $преподаватель )
  
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
          <дисциплина>{ $дисциплина }</дисциплина>
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
        $датаСдачи || '--' || random:uuid() || '.txt'
      
      let $createDir :=
        file:create-dir( $dirName )
      
      return
        (
          file:write-text( $dirName || $fileName, $jwt ),
          <div>
            <p style = 'color: green;'>Результат успешно записан (<a href = "/sandbox/ivgpu/вопросник/деканат/допуски/кафедры/эуф/годы/2020">посмотреть здесь</a>)</p>
            <p><a href = "{ $callBackURL }"><button>вернуться назад</button></a></p>
          </div>
        )
     )
    else( <div><p>Результат не записан, так как подпись недействительна</p><p><a href = "{ $callBackURL }"><button>вернуться назад</button></a></p></div> )
};