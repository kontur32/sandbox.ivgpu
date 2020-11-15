module namespace список.загрузок = 'sandbox/ivgpu/вопросник/деканат/список- загрузок';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at '../functions.xqm';
import module namespace 
  config = 'sandbox/ivgpu/вопросник/модули/config'
    at '../config.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/деканат/допуски/кафедры/эуф/годы/2020' )
  %rest:query-param( 'дата', '{ $дата }', '2020-11-15' )
  %output:method( 'xhtml' )
function список.загрузок:main( $дата ){
  
  let $dirPath :=  Q{org.basex.util.Prop}HOMEDIR() || config:param( 'exBlankLocalPath' )
  
  let $данные :=
    for $i in file:list( $dirPath )
    where file:is-dir( $dirPath || '/' || $i  )
    return
       <li>{ $i }
         <ul>
           <table class = "table border">
         {
           for $j in file:list( $dirPath || '/' || $i  )
           let $filePath := $dirPath || '/' || $i || '/' || $j
           where not( file:is-dir( $filePath  ) )
           order by xs:date( substring-before( $j, '--' ) )
           order by file:last-modified( $filePath  )
           let $f := substring-after( $j, '--' )
           group by $f
           return
             <tr>{
                 for $td in tokenize( substring-before( $j[ last() ], '.txt' ), '--' )
                 return
                   <td>{ replace( $td, '\+', ' ' ) }</td> ,
                 let $file := file:read-text( $filePath[ last() ] )
                 let $data := tokenize( $file, '\.' )[ 2 ]
                 let $оценка := 
                   json:parse(
                     convert:binary-to-string( xs:base64Binary( $data ) )
                   )/json/оценка/text()
                 return
                   <td>{ $оценка }</td>,
                   let $url := 'http://localhost:9984/sandbox/ivgpu/api/v01/generate/exam-form'
                   let $path := 
                     'http://localhost:9984/static/ivgpu/euf/exBlank/2020/' || 
                     replace( $i, '\' || file:dir-separator(), '/' )
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
        'заголовок' : <div><span class = 'h3 text-left'>Группа: </span><br/><span>по преподавателю: </span></div>,
        'данные' : <div><ul>{ $данные }</ul></div>,
        'экзаменационныйЛист' : <div class = 'article d-none' style="width: 100%;"></div>
      }
   
   return
     funct:tpl( '/src/main.html', $params )
};