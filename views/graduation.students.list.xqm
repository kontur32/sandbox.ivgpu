
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
        return
           <tr>
            <td>{ $c }.</td>
            <td>{ $i/cell[ @label = "Студент" ]/text() }</td>
            <td>{ $i/cell[ @label = "Тема ВКР" ]/text() }</td>
            <td>{ $i/cell[ @label = "ФИО руководителя ВКР" ]/text() }</td>
          </tr>
      }
    </table>
    
  let $tpl := doc( "../html/main.tpl.html" )
  return
    $tpl update insert node <div>Темы ВКР студентов группы { $group } кафедры <a href = "../groups">"{ $department }"</a>{ $списокСтудентов }</div> into .//body
};