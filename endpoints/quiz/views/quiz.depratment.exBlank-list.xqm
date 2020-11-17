module namespace список.загрузок = 'sandbox/ivgpu/вопросник/деканат/список- загрузок';

import module namespace request = 'http://exquery.org/ns/request';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at '../functions.xqm';
import module namespace 
  config = 'sandbox/ivgpu/вопросник/модули/config'
    at '../config.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at '../modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/деканат/допуски/кафедры/эуф/годы/2020' )
  %rest:query-param( 'дата', '{ $дата }', '2020-11-15' )
  %output:method( 'xhtml' )
function список.загрузок:main( $дата ){
  
  let $задолженности := 
    данные:получитьзадолженность()
    [ cell [ @label = 'Дата ликвидации' ] = '' ]
  
  let $dirPath :=  Q{org.basex.util.Prop}HOMEDIR() || config:param( 'exBlankLocalPath' )
  
  let $данные :=
    for $i in file:list( $dirPath )
    where file:is-dir( $dirPath || '/' || $i  )
    let $день := replace( $i, '(\d{4})-(\d{2})-(\d{2}).{1}$', '$3.$2.$1')
    return
       <li>Экз. листы за <b>{ $день }:</b>
         <ul>
           <table class = "table border">
         {
           for $j in file:list( $dirPath || '/' || $i  )
           let $filePath := $dirPath || '/' || $i || '/' || $j
           
           where not( file:is-dir( $filePath  ) )
           
           order by xs:date( substring-before( $j, '--' ) )
           
           order by file:last-modified( $filePath  )
           
           let $file := file:read-text( $filePath[ last() ] )
           let $payLoad := tokenize( $file, '\.' )[ 2 ]
           let $данные := 
             json:parse(
               convert:binary-to-string( xs:base64Binary( $payLoad ) )
             )/json
           
           let $f := 
             string-join(
               (
                 $данные/группа,
                 $данные/студент,
                 $данные/дисциплина,
                 $данные/формаОтчетности
               ),
               '--'
             )
           
           group by $f
           let $датаСдачи := $данные[ last() ]/датаСдачи/text()
           let $преподаватель := $данные[ last() ]/преподаватель/text()
           let $оценка := $данные[ last() ]/оценка/text()
           
           let $учтена :=
             список.загрузок:зачтенаЗадолженность( $f, $задолженности ) 
           
           let $стильУчтенной := 
             if( $учтена )
             then( 'background-color: Silver;' )
             else()
           
           return
             <tr style = "{ $стильУчтенной }">
               <td>{ replace( $датаСдачи, '(\d{4})-(\d{2})-(\d{2})', '$3.$2.$1') }</td>
               {
                 let $td := tokenize( $f, '--' )
                 return
                   (
                     <td>{ $td[ 1 ] }</td>,
                     <td>{ список.загрузок:ФИО( $td[ 2 ] ) }</td>,
                     <td>{ $td[ 3 ] }</td>,
                     <td>{ $td[ 4 ] }</td>
                   ),
                 <td>{ список.загрузок:ФИО( $преподаватель ) }</td>,
                 <td>{ $оценка }</td>,
                   let $url := 
                     'http://' || request:hostname() || ':' || request:port() || '/sandbox/ivgpu/api/v01/generate/exam-form'
                   
                   let $path := 
                     'http://' || request:hostname() || ':' || request:port() ||  
                     '/static/ivgpu/euf/exBlank/2020/' || 
                     replace( $i, '\\', '/' )
                     || $j[ last() ]
                   let $href := 
                     web:create-url(
                       $url,
                       map{
                         '_jwt-path' : $path
                       }
                     )
                   return
                     <td>
                       <a href = '{ $href }'>
                         <button class = 'btn btn-primary'>Скачать</button>
                       </a>
                     </td>
             }</tr>
         }
         </table>
         </ul>
       </li>
  
  let $params := 
      map{
        'заголовок' : <div><span class = 'h3 text-left'>Экзаменнационные листы по дисциплинам кафедры ЭУФ</span><br/><span>за ноябрь 2020 года</span></div>,
        'данные' : <div><ul>{ $данные }</ul></div>,
        'экзаменационныйЛист' : <div class = 'article d-none' style="width: 100%;"></div>
      }
   
   return
     funct:tpl( '/src/main.html', $params )
};

declare 
  %private
function
  список.загрузок:зачтенаЗадолженность(
    $f as xs:string,
    $задолженности as element( row )*
  ) as xs:boolean
{
  let $r := tokenize( $f, '--' )
  let $b :=
    $задолженности
    [
      cell [ @label="Группа" ] = $r[ 1 ] and
      cell [ @label="ФИО студента" ] = $r[ 2 ] and
      cell [ @label="Дисциплина" ] = $r[ 3 ] and
      cell [ @label="Форма отчетности" ] = $r[ 4 ] 
    ]  
  return
    empty( $b )
};

declare function  список.загрузок:ФИО( $ФИОполностью ){
  let $t := tokenize( $ФИОполностью )
  return
    $t[ 1 ] || ' ' ||
    substring( $t[ 2 ], 1, 1 ) ||'.'
    ||substring( $t[ 3 ], 1, 1 ) ||'.'
};