module namespace graduation  = 'graduation.root';

import module namespace request = "http://exquery.org/ns/request";
import module namespace session = "http://basex.org/modules/session";

import module namespace 
  bitrix.disk = 'bitrix.disk' 
    at '../modules/bitrix.disk.xqm';

declare variable $graduation:folderID := '428956';

declare 
  %rest:path( '/sandbox/ivgpu/graduation/{ $year }/{ $department }/groups' )
  %output:method( 'xhtml' )
function graduation:view( $year, $department ){
  let $группы := 
    bitrix.disk:getFileXLSX( $graduation:folderID, map{ 'recursive' : 'yes', 'name' : 'Список групп.xlsx' } )
  let $спискиГруппЗагруженные := 
    bitrix.disk:getFileList( $graduation:folderID, map{ 'recursive' : 'yes', 'name' : '.' } )/NAME/substring-before( text(), '.' )[ matches( ., '-[0-9]{2}' ) ]
  
  let $списокГрупп :=
    <div>Выпускные группы кафедры "{ $department }" в { $year } году:
      <table class = "table">
      {
        for $i in $группы/file/table[ 1 ]/row
        let $номерГруппы := $i/cell[ @label = "Группа" ]/text()
        let $href := 'groups/' || $номерГруппы
        let $hrefСлужебка := 
          '/sandbox/ivgpu/generate/Служебная/21/ТемыВКР/' || $номерГруппы
        return
           <tr>
             <td><a href = "{ $href }">{ $номерГруппы }</a></td>
             <td>
               {
                 if( $номерГруппы = $спискиГруппЗагруженные )
                 then(
                   <a href = "{ $hrefСлужебка }" class="btn btn-primary">Скачать служебку на темы</a>
                 )
                 else()
               }</td>
           </tr>
      }
      </table>
    </div>
    
  let $tpl := doc( "../html/main.tpl.html" )
  return
    $tpl update insert node <div>{ $списокГрупп }</div> into .//body
};