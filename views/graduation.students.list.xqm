
module namespace graduation  = 'graduation.root';

import module namespace request = "http://exquery.org/ns/request";
import module namespace session = "http://basex.org/modules/session";

import module namespace 
  bitrix.disk = 'bitrix.disk' 
    at '../modules/bitrix.disk.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/graduation/{ $year }/{ $department }/groups/{ $group }' )
  %output:method( 'xhtml' )
function graduation:view( $year, $department, $group ){
  
  let $группа := 
    bitrix.disk:getFileXLSX( '428956', map{ 'recursive' : 'yes', 'name' : $group } )
  
  let $списокСтудентов :=
    <table class = "table">
      <tr>
        <td>№ пп</td>
        <td>Студент</td>
        <td>Тема ВКР</td>
        <td>Руководитель</td>
      </tr>
      {
        for $i in $группа/file/table[ 1 ]/row
        count $c
        let $href-титулПрактика := 
          '/sandbox/ivgpu/generate/титул/преддипломная/' ||
          $group || '/' ||
          $i/cell[ @label = "Студент" ]/text()
        let $href-титулВКР := 
          '/sandbox/ivgpu/generate/титул/ВКР/' ||
          $group || '/' ||
          $i/cell[ @label = "Студент" ]/text()
        return
           <tr>
            <td>{ $c }.</td>
            <td>{ $i/cell[ @label = "Студент" ]/text() }</td>
            <td>{ $i/cell[ @label = "Тема ВКР" ]/text() }</td>
            <td>{ $i/cell[ @label = "ФИО руководителя ВКР" ]/text() }</td>
            <td><a href = "{ $href-титулПрактика }" class="btn btn-primary">Титул отчета по практике</a></td>
            <td><a href = "{ $href-титулВКР }" class="btn btn-primary">Титул ВКР</a></td>
          </tr>
      }
    </table>
    
  let $tpl := doc( "../html/main.tpl.html" )
  return
    $tpl update insert node <div>Темы ВКР студентов группы { $group } кафедры <a href = "../groups">"{ $department }"</a>{ $списокСтудентов }</div> into .//body
};